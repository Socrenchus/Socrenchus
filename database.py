#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein.
# All rights reserved.
#

"""
The system currently known as Socrenchus is designed to be a personal tutor 
that not only caters to every student individually to help them learn, it also 
caters to every professor helping them build up the areas of their course that 
need work.

This is the database model and core logic.
"""

from ndb import model, polymodel
from google.appengine.api import users

import random


##########################
## Core Model and Logic ##
##########################

class Connection(model.Model):
  """
  Models a link between questions.
  """
# parent = Question or Answer
  target = model.KeyProperty()
  score = model.FloatProperty(default=0.0)
  age = model.IntegerProperty(default=0)

class Question(model.Model):
  """
  Models a question.
  """
  author = model.UserProperty(auto_current_user_add=True)
  value = model.TextProperty()
  answers = model.KeyProperty(repeated=True)

class Answer(model.Model):
  """
  Models an answer.
  """
  author = model.UserProperty(auto_current_user_add = True)
  value = model.TextProperty()
  correctness = model.FloatProperty(default=0.0) # probability of answer being correct
  confidence = model.FloatProperty(default=0.0)  # probability of grading being correct
# parent = Question

  def canShowScore(self):
    """
    Determines if it is safe to show the user the score.
    """
    # TODO: implement a real check
    return (self.author == users.get_current_user())

  def __json__(self):
    prop_filter = ['value']
    if self.canShowScore():
      prop_filter += ['correctness', 'confidence', 'author']
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field) and field in prop_filter:
        output[field] = getattr(self, field)
    return output

##########################
## User Model and Logic ##
##########################

class UserData(model.Model):
  """
  Stores data specific to a user.
  """
  assignments = model.KeyProperty(repeated=True)

class Assignment(polymodel.PolyModel):
  """
  Models a generic assignment
  """
  user = model.UserProperty(auto_current_user_add = True)
  time = model.DateTimeProperty(auto_now = True)
# parent = assigned item
  
  @classmethod
  def assign(cls, item=None, user=None):
    """
    Assign an object (key) if it isn't already assigned
    """
    if not user:
      user = users.get_current_user()
    if not item:
      item = cls.getItem()
    instance = cls.getInstance(item, user)
    if not instance:
      instance = cls(parent=item)
      instance.user = user
      instance = instance.prepare()
      if instance:
        ud = UserData.get_or_insert(str(user.user_id()))
        ud.assignments.append(instance.key)
        ud.put()
    return instance
    
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    return cls.query(cls.user==user, ancestor=item).get()
  
  def prepare(self):
    """
    After initializing, prepare sets up and stores the assignment.
    """
    self.put()
    return self

class aQuestion(Assignment):
  """
  Models user specific question data.
  """
  liked = model.BooleanProperty(default=False)
  score = model.FloatProperty(default=0.0)
# user = model.UserProperty(auto_current_user = True)
# parent = question

  def submitAnswer(self):
    """
    Assigns follow up questions.
    """
    result = []
    for c in Connection.query(ancestor=self.key.parent()):
      result.append(aShortAnswerQuestion.assign(c.target))
      
    return result

  def __json__(self):
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field):
        output[field] = getattr(self, field)
    output['key'] = self.key.urlsafe()
    if self.key.parent():
      output['question'] = self.key.parent().get()
    output['_class'] = self.class_
    return output

class aShortAnswerQuestion(aQuestion):
  answer = model.KeyProperty()
  def submitAnswer(self, myAnswer):
    """
    Answers the question if it hasn't been answered.
    """
    if self.answer:
      return False    
    # get user (login is required in app.yaml)
    u = users.User()
    
    # Generate the assesment question
    q = None
    teacherQ = True
    parent = self.key.parent().get()
    if len(parent.answers) >= 1:
      q = aGraderQuestion.assign(parent.key)
    
    teacherQ = aConfidentGraderQuestion.isGradingQuestion(parent.key)
        
    # Create the user's answer
    self.answer = Answer(value=myAnswer, parent=parent.key).put()
    parent.answers.append(self.answer)
    parent.put()
    
    # Assign the teacher to grade
    if not teacherQ:
      aConfidentGraderQuestion.assign(parent.key, parent.author)
    
    result = [self]
    
    if q:
      result.append(q)

    self.put()
    
    result.extend(aQuestion.submitAnswer(self))
    
    # assign the grading question
    return result
    
  def __json__(self):
    properties = self._properties.items()
    output = {}
    for field, value in properties:
      if hasattr(self, field):
        output[field] = getattr(self, field)
    output['key'] = self.key.urlsafe()
    if self.key.parent():
      output['question'] = self.key.parent().get()
    if self.answer:
      output['score'] = self.answer.get().correctness
    output['_class'] = self.class_
    return output

