#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein.
# All rights reserved.
#

"""
The system currently known as Socrenchus is designed to be a personal tutor 
that not only caters to every student individually to help them learn, it also 
caters to every professor helping them build up the areas of their course that 
need work.

This is the database model and core logic.
"""

from google.appengine.ext import db
from google.appengine.api import users
from google.appengine.ext.db import polymodel

import random


##########################
## Core Model and Logic ##
##########################

class Connection(db.Model):
  """
  Models a graph edge.
  """
  source = db.ReferenceProperty(db.Model, collection_name="outgoing")
  target = db.ReferenceProperty(db.Model, collection_name="incoming")
  weight = db.IntegerProperty(default=0)

class Question(db.Model):
  """
  Models a question.
  """
  author = db.UserProperty(auto_current_user_add = True)
  value = db.TextProperty()
  answers = db.ListProperty(db.Key)
# incoming = db.Query(Connection<Answer>)
# outgoing = db.Query(Connection<Question>)
# assignments = db.Query(aQuestion)

class Answer(db.Model):
  """
  Models an answer.
  """
  author = db.UserProperty(auto_current_user_add = True)
  value = db.StringProperty(multiline=True)
  correctness = db.FloatProperty(default=0.0) # probability of answer being correct
  confidence = db.FloatProperty(default=0.0)  # probability of grading being correct
  question = db.ReferenceProperty(Question)
  graders = db.ListProperty(users.User) # FIXME: seems out of place
# outgoing = [db.Query(Connection<Question>)]

  def __json__(self):
    properties = self.properties().items()
    output = {}
    for field, value in properties:
      if field in ['value', 'correctness', 'confidence', 'author']:
        output[field] = getattr(self, field)
    return output

##########################
## User Model and Logic ##
##########################

class Assignment(polymodel.PolyModel):
  """
  Models a generic assignment
  """
  @classmethod
  def assign(cls, item=None, user=None):
    """
    Assign an object if it isn't already assigned
    """
    if not user:
      user = users.User()
    if not item:
      item = cls.getItem()
    instance = cls.getInstance(item, user)
    if not instance:
      instance = cls(parent=item)
      instance.user = user
      instance.put()
      instance = instance.prepare()
    return instance
    
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    q = cls.all()
    q = q.ancestor(item)
    return q.filter('user =', user).get()
  
  def prepare(self):
    self.put()
    return self

  user = db.UserProperty(auto_current_user_add = True)
  time = db.DateTimeProperty(auto_now_add = True)
# parent = db.ReferenceProperty(db.Model)

class aQuestion(Assignment):
  """
  Models user specific question data.
  """
  liked = db.BooleanProperty(default = False)
  score = db.FloatProperty(default=0.0)
# user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Question)

  def __json__(self):
    properties = self.properties().items()
    output = {}
    for field, value in properties:
      output[field] = getattr(self, field)
    output['key'] = str(self.key())
    if self.parent():
      output['question'] = self.parent()
    return output

class aShortAnswerQuestion(aQuestion):
  answer = db.ReferenceProperty(Answer)
  def submitAnswer(self, myAnswer):
    """
    Answers the question if it hasn't been answered.
    """
    if self.answer:
      return False    
    # get user (login is required in app.yaml)
    u = users.User()
    
    # Generate the assesment question
    q = None
    teacherQ = True
    if len(self.parent().answers) >= 5:
      q = aGraderQuestion.assign(self.parent())
    
    teacherQ = None
    for cgq in aConfidentGraderQuestion.all().filter('user =', self.parent().author).ancestor(self.parent()):
      if not cgq.answer:
        teacherQ = cgq
        
    # Create the user's answer
    self.answer = Answer(value=myAnswer).put()
    self.parent().answers.append(self.answer.key())
    self.parent().put()
    
    # Assign the teacher to grade
    if not teacherQ:
      aConfidentGraderQuestion.assign(self.parent(), self.parent().author)
    
    result = [self]
    
    if q:
      # Attach the question to the answer
      Connection(source=self.answer, target=q).put()
      result.append(q)

    self.put()
    
    # assign the grading question
    return result
    
  def __json__(self):
    properties = self.properties().items()
    output = {}
    for field, value in properties:
      output[field] = getattr(self, field)
    output['key'] = str(self.key())
    if self.parent():
      output['question'] = self.parent()
    if self.answer:
      output['score'] = self.answer.correctness
    return output
    
