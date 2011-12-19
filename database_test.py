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
from ndb import model, polymodel
#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein.
# All rights reserved.
#

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
    self.testbed.init_memcache_stub()
    self.testbed.init_user_stub()
    
  def teardown(self):
    self.testbed.deactivate()

  def testNoneQuery(self):
    Question(answers=[Answer(value="yay").put()]).put()
    Question().put()
    self.assertEqual(Question.query(Question.answers == None).count(2), 1)
  
  def testUserSwitching(self):
    os.environ['USER_EMAIL'] = 'test1@example.com'
    self.assertEqual(users.get_current_user().email(), 'test1@example.com')
    os.environ['USER_EMAIL'] = 'test2@example.com'
    self.assertEqual(users.get_current_user().email(), 'test2@example.com')

  def testGradeDistribution(self):
    os.environ['USER_EMAIL'] = 'teacher@example.com'
    a = aBuilderQuestion.assign()
    a.submitAnswer('Name a number that is divisible by four.')
    question = a.answer
  
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
      a = aShortAnswerQuestion.assign(question)
      a.submitAnswer(str(i))
    
    # confidently grade some answers
    os.environ['USER_EMAIL'] = 'teacher@example.com'
    a = aConfidentGraderQuestion.query(Assignment.user == users.User('teacher@example.com')).get()
    for i in range(5):
      a = a.submitAnswer(answers[int(a.answerInQuestion.get().value)%4])[1]
      
    # have the users grade eachother's answer
    for i in range(5,30):
      os.environ['USER_EMAIL'] = 'test'+str(i)+'@example.com'
      a = aShortAnswerQuestion.query(Assignment.user == users.User()).get()
      q = aGraderQuestion.query(Assignment.user == users.User()).get()
      myAnswer = []
      agree = random.random() < (0.9 * scores[int(a.answer.get().value)%4])
      for a in q.answers:
        a = a.get()
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
    for a in question.get().answers:
      a = a.get()
      if not a.value in answers:
        n += 1.0
        correct += scores[int(a.value)%4] - a.correctness
    correct /= n
    
    print 'Average error was: '+str(correct)
      