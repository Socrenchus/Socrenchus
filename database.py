#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
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
from search import *
from random import shuffle

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

class Question(Searchable, db.Model):
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
  value = db.StringProperty()
  correctness = db.FloatProperty(default=0.0) # probability of answer being correct
  confidence = db.FloatProperty(default=0.0)  # probability of grading being correct
  question = db.ReferenceProperty(Question)
  graders = db.ListProperty(users.User) # FIXME: seems out of place
# outgoing = [db.Query(Connection<Question>)]

  def __json__(self):
    properties = self.properties().items()
    output = {}
    for field, value in properties:
      if field in ['value', 'correctness', 'author']:
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
  def assign(cls, item, user=None):
    if not user:
      user = users.User()
    instance = cls.all()
    instance = instance.ancestor(item)
    instance = instance.filter('user =', user).get()
    if not instance:
      instance = cls(parent=item)
      instance.user = user
      instance.prepare()
      instance.put()
    return instance
  
  def prepare(self):
    pass

  user = db.UserProperty(auto_current_user = True)
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

class aNumericAnswerQuestion(aQuestion):
  """
  Handles questions that evaluate numerically.
  """
  pass

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
    else:
      teacherQ = aConfidentGraderQuestion.all().filter('user =', self.parent().author).ancestor(self.parent()).filter('answer =',None).get()
        
    # Create the user's answer
    self.answer = Answer(value=myAnswer).put()
    self.parent().answers.append(self.answer.key())
    
    # Assign the teacher to grade
    if not teacherQ:
      aConfidentGraderQuestion.assign(self.parent(), self.parent().author)
    
    result = [self]
    
    if q:
      # Attach the question to the answer
      Connection(source=self.answer, target=q).put()
      result.append(Assignment.assign(q))

    self.put()
    
    # assign the grading question
    return result
    
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
      
    shuffle(myAnswers)
    self.answers = myAnswers
    self.put()
    
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
    
    shuffle(answers)
    
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
    confidence = 0.0
    normalizer = 0.0
    answers = []
    for a in self.answers:
      ans = Answer.get(a)
      answers.append(ans)
      normalizer += ans.confidence
      markedCorrect = (ans.key() in self.answer)
      answerCorrect = (ans.correctness > 0.65)
      if markedCorrect == answerCorrect:
        confidence += ans.confidence
    if normalizer != 0:
      confidence /= float(normalizer)
    
    # grade with new found confidence
    for a in answers:
      markedCorrect = (a.key() in self.answer)
      numGraders = len(a.graders)
      tmp = numGraders*(a.confidence * a.correctness)
      tmp += confidence * float(markedCorrect)
      if (confidence + numGraders*a.confidence) != 0:
        tmp /= (confidence + numGraders*a.confidence)
      a.correctness = tmp
      a.confidence = (confidence + (a.confidence * numGraders)) / (1 + numGraders)
      a.graders.append(users.User())
      a.put()
    
    self.score = confidence
    self.put()
    
class aConfidentGraderQuestion(aMultipleChoiceQuestion):
  """
  Allows the creator of a short answer question to set the baseline.
  """
  answerInQuestion = db.ReferenceProperty(Answer)
  def prepare(self):
    """
    Chooses the lowest confidence answer to grade.
    """
    minAns = Answer()
    minAns.confidence = 1.0
    for ans in self.parent().answers:
      a = Answer.get(ans)
      if a.confidence < minAns.confidence:
        minAns = a
      if minAns.confidence == 0.0:
        break
    
    # add the answer in question
    self.answerInQuestion = minAns.key()
    
    # add the answers
    answers = [
      'Definetly Correct',
      'Not Completely Correct',
      'Not Completely Wrong',
      'Definetly Wrong',
    ]
    for gradingAnswer in answers:
      self.answers.append(Answer(value=gradingAnswer).put())
      
    self.put()

  def submitAnswer(self, answer):
    """
    Submits the grade, regrades neighbors, and assigns 
    next ConfidentGraderQuestion.
    """
    
    # submit the grade
    a = Answer.get(self.answers[0])
    a.correctness = {
      'Definetly Correct': 1.0,
      'Not Completely Correct': 0.75,
      'Not Completely Wrong': 0.5,
      'Definetly Wrong': 0.0,
    }[answer]
    a.confidence = 1.0
    a.put()
    
    # TODO: fix
    self.answer.append(Answer(value=answer).put())
    self.put()
    
    # find neighbors
    # TODO: Go out a certain radius
    query = aGraderQuestion.all().ancestor(self.parent()).filter('answers =',a.key())
    for q in query:
      q.grade()
      
    # assign next ConfidentGraderQuestion
    # TODO: Fix this design problem
    return [self, aConfidentGraderQuestion.assign(self.parent())]