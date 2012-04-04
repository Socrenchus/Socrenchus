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
    
  def testExperienceReferencing(self):
    # create post
    self.switchToUser(100)
    post = Post()
    post.put()
    # designate a list of tag names
    tag_names = range(1, 11)
    # tag the post
    for i in tag_names:
      for j in range(i):
        self.switchToUser(j)
        t = Tag(parent=post.key, title=str(i))
        t.put()
        self.assertEqual(round(t.xp), 1) # check that our start xp is the base score
    # adjust the score
    post.adjust_score(100.0)
    # check that the tags were updated properly
    user = Stream.query(Stream.user==post.author).iter(keys_only=True).next()
    tags = Tag.query(ancestor=user).fetch()
    self.assertEqual(len(tags),len(tag_names))
    for t in tags:
      self.assertEqual(round(t.xp), round(int(t.title)*(100.0/sum(tag_names))+1))
      
  def testExperienceDereferencing(self):
    # switch to 'tagging' user
    self.switchToUser('tagging')
    user = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    # give 'tagging' user experience in a few tags
    Tag(parent=user, title='a', xp=100).put()
    Tag(parent=user, title='b', xp=50).put()
    Tag(parent=user, title='c', xp=25).put()
    # switch to 'posting' user
    self.switchToUser('posting')
    # create a post
    p = Post().put()
    # switch between arbitrary users and tag the post as such
    self.switchToUser('userA')
    Tag(parent=p, title='a', xp=1).put()
    Tag(parent=p, title='b', xp=3).put()
    Tag(parent=p, title='c', xp=2).put()
    self.switchToUser('userB')
    Tag(parent=p, title='a', xp=2).put()
    Tag(parent=p, title='b', xp=2).put()
    Tag(parent=p, title='d', xp=5).put()
    self.switchToUser('userC')
    Tag(parent=p, title='a', xp=3).put()
    # switch back to 'tagging' user and apply a tag
    self.switchToUser('tagging')
    t = Tag(parent=p, title='blah')
    t.put()
    self.assertEqual(round(t.xp), 50)