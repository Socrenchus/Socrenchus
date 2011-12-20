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

from ndb import model, polymodel
from google.appengine.api import users

import random


##########################
## Core Model and Logic ##
##########################

class Connection(model.Model):
  """
  Models a graph edge.
  """
  source = model.KeyProperty()
  target = model.KeyProperty()
  weight = model.IntegerProperty(default=0)

class Question(model.Model):
  """
  Models a question.
  """
  author = model.UserProperty(auto_current_user_add=True)
  value = model.TextProperty()
  answers = model.KeyProperty(repeated=True)
# assignments = model.Query(aQuestion)

class Answer(model.Model):
  """
  Models an answer.
  """
  author = model.UserProperty(auto_current_user_add = True)
  value = model.StringProperty()
  correctness = model.FloatProperty(default=0.0) # probability of answer being correct
  confidence = model.FloatProperty(default=0.0)  # probability of grading being correct
  graders = model.UserProperty(repeated=True) # FIXME: seems out of place
# parent = Question

  def canShowScore(self):
    """
    Determines if it is safe to show the user the score.
    """
    # TODO: implement a real check
    return self.author == users.get_current_user()

  def __json__(self):
    prop_filter = ['value', 'author']
    if self.canShowScore():
      prop_filter += ['correctness', 'confidence']
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field) and field in ['value', 'correctness', 'confidence', 'author']:
        output[field] = getattr(self, field)
    return output

##########################
## User Model and Logic ##
##########################

class UserData(model.Model):
  """
  Stores data specific to a user.
  """
  assignments = model.KeyProperty(repeated=True)

class Assignment(polymodel.PolyModel):
  """
  Models a generic assignment
  """
  user = model.UserProperty(auto_current_user_add = True)
  time = model.DateTimeProperty(auto_now_add = True)
# parent = assigned item
  
  @classmethod
  def assign(cls, item=None, user=None):
    """
    Assign an object (key) if it isn't already assigned
    """
    if not user:
      user = users.get_current_user()
    if not item:
      item = cls.getItem()
    instance = cls.getInstance(item, user)
    if not instance:
      instance = cls(parent=item)
      instance.user = user
      instance = instance.prepare()
      if instance:
        ud = UserData.get_or_insert(str(user.user_id()))
        ud.assignments.append(instance.key)
        ud.put()
    return instance
    
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    return cls.query(cls.user==user, ancestor=item).get()
  
  def prepare(self):
    """
    After initializing, prepare sets up and stores the assignment.
    """
    self.put()
    return self

class aQuestion(Assignment):
  """
  Models user specific question data.
  """
  liked = model.BooleanProperty(default=False)
  score = model.FloatProperty(default=0.0)
# user = model.UserProperty(auto_current_user = True)
# parent = question

  def __json__(self):
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field):
        output[field] = getattr(self, field)
    output['key'] = self.key.urlsafe()
    if self.key.parent():
      output['question'] = self.key.parent().get()
    output['_class'] = self.class_
    return output

class aShortAnswerQuestion(aQuestion):
  answer = model.KeyProperty()
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
    parent = self.key.parent().get()
    if len(parent.answers) >= 5:
      q = aGraderQuestion.assign(parent.key)
    
    teacherQ = aConfidentGraderQuestion.isGradingQuestion(parent.key)
        
    # Create the user's answer
    self.answer = Answer(value=myAnswer, parent=parent.key).put()
    parent.answers.append(self.answer)
    parent.put()
    
    # Assign the teacher to grade
    if not teacherQ:
      aConfidentGraderQuestion.assign(parent.key, parent.author)
    
    result = [self]
    
    if q:
      # Attach the question to the answer
      Connection(source=self.answer, target=q.key).put()
      result.append(q)

    self.put()
    
    # assign the grading question
    return result
    
  def __json__(self):
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field):
        output[field] = getattr(self, field)
    output['key'] = self.key.urlsafe()
    if self.key.parent():
      output['question'] = self.key.parent().get()
    if self.answer:
      output['score'] = self.answer.get().correctness
    output['_class'] = self.class_
    return output
    
class aMultipleAnswerQuestion(aQuestion):
  answers = model.KeyProperty(repeated=True)
  answer = model.KeyProperty(repeated=True)
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    myAnswers = []
    parent = self.key.parent().get()
    for i in parent.answers:
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
      
    myAnswers = []
    for a in self.answers:
      ans = a.get()
      if ans.value in answer:
        myAnswers.append(a)
    
    # None of the above case
    if len(answer) == 1 and answer[0] == 'None of the above':
      a = Answer.get_or_insert('none', value="None of the above")
      myAnswers.append(a)

    self.answer = myAnswers
    self.put()
    return [self]

