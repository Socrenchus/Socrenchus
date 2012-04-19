#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
# All rights reserved.
#

"""
Test file for the database model and handler model interaction and core logic.
"""
import unittest
import os
import random
import json
from StringIO import StringIO
from google.appengine.ext import ndb
from google.appengine.ext import db
from google.appengine.api import users
from google.appengine.ext import testbed
from google.appengine.ext import webapp
from google.appengine.datastore import datastore_stub_util
import logging
from handlers import *
from database import *
class HandlerTests(unittest.TestCase):
  def setUp(self):
    # Create test bed
    self.testbed = testbed.Testbed()
    self.testbed.activate()
    # Create a consistency policy that will simulate the High Replication consistency model.
    self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1.0)
    # Initialize the datastore stub with this policy.
    self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
    self.testbed.init_memcache_stub()
    self.testbed.init_user_stub()

  def teardown(self):
    self.testbed.deactivate()

  def switchToUser(self, id):
    os.environ['USER_EMAIL'] = 'test'+str(id)+'@example.com'
    os.environ['USER_ID'] = str(id)
    stream = Stream.query(Stream.user==users.User()).get()
    if not stream:
      Stream().put()

  def testGet(self):
    # get post list
    request = webapp.Request({
      "wsgi.input": StringIO(),
      "CONTENT_LENGTH": 0,
      "METHOD": "GET",
      "PATH_INFO": "/",
    })
    response = webapp.Response()
    handler = RESTfulHandler()
    handler.initialize(request, response)
    handler.get(1)

  def testPost(self):
    # create a post and sync with database
    postData = {}
    postData['content'] =  '{posttext: "What is your earliest memory of WWII?", linkdata: "<img src = \'http://www.historyplace.com/unitedstates/pacificwar/2156.jpg\' width = \'350\' height = \'auto\'>"})'
    postData = json.simplejson.dumps(postData)
    handler = RESTfulHandler()
    handler.request = webapp.Request({
      'REQUEST_METHOD': 'POST',
      'PATH_INFO': '/',
      'body': postData,
      'wsgi.input': StringIO(postData),
      'CONTENT_LENGTH': len(postData),
      'SERVER_NAME': 'hi',
      'SERVER_PORT': '80',
      'wsgi.url_scheme': 'http',
    })
    handler.response = webapp.Response()
    handler.post(1)
    childPost = {}
    childPost['content'] = '{posttext: "My earlliest memory is eating this candy" linkdata: ""}'
    #childPost['parent'] = handler.response['key']
    handler1 = RESTfulHandler()
    handler1.request = webapp.Request({
      'REQUEST_METHOD': 'POST',
      'PATH_INFO': '/',
      'body': postData,
      'wsgi.input': StringIO(postData),
      'CONTENT_LENGTH': len(postData),
      'SERVER_NAME': 'hi',
      'SERVER_PORT': '80',
      'wsgi.url_scheme': 'http',
    })
    logging.debug(str(handler.response))
    handler1.response = webapp.Response()
    handler1.post(1)
   



 