class aNumericAnswerQuestion(aQuestion):
  """
  Models a question where a numeric response is required.
  """
  answer = model.FloatProperty()

class aGraderQuestion(aNumericAnswerQuestion):
  """
  Used to grade short answer questions.
  """
  answerInQuestion = model.KeyProperty()
  @classmethod
  def gradedAnswer(cls, answer):
    """
    Returns a query for assignments that graded any given answer.
    """
    return cls.query(cls.answerInQuestion==answer, ancestor=answer.parent())
    
  @classmethod
  def userGradedAnswer(cls, answer, user=None):
    """
    Returns a query for an assignment graded by a user.
    """
    if not user:
      user = users.get_current_user()
    return cls.gradedAnswer(answer).filter(cls.user==user)
    
  @classmethod
  def userGradesForQuestion(cls, question, user=None):
    """
    Returns all of a users grading for the current question.
    """
    if not user:
      user = users.get_current_user()
    return cls.query(cls.user==user, ancestor=question)
    
  @classmethod
  def regradeAnswer(cls, answer):
    """
    Regrade the given answer key.
    """      
    # find neighbors
    query = aGraderQuestion.gradedAnswer(answer)
    for q in query:
      if q.answer != None:
        q.grade()
  
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    return None

  def prepare(self):
    """
    Assigns the answers from the question.
    """
    answers = []
    parent = self.key.parent().get()
    for ans in parent.answers:
      answers.append(ans)
    
    random.shuffle(answers)
    
    # All answers waiting to be graded by count
    answerCount = {}
    for a in answers:
      count = aGraderQuestion.gradedAnswer(a).count()
      if count in answerCount.keys():
        answerCount[count].append(a)
      else:
        answerCount[count] = [a]
        
        
    gradedAnswers = [g.answerInQuestion for g in aGraderQuestion.userGradesForQuestion(self.key.parent())]
    
    # Assign the answer
    self.answerInQuestion = None
    for count in answerCount.keys():
      if self.answerInQuestion:
        break
      for a in answerCount[count]:
        if not a in gradedAnswers and a.get().author != self.user:
          self.answerInQuestion = a
          break
    
    # Check that there was enough
    if not self.answerInQuestion:
      return None
    
    self.put()
    return self

  def submitAnswer(self, answer):
    """
    Submits the answer.
    """

    self.answer = float(answer)
    self.put()
    
    self.grade()

    # assign next GraderQuestion
    result = [self]
    next = aGraderQuestion.assign(self.key.parent())
    if next:
      result.append(next)

    result.extend(aQuestion.submitAnswer(self))

    return result
  
  def getConfidence(self):
    """
    Gets the confidence in the current user's grading of the question.
    """
    confidenceSum = 0.0
    confidenceSumMax = 0.0
    normalizer = 0
    myAnswer = (self.answer/100.0)
    for g in aGraderQuestion.userGradesForQuestion(self.key.parent()):
      # get and store the answer
      a = g.answerInQuestion
      ans = a.get()
            
      # answer's current marks with grader's
      match = abs(myAnswer - ans.correctness)
      
      # give the grader some of the answer's confidence
      confidenceSum += match * ans.confidence
      
      # increment normalizer
      normalizer += 1
      confidenceSumMax += ans.confidence
      
    # error check
    if normalizer == 0:
      return
      
    # calculate score (confidence normalized by maximum)
    if confidenceSumMax != 0:
      self.score = (confidenceSum / confidenceSumMax)
    self.put()
      
    # normalize confidence (if no error)
    return (confidenceSum / float(normalizer))
  
  def grade(self):
    """
    Apply grading relevent to aGraderQuestion
    """
    # grade with new found confidence
    answersToRegrade = []
    myAnswer = (self.answer/100.0)
    confidence = self.getConfidence()
    for g in aGraderQuestion.userGradesForQuestion(self.key.parent()):
      a = g.answerInQuestion.get()
      if not aConfidentGraderQuestion.hasGradedAnswer(a.key):
        numGraders = aGraderQuestion.gradedAnswer(a.key).count()
        tmp = numGraders*(a.confidence * a.correctness)
        tmp += confidence * myAnswer
        if (confidence + numGraders*a.confidence) != 0:
          tmp /= (confidence + numGraders*a.confidence)
        a.correctness = tmp
        beforeConfidence = a.confidence
        a.confidence = (confidence + (a.confidence * numGraders)) / (1 + numGraders)
        a.put()
      
        # recurse if condition is met
        # TODO: fiddle with condition
        if a.confidence - beforeConfidence > 0.1:
          answersToRegrade.append(a)
    
    # recurse
    for a in answersToRegrade:
      aGraderQuestion.regradeAnswer(a.key)

