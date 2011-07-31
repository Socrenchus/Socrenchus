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

from google.appengine.api import datastore
from google.appengine.api import datastore_types
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template
from search import *


_DEBUG = True

class Question(Searchable,db.Model):
  value = db.TextProperty()
  correct = db.TextProperty()
  correct_next = db.SelfReferenceProperty(collection_name="next_questions")
  incorrect1 = db.TextProperty()
  incorrect1_help = db.SelfReferenceProperty(collection_name="help_questions1")
  incorrect2 = db.TextProperty()
  incorrect2_help = db.SelfReferenceProperty(collection_name="help_questions2")
  incorrect3 = db.TextProperty()
  incorrect3_help = db.SelfReferenceProperty(collection_name="help_questions3")
  INDEX_TITLE_FROM_PROP = 'value'
  
class SearchHandler(webapp.RequestHandler):
  def get(self):
    # Search for existing entry
    q = self.request.get('q')
    results = None
    if q:
      results = Question.search(q)
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'SearchQuestion.html'))
    self.response.out.write(template.render(path, {"results":results,"query":q}, debug=_DEBUG))

class NewQuestionHandler(webapp.RequestHandler):
  def parseRefUrl(self, aURL):
    """Turns a reference URL into a database object."""
    if aURL is None:
      return None
    o = urlparse.urlparse(aURL)
    q = Question.get(o.path.split('/')[1])
    return q
  def get(self):
    """Displays the new question form."""
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'NewQuestion.html'))
    self.response.out.write(template.render(path, None, debug=_DEBUG))
  def post(self):
    """Stores a newly created question."""
    q = Question()
    q.value = self.request.get('question')
    q.correct = self.request.get('correct-answer')
    correct_next_url = self.request.get('correct-answer-next')
    if (correct_next_url):
      q.correct_next = self.parseRefUrl(correct_next_url)
    q.incorrect1 = self.request.get('incorrect-answer1')
    incorrect_answer1_help_url = self.request.get('incorrect-answer1-help')
    if (incorrect_answer1_help_url):
      q.incorrect1_help = self.parseRefUrl(incorrect_answer1_help_url)
    q.incorrect2 = self.request.get('incorrect-answer2')
    incorrect_answer2_help_url = self.request.get('incorrect-answer2-help')
    if (incorrect_answer2_help_url):
      q.incorrect2_help = self.parseRefUrl(incorrect_answer2_help_url)
    q.incorrect3 = self.request.get('incorrect-answer3')
    incorrect_answer3_help_url = self.request.get('incorrect-answer3-help')
    if (incorrect_answer3_help_url):
      q.incorrect3_help = self.parseRefUrl(incorrect_answer3_help_url)
    
    q.put()
    q.index()
    o = urlparse.urlparse(self.request.url)
    s = urlparse.urlunparse((o.scheme, o.netloc, '/'+str(q.key()), '', '', ''))
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'LinkExplainer.html'))
    self.response.out.write(template.render(path, {'link':s,'question':q.value}, debug=_DEBUG))

    
class AskQuestionHandler(webapp.RequestHandler):
    def get(self,key):
      """Display the specified question."""
      q = Question.get(key)
      answers = [q.correct, q.incorrect1, q.incorrect2, q.incorrect3]
      random.shuffle(answers)
      template_vars = {
        "question_text" : q.value,
        "answers" : answers,
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'AskQuestion.html'))
      self.response.out.write(template.render(path, template_vars, debug=_DEBUG))
    def post(self,key):
      """Grade the answer that has been chosen."""
      ans = self.request.get('answer')
      q = Question.get(key)
      o = urlparse.urlparse(self.request.url)
      next_question = None
      s = None
      if ans == q.correct:
        next_question = q.correct_next
      elif ans == q.incorrect1:
        next_question = q.incorrect1_help
      elif ans == q.incorrect2:
        next_question = q.incorrect2_help
      elif ans == q.incorrect3:
        next_question = q.incorrect3_help
      if next_question:
        s = urlparse.urlunparse((o.scheme, o.netloc, '/'+str(next_question.key()), '', '', ''))
      template_vars = {
        "url" : s,
        "correct" : q.correct == ans,
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
