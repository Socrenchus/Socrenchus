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
"""

__author__ = 'Bryan Goldstein'

import wsgiref.handlers
import json
import os
from google.appengine.ext.webapp import template

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

class ExperimentOneHandler(webapp.RequestHandler):

  def get(self):
    """
    Assigns the builder question, serves stream.html.
    """
    
    aBuilderQuestion.assign()

    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'stream.html'))
    self.response.out.write(open(path).read())
    
class TestDataHandler(webapp.RequestHandler):
  def get(self):
    """
    Generates test data, serves stream.html.
    """
    
    if not Question.all().get():
    
      os.environ['USER_EMAIL'] = 'teacher@example.com'
      a = aBuilderQuestion.assign()
      a.submitAnswer('Name a number that is divisible by four.')
      q = a.answer
    
      answers = [
        'Definitely Correct',
        'Not Completely Correct',
        'Not Completely Wrong',
        'Definitely Wrong',
      ]
      
      scores = [
      1.0,
      0.75,
      0.25,
      0.0,
      ]
        
      # have users answer the question
      for i in range(30):
        os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
        a = aShortAnswerQuestion.assign(q)
        a.submitAnswer(str(i))
      
      # confidently grade some answers
      os.environ['USER_EMAIL'] = 'teacher@example.com'
      a = aConfidentGraderQuestion.assign(q)
      for i in range(5):
        a = a.submitAnswer(answers[int(a.answerInQuestion.value)%4])[2]
        
      # have the users grade eachother's answer
      query = db.Query(Answer,keys_only=True)
      for i in range(5,30):
        os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
        a = aShortAnswerQuestion.all().filter('user =', users.User()).get()
        q = aGraderQuestion.all().filter('user =', users.User()).get()
        myAnswer = []
        agree = random.random() < (0.9 * scores[int(a.answer.value)%4])
        for a in q.answers:
          a = Answer.get(a)
          if scores[int(a.value)%4] > 0.5:
            if agree:
              myAnswer.append(a.value)
          else:
            if not agree:
              myAnswer.append(a.value)

        if len(myAnswer) == 0:
          myAnswer += 'None of the above'

        q.submitAnswer(myAnswer)

    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'stream.html'))
    self.response.out.write(open(path).read())
    
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
    
    args = self.request.arguments()
    theClass = aShortAnswerQuestion
    if 'class[aGraderQuestion]' in args:
      theClass = aGraderQuestion

    result = db.get(qid)
    if isinstance(result,Question):
      result = theClass.assign(result)
    elif bool(ans) and not result.answer:
      result = result.submitAnswer(ans)
        
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
    
class StaticPageServer(webapp.RequestHandler):
  
  def get(self):
    path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'stream.html'))
    self.response.out.write(open(path).read())

def main():
  application = webapp.WSGIApplication([
    ('/ajax/search', SearchHandler),
    ('/ajax/stream', StreamHandler),
    (r'/ajax/answer', AnswerQuestionHandler),
    ('/experiments/1', ExperimentOneHandler),
    ('/experiments/test', TestDataHandler),
    ('/.*', StaticPageServer),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

