#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.

This file contains all of the request handlers required to
serve json to the client.

This line logs the user in for our unit tests:
>>> os.environ['USER_EMAIL'] = u'test@example.com'
"""

__author__ = 'Bryan Goldstein'

import wsgiref.handlers
import json
import os

from google.appengine.ext import webapp
from google.appengine.api import users
from database import *

_DEBUG = True

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
    Stores a newly created question.
    """
    question_text = self.request.get('question')
    answers = [self.request.get(str(i)+'-a') for i in range(4)]
    connections = [self.request.get_all(str(i)+'-n[]') for i in range(4)]
    
    key = Question.createNewQuestion(question_text,answers,connections)    
    assignment = Assignment.fromQuestion(key.id())
    
    json_response = json.encode(assignment)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json_response)
    
class AnswerQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Assign the specified question or grade it.
    """
    # obtain the question
    qid = self.request.get('question_id')

    # obtain the answer
    ans = self.request.get('answer')
    
    assignment = Assignment.fromQuestion(long(qid))
    
    assignment.put()
    
    if not ans:
      return
      
    success = assignment.submitAnswer(ans)
    
    if not success:
      return
      
    assignment.put()
    
    json_response = json.encode(assignment)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json_response)

        

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
      
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode(assignments))

def main():
  application = webapp.WSGIApplication([
    ('/ajax/search', SearchHandler),
    ('/ajax/new', NewQuestionHandler),
    ('/ajax/stream', StreamHandler),
    (r'/ajax/answer', AnswerQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

