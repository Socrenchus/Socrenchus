#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
Test file for the database model and core logic.
"""

import unittest
import os
from google.appengine.ext import db
from google.appengine.ext import testbed
from google.appengine.datastore import datastore_stub_util
from database import *

class ShortAnswerGradingTestCase(unittest.TestCase):
  
  def setUp(self):
    # Create test bed
    self.testbed = testbed.Testbed()
    self.testbed.activate()
    # Create a consistency policy that will simulate the High Replication consistency model.
    self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
    # Initialize the datastore stub with this policy.
    self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
    self.testbed.init_user_stub()
    
  def teardown(self):
    self.testbed.deactivate()
    
  def testCreateQuestion(self):
    q = ShortAnswerQuestion()
    q.value = 'the question text'
    a = Answer()
    a.value = 'the first correct answer'
    a.confidence = 1.0
    a.correctness = 1.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the second correct answer'
    a.confidence = 1.0
    a.correctness = 1.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the third correct answer'
    a.confidence = 1.0
    a.correctness = 1.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the fourth correct answer'
    a.confidence = 1.0
    a.correctness = 1.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the fifth correct answer'
    a.confidence = 1.0
    a.correctness = 1.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the first incorrect answer'
    a.confidence = 1.0
    a.correctness = 0.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the second incorrect answer'
    a.confidence = 1.0
    a.correctness = 0.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the third incorrect answer'
    a.confidence = 1.0
    a.correctness = 0.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the fourth incorrect answer'
    a.confidence = 1.0
    a.correctness = 0.0
    q.answers.append(a.put())
    a = Answer()
    a.value = 'the fifth incorrect answer'
    a.confidence = 1.0
    a.correctness = 0.0
    q.answers.append(a.put())
    q.put()
    self.assertEqual(10, len(Answer.all().fetch(11)))
    self.assertEqual(1, len(Question.all().fetch(2)))
    
  def testAnswerQuestion(self):
    # create the question
    self.testCreateQuestion()
    q = ShortAnswerQuestion.all().get()
    
    # have 1000 users answer the question
    for i in range(3):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = Assignment.assign(q)
      a.submitAnswer('answer #'+str(i))