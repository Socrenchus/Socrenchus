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

This file contains all of the request handlers.
"""

__author__ = 'Bryan Goldstein'

import wsgiref.handlers
import json
import os

from google.appengine.ext import webapp
from google.appengine.api import users
from ndb import context
from rpc import *

_DEBUG = 'localhost' in users.create_logout_url( "/" )
    
class LoginHander(webapp.RequestHandler):
  """
  Logs the user in and redirects.
  """
  def get(self):
    self.redirect('/')
    
class RPCHandler(webapp.RequestHandler):
  """ 
  Allows access to functions defined in the RPCMethods class.
  """

  def __init__(self):
    webapp.RequestHandler.__init__(self)
    self.methods = RPCMethods()

  def get(self):
    func = None

    action = self.request.get('action')
    if action:
      if action[0] == '_':
        self.error(403) # access denied
        return
      else:
        func = getattr(self.methods, action, None)

    if not func:
      self.error(404) # file not found
      return

    args = ()
    while True:
      key = 'arg%d' % len(args)
      val = self.request.get(key)
      if val:
        args += (json.simplejson.loads(val),)
      else:
        break
    result = func(*args)
    self.response.out.write(json.encode(result))

def main():
  options = [
    ('/rpc', RPCHandler),
    #(r'/(.*)/report.csv', GradeReport),
    ('/login', LoginHander),
  ]
  application = webapp.WSGIApplication(options, debug=_DEBUG)
  application = context.toplevel(application.__call__)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()

