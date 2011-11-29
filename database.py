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
from search import *

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
# answers = db.Query(Answer)
# incoming = db.Query(Connection<Answer>)
# outgoing = db.Query(Connection<Lesson>)
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
  
  def getAnswer(myAnswer):
    """
    Returns an answer object from a string.
    """
    for ans in self.question.answers:
      if ans.value == answer_string:
          return ans
          
    # returns None if answer isn't found
    return None
  
class MultiplePickQuestion(Question):
  """
  Handles questions that have more than one correct answer.
  """
  pass
class MultipleChoiceQuestion(MultiplePickQuestion):
  """
  Handles multiple choice questions.
  """
  pass
class SortAnswerQuestion(Question):
  """
  Handles short answer questions.
  """
  pass
class BuilderQuestion(SortAnswerQuestion):
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
  correctness = db.FloatProperty()
  confidence = db.FloatProperty()
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

class Assignment(db.Model):
  """
  Models a generic assignment
  """
  @staticmethod
  def assign(question):
    assignmentClass = eval('a'+question.__class__.__name__)
    instance = assignmentClass.all()
    instance = instance.ancestor(question)
    instance = instance.filter('user =', users.User()).get()
    if instance:
      return instance
    else:
      return assignmentClass(parent=question)

  user = db.UserProperty(auto_current_user = True)
  time = db.DateTimeProperty(auto_now = True)
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
  answers = db.StringListProperty()
  answer = db.ReferenceProperty(Answer)
  liked = db.BooleanProperty(default = False)
# user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Question)

  def submitAnswer(self, answer_string):
    """
    Answers the question if it hasn't been answered.
    """
    if self.answer:
      return False

    self.answer = self.question.getAnswer(answer_string)
    self.put()
    # assign the next questions
    for q in self.answer.outgoing.fetch(5):
      aQuestion(q.target).put()

      return result