class aMultipleChoiceQuestion(aQuestion):
  answers = model.KeyProperty(repeated=True)
  answer = model.KeyProperty()
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    myAnswers = []
    parent = self.key.parent().get()
    for i in parent.answers:
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

    self.answer = None
    for a in self.answers:
      ans = a.get()
      if ans.value in answer:
        self.answer = a

    self.put()

    return [self]

class aGraderQuestion(aMultipleAnswerQuestion):
  """
  Used to grade short answer questions.
  """
  @classmethod
  def gradedAnswer(cls, answer):
    """
    Returns a query for assignments that graded any given answer.
    """
    return aGraderQuestion.query(cls.answers==answer, ancestor=answer.parent())
  
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    answers = []
    parent = self.key.parent().get()
    for ans in parent.answers:
      answers.append(ans)
    
    random.shuffle(answers)
    
    # All answers waiting to be graded by count
    answerCount = {}
    query = aGraderQuestion.query(ancestor=self.key.parent())
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
      ans = a.get()
      answers.append(ans)
      
      # answer's current marks with grader's
      match = ans.correctness
      if not (ans.key in self.answer):
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
    answersToRegrade = []
    for a in answers:
      if not aConfidentGraderQuestion.hasGradedAnswer(a.key):
        markedCorrect = (a.key in self.answer)
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
          answersToRegrade.append(a)
    
    # recurse
    for a in answersToRegrade:
      query = aGraderQuestion.gradedAnswer(a.key)
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
  answerInQuestion = model.KeyProperty()
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned question.
    """
    user = item.get().author
    q = cls.query(ancestor=item)
    
    # TODO: fix none query
    q.filter(cls.user==user)
    for i in q.iter():
      if not i.answer:
        return i
      
    return None
  
  @classmethod
  def isGradingQuestion(cls, question_key):
    """
    True if the question is being graded
    """
    return bool(cls.getInstance(question_key))
    
  @classmethod
  def hasGradedAnswer(cls, answer):
    """
    True if the answer has been graded
    """
    q = cls.query(cls.answerInQuestion==answer, ancestor=answer.parent())
    return (q.count(1) > 0)
  
  def prepare(self):
    """
    Chooses the lowest confidence answer to grade.
    """
    minAns = Answer()
    minAns.confidence = 1.0
    existing = [x for x in aConfidentGraderQuestion.query(ancestor=self.key.parent())]
    parent = self.key.parent().get()
    for ans in parent.answers:
      a = ans.get()
      if a.confidence < minAns.confidence and not a in existing:
        minAns = a
      if minAns.confidence == 0.0:
        break
        
    if minAns.confidence == 1.0:
      self.key.delete()
      return None
    
    # add the answer in question
    self.answerInQuestion = minAns.key
    
    # add the answers
    answers = [
      'Definitely Correct',
      'Not Completely Correct',
      'Not Completely Wrong',
      'Definitely Wrong',
    ]
    if not self.answers:
      self.answers = []
    for gradingAnswer in answers:
      self.answers.append(Answer.get_or_insert(gradingAnswer,value=gradingAnswer).key)
      
    self.put()
    return self

  def submitAnswer(self, answer):
    """
    Submits the grade, regrades neighbors, and assigns 
    next ConfidentGraderQuestion.
    """
    
    # get the builder question
    builder = aBuilderQuestion.builderForQuestion(self.key.parent())
    
    # submit the grade
    a = self.answerInQuestion.get()
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

    self.answer = Answer.get_or_insert(answer,value=answer).key
    self.score = a.correctness
    self.put()
    
    # find neighbors
    query = aGraderQuestion.gradedAnswer(a.key)
    for q in query:
      q.grade()
      
    # assign next ConfidentGraderQuestion
    result = [self]
    parent = self.key.parent().get()
    next = aConfidentGraderQuestion.assign(parent.key, parent.author)
    if next:
      result.append(next)
    result.append(builder)

    return result
    
class aBuilderQuestion(aQuestion):
  """
  Creates a short answer question and tracks class progress.
  """
  answer = model.KeyProperty() # Question
  estimatedGrades = model.FloatProperty(repeated=True)
  confidentGrades = model.FloatProperty(repeated=True)
  @classmethod
  def getItem(cls):
    """
    Get the builder question.
    """
    txt = 'Think of a short answer question that you would ask your students...'
    return Question.get_or_insert('builderQuestion', value=txt, author=users.User('Personal Assistant')).key
  
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    q = cls.query(ancestor=item)
    # TODO: fix none query
    for i in q.filter(cls.user==user,cls.answer==None):
      if not i.answer:
        return i
        
    return None
  
  @classmethod
  def builderForQuestion(cls, question_key):
    return cls.query(cls.answer==question_key, ancestor=aBuilderQuestion.getItem()).get()  
  
  def submitAnswer(self, answer):
    """
    Create the short answer question.
    """
    self.answer = Question(value=answer).put()
    self.put()
    return [self]