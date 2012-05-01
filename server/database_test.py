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
    return Stream.get_or_create(users.get_current_user())
    
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
      t = Tag(parent=post.key, title=',correct', xp=x)
      t.eval_score_change()
      t.put()
    # check that the post score is positive
    self.assertEqual(post.score, sum(xpc))
    # create incorrect tags
    xpi = [6,9,16,19,23,2]
    for x in xpi:
      self.switchToUser(x)
      t = Tag(parent=post.key, title=',incorrect', xp=x)
      t.eval_score_change()
      t.put()
    # check that the post score is zero
    self.assertEqual(post.score, 0)
    # now lets make the post score negative
    self.switchToUser(2)
    t = Tag(parent=post.key, title=',incorrect', xp=2)
    t.eval_score_change()
    t.put()
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
        t = Tag(parent=post.key, title=str(i), xp=2)
        t.put()
        self.assertEqual(round(t.xp), 2)
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
    
  def testPointsFromTagging(self):
    # create the common post
    self.switchToUser('user')
    p = Post().put()
    # give users a starting experience
    self.switchToUser('A')
    a = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    aa = Tag(parent=a, title='a', xp=500).put()
    ab = Tag(parent=a, title='b', xp=50).put()
    ac = Tag(parent=a, title='c', xp=5).put()
    self.switchToUser('B')
    b = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    ba = Tag(parent=b, title='a', xp=50).put()
    bb = Tag(parent=b, title='b', xp=500).put()
    bc = Tag(parent=b, title='c', xp=50).put()
    self.switchToUser('C')
    c = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    ca = Tag(parent=c, title='a', xp=5).put()
    cb = Tag(parent=c, title='b', xp=50).put()
    cc = Tag(parent=c, title='c', xp=500).put()
    # have users tag posts
    self.switchToUser('A')
    Tag(parent=p, title='a').put()
    self.switchToUser('B')
    Tag(parent=p, title='a').put()
    Tag(parent=p, title='b').put()
    self.switchToUser('C')
    Tag(parent=p, title='a').put()
    Tag(parent=p, title='b').put()
    Tag(parent=p, title='c').put()
    # check users ending experience
    self.assertGreater(aa.get().xp, 500)
    self.assertEqual(ab.get().xp, 50)
    self.assertEqual(ac.get().xp, 5)
    self.assertGreater(ba.get().xp, 50)
    self.assertGreater(bb.get().xp, 500)
    self.assertGreater(ca.get().xp, 5)
    self.assertGreater(cb.get().xp, 50)
    self.assertEqual(cc.get().xp, 500)
    # check the final post score
    # figure out why the post sometimes gets 100 points
    self.assertEqual(p.get().score, 0)

  def testIncrementalAssignment(self):
    # create post
    self.switchToUser('user')
    user = self.switchToUser('user')
    post = user.create_post('my post')
    Tag(parent=post.key, title='a').put()
    # create responses
    resp = []
    for i in range(10):
      user = self.switchToUser(str(i))
      user.assign_post(post.key)
      resp.append(user.create_post(str(i), post.key).key)
    # check assignments
    stream = self.switchToUser(str(1))
    for i in range(2):
      # acquire points
      stream.adjust_experience('a',25)
      # check assignments
      self.assertEqual(stream.assignments().count(), (5*(i+1)))
    # check that grandchildren don't get assigned
    user = self.switchToUser(str(2))
    user.assign_post(resp[1])
    p = user.create_post(str(i), resp[1])
    stream = self.switchToUser(str(1))
    stream.adjust_experience('a',25)
    m = "Grandchildren are being assigned mistakenly."
    for a in stream.assignments().iter(keys_only=True):
      self.assertNotEqual(a.parent(), p.key,msg=m)

  def testCreateResponse(self):
    self.switchToUser('user')
    user = self.switchToUser('user')
    post = user.create_post('my post')
    post2 = user.create_post('my second post', post.key)
    def tag_enum(key):
      return key.parent()
    post_keys = user.assignments().map(tag_enum,keys_only=True)
    self.assertEqual(len(post_keys), len(set(post_keys)))
