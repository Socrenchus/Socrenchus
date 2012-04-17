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

#import wsgiref.handlers
#import json

import os, sys, inspect, Cookie
import logging
from database import Stream

from google.appengine.ext import webapp
from google.appengine.api import users
from google.appengine.ext.ndb import context
#from rpc import #
from google.appengine.ext.webapp import template
from google.appengine.ext import webapp
from google.appengine.ext import ndb
from google.appengine.ext.webapp.util import run_wsgi_app

from django.utils import simplejson

from datetime import datetime
#_DEBUG = 'localhost' in users.create_logout_url( "/" )

#class PostList(ndb.Model):
#  timestamp = ndb.DateTimeProperty(auto_now_add=True)

#class Posts(ndb.Model):
#  postlist = ndb.KeyProperty(PostList)
# parentID = ndb.IntegerProperty()
# content = ndb.StringProperty()
# votecount = ndb.IntegerProperty()
# def toDict(self):
#    post = {
#      'id': self.key.id(),
#      'parentID': self.parentID,
#      'content': self.content,
#      'votecount': self.votecount
#      }
#    return post
    

class RESTfulHandler(webapp.RequestHandler):
  def get(self, id):
    stream = Stream.get_or_create(users.get_current_user())
    #postlist = stream.assignments
    #logging.debug(postlist)
    #query = Post.all()
    #query.filter("postlist =", postlist.key)
    #for post in query:
    #  posts.append(todo.toDict())
    #posts = simplejson.dumps(posts)
    #self.response.out.write(posts)
    self.response.out.write("GETWORKING")
  """
  def post(self, id):
    #key = self.request.cookies['posts']
    #postlist = key.get()
    post = simplejson.loads(self.request.body)
    post = Posts(
  	       parentID   = post['parentID'],
  	       content = post['content'],
  	       votecount  = post['votecount'])
    post.put()
    #post = simplejson.dumps(post.toDict())
    #self.response.out.write(post)
  """
  def put(self, id):
    logging.debug("id: " + str(id))
    stream = Stream.get_or_create(users.get_current_user())
    #if post.postlist.key() == postlist.key():
    tmp = simplejson.loads(self.request.body)
    if 'parent' in tmp:
      post = stream.create_post(str(tmp['content']), tmp['parent'])
    else:
      post = stream.create_post(str(tmp['content']))
    #post = simplejson.dumps(post.toDict())
    #postlist = stream.assignments
    #self.response.out.write(post)
    #else:
    #  self.error(403)
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
    self.redirect('/#servertest')
    
class LogoutHandler(webapp.RequestHandler):
  """
  Logs the user out and redirects.
  """
  def get(self):
    self.redirect(users.create_logout_url( "/" ))
    
class RPCHandler(webapp.RequestHandler):
  """ 
  Allows access to functions defined in the RPCMethods class.
  """

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
    
class CollectionHandler(webapp.RequestHandler):
  """
  Handle Backbone.js collection sync calls.
  """
  pass

options = [
  #(r'/(.*)/report.csv', GradeReport),
  ('/login', LoginHandler),
  ('/logout', LogoutHandler),
  #(r'/rpc/(.*)/(.*)', RPCHandler),
  #(r'/rpc/(.*)()', RPCHandler),
  #r'/rpc()()', RPCHandler)
  ('/posts\/?([0-9]*)', RESTfulHandler)
]
#application = webapp.WSGIApplication(options, debug=_DEBUG)
application = webapp.WSGIApplication(options, debug=True)
#application = context.toplevel(application.__call__)
  
def main():
  #wsgiref.handlers.CGIHandler().run(application)
  run_wsgi_app(application)

if __name__ == '__main__':
  main()