class aMultipleAnswerQuestion(aQuestion):
  answers = db.ListProperty(db.Key)
  answer = db.ListProperty(db.Key)
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    myAnswers = []
    for i in self.parent().answers:
      myAnswers.append(i)
      
    random.shuffle(myAnswers)
    self.answers = myAnswers
    self.put()
    return self
    
  def submitAnswer(self, answer):
    """
    Answers the question if it hasn't been answered.
    """
    if self.answer:
      return False

    self.answer = []
    for a in self.answers:
      ans = Answer.get(a)
      if ans.value in answer:
        self.answer.append(a)
    
    # None of the above case
    if len(answer) == 1 and answer[0] == 'None of the above':
      a = Answer.get_or_insert('none', value="None of the above")
      self.answer.append(a)

    self.put()

    return [self]

class aMultipleChoiceQuestion(aMultipleAnswerQuestion):
  pass

class aGraderQuestion(aMultipleAnswerQuestion):
  """
  Used to grade short answer questions.
  """
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    answers = []
    for ans in self.parent().answers:
      answers.append(ans)
    
    random.shuffle(answers)
    
    # All answers waiting to be graded by count
    answerCount = {}
    query = aGraderQuestion.all().ancestor(self.parent())
    for a in answers:
      answerCount[a] = 0
    for g in query:
      for a in g.answers:
        if a in answerCount.keys():
          answerCount[a] += 1
        else:
          answerCount[a] = 1
    
    # Find out how many assignments per answer to accept and still have enough
    target = min(answerCount.values())
    i = answerCount.values().count(target)
    while i < 5:
      target += 1
      i += answerCount.values().count(target)
    
    # Assign the answers
    i = 0
    for a in answers:
      if i >= 5:
        break
      if answerCount[a] <= target:
        self.answers.append(a)
        i += 1
      
    self.put()
    return self
  
  def submitAnswer(self, answer):
    """
    Runs the grading algorithm after answer is submitted.
    """
    if self.answer:
      return False

    # submit the answer like normal
    tmp = aMultipleAnswerQuestion.submitAnswer(self, answer)
    
    # grade
    self.grade()
    
    return tmp
    
  def grade(self):
    confidenceSum = 0.0
    maxPossibleConfidenceSum = 0.0
    answers = []
    for a in self.answers:
      # get and store the answer
      ans = Answer.get(a)
      answers.append(ans)
      
      # answer's current marks with grader's
      match = ans.correctness
      if not (ans.key() in self.answer):
        match = 1.0 - ans.correctness
      
      # give the grader some of the answer's confidence
      confidenceSum += match * ans.confidence
      
      # get the normalizer for the score
      if match < 0.5:
        match = 1 - match
      maxPossibleConfidenceSum += match * ans.confidence
      
    # error check
    if len(self.answers) == 0:
      return
      
    # normalize confidence (if no error)
    confidence = confidenceSum / float(len(self.answers))
    
    # grade with new found confidence
    for a in answers:
      cgq = aConfidentGraderQuestion.all().filter('answerInQuestion =',a).get()
      if not cgq or not cgq.answer:
        markedCorrect = (a.key() in self.answer)
        numGraders = len(a.graders)
        tmp = numGraders*(a.confidence * a.correctness)
        tmp += confidence * float(markedCorrect)
        if (confidence + numGraders*a.confidence) != 0:
          tmp /= (confidence + numGraders*a.confidence)
        a.correctness = tmp
        beforeConfidence = a.confidence
        a.confidence = (confidence + (a.confidence * numGraders)) / (1 + numGraders)
        a.graders.append(users.User())
        a.put()
      
        # recurse if condition is met
        # TODO: fiddle with condition
        if a.confidence - beforeConfidence > 0.1:
          query = aGraderQuestion.all().ancestor(self.parent()).filter('answers =',a.key())
          for q in query:
            q.grade()
    
    # calculate score (confidence normalized by maximum)
    if maxPossibleConfidenceSum != 0:
      self.score = (confidenceSum / maxPossibleConfidenceSum)
    self.put()
    
