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
from google.appengine.api import users, memcache
from google.appengine.ext import testbed
from database import *

class DatabaseTests(unittest.TestCase):
  
  def setUp(self):
    self.testbed = testbed.Testbed()
    self.testbed.activate()
    self.testbed.init_user_stub()
    self.testbed.init_datastore_v3_stub()
    self.testbed.init_memcache_stub()
    from ndb import tasklets
    ctx = tasklets.get_context()
    ctx.set_cache_policy(lambda key: False)
    ctx.set_memcache_policy(lambda key: False)
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
    post.adjust_score(100.0).wait()
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
    Tag.get_or_create('a', p, None, 1)
    Tag.get_or_create('b', p, None, 3)
    Tag.get_or_create('c', p, None, 2)
    self.switchToUser('userB')
    Tag.get_or_create('a', p, None, 2)
    Tag.get_or_create('b', p, None, 2)
    Tag.get_or_create('d', p, None, 5)
    self.switchToUser('userC')
    Tag.get_or_create('a', p, None, 3)
    # switch back to 'tagging' user and apply a tag
    self.switchToUser('tagging')
    t = Tag(parent=p, title='blah')
    t.put()
    self.assertEqual(round(t.xp), 50)
    
  def testPointsFromTagging(self):
    # create the common post
    self.switchToUser('user')
    p = Post()
    p.put()
    # give users a starting experience
    self.switchToUser('A')
    a = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    aa = Tag.get_or_create('a', a, None, 500).key
    ab = Tag.get_or_create('b', a, None, 50).key
    ac = Tag.get_or_create('c', a, None, 5).key
    self.switchToUser('B')
    b = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    ba = Tag.get_or_create('a', b, None, 50).key
    bb = Tag.get_or_create('b', b, None, 500).key
    bc = Tag.get_or_create('c', b, None, 50).key
    self.switchToUser('C')
    c = Stream.query(Stream.user==users.User()).iter(keys_only=True).next()
    ca = Tag.get_or_create('a', c, None, 5).key
    cb = Tag.get_or_create('b', c, None, 50).key
    cc = Tag.get_or_create('c', c, None, 500).key
    # have users tag posts
    self.switchToUser('A')
    p.add_tag('a')
    self.switchToUser('B')
    p.add_tag('a')
    p.add_tag('b')
    self.switchToUser('C')
    p.add_tag('a')
    p.add_tag('b')
    p.add_tag('c')
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
    
  def testAssignment(self):
    # create post
    self.switchToUser('user')
    user = self.switchToUser('user')
    post = user.create_post('my post')
    post.add_tag('a')
    # create responses
    resp = []
    for i in range(15):
      user = self.switchToUser(str(i))
      resp.append(user.create_post(str(i), post.key).key)
    # check assignments
    stream = self.switchToUser(str(1))
    a = stream.get_assignments()
    m = "Stream contains unexpected duplicates."
    self.assertEqual(len(a), len(set([x for x in a])), msg=m)

    # check that grandchildren don't get assigned
    count = len(stream.get_assignments())
    user = self.switchToUser(str(2))
    p = user.create_post(str("grandchild"), resp[3])
    stream = self.switchToUser(str(1))
    stream.adjust_experience('a',15)
    m = "Grandchildren are being assigned mistakenly."
    self.assertEqual(count, len(stream.get_assignments()))
    for a in stream.get_assignments():
      self.assertNotEqual(a.get().depth, 4,msg=m)
  
  def testTagCounter(self):
    ctx = ndb.get_context()
    ctx.clear_cache()
    # create the common posts
    stream = self.switchToUser('user')
    p1 = Post()
    p1.put()
    p2 = Post()
    p2.put()
    # make a and b correlated
    p1.add_tag('a')
    p1.add_tag('b')
    # make b and c correlated
    p2.add_tag('c')
    p2.add_tag('b')
    # get count models
    a = TagCount.get_or_create('a')
    b = TagCount.get_or_create('b')
    c = TagCount.get_or_create('c')
    # get correlation models
    ab = TagCount.get_or_create('a', 'b')
    bc = TagCount.get_or_create('c', 'b')
    ac = TagCount.get_or_create('a', 'c')
    # check counts
    self.assertEqual(a.count, 1)
    self.assertEqual(b.count, 2)
    self.assertEqual(c.count, 1)
    # check correlations
    # TODO: Figure out why this isn't working.
    #self.assertEqual(ab.count, 1)
    #self.assertEqual(bc.count, 1)
    self.assertEqual(ac.count, 0)
    # check that xp matches since they should all be baseline
    for t in [a, b, c, ab, bc, ac]:
      self.assertEqual(t.count, t.xp)
    
