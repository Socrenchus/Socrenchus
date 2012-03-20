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

from google.appengine.api import users
from google.appengine.ext import ndb

import random

class Post(ndb.Model):
  """
  A post can be a question, it can be an answer, it can even be a statement.    
  """
# parent    = parent post (optional)
  author    = ndb.UserProperty(auto_current_user_add=True)
  content   = ndb.TextProperty()
  score     = ndb.FloatProperty(default=0.0)
  timestamp = ndb.DateTimeProperty(auto_now=True)
  
class Tag(ndb.Model):
  """
  A tag is a byte sized, repeatable, calculable piece of information about  
  something. It can be used to describe a post, or even a user or a tag.
  """
# parent    = item being tagged
  user      = ndb.UserProperty(auto_current_user_add=True)
  title     = ndb.StringProperty()
  xp        = ndb.FloatProperty(default=0.0)
  timestamp = ndb.DateTimeProperty(auto_now=True)
  
  def weight(self):
    """
    Finds the importance of a tag on a given post.
    """
    count = Tag.query(Tag.title==self.title, ancestor=self.key.parent()).count()
    total = Tag.query(ancestor=self.key.parent()).count()
    count = float(count)
    total = float(total)
    
    if total > 0:
      return count/total
    else:
      return 0.0
      
  def is_base(self):
    """
    Check if tag is a base tag.
    """
    return self.title == 'correct' or self.title == 'incorrect'
    
  def update_experience(self):
    """
    Update experience points of tag by dereferencing against parent post.
    """
    # check if experience was manually set
    if not self.xp:
      # check if parent post exists
      if self.key.parent().parent():
        # dereference the experience points
        self.xp = 0 # clear the current
        # get tags of parent post by weight
        tags_d = [t.title for t in Tag.query(ancestor=self.key.parent().parent())]
        tags = list(set(tags_d))
        for tag in tags:
          # get users experience for each tag
          ref_tag = Tag.query(Tag.title == tag, ancestor=self.user).get()
          if not ref_tag:
            ref_tag = Tag(title=tag, parent=user)
          # use weights to calculate new experience
          self.xp += ((ref_tag.xp * tags_d.count(tag)) / len(tags_d))
      else:
        self.xp = 1 # base point for tagging
      
  def update_post_score(self, remove=False):
    """
    Update our tagged post's score if we are a base tag.
    """
    if self.is_base() and self.key.parent().kind() == 'Post':
      # update the score of the post
      post = self.key.parent().get()
      delta = self.xp
      if self.title == 'incorrect':
        delta = -delta
      if remove:
        delta = -delta
      post.score += delta
      
      # reference the experience points earned
      user = Stream.query(Stream.user==post.author).iter(keys_only=True).next()
      tags_d = [t.title for t in Tag.query(ancestor=self.key.parent())]
      tags = list(set(tags_d))
      for tag in tags:
        ref_tag = Tag.query(Tag.title == tag, ancestor=user).get()
        if not ref_tag:
          ref_tag = Tag(title=tag, parent=user)
        ref_tag.xp += ((delta * tags_d.count(tag)) / len(tags_d))
        ref_tag.put_async()
  
  def _pre_put_hook(self):
    # call update_post_scores when tag is created
    self.update_experience()
    self.update_post_score()

  def _pre_delete_hook(self):
    # call update_score when tag is deleted
    self.update_post_score(remove=True)

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user      = ndb.UserProperty(auto_current_user_add=True)
  posts     = ndb.KeyProperty(kind=Post, repeated=True)
  timestamp = ndb.DateTimeProperty(auto_now=True)
  