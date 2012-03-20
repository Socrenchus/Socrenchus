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
  xp        = ndb.FloatProperty(default=1.0)
  timestamp = ndb.DateTimeProperty(auto_now=True)
      
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
    if self.xp == 1.0:
      # dereference the experience points
      user = Stream.query(Stream.user==self.user).iter(keys_only=True).next()
      self.xp = 0 # clear the current
      def title_list(tag):
        return tag.title
      tags_d = Tag.query(ancestor=self.key.parent()).map(title_list)
      # check if parent post exists
      parent = self.key.parent().parent()
      if parent:
        tags_d.extend(Tag.query(ancestor=parent).map(title_list))
      tags = list(set(tags_d))
      for tag in tags:
        # get users experience for each tag
        ref_tag = Tag.query(Tag.title == tag, ancestor=user).get()
        if not ref_tag:
          ref_tag = Tag(title=tag, parent=user)
        # use weights to calculate new experience
        self.xp += ((ref_tag.xp * tags_d.count(tag)) / len(tags_d))
      
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
      def title_list(tag):
        return tag.title
      tags_d = Tag.query(ancestor=self.key.parent()).map(title_list)
      # check if parent post exists
      parent = self.key.parent().parent()
      if parent:
        tags_d.extend(Tag.query(ancestor=parent).map(title_list))
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
  