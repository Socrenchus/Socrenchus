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
    self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=0.7)
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
    
  def testTagScoreInference(self):
    # create six posts
    parent = Post().put()
    posts = [Post(parent=parent).put() for i in range(5)]
    # one that shares one tag
    Tag(parent=posts[0], title='1').put()
    Tag(parent=posts[0], title='two').put()
    Tag(parent=posts[0], title='red').put()
    Tag(parent=posts[0], title='blue').put()
    # one that shares one important tag
    for i in range(10):
      Tag(parent=posts[1], title='5').put()
    Tag(parent=posts[1], title='is').put()
    Tag(parent=posts[1], title='right').put()
    Tag(parent=posts[1], title='out').put()
    # one that shares multiple tags
    for i in range(10):
      Tag(parent=posts[2], title=str(i)).put()
    Tag(parent=posts[3], title='ok').put()
    # one that doesn't share any tags
    Tag(parent=posts[3], title='I').put()
    Tag(parent=posts[3], title='dont').put()
    Tag(parent=posts[3], title='match').put()
    # one that share's tags but is not a sibling
    for i in range(10):
      Tag(parent=parent, title=str(i)).put()
    Tag(parent=parent, title='uhh').put()
    # one that share's all its tags
    for i in range(10):
      Tag(parent=posts[4], title=str(i)).put()
    
    # make sure our scores stayed at zero
    self.assertEqual(parent.get().score, 0)
    for post in posts:
      self.assertEqual(post.get().score, 0)
      
    # try marking the post that shares all its tags correct
    Tag(parent=posts[4], title='correct').put()
    
    # check that scores updated appropriately
    self.assertTrue(posts[1].get().score > posts[0].get().score)
    self.assertTrue(posts[0].get().score > posts[3].get().score)
    self.assertEqual(posts[3].get().score, 0)
    self.assertEqual(parent.get().score, 0)
    self.assertNotEqual(posts[4].get().score, 0)
    