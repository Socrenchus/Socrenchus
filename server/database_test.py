#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
# All rights reserved.
#

"""
Test file for the database model and core logic.
"""

import unittest
import os
import random
import json
from google.appengine.ext import ndb
from google.appengine.ext import db
from google.appengine.api import users
from google.appengine.ext import testbed
from google.appengine.datastore import datastore_stub_util
from database import *

class DatabaseTests(unittest.TestCase):
  
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
    
    os.environ['AUTH_DOMAIN'] = 'testbed'
    self.switchToUser(0)
    
  def teardown(self):
    self.testbed.deactivate()
    
  def switchToUser(self, id):
    os.environ['USER_EMAIL'] = 'test'+str(id)+'@example.com'
    os.environ['USER_ID'] = str(id)
    stream = Stream.query(Stream.user==users.User()).get()
    if not stream:
      Stream().put()
    
  def testPostScoring(self):
    # create post
    post = Post()
    post.put()
    # check that post score is zero
    self.assertEqual(post.score, 0)
    # create correct tags
    xpc = [5,10,15,20,25]
    for x in xpc:
      self.switchToUser(x)
      Tag(parent=post.key, title='correct', xp=x).put()
    # check that the post score is positive
    self.assertEqual(post.score, sum(xpc))
    # create incorrect tags
    xpi = [6,9,16,19,24,1]
    for x in xpi:
      self.switchToUser(x)
      Tag(parent=post.key, title='incorrect', xp=x).put()
    # check that the post score is zero
    self.assertEqual(post.score, 0)
    # now lets make the post score negative
    self.switchToUser(2)
    Tag(parent=post.key, title='incorrect', xp=2).put()
    # check it
    self.assertEqual(post.score, -2)
    