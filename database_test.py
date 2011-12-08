#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
Test file for the database model and core logic.
"""

import unittest
import os
import random
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
    os.environ['USER_EMAIL'] = 'teacher@example.com'
    q = ShortAnswerQuestion()
    q.value = 'question'
    q.put()
    for i in range(5):
      a = Answer()
      a.value = str(i+100)
      a.confidence = 1.0
      a.correctness = 1.0
      a.graders.append(users.User())
      a.questions.append(q.key())
      q.answers.append(a.put())
      a = Answer()
      a.value = str(i-5)
      a.confidence = 1.0
      a.correctness = 0.0
      a.graders.append(users.User())
      a.questions.append(q.key())
      q.answers.append(a.put())
    q.put()
    self.assertEqual(10, len(Answer.all().fetch(11)))
    self.assertEqual(1, len(Question.all().fetch(2)))
    
  def testAnswerQuestion(self):
    # create the question
    self.testCreateQuestion()
    q = ShortAnswerQuestion.all().get()
    
    # have users answer the question
    for i in range(30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = Assignment.assign(q)
      a.submitAnswer(str(i))
  
  def testGradeDistribution(self):
    # create the question
    self.testAnswerQuestion()
    saq = ShortAnswerQuestion.all().get()

    # have the users grade eachother's answer
    query = db.Query(Answer,keys_only=True)
    correct = query.filter('correctness =', 1.0).fetch(15)
    self.assertEqual(len(correct), 5)
    for i in range(30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = Assignment.assign(saq)
      q = aGraderQuestion.all().filter('user =', users.User()).get()
      smart = random.random() < 0.9
      if smart:
        correct.append(a.answer.key())
      myAnswer = []
      for a in q.answers:
        a = Answer.get(a)
        r = random.random()
        if smart:
          if a.key() in correct:
            myAnswer.append(a.value)
        else:
          if not a.key() in correct:
            myAnswer.append(a.value)
      q.submitAnswer(myAnswer)
      
    # print the grades
    correct = 0.0
    n = 0.0
    for a in Answer.all().fetch(110):
      n += 1.0
      # print a.correctness
      if n <= 10:
        startAnswerTest = float(int(n) % 2)
        message = 'The grade '+str(a.correctness)+' for one of the example answers exceeded acceptable error margin.'
        self.assertTrue((startAnswerTest - 0.15) < a.correctness, msg=message)
        self.assertTrue((startAnswerTest + 0.15) > a.correctness, msg=message)
      correct += a.correctness
    correct /= n
    
    expectedClassAverage = 0.8
    message = 'The class average '+str(correct)+' was too far off from the expected average of '+str(expectedClassAverage)+'.'
    self.assertTrue((expectedClassAverage - 0.1) < correct, msg=message)
    self.assertTrue((expectedClassAverage + 0.1) > correct, msg=message)
      