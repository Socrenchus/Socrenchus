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
    
    q = Question()
    q.value = self.request.get('question') # the question text
    key = q.put()
    a = Answer()
    a.value = self.request.get('correct1') # the first correct answer
    a.confidence = 1.0
    a.correctness = 1.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('correct2') # the second correct answer
    a.confidence = 1.0
    a.correctness = 1.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('correct3') # the third correct answer
    a.confidence = 1.0
    a.correctness = 1.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('correct4') # the fourth correct answer
    a.confidence = 1.0
    a.correctness = 1.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('correct5') # the fifth correct answer
    a.confidence = 1.0
    a.correctness = 1.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('incorrect1') # the first incorrect answer
    a.confidence = 1.0
    a.correctness = 0.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('incorrect2') # the second incorrect answer
    a.confidence = 1.0
    a.correctness = 0.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('incorrect3') # the third incorrect answer
    a.confidence = 1.0
    a.correctness = 0.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('incorrect4') # the fourth incorrect answer
    a.confidence = 1.0
    a.correctness = 0.0
    a.question = q
    a.put()
    a = Answer()
    a.value = self.request.get('incorrect5') # the fifth incorrect answer
    a.confidence = 1.0
    a.correctness = 0.0
    a.question = q
    a.put()
        
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode({'id':key.id()}))
    
class AnswerQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Assign the specified question or grade it.
    """
    # obtain the question
    qid = self.request.get('question_id')

    # obtain the answer
    ans = self.request.get('answer')
    
    result = Assignment.assign(Question.get_by_id(long(float(qid))))
    
    result.put()
    
    if bool(ans) and ans != result.answer.value:
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
    ('/ajax/rate', RateQuestionHandler),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

