#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein.
# All rights reserved.
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

from google.appengine.ext import webapp
from google.appengine.api import users
from ndb import context
from database import *

_DEBUG = True

class ExperimentOneHandler(webapp.RequestHandler):

  def get(self):
    """
    Assigns the builder question, serves stream.html.
    """
    
    aBuilderQuestion.assign()

    self.redirect('/')

class ClearDataHandler(webapp.RequestHandler):
  def get(self):
    """
    Erases all the data in the datastore and memcache.
    """
    model.delete_multi([a.key for a in Assignment.query()])
    model.delete_multi([a.key for a in UserData.query()])
    model.delete_multi([a.key for a in Question.query()])
    model.delete_multi([a.key for a in Answer.query()])
    
class TestDataHandler(webapp.RequestHandler):
  def get(self):
    """
    Generates test data, serves stream.html.
    """
    # FIXME: os.environ['USER_EMAIL'] doesn't work outside testbed
    if not Question.query().count(1):
    
      os.environ['USER_EMAIL'] = 'teacher@example.com'
      ab = aBuilderQuestion.assign()
      ab.submitAnswer('Name a number that is divisible by four.')
      question = ab.answer

      # have users answer the question
      for i in range(30):
        os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
        a = aShortAnswerQuestion.assign(question, users.User('test'+str(i)+'@example.com'))
        a.submitAnswer(str(i))

      # confidently grade some answers
      os.environ['USER_EMAIL'] = 'teacher@example.com'
      a = aConfidentGraderQuestion.query(Assignment.user == users.User('teacher@example.com')).get()
      for i in range(5):
        a = a.submitAnswer(1.0-float(int(a.answers[0].get().value)%4/4))[2]
      
      # have the users grade eachother's answer
      for i in range(5,30):
        os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
        a = aShortAnswerQuestion.query(Assignment.user == users.User()).get()
        q = aGraderQuestion.query(Assignment.user == users.User()).get()
        myAnswer = []
        agree = random.random() < (0.9 * (1.0-float(int(a.answer.get().value)%4/4)))
        for a in q.answers:
          a = a.get()
          if (1.0-float(int(a.value)%4/4)) > 0.5:
            if agree:
              myAnswer.append(a.value)
          else:
            if not agree:
              myAnswer.append(a.value)

        q.submitAnswer(myAnswer)

    self.redirect('/')
    
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

    q = model.Key(urlsafe=qid).get()
    result = None
    if isinstance(q,Question):
      result = theClass.assign(q.key)
    elif bool(ans):
      result = q.submitAnswer(ans)
        
    json_response = json.encode(result)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json_response)

class StreamHandler(webapp.RequestHandler):
  
  def get(self):
    """
    Return the user's question stream.
    """
    
    ud = UserData.get_or_insert(str(users.get_current_user().user_id()))
    
    assignments = model.get_multi(ud.assignments)
    
    self.response.headers.add_header("Content-Type", 'application/json')
    self.response.out.write(json.encode({'logout': users.create_logout_url( "/" ), 'assignments':assignments}))
    
class GradeReport(webapp.RequestHandler):
  """
  Downloads a csv grade report.
  """
  def get(self, param):
    q = model.Key(urlsafe=param).get().answer.get()
    if q and q.author == users.User():
      output = 'email, grade\n'
      for a in q.answers:
        a = a.get()
        output += a.author.email()+', '
        output += str(a.correctness*100)+'%\n'
        
      self.response.headers.add_header("Content-Type", 'text/csv')
      self.response.out.write(output)
    
class StaticPageServer(webapp.RequestHandler):
  """
  Serves the static pages after determining login status.
  """
  def get(self):
    if users.get_current_user():
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'stream.html'))
    else:
      path = os.path.join(os.path.dirname(__file__), os.path.join('templates', 'index.html'))
    
    self.response.out.write(open(path).read())
    
class LoginHander(webapp.RequestHandler):
  """
  Logs the user in and redirects.
  """
  def get(self):
    if users.get_current_user():
      self.redirect('/')
    else:
      self.redirect(users.create_login_url(self.request.uri))

def main():
  options = [
    ('/ajax/stream', StreamHandler),
    (r'/ajax/answer', AnswerQuestionHandler),
    ('/experiments/1', ExperimentOneHandler),
    (r'/(.*)/report.csv', GradeReport),
    ('/login', LoginHander),
    ('/.*', StaticPageServer),
  ]
  if _DEBUG:
    options = [
      ('/experiments/test', TestDataHandler),
      ('/experiments/deleteall', ClearDataHandler),
    ] + options
  application = webapp.WSGIApplication(options, debug=_DEBUG)
  application = context.toplevel(application.__call__)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

