#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.

This file contains all the database models and the logic
that can be performed on them.

This line logs the user in for our unit tests:
>>> os.environ['USER_EMAIL'] = u'test@example.com'
"""

__author__ = 'Bryan Goldstein'

import os
from random import shuffle

from google.appengine.api import datastore
from google.appengine.api import datastore_types
from google.appengine.api import users
from google.appengine.ext import db
from search import *

_DEBUG = True

class Question(Searchable, db.Model):
  """
  Searchable db.Model for a question object
  
  You can create a question with only question text:
  >>> my_question = Question(value=u'What is your favorite color?')
  
  The author is set automatically:
  >>> my_question.author
  users.User(email='test@example.com')
  
  Store your question:
  >>> key = my_question.put()
  
  You can retrieve it with a key:
  >>> q = Question.get(key)
  >>> q.value == my_question.value
  True
  
  """
  value = db.TextProperty()
  author = db.UserProperty(auto_current_user_add = True)
  liked = db.ListProperty(users.User)
  time = db.DateTimeProperty(auto_now_add = True)
  INDEX_TITLE_FROM_PROP = 'value'
  
  @staticmethod
  def createNewQuestion(question_text,answers,connected_ids):
    """
    Create the new Question, Answers, and Connections.
    The first answer in the list is correct and the others are incorrect.
    The connections match up their order with the answers.
    
    It will take the user specified questions:
    >>> ids = [[Question(value="ello").put().id()],[],[],[]]
    
    Create a question with answers and connections returning only the question key:
    >>> key = Question.createNewQuestion("The number of the counting shall be?",["3","1","2","5"],ids)
    
    You can get the Question object with:
    >>> q = Question.get(key)
    
    And make sure it is the one you meant to create:
    >>> q.value
    u'The number of the counting shall be?'
    >>> for i in range(4):
    ...   q.answers[i].value
    u'3'
    u'1'
    u'2'
    u'5'
    >>> len(q.answers[0].connections.fetch(2))
    1
    """
    # create the question
    q = Question()
    q.value = question_text
    q.put()

    # loop through the four answers
    for i in range(len(answers)):
      # now create the answer
      a = Answer()
      a.value = answers[i]
      a.correct = (i == 0)
      a.question = q
      a.put()
      # create the connection if included
      if connected_ids:
        target = connected_ids[i]
        for t in target:
          c = Connection()
          c.target = Question.get_by_id(long(t))
          c.source = a
          c.put()

    # index question
    q.index()
    
    # return our key
    return q.key()
    
  def rate(self):
    """
    Rate the question and associate connection and store it.

    Start with one question and ten answers that connect to it;
    Only the odd answers were chosen by the user:
    >>> question = Question(value=u'hi')
    >>> key = question.put()
    >>> answers = []
    >>> connections = []
    >>> for i in range(10):
    ...   answers.append(Answer(value=str(i)))
    ...   key = answers[i].put()
    ...   connections.append(Connection(source=answers[i],target=question).put())
    ...   if i % 2 == 1:
    ...     answers[i].user.append(users.User())
    ...   key = answers[i].put()

    Now the user can rate the question:
    >>> question.rate()
    True
    
    Now the even connections are ranked lower then odd ones:
    >>> even = 0L
    >>> odd = 0L
    >>> for i in range(10):
    ...   if i % 2 == 0:
    ...     even += Connection.get(connections[i]).weight
    ...   else:
    ...     odd += Connection.get(connections[i]).weight
    >>> even < odd
    True
    
    We can also see that the user has been added to the question's liked list:
    >>> users.User() in question.liked
    True
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

class Answer(db.Model):
  """
  Holds an answer,
  
  >>> answer = Answer(value=u'world!')
  
  along with its question
  
  >>> answer.question = Question.get(Question(value=u'hello').put())
  
  and correctness
  
  >>> answer.correct = True
  
  >>> key = answer.put()
  
  and connections
  
  >>> connection_key = Connection(weight=5,source=answer).put()
  
  see
  
  >>> answer = Answer.get(key)
  >>> answer.question.value
  u'hello'
  >>> answer.value
  u'world!'
  >>> answer.connections.fetch(1)[0].weight
  5L
  """
  value = db.TextProperty()
  correct = db.BooleanProperty()
  question = db.ReferenceProperty(Question, collection_name="answers")
  user = db.ListProperty(users.User)

class Connection(db.Model):
  """
  Holds a directed connection
  
  >>> connection = Connection(weight=9000L)
  
  from an answer
  
  >>> connection.source = Answer(value="42").put()
  
  to a question.
  
  >>> connection.target = Question(value="What is the ultimate question?").put()
  
  >>> key = connection.put()
  
  see
  
  >>> connection = Connection.get(key)
  >>> connection.source.value
  u'42'
  >>> connection.target.value
  u'What is the ultimate question?'
  >>> connection.weight
  9000L
  """
  target = db.ReferenceProperty(Question,collection_name="incoming")
  weight = db.IntegerProperty(default=0)
  source = db.ReferenceProperty(Answer,collection_name="connections")
  
class Assignment(db.Model):
  """
  Links a question to the current user.

  >>> key = Assignment(question = Question(value = u'test').put()).put()
  >>> a = Assignment.get(key)

  >>> a.question.value
  u'test'

  >>> a.user.email()
  u'test@example.com'

  >>> a.time != None
  True
  """
  question = db.ReferenceProperty(Question, collection_name = "assignments")
  answers = db.StringListProperty()
  answer = db.ReferenceProperty(Answer)
  list = db.TextProperty(default="assignments")
  time = db.DateTimeProperty(auto_now = True)
  liked = db.BooleanProperty(default = False)
  user = db.UserProperty(auto_current_user_add = True)

  @staticmethod
  def fromQuestion(qid):
    """
    Create an assignment 
    
    >>> q = Question(value=u'hello').put()
    >>> key = Assignment.fromQuestion(q.id()).put()
    
    or get it back from a question id.
    
    >>> Assignment.fromQuestion(q.id()).key() == key
    True
    
    """
    q = Question.get_by_id(qid)
    result = q.assignments.filter('user =', users.User()).get()
    
    if not result:
      result = Assignment(question = q)
      result.answers = []
      for answer in result.question.answers:
        result.answers.append(answer.value)
        if users.User() == result.question.author and answer.correct:
          result.answer = answer
      shuffle(result.answers)
      result.put()
    
    return result

  def submitAnswer(self, answer_string):
    """
    Answers the question if it hasn't been answered.
    
    Create a two questions liked through an answer:
    >>> first_question = Question(value=u'hello').put()
    >>> answer = Answer(value=u'oooo!',question=first_question).put()
    >>> next_question = Question(value=u'world').put()
    >>> connection = Connection(source=answer,target=next_question).put()
    
    Try answering it:
    >>> assignment1 = Assignment.fromQuestion(first_question.id())
    >>> key = assignment1.put()
    >>> len(assignment1.submitAnswer("oooo!")) == 2
    True
    
    Find the assignment:
    >>> Assignment.all().filter('question =', next_question).get() != None
    True
    
    Try changing your answer:
    >>> assignment1.submitAnswer("ahhhh!")
    False
    """
    if self.answer:
      return False
    
    result = []
    for ans in self.question.answers:
      if ans.value == answer_string:
        self.answer = ans
        self.put()
        result.append(self)
        # assign the next questions
        for q in self.answer.connections.fetch(5):
          tmp = Assignment.fromQuestion(q.target.key().id())
          result.append(tmp)
          tmp.put()
    
    return result