class aConfidentGraderQuestion(aGraderQuestion):
  """
  Allows the creator of a short answer question to set the baseline.
  """
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned question.
    """
    user = item.get().author
    q = cls.query(ancestor=item)
    
    q.filter(cls.user==user)
    for i in q.iter():
      if i.answer == None:
        return i
      
    return None
  
  @classmethod
  def isGradingQuestion(cls, question_key):
    """
    True if the question is being graded
    """
    return bool(cls.getInstance(question_key))
    
  @classmethod
  def hasGradedAnswer(cls, answer):
    """
    True if the answer has been graded
    """
    q = cls.query(cls.answerInQuestion==answer, ancestor=answer.parent())
    return (q.count(1) > 0)
  
  def prepare(self):
    """
    Chooses the lowest confidence answer to grade.
    """
    minAns = Answer()
    minAns.confidence = 1.0
    existing = [x for x in aConfidentGraderQuestion.query(ancestor=self.key.parent())]
    parent = self.key.parent().get()
    for ans in parent.answers:
      a = ans.get()
      if a.confidence < minAns.confidence and not (a in existing):
        minAns = a
      if minAns.confidence == 0.0:
        break
        
    if minAns.confidence == 1.0:
      return None
    
    # add the answer in question
    self.answerInQuestion = minAns.key
    
    self.put()
    return self

  def submitAnswer(self, answer):
    """
    Submits the grade, regrades neighbors, and assigns 
    next ConfidentGraderQuestion.
    """

    # submit the grade
    a = self.answerInQuestion.get()
    a.correctness = float(float(answer)/100.0)
    a.confidence = 1.0
    a.put()

    self.answer = float(answer)
    self.score = a.correctness
    self.put()
    
    # regrade the answer
    aGraderQuestion.regradeAnswer(a.key)

    # assign next ConfidentGraderQuestion
    result = [self, aBuilderQuestion.builderForQuestion(self.key.parent())]
    parent = self.key.parent().get()
    next = aConfidentGraderQuestion.assign(parent.key, parent.author)
    if next:
      result.append(next)

    return result
    
class aBuilderQuestion(aQuestion):
  """
  Creates a short answer question and tracks class progress.
  """
  answer = model.KeyProperty() # Question
  @classmethod
  def getItem(cls):
    """
    Get the builder question.
    """
    return Question.get_or_insert('builderQuestion').key
  
  @classmethod
  def getInstance(cls, item, user=None):
    """
    Get an instance from the assigned object.
    """
    q = cls.query(ancestor=item)

    for i in q.filter(cls.user==user,cls.answer==None):
      if not i.answer:
        return i
        
    return None
  
  @classmethod
  def builderForQuestion(cls, question_key):
    return cls.query(cls.answer==question_key, ancestor=aBuilderQuestion.getItem()).get()  

  def submitAnswer(self, answer):
    """
    Create the short answer question.
    """
    self.answer = Question(value=answer).put()
    self.put()
    
    return [self, aFollowUpBuilderQuestion.assign(self.answer)]
    
  def __json__(self):
    output = aQuestion.__json__(self)
    output['gradeDistribution'] = [0 for i in range(11)]
    output['confidentGradeDistribution'] = [0 for i in range(11)]
    if self.answer:
      for a in self.answer.get().answers:
        ans = a.get()
        d = int(round(ans.correctness*10.0))
        if d and ans.confidence != 0:
          if aConfidentGraderQuestion.hasGradedAnswer(a):
            output['confidentGradeDistribution'][d] += 1
          else:
            output['gradeDistribution'][d] += 1

    return output
    
class aFollowUpBuilderQuestion(aBuilderQuestion):
  """
  Same as a builder question but associates the question with an assignment.
  """
  
  def prepare(self):
    """
    Just override parent's prepare function.
    """
    return Assignment.prepare(self)
  
  def submitAnswer(self, answer):
    """
    Adds the new question to follow the parent.
    """
    # submit answer as normal
    result = aBuilderQuestion.submitAnswer(self, answer)
    
    # add the connection object
    Connection(parent=self.key.parent(),target=self.answer).put()
    
    # search for answered assignments of the connection object
    q = self.key.parent().get()
    if isinstance(q, Answer):
      # the connection source is an answer
      aShortAnswerQuestion.assign(self.answer, q.author)
      
      # TODO: assign to all the graders
    else:
      # assign to all the answerers
      query = aShortAnswerQuestion.query(ancestor=q.key)
      for item in query:
        item = item.get()
        if item.answer != None:
          aShortAnswerQuestion.assign(self.answer, item.user)
      
    return result
  