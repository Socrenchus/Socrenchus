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


_DEBUG = True

class Question(db.Model):
  value = db.TextProperty()
  correct = db.TextProperty()
  correct_next = db.SelfReferenceProperty(collection_name="next_questions")
  incorrect1 = db.TextProperty()
  incorrect1_help = db.SelfReferenceProperty(collection_name="help_questions1")
  incorrect2 = db.TextProperty()
  incorrect2_help = db.SelfReferenceProperty(collection_name="help_questions2")
  incorrect3 = db.TextProperty()
  incorrect3_help = db.SelfReferenceProperty(collection_name="help_questions3")
  order = db.IntegerProperty()

class NewQuestionHandler(webapp.RequestHandler):
  def parseRefUrl(self, aURL):
    """Turns a reference URL into a database object."""
    if aURL is None:
      return None
    o = urlparse.urlparse(aURL)
    return o.path.split('/')[0]
  def get(self):
    """Displays the new question form."""
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'NewQuestion.html'))
    self.response.out.write(template.render(path, None, debug=_DEBUG))
  def post(self):
    """Stores a newly created question."""
    q = Question()
    q.value = self.request.get('question')
    q.correct = self.request.get('correct-answer')
    #q.correct_next = self.parseRefUrl(self.request.get('correct-answer-next'))
    q.incorrect1 = self.request.get('incorrect-answer1')
    #q.incorrect1_help = self.parseRefUrl(self.request.get('incorrect-answer1-help'))
    q.incorrect2 = self.request.get('incorrect-answer2')
    #q.incorrect2_help = self.parseRefUrl(self.request.get('incorrect-answer2-help'))
    q.incorrect3 = self.request.get('incorrect-answer3')
    #q.incorrect3_help = self.parseRefUrl(self.request.get('incorrect-answer3-help'))
    q.put()
    o = urlparse.urlparse(self.request.url)
    s = urlparse.urlunparse((o.scheme, o.netloc, '/'+str(q.key()), '', '', ''))
    self.response.out.write(s)
    
class AskQuestionHandler(webapp.RequestHandler):
    def get(self,key):
      """Display the specified question."""
      q = Question.get(key)
      answers = [q.correct, q.incorrect1, q.incorrect2, q.incorrect3]
      random.shuffle(answers)
      template_vars = {
        "question_text" : q.value,
        "answers" : answers,
        "answered" : False
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'AskQuestion.html'))
      self.response.out.write(template.render(path, template_vars, debug=_DEBUG))
    def post(self,key):
      """Grade the answer that has been chosen."""
      q = Question.get(key)
      template_vars = {
        "question_text" : q.value,
        #TODO: respect order
        "answers" : [q.correct, q.incorrect1, q.incorrect2, q.incorrect3],
        "selected_answer" : self.request.get('answer'),
        "correct_answer" : q.correct,
        "answered" : True
      }
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'AskQuestion.html'))
      self.response.out.write(template.render(path, template_vars, debug=_DEBUG))
      #TODO: respect order
def main():
  application = webapp.WSGIApplication([
    (r'/(.+)', AskQuestionHandler),
    ('/', NewQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()