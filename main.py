#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.

This line logs the user in for our unit tests:
>>> os.environ['USER_EMAIL'] = u'test@example.com'
"""

__author__ = 'Bryan Goldstein'

import cgi
import datetime
import os
import re
import sys
import urllib
import urlparse
import wsgiref.handlers
import random

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'

from google.appengine.dist import use_library
use_library('django', '1.2')

from google.appengine.api import datastore
from google.appengine.api import datastore_types
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template
from search import *

_DEBUG = True

#################################################################################
##  Database Models #############################################################
#################################################################################

class Question(Searchable,db.Model):
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
  author = db.UserProperty(auto_current_user_add=True)
  liked = db.ListProperty(users.User)
  INDEX_TITLE_FROM_PROP = 'value'

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
    
    # get user (login is required in app.yaml)
    u = users.User()
    
    # get all the users answers
    answers = list(Answer.all().filter("user =", u))

    # get connections to adjust
    connections = self.incoming.filter("source in", answers)

    # rate and adjust connection weights
    if u in self.liked:
      # unlike the question
      self.liked.remove(u)
      # decrease connection weights
      for c in connections:
        c.weight -= 1
        c.put()
    else:
      # like the question
      self.liked.append(u)
      # increase connection weights
      for c in connections:
        c.weight += 1
        c.put()
    
    # store the question
    self.put()

  @staticmethod
  def parseRefUrl(aURL):
    """
    Turns a reference URL:
    
    >>> key = Question(value=u'test').put()
    >>> reference_url = 'http://www.example.com/'+str(key)
    
    Into a database object:
    
    >>> q = Question.parseRefUrl(reference_url)
    >>> q.value
    u'test'
    """
    if not aURL:
      return None
    o = urlparse.urlparse(aURL)
    q = Question.get(o.path.split('/')[1])
    return q

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

#################################################################################
##  Request Handlers ############################################################
#################################################################################

class SearchHandler(webapp.RequestHandler):

  def get(self):
    """
    Search for existing entry.
    """
    q = self.request.get('q')
    results = None
    if q:
      results = Question.search(q)
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'SearchQuestion.html'))
    self.response.out.write(template.render(path, {"results":results,"query":q}, debug=_DEBUG))

class NewQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Displays the new question form.
    """
    # grab the url arguments to put them into the form
    url_args = {}
    for a in self.request.arguments():
      url_args[a] = self.request.get(a)

    # generate the template
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'NewQuestion.html'))
    self.response.out.write(template.render(path, {'url_args':url_args}, debug=_DEBUG))

  def post(self):
    """
    Stores a newly created question.
    """
    question_text = self.request.get('question')
    answers = [self.request.get(str(i)+'-a') for i in range(4)]
    connection_urls = [Question.parseRefUrl(self.request.get(str(i)+'-n')) for i in range(4)]
    
    key = NewQuestionHandler.createNewQuestion(question_text,answers,connection_urls)
    
    # build the question url
    o = urlparse.urlparse(self.request.url)
    s = urlparse.urlunparse((o.scheme, o.netloc, '/'+str(key), '', '', ''))
    
    # display it
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'LinkExplainer.html'))
    self.response.out.write(template.render(path, {'link':s,'question':q.value}, debug=_DEBUG))
  
  @staticmethod
  def createNewQuestion(question_text,answers,connection_urls):
    """
    Create the new Question, Answers, and Connections.
    The first answer in the list is correct and the others are incorrect.
    The connections match up their order with the answers.
    
    It will take the user specified question references:
    >>> question_refs = []
    >>> for i in range(4):
    ...   question_refs.append(str(Question(value=str(i)).put()))
    
    Create a question with answers and connections returning only the question key:
    >>> key = NewQuestionHandler.createNewQuestion("The number of the counting shall be?",["3","1","2","5"],question_refs)
    
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
      target = connection_urls[i]
      if (target):
        c = Connection()
        c.target = Question.get(target)
        c.source = a
        c.put()

    # index question
    q.index()
    
    # return our key
    return q.key()
    
class AskQuestionHandler(webapp.RequestHandler):

  def get(self,key):
    """
    Display the specified question.
    """
    self.response.out.write(self.display(key))

  def post(self,key):
    """
    Grade the answer that has been chosen.
    """
    # obtain the submitted answer
    ans = self.request.get('answer')
    
    self.response.out.write(self.display(key))
    
  @staticmethod
  def display(key,ans=None):
    """
    >>> key = NewQuestionHandler.createNewQuestion("The number of the counting shall be?",["3","1","2","5"],["","","",""])
    
    Either ask the question 
    
    >>> output = AskQuestionHandler.display(key)
    >>> "The number of the counting shall be?" in output
    True
    >>> "5" in output
    True
    
    or after the user answers the question
    
    >>> output = AskQuestionHandler.display(key,"3")
    >>> "Correct" in output
    True
    
    show the result page.
    
    >>> refresh_output = AskQuestionHandler.display(key)
    
    >>> output == refresh_output
    True
    
    """
    # get the current question
    q = Question.get(key)

    # check if it is being answered
    answered_now = bool(ans)

    # check if the user answered the question before
    answered_before = False
    for a in q.answers:
      if users.User() in a.user:
        ans = a.value
        answered_before = True

    if answered_before or answered_now:
      # find the associated answer to get correctness and connections
      correctness = False
      next_questions = []
      for a in q.answers:
        if ans == a.value:
          correctness = a.correct
          next_questions = a.connections.order('weight').fetch(5)
          if not answered_before:
            a.user.append(users.User())
            a.put()
        
      # build the template
      template_vars = {
        "current" : q,
        "next" : next_questions,
        "correct" : correctness,
        "answer_changed" : answered_now and answered_before,
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'Response.html'))
      return template.render(path, template_vars, debug=_DEBUG)
    else:
      answers = [a.value for a in q.answers]
      random.shuffle(answers)

      # create the template
      template_vars = {
        "question_text" : q.value,
        "answers" : answers,
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'AskQuestion.html'))
      return template.render(path, template_vars, debug=_DEBUG)
    
    
class RateQuestionHandler(webapp.RequestHandler):

  def post(self):
    """
    Handle the user rating the question.
    """
    # get the question object
    question_key = self.request.get('question_key')
    q = Question.get(question_key)
    
    # rate the question and store it
    q.rate()

def main():
  application = webapp.WSGIApplication([
    ('/', SearchHandler),
    ('/new', NewQuestionHandler),
    (r'/(.+)', AskQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

