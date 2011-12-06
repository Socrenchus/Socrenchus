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
# answers = db.Query(Answer)
# incoming = db.Query(Connection<Answer>)
# outgoing = db.Query(Connection<Question>)
# assignments = db.Query(aQuestion)

  def rate(self):
    """
    Rate the question and associated connections and store it.
    """
    result = False
  
    # get user (login is required in app.yaml)
    u = users.User()
  
    # get all the users answers
    answers = list(Answer.all().filter("user =", u))

    # get connections to adjust
    connections = self.incoming.filter("source in", answers)

    # rate and adjust connection weights
    if u in self.liked:
      result = False
      # unlike the question
      self.liked.remove(u)
      # decrease connection weights
      for c in connections:
        c.weight -= 1
        c.put()
    
    else:
      result = True
      # like the question
      self.liked.append(u)
      # increase connection weights
      for c in connections:
        c.weight += 1
        c.put()
  
    # store the question
    self.put()
    return result
  
  def getAnswer(self, myAnswer):
    """
    Returns an answer object from a string.
    """
    for ans in self.answers:
      if ans.value == myAnswer:
          return ans
          
    # returns None if answer isn't found
    return None

class MultipleAnswerQuestion(Question):
  """
  Handles questions that have more than one correct answer.
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
  def getAnswer(self, myAnswer):
    """
    Returns an answer object from a string.
    """
    result = None
    for ans in self.answers:
      if ans.value == myAnswer:
          result = ans
    
    if not result:
      result = Answer(question=self,value=myAnswer)
      result.put()
    
    return result

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
  question = db.ReferenceProperty(Question, collection_name="answers")
  value = db.TextProperty()
  correctness = db.FloatProperty() # probability of answer being correct
  confidence = db.FloatProperty()  # probability of grading being correct
# outgoing = [db.Query(Connection<Question>)]
  
class Lesson(db.Model):
  """
  Models a lesson.
  """
  author = db.UserProperty(auto_current_user_add = True)
  title = db.StringProperty()
# incoming = [db.Query(Connection<Question>)]

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

class aLesson(Assignment):
  """
  Models user specific lesson data.
  """
# user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Lesson)
# assigned_questions = db.Query(aQuestion)

class aQuestion(Assignment):
  """
  Models user specific question data.
  """
  liked = db.BooleanProperty(default = False)
# user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Question)
      
class aShortAnswerQuestion(aQuestion):
  answer = db.ReferenceProperty(Answer)
  def submitAnswer(self, answer):
    """
    Answers the question if it hasn't been answered.
    """
    if self.answer:
      return False    
    # get user (login is required in app.yaml)
    u = users.User()
    
    answers = []
    for ans in self.parent().answers:
      answers.append(ans)
    
    # Generate the assesment question
    txt = "Check all the answers you believe correctly answer the question. "
    txt += "(" + self.parent().value + ")"
    q = MultipleAnswerQuestion(value=txt)
    q.put()
    
    shuffle(answers)
    # Add the answers to the question
    for i in range(5):
      answers[i].question = q
      answers[i].put()
      
    # Get/create the user's answer
    self.answer = self.parent().getAnswer(answer)
    
    # Attach the question to the answer
    Connection(source=self.answer, target=q).put()

    self.put()
    
    # assign the grading question
    return [self,Assignment.assign(self.answer.outgoing.get().target)]
  
class aMultipleAnswerQuestion(aQuestion):
  answers = db.StringListProperty()
  answer = db.ListProperty(db.Key)
  def prepare(self):
    """
    Assigns the answers from the question.
    """
    myAnswers = []
    for i in self.parent().answers:
      myAnswers.append(i.value)
      
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
    for a in answer:
      self.answer.append(self.parent().getAnswer(a).key())

    self.put()

    # TODO: Assign next questions
    return None