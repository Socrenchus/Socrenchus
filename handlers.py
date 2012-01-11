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

class CreateQuestionHandler(webapp.RequestHandler):

  def get(self):
    """
    Assigns the builder question, serves stream.html.
    """
    
    aBuilderQuestion.assign()

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
    
    sid = self.request.get('segment')
    if not sid:
      sid = 0
    else:
      sid = int(sid)
    
    start = sid*15
    end = start+15

    
    ud = UserData.get_or_insert(str(users.get_current_user().user_id()))
    
    assignment_keys = ud.assignments
    assignment_keys.reverse()
    assignments = model.get_multi(assignment_keys[start:end])
    self.response.headers["Content-Type"] = "application/json"
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
        
      self.response.headers["Content-Type"] = "text/csv"
      self.response.out.write(output)
    
class StaticPageServer(webapp.RequestHandler):
  """
  Serves the static pages after determining login status.
  """
  def get(self):
    user = users.get_current_user()
    if user and (_DEBUG or UserData.get_by_id(user.user_id())):
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
    ('/teach', CreateQuestionHandler),
    (r'/(.*)/report.csv', GradeReport),
    ('/login', LoginHander),
    ('/.*', StaticPageServer),
  ]
  application = webapp.WSGIApplication(options, debug=_DEBUG)
  application = context.toplevel(application.__call__)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

