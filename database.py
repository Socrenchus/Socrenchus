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

class Question(Searchable, polymodel.PolyModel):
  """
  Models a question.
  """
  author = db.UserProperty(auto_current_user_add = True)
  value = db.TextProperty()
  answers = db.ListProperty(db.Key)
# incoming = db.Query(Connection<Answer>)
# outgoing = db.Query(Connection<Question>)
# assignments = db.Query(aQuestion)

class MultipleAnswerQuestion(Question):
  """
  Handles questions that involve selecting the correct answer(s).
  """
class GraderQuestion(MultipleAnswerQuestion):
  """
  Handles the grading of short answer questions.
  """
  pass
class MultipleChoiceQuestion(MultipleAnswerQuestion):
  """
  Handles multiple choice questions.
  """
  pass
class ShortAnswerQuestion(Question):
  """
  Handles short answer questions.
  """
  pass

class BuilderQuestion(ShortAnswerQuestion):
  """
  Handles questions that are made to generate content.
  """
  pass
  
class Answer(db.Model):
  """
  Models an answer.
  """
  author = db.UserProperty(auto_current_user_add = True)
  value = db.StringProperty()
  correctness = db.FloatProperty(default=0.0) # probability of answer being correct
  confidence = db.FloatProperty(default=0.0)  # probability of grading being correct
  questions = db.ListProperty(db.Key)
  graders = db.ListProperty(users.User)
# outgoing = [db.Query(Connection<Question>)]

  def __json__(self):
    return {'value':self.value,'corectness':self.correctness}

##########################
## User Model and Logic ##
##########################

class Assignment(polymodel.PolyModel):
  """
  Models a generic assignment
  """
  @staticmethod
  def assign(item):
    assignmentClass = eval('a'+item.__class__.__name__)
    instance = assignmentClass.all()
    instance = instance.ancestor(item)
    instance = instance.filter('user =', users.User()).get()
    if not instance:
      instance = assignmentClass(parent=item)
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
# user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Question)

  def __json__(self):
    properties = self.properties().items()
    output = {}
    for field, value in properties:
      output[field] = getattr(self, field)
    output['id'] = self.key().id()
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
    
    answers = []
    for ans in self.parent().answers:
      answers.append(Answer.get(ans))
    
    # Generate the assesment question
    txt = "Check all the answers you believe correctly answer the question. "
    txt += "(" + self.parent().value + ")"
    q = GraderQuestion(value=txt)
    q.author = users.User('grader@socrench.us')
    q.put()
    
    shuffle(answers)
    
    # Find min questions per answer
    countByQPA = {}
    for a in answers:
      i = len(a.questions)
      if i in countByQPA.keys():
        countByQPA[i] += 1
      else:
        countByQPA[i] = 1
    
    # Find out how many QPA to accept and still have enough
    targetQPA = min(countByQPA.keys())
    i = countByQPA[targetQPA]
    while i < 10:
      targetQPA = countByQPA.keys()[countByQPA.keys().index(targetQPA)+1]
      i += countByQPA[targetQPA]
    
    # Add the answers to the question
    i = 0
    for a in answers:
      if i >= 5:
        break
      if len(a.questions) <= targetQPA:
        q.answers.append(a.key())
        a.questions.append(q.key())
        a.put()
        i += 1
      
    q.put()
      
    # Create the user's answer
    self.answer = Answer(value=myAnswer).put()
    self.parent().answers.append(self.answer.key())
    
    # Attach the question to the answer
    Connection(source=self.answer, target=q).put()

    self.put()
    
    # assign the grading question
    return [self,Assignment.assign(self.answer.outgoing.get().target)]
  
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
    
class aGraderQuestion(aMultipleAnswerQuestion):
  """
  Used to grade short answer questions. Cannot be assigned manually.
  """
  def submitAnswer(self, answer):
    """
    Runs the grading algorithm after answer is submitted.
    """
    if self.answer:
      return False
    
    # gather probabilities
    confidence = 0.0
    normalizer = 0.0
    answers = []
    for a in self.answers:
      ans = Answer.get(a)
      answers.append(ans)
      normalizer += ans.confidence
      markedCorrect = (ans.value in answer)
      answerCorrect = (ans.correctness > 0.5)
      if markedCorrect == answerCorrect:
        confidence += ans.confidence
    if normalizer != 0:
      confidence /= float(normalizer)
    
    # grade with new found confidence
    for a in answers:
      markedCorrect = (a.value in answer)
      numGraders = len(a.graders)
      tmp = numGraders*(a.confidence * a.correctness)
      tmp += confidence * float(markedCorrect)
      if (confidence + numGraders*a.confidence) != 0:
        tmp /= (confidence + numGraders*a.confidence)
      a.correctness = tmp
      a.confidence = (confidence + (a.confidence * numGraders)) / (1 + numGraders)
      a.graders.append(users.User())
      a.put()

    # submit the answer like normal
    return aMultipleAnswerQuestion.submitAnswer(self, answer)