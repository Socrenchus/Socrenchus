#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein.
# All rights reserved.
#

"""
A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.

This file contains all of the remote procedural calls.
"""

__author__ = 'Bryan Goldstein'


from database import *

class RPCMethods:
    """ 
    Defines the methods that can be RPCed.
    """
    
    def assignments(self, key, obj):
      """
      Handles assignment related queries.
      """
      result = None
      if key:
        if obj:
          """ update """          
          # retrieve the assignment
          q = model.Key(urlsafe=key).get()

          # answer it
          if 'answer' in obj.keys() and 'value' in obj['answer'].keys():
            result = q.submitAnswer(obj['answer']['value'])
            
          # put/assign it
          q.put()
        else:
          """ delete """          
          pass
      else:
        if obj:
          """ create """
        else:
          """ read """
          result = self.stream(0)['assignments']

      return result

    
    def questions(self, *args):
      """
      Handles question related queries.
      """
      result = None
      if key:
        if obj:
          """ update """
          pass
        else:
          """ delete """          
          pass
      else:
        if obj:
          """ create """
          pass
        else:
          """ read """
          pass

      return result
    
    def assign(self, *args):
      """
      Assign a question to the user.
      """
      # get the question key
      key = str(args[0])

      # retrieve the question
      q = model.Key(urlsafe=key).get()
      
      # assign it
      result = aShortAnswerQuestion.assign(q.key)
      
      return result
      
    def answer(self, *args):
      """
      Let the user answer a question.
      """
      # get the question key
      key = str(args[0])

      # obtain the answer
      ans = args[1]

      # retrieve the assignment
      q = model.Key(urlsafe=key).get()
      
      # answer it
      result = q.submitAnswer(ans)
      
      return result
      
    def stream(self, *args):
      """
      Return the user's question stream.
      """
      
      # get the stream segment
      if args and len(args) > 0:
        sid = int(args[0])
      else:
        sid = 0

      start = sid*15
      end = start+15

      ud = UserData.get_or_insert(str(users.get_current_user().user_id()))

      assignment_keys = ud.assignments
      assignment_keys.reverse()
      assignments = model.get_multi(assignment_keys[start:end])

      myDict = {'logout': users.create_logout_url( "/" ), 'assignments': assignments}
      return myDict
      
    def createClass(self, *args):
      """
      Creates a class for the user.
      """
      return [ aBuilderQuestion.assign() ]