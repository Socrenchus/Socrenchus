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
    
    q = ShortAnswerQuestion()
    q.value = self.request.get('question')
    for i in range(5):
      a = Answer()
      a.value = self.request.get('correct'+str(i+1))
      a.confidence = 1.0
      a.correctness = 1.0
      q.answers.append(a.put())
      a = Answer()
      a.value = self.request.get('incorrect'+str(i+1))
      a.confidence = 1.0
      a.correctness = 0.0
      q.answers.append(a.put())
    q.put()
        
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode({'id':q.key().id()}))
    
class AnswerQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Assign the specified question or grade it.
    """
    # obtain the question
    qid = self.request.get('question_id')

    # obtain the answer
    ans = self.request.get_all('answer[]')
    if not ans:
      ans = self.request.get('answer')

    result = Assignment.assign(Question.get_by_id(long(float(qid))))
    
    if bool(ans) and not result.answer:
      result = result.submitAnswer(ans)
        
    json_response = json.encode(result)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json_response)

class RateQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Handle the user rating the question.
    """
    # get the question object
    question_id = self.request.get('question_id')
    result = Assignment.fromQuestion(long(float(question_id)))
    
    # rate the question and store it
    result.liked = result.question.rate()
    
    result.question.put()
    result.put()
    
    json_response = json.encode(result)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json_response)
    
class StreamHandler(webapp.RequestHandler):
  
  def get(self):
    """
    Return the user's question stream.
    """
    q = aQuestion.all()
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
    ('/ajax/rate', RateQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

