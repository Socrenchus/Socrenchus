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

_DEBUG = 'localhost' in users.create_logout_url( "/" )

class PostHandler(webapp.RequestHandler):
  def get(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    postlist = stream.assignments().fetch(keys_only=True)
    posts = []
    for post in postlist:
      jsonPost = json.simplejson.loads(json.encode(post.parent().get()))
      #FIXME: find the real problem rather than removing duplicate posts
      #if jsonPost not in posts:
      posts.append(jsonPost)    
    posts.reverse()
    posts = json.simplejson.dumps(posts)
    self.response.out.write(posts)

 
  def post(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    tmp = json.simplejson.loads(self.request.body)
    if 'parent' in tmp:
      post = stream.create_post(tmp['content'], ndb.Key(urlsafe=tmp['parent']))
    else:
      post = stream.create_post(tmp['content'])
    post = json.simplejson.dumps(json.encode(post))
    self.response.out.write(post)

  def put(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    tmp = json.simplejson.loads(self.request.body)
    if 'parent' in tmp:
      post = stream.create_post(tmp['content'], ndb.Key(urlsafe=tmp['parent']))
    else:
      post = stream.create_post(tmp['content'])
    post = json.simplejson.dumps(json.encode(post))
    self.response.out.write(post)

class TagHandler(webapp.RequestHandler):
  def get(self, id):
    def tag_enum(tag):
      return tag
    taglist = Tag.query(Tag.title != Tag.base("assignment"), Tag.user == users.get_current_user()).map(tag_enum,keys_only=False)
    tags = []
    for tag in taglist:
      jsonTag = json.simplejson.loads(json.encode(tag))
      tags.append(jsonTag)
    tags = json.simplejson.dumps(tags)
    self.response.out.write(tags)
 
  def post(self, id):
    tmp = json.simplejson.loads(self.request.body)
    tag = Tag(parent=ndb.Key(urlsafe=tmp['parent']), user=users.get_current_user(), title=tmp['title'])
    tag.put()
    self.response.out.write(tag)

  def put(self, id):
    tmp = json.simplejson.loads(self.request.body)
    tag = Tag(parent=ndb.Key(urlsafe=tmp['parent']), user=users.get_current_user(), title=tmp['title'])
    tag.put()
    self.response.out.write(tag)

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
class LoginHandler(webapp.RequestHandler):
  """
  Logs the user in and redirects.
  """
  def get(self):
    self.redirect('/')
    
class LogoutHandler(webapp.RequestHandler):
  """
  Logs the user out and redirects.
  """
  def get(self):
    self.redirect(users.create_logout_url( "/" ))
   

class MainPage(webapp.RequestHandler):
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
      'url_linktext': url_linktext,
    }

    path = os.path.join(os.path.dirname(__file__), '../client/static/index.html')
    self.response.out.write(template.render(path, template_values))

"""
class RPCHandler(webapp.RequestHandler):
  def __init__(self):
    webapp.RequestHandler.__init__(self)
    self.methods = RPCMethods()

  def get(self, collection, key):
    func = None

    if not collection:
      collection = self.request.get('action')

    if collection:
      if collection[0] == '_':
        self.error(403) # access denied
        return
      else:
        func = getattr(self.methods, collection, None)

    if not func:
      self.error(404) # file not found
      return
    
    obj = None
    if self.request.body:
      obj = json.simplejson.loads(self.request.body)
    
    result = func(key, obj)
    self.response.out.write(json.encode(result))
    
  def put(self, collection, key):
    return self.get(collection, key)
    """
class CollectionHandler(webapp.RequestHandler):
  """
  Handle Backbone.js collection sync calls.
  """
  pass

options = [
  #(r'/(.*)/report.csv', GradeReport),
  ('/login', LoginHandler),
  ('/logout', LogoutHandler),
  ('/', MainPage),
  ('/posts\/?([0-9]*)', PostHandler),
  ('/tags\/?([0-9]*)', TagHandler)
]
application = webapp.WSGIApplication(options, debug=_DEBUG)
application = ndb.toplevel(application.__call__)
  
def main():
  #wsgiref.handlers.CGIHandler().run(application)
  run_wsgi_app(application)

if __name__ == '__main__':
  main()

