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
from ndb import model, polymodel
from google.appengine.ext import db
from google.appengine.api import users
from google.appengine.ext import testbed
from google.appengine.datastore import datastore_stub_util
from database import *

class DefaultTestClass(unittest.TestCase):
  '''
  Setup, teardown, and assorted utility functions for all test cases.
  '''
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
  
  def _testAssignQuestion(self, cls, item=None, user=None):
    if not user:
      user = users.get_current_user()
    # Check length of assignments before
    u = UserData.get_by_id(str(user.user_id()))
    l = 0
    if u:
      l = len(u.assignments)
    
    cls.assign(item, user)
    
    # Check that it was added to UserData
    u = UserData.get_by_id(str(user.user_id()))
    self.assertEqual(len(u.assignments), l+1)
    
    # Check that the item was assigned
    assigned = u.assignments[l].get()
    if item:
      self.assertEqual(assigned.key.parent(), item)
    
    # Check that the right user was assigned
    self.assertEqual(assigned.user, user)


class BuilderQuestionTests(DefaultTestClass):
  '''
  Make sure builder questions are functioning properly.
  '''
  
  def testAssignBuilderQuestion(self):
    '''
    Tests that builder questions get assigned properly.
    '''
    self._testAssignQuestion(aBuilderQuestion)
    
  def testAnswerBuilderQuestion(self):
    '''
    Tests that a builder question creates a new question upon answering.
    '''
    pass
    
  def testSerializeBuilderQuestion(self):
    '''
    Tests that the builder question gets serialized properly.
    '''
    pass

class ShortAnswerQuestionTests(DefaultTestClass):
  '''
  Make sure short answer questions are functioning properly.
  '''
  
  def testAssignShortAnswerQuestion(self):
    '''
    Tests that short answer questions get assigned properly.
    '''
    self._testAssignQuestion(aShortAnswerQuestion, Question().put())
    
  def testAnswerShortAnswerQuestion(self):
    '''
    Tests that short answer questions behave as expected when answered.
    '''
    pass
    
  def testSerializeShortAnswerQuestion(self):
    '''
    Tests that a short answer question gets serialized properly.
    '''
    pass
    
class GraderQuestionTests(DefaultTestClass):
  '''
  Make sure grader questions are functioning as they should.
  '''
  
  def testAssignGraderQuestion(self):
    '''
    Tests that the grader question gets assigned properly.
    '''
    
    q = Question(answers=[Answer().put()]).put()
    self.switchToUser(1)
    self._testAssignQuestion(aGraderQuestion, q)
    
  def testAnswerGraderQuestion(self):
    '''
    Tests that the grading works.
    '''
    pass
  
  def testSerializeGraderQuestion(self):
    '''
    Tests that grader questions get serialized properly.
    '''
    pass

class ConfidentGraderQuestionTests(DefaultTestClass):
  '''
  Make sure grader questions are functioning as they should.
  '''

  def testAssignConfidentGraderQuestion(self):
    '''
    Tests that the grader question gets assigned properly.
    '''
    q = Question(answers=[Answer().put()]).put()
    self._testAssignQuestion(aConfidentGraderQuestion, q)

  def testAnswerConfidentGraderQuestion(self):
    '''
    Tests that the grading works.
    '''
    pass

  def testSerializeConfidentGraderQuestion(self):
    '''
    Tests that grader questions get serialized properly.
    '''
    pass

class FollowUpQuestionTests(DefaultTestClass):
  '''
  Make sure everything related to followup questions is working.
  '''
    
  def testAssignFollowUpBuilderQuestion(self):
    '''
    Tests assigning a followup builder question.
    '''
    self._testAssignQuestion(aFollowUpBuilderQuestion)
    
  def testAnswerFollowUpBuilderQuestion(self):
    '''
    Tests creation of a followup question.
    '''
    pass
    
  def testAssignFollowUpQuestion(self):
    '''
    Tests that followup question gets assigned when it should.
    '''
    pass
  
  def testSerializeFollowUpQuestion(self):
    '''
    Tests that a followup question gets serialized properly.
    '''
    pass