class aConfidentGraderQuestion(aMultipleChoiceQuestion):
  """
  Allows the creator of a short answer question to set the baseline.
  """
  answerInQuestion = db.ReferenceProperty(Answer)
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned question.
    """
    q = cls.all()
    q = q.ancestor(item)
    return q.filter('user =', user).filter('answer =',None).get()
  
  def prepare(self):
    """
    Chooses the lowest confidence answer to grade.
    """
    minAns = Answer()
    minAns.confidence = 1.0
    existing = [x for x in aConfidentGraderQuestion.all().ancestor(self.parent())]
    for ans in self.parent().answers:
      a = Answer.get(ans)
      if a.confidence < minAns.confidence and not a in existing:
        minAns = a
      if minAns.confidence == 0.0:
        break
        
    if minAns.confidence == 1.0:
      self.delete()
      return None
    
    # add the answer in question
    self.answerInQuestion = minAns.key()
    
    # add the answers
    answers = [
      'Definitely Correct',
      'Not Completely Correct',
      'Not Completely Wrong',
      'Definitely Wrong',
    ]
    for gradingAnswer in answers:
      self.answers.append(Answer.get_or_insert(gradingAnswer,value=gradingAnswer).key())
      
    self.put()
    return self

  def submitAnswer(self, answer):
    """
    Submits the grade, regrades neighbors, and assigns 
    next ConfidentGraderQuestion.
    """
    
    # get the builder question
    builder = aBuilderQuestion.all().filter('answer =',self.parent()).get()    
    
    # submit the grade
    a = self.answerInQuestion
    builder.estimatedGrades.append(a.correctness) # add the prior to the chart
    a.correctness = {
      'Definitely Correct': 1.0,
      'Not Completely Correct': 0.75,
      'Not Completely Wrong': 0.25,
      'Definitely Wrong': 0.0,
    }[answer]
    builder.confidentGrades.append(a.correctness) # add the post to the chart
    builder.put()
    a.confidence = 1.0
    a.put()
    
    self.answer.append(Answer(value=answer).put())
    self.score = a.correctness
    self.put()
    
    # find neighbors
    query = aGraderQuestion.all().ancestor(self.parent()).filter('answers =',a.key())
    for q in query:
      q.grade()
      
    # assign next ConfidentGraderQuestion
    result = [self]
    next = aConfidentGraderQuestion.assign(self.parent(), self.parent().author)
    if next:
      result.append(next)
    result.append(aBuilderQuestion.all().filter('answer =',self.parent()).get())

    return result
    
class aBuilderQuestion(aQuestion):
  """
  Creates a short answer question and tracks class progress.
  """
  answer = db.ReferenceProperty(Question)
  estimatedGrades = db.ListProperty(float)
  confidentGrades = db.ListProperty(float)
  @classmethod
  def getItem(cls):
    """
    Get the builder question.
    """
    txt = 'Think of a short answer question that you would ask your students...'
    return Question.get_or_insert('builderQuestion', value=txt, author=users.User('Personal Assistant'))
  
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    q = cls.all()
    q = q.ancestor(item)
    return q.filter('user =', user).filter('answer =',None).get()
  
  def submitAnswer(self, answer):
    """
    Create the short answer question.
    """
    self.answer = Question(value=answer).put()
    self.put()
    return [self]