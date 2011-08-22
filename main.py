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
from random import shuffle
import json

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
    >>> key = Question.createNewQuestion("The number of the counting shall be?",["3","1","2","5"],question_refs)
    
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
    >>> reference_url = 'http://www.example.com/q/'+str(key.id())
    
    Into a database object:
    
    >>> q = Question.parseRefUrl(reference_url)
    >>> q.value
    u'test'
    """
    if not aURL:
      return None
    o = urlparse.urlparse(aURL)
    q = Question.get_by_id(long(o.path.split('/')[2]))
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
  answer = db.ReferenceProperty(Answer)
  time = db.DateTimeProperty(auto_now = True)
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
    >>> assignment1.submitAnswer("oooo!")
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
    
    for ans in self.question.answers:
      if ans.value == answer_string:
        self.answer = ans
        self.put()
        # assign the next questions
        for q in self.answer.connections.fetch(5):
          Assignment.fromQuestion(q.target.key().id()).put()
    
    return True

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
    
    key = Question.createNewQuestion(question_text,answers,connection_urls)
    
    q = Question.get(key)
    
    # build the question url
    o = urlparse.urlparse(self.request.url)
    s = urlparse.urlunparse((o.scheme, o.netloc, '/q/'+str(key.id()), '', '', ''))
    
    # display it
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'LinkExplainer.html'))
    self.response.out.write(template.render(path, {'link':s,'question':q.value}, debug=_DEBUG))
    
class AskQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Assign the specified question.
    """
    # obtain the question
    qid = self.request.get('question_id')

    assignment = Assignment.fromQuestion(int(qid))
    assignment.put()

  def post(self):
    """
    Grade the answer that has been chosen.
    """
    # obtain the parameters
    qid = self.request.get('question_id')
    ans = self.request.get('answer')

    assignment = Assignment.fromQuestion(long(qid))
    success = assignment.submitAnswer(ans)

    if success:
      assignment.put()

    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode(success))



class RateQuestionHandler(webapp.RequestHandler):

  def post(self):
    """
    Handle the user rating the question.
    """
    # get the question object
    question_id = self.request.get('question_id')
    q = Question.get(question_id)
    
    # rate the question and store it
    q.rate()
    
class StreamHandler(webapp.RequestHandler):
  
  def get(self):
    """
    Return the user's question stream.
    """
    q = Assignment.all()
    q = q.filter('user =', users.User())
    q = q.order('time')
    assignments = q.fetch(10)
    
    result = []
    for a in assignments:
      answers = a.question.answers.fetch(4)
      shuffle(answers)
      result.append({
        'assignment': a,
        'answers': answers
      })
      
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode(result))

def main():
  application = webapp.WSGIApplication([
    ('/search', SearchHandler),
    ('/new', NewQuestionHandler),
    ('/ajax/stream', StreamHandler),
    (r'/ajax/ask', AskQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

