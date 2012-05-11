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
import os, sys, inspect
cmd_folder = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
if cmd_folder not in sys.path:
  sys.path.insert(0, cmd_folder)
import json
from google.appengine.ext import webapp
from google.appengine.api import users
from google.appengine.ext.ndb import context
from google.appengine.ext import ndb
import logging
from database import *
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template
#TODO: figure out why this doesn't get rid of the warning
from google.appengine.dist import use_library
use_library('django', '0.96')
from bootstrap import BootStrap

_DEBUG = True
class BootstrapHandler(webapp.RequestHandler):
  def get(self, id):
    if _DEBUG:
      BootStrap.loadconfiguration(id)
    self.redirect('/')

class PostHandler(webapp.RequestHandler):
  def get(self, id):
    result = None
    stream = Stream.get_or_create(users.get_current_user())
    if id:
      key = ndb.Key(urlsafe=id)
      result = stream.get_children(key)
    else:
      result = stream.get_assignments()
    self.response.out.write(json.encode(result))

 
  def post(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    tmp = json.simplejson.loads(self.request.body)
    if 'parent' in tmp:
      post = stream.create_post(tmp['content'], ndb.Key(urlsafe=tmp['parent']))
    else:
      post = stream.create_post(tmp['content'])
    self.response.out.write(json.encode(post))

  def put(self):
    self.post(id)

class TagHandler(webapp.RequestHandler):
  def get(self, id):
    q = Tag.query(Tag.user == users.get_current_user()).fetch()
    self.response.out.write(json.encode(q))
 
  def post(self, id):
    tmp = json.simplejson.loads(self.request.body)
    t = Tag.get_or_create(tmp['title'],ndb.Key(urlsafe=tmp['parent']))
    self.response.out.write(json.encode(t))

  def put(self, id):
    self.post(id)

  """
  def delete(self, id):
    key = self.request.cookies['posts']
    postlist = db.get(key)
    post = Posts.get_by_id(int(id))
    if post.postlist.key() == postlist.key():
      tmp = post.toDict()
      post.delete()
    else:
      self.error(403)
  """

class StreamHandler(webapp.RequestHandler):
  def get(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    self.response.out.write(json.encode(stream))

class AccountHandler(webapp.RequestHandler):
  def get(self):
    if users.get_current_user():
      url = users.create_logout_url(self.request.uri)
      url_linktext = 'Logout'
    else:
      url = users.create_login_url(self.request.uri)
      self.redirect(url)
      url_linktext = 'Login'
    template_values = {
      'url': url,
      'url_linktext': url_linktext
    }

    path = os.path.join(os.path.dirname(__file__), '../client/static/index.html')
    self.response.out.write(template.render(path, template_values))

options = [  
  ('/load/?(.*)', BootstrapHandler),
  ('/', AccountHandler),
  (r'/posts/?(.*)', PostHandler),
  (r'/tags/?(.*)', TagHandler),
  (r'/stream/?(.*)', StreamHandler)
]
application = webapp.WSGIApplication(options, debug=_DEBUG)
application = ndb.toplevel(application.__call__)
  
def main():
  run_wsgi_app(application)

if __name__ == '__main__':
  main()

