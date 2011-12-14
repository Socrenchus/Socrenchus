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
    a = aBuilderQuestion.assign()
    a.submitAnswer('question')
    
    self.assertEqual(2, len(Question.all().fetch(3)))
    
  def testAnswerQuestion(self):
    # create the question
    self.testCreateQuestion()
    q = aBuilderQuestion.all().get().answer
        
    # have users answer the question
    for i in range(30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = aShortAnswerQuestion.assign(q)
      a.submitAnswer(str(i))
  
  def testGradeDistribution(self):
    os.environ['USER_EMAIL'] = 'teacher@example.com'
    a = aBuilderQuestion.assign()
    a.submitAnswer('Name a number that is divisible by four.')
    q = a.answer
  
    answers = [
      'Definitely Correct',
      'Not Completely Correct',
      'Not Completely Wrong',
      'Definitely Wrong',
    ]
    
    scores = [
    1.0,
    0.75,
    0.25,
    0.0,
    ]
      
    # have users answer the question
    for i in range(30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = aShortAnswerQuestion.assign(q)
      a.submitAnswer(str(i))
    
    # confidently grade some answers
    os.environ['USER_EMAIL'] = 'teacher@example.com'
    a = aConfidentGraderQuestion.all().filter('user =', users.User('teacher@example.com')).get()
    for i in range(5):
      a = a.submitAnswer(answers[int(a.answerInQuestion.value)%4])[2]
      
    # have the users grade eachother's answer
    query = db.Query(Answer,keys_only=True)
    for i in range(5,30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = aShortAnswerQuestion.all().filter('user =', users.User()).get()
      q = aGraderQuestion.all().filter('user =', users.User()).get()
      myAnswer = []
      agree = random.random() < (0.9 * scores[int(a.answer.value)%4])
      for a in q.answers:
        a = Answer.get(a)
        if scores[int(a.value)%4] > 0.5:
          if agree:
            myAnswer.append(a.value)
        else:
          if not agree:
            myAnswer.append(a.value)

      if len(myAnswer) == 0:
        myAnswer += 'None of the above'

      q.submitAnswer(myAnswer)
      
    # print the grades
    correct = 0.0
    n = 0.0
    for a in Answer.all().fetch(110):
      if not a.value in answers:
        n += 1.0
        correct += scores[int(a.value)%4] - a.correctness
    correct /= n
    
    print 'Average error was: '+str(correct)
      