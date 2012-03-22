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
  
  def dereference_experience(self):
    """
    Dereference a user's experience on a post.
    """
    # TODO: abstract out dereferencing here
    pass
  
  def adjust_score(self, delta):
    """
    Adjust post's score by delta and reference experience.
    """
    # adjust the score by delta
    self.score += delta
    # reference the experience points earned
    user = Stream.query(Stream.user==self.author).iter(keys_only=True).next()
    tags_d = {}
    def tags_by_weight(tag):
      if tag.title in tags_d.keys():
        tags_d[tag.title] += tag.xp
      else:
        tags_d[tag.title] = tag.xp
    Tag.query(ancestor=self.key).map(tags_by_weight)
    # check if parent post exists
    parent = self.key.parent()
    if parent:
      Tag.query(ancestor=parent).map(tags_by_weight)
    tags = tags_d.keys()
    for tag in tags:
      ref_tag = Tag.query(Tag.title == tag, ancestor=user).get()
      if not ref_tag:
        ref_tag = Tag(title=tag, parent=user)
      s = sum(tags_d.values())
      if s > 0:
        ref_tag.xp += ((delta * tags_d[tag]) / s)
        ref_tag.put()
    self.put()
    
  def recommend(self, n=1, tags=None):
    """
    Use this post to recommend the next n posts to the user.
    """
    # TODO: Implement Post's recommend(n) function
    # TODO: Design solution for recommending on the root
    # only recomend if we responded to the post
    resp = Post.query(ancestor=self.key).iter(keys_only=True)
    if resp.has_next():
      # get our response to the post
      resp = resp_next()
      # do query to get direct children of post (matching one of the tags)
      children = {}
      def count_children(key):
        while key != self.key:
          if not key in children.keys():
            children[key] = 0
          children[key] += 1
          key = key.parent()
      Post.query(ancestor=self.key).map(keys_only=True)
      # TODO: filter recommendation on tags
      # dereference current user's experience on our response to post
      xp = resp.dereference_experience()
      # use experience on our response to post to get user's percentile on post
      percentile = None # TODO: calculate percentile
      # advance in the ordered sub posts according to percentile
      #  e.g. user with highest experience gets least popular posts
  
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
      tags_d = {}
      def tags_by_weight(tag):
        if tag.title in tags_d.keys():
          tags_d[tag.title] += tag.xp
        else:
          tags_d[tag.title] = tag.xp
      Tag.query(ancestor=self.key.parent()).map(tags_by_weight)
      # check if parent post exists
      parent = self.key.parent().parent()
      if parent:
        Tag.query(ancestor=parent).map(tags_by_weight)
      tags = tags_d.keys()
      for tag in tags:
        # get users experience for each tag
        ref_tag = Tag.query(Tag.title == tag, ancestor=user).get()
        if not ref_tag:
          ref_tag = Tag(title=tag, parent=user)
        # use weights to calculate new experience
        s = sum(tags_d.values())
        if s > 0:
          self.xp += ((ref_tag.xp * tags_d[tag]) / s)
      if self.xp == 0:
        self.xp = 1 # give it the base score
      
  def eval_score_change(self, remove=False):
    """
    Update our tagged post's score if we are a base tag.
    """
    # check that we meet the conditions for a score adjustment
    if self.key.parent().kind() == 'Post':
      if self.is_base(): # adjust the score for the poster
        # TODO: don't adjust score if we've changed our mind
        # figure out the sign on the score change
        delta = self.xp
        if self.title == 'incorrect':
          delta = -delta
        if remove:
          delta = -delta
        # adjust the score
        post = self.key.parent().get()
        post.adjust_score(delta)
      else: # TODO: adjust the experience for the taggers
        pass
   
  
  def _pre_put_hook(self):
    # call eval_score_changes when tag is created
    self.update_experience()
    self.eval_score_change()

  def _pre_delete_hook(self):
    # call update_score when tag is deleted
    self.eval_score_change(remove=True)

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user      = ndb.UserProperty(auto_current_user_add=True)
  posts     = ndb.KeyProperty(kind=Post, repeated=True)
  timestamp = ndb.DateTimeProperty(auto_now=True)
  