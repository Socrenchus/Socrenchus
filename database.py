#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""
The system currently known as Socrenchus is designed to be a personal tutor 
that not only caters to every student individually to help them learn, it also 
caters to every professor helping them build up the areas of their course that 
need work.

This is the database model and core logic.
"""

from google.appengine.ext import db

##########################
##  App Engine Graph    ##
##########################

class Edge(db.Model):
  """
  Models a graph edge.
  """
  source = db.Key
  target = db.Key
  weight = db.IntegerProperty(default=0)
  
class Node(db.Model):
  """
  Models a graph node.
  """
  def connectTo(self, aNode):
    """
    Connects a node to another node.
    """
    if not isinstance(aNode, Node):
      throw Exception('You can only connect to another node.')
    
    return Edge(source = self, target = aNode).put()
    
  
  def _getConnections(self, self_type, num = 0):
    """
    Returns a list of nodes.
    """
    filter_string = self_type + " ="
    query = Edge.all().filter(filter_string).order(weight)
    
    not_self_type = (self_type == "source") ? "target" : "source"
    
    i = 1
    result = []
    for q in query:
      if i == num:
        break
      result += getattr(q, not_self_type)
      
    return db.get(result)
    
  def incoming(self, num = 0):
    """
    Get objects that point to this node.
    """
    return self._getConnections("target", num)
    
  
  def outgoing(self, num = 0):
    """
    Get objects that this node points to.
    """
    return self._getConnections("source", num)

##########################
## Core Model and Logic ##
##########################

class Question(db.Model, Node):
  """
  Models a question.
  """
  author = db.UserProperty(auto_current_user_add = True)
  title = db.StringProperty()
  body = db.TextProperty()
# answers = db.Query(Answer)
# incoming(num) = [Answer]
# outgoing(num) = [Lesson]
# assignments = db.Query(aQuestion)
  
class Answer(db.Model, Node):
  """
  Models an answer.
  """
  author = db.UserProperty(auto_current_user_add = True)
  question = db.ReferenceProperty(Question, collection_name="answers")
  text = db.TextProperty()
  correctness = db.FloatProperty()
  confidence = db.FloatProperty()
# outgoing(num) = [Question]
  
class Lesson(db.Model, Node):
  """
  Models a lesson.
  """
  author = db.UserProperty(auto_current_user_add = True)
  title = db.StringProperty()
# incoming(num) = [Question]
  
##########################
## User Model and Logic ##
##########################

class Assignment(db.Model):
  """
  Models a generic assignment
  """
  def __new__(cls, assignedModel):
    db.all().ancestor(assignedModel).filter('user =', users.User())
    
    if not cls._instance:
        cls._instance = super(Singleton, cls).__new__(
                            cls, *args, **kwargs)
    return cls._instance
    
  def __init__(self, assignedModel):
    pass

class aLesson(db.Model, Assignment):
  """
  Models user specific lesson data.
  """
  user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Lesson)
# assigned_questions = db.Query(aQuestion)

class aQuestion(db.Model, Assignment):
  """
  Models user specific question data.
  """
  user = db.UserProperty(auto_current_user = True)
# parent = db.ReferenceProperty(Question)