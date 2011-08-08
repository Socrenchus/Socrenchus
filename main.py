#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.
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

class Question(Searchable,db.Model):
  """
  Model for a question object. Correct answer stored first.
  """
  value = db.TextProperty()
  INDEX_TITLE_FROM_PROP = 'value'
  
  @staticmethod
  def parseRefUrl(aURL):
    """
    Turns a reference URL into a database object.
    """
    if not aURL:
      return None
    o = urlparse.urlparse(aURL)
    q = Question.get(o.path.split('/')[1])
    return q
    
class Answer(db.Model):
  """
  Holds an answer, along with its correctness and connections.
  """
  value = db.TextProperty()
  correct = db.BooleanProperty()
  question = db.ReferenceProperty(Question, collection_name="answers")
  
class Connection(db.Model):
  """
  Holds a directed connection from an answer to a question.
  """
  target = db.ReferenceProperty(Question)
  weight = db.IntegerProperty()
  answer = db.ReferenceProperty(Answer,collection_name="connections")
  
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
    # create the question
    q = Question()
    q.value = self.request.get('question')
    q.put()
    
    # loop through the four answers
    for i in range(4):
      # now create the answer
      a = Answer()
      a.value = self.request.get(str(i)+'-a')
      a.correct = (i == 0)
      a.question = q
      a.put()
      # create the connection if included
      target = Question.parseRefUrl(self.request.get(str(i)+'-n'))
      if (target):
        c = Connection()
        c.target = Question.get(target)
        c.answer = a
        c.put()
      
    # index question
    q.index()
    
    # build the question url
    o = urlparse.urlparse(self.request.url)
    s = urlparse.urlunparse((o.scheme, o.netloc, '/'+str(q.key()), '', '', ''))
    # display it
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'LinkExplainer.html'))
    self.response.out.write(template.render(path, {'link':s,'question':q.value}, debug=_DEBUG))

    
class AskQuestionHandler(webapp.RequestHandler):
    
    def get(self,key):
      """
      Display the specified question.
      """
      
      # fetch the question and shuffle answers
      q = Question.get(key)
      answers = [a.value for a in q.answers]
      random.shuffle(answers)
      
      # create the template
      template_vars = {
        "question_text" : q.value,
        "answers" : answers,
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'AskQuestion.html'))
      self.response.out.write(template.render(path, template_vars, debug=_DEBUG))
    
    def post(self,key):
      """
      Grade the answer that has been chosen.
      """
      # obtain the submitted answer
      ans = self.request.get('answer')
      
      # fetch the answers to the current question
      o = urlparse.urlparse(self.request.url)
      q = Question.get(key)
      answers = q.answers.fetch(4)
      
      # find the associated answer to get correctness and connections
      correctness = False
      next_questions = []
      for a in answers:
        if ans == a.value:
          correctness = a.correct
          next_questions = a.connections.order('weight').fetch(5)

      # build the template
      template_vars = {
        "next" : next_questions,
        "correct" : correctness,
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'Response.html'))
      self.response.out.write(template.render(path, template_vars, debug=_DEBUG))

def main():
  application = webapp.WSGIApplication([
    ('/', SearchHandler),
    ('/new', NewQuestionHandler),
    (r'/(.+)', AskQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()
