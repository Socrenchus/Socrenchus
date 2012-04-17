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
    stream = Stream.get_or_create(users.get_current_user())
    postlist = stream.assignments
    """
    request = webapp.Request({
      "wsgi.input": StringIO(),
      "CONTENT_LENGTH": 0,
      "METHOD": "GET",
      "PATH_INFO": "/",
    })
    response = webapp.Response()
    handler = RESTfulHandler()
    handler.initialize(request, response)
    handler.get()
    self.assertEqual(response.out.getvalue(), "GETWORKING")
    """


 
