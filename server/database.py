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

all_futures = []

class Post(ndb.Model):
  """
  A post can be a question, it can be an answer, it can even be a statement.    
  """
# parent      = parent post (optional)
  author      = ndb.UserProperty(auto_current_user_add=True)
  content     = ndb.TextProperty()
  score       = ndb.FloatProperty(default=0.0)
  timestamp   = ndb.DateTimeProperty(auto_now=True)
  
  def sibling(self):
    """
    Return a query for a sibling of this post.
    """
    return ndb.Query(ancestor=self.key.parent())
  
  @ndb.ComputedProperty
  def popularity(self):
    """
    Count the number of children a post has.
    """
    return ndb.Query(ancestor=self.key).count()
  
  def dereference_experience(self):
    """
    Dereference a user's experience on a post.
    """
    user = Stream.query(Stream.user==users.get_current_user()).get()
    result = 0 # clear the current
    tags_d = Tag.weights(Tag.query(ancestor=self.key))
    # check if parent post exists
    parent = self.key.parent()
    if parent:
      Tag.query(ancestor=parent).map(tags_by_weight)
    tags = tags_d.keys()
    for tag in tags:
      # use weights to calculate new experience
      s = sum(tags_d.values())
      if s > 0:
        result += ((user.get_experience(tag) * tags_d[tag]) / s)
    if result == 0:
      result = 1 # give it the base score
    
    return result
  
  def adjust_score(self, delta):
    """
    Adjust post's score by delta and reference experience.
    """
    # adjust the score by delta
    self.score += delta
    # reference the experience points earned
    user = Stream.query(Stream.user==self.author).get()
    tags_d = Tag.weights(Tag.query(ancestor=self.key))
    # check if parent post exists
    parent = self.key.parent()
    if parent:
      Tag.query(ancestor=parent).map(tags_by_weight)
    tags = tags_d.keys()
    s = sum(tags_d.values())
    for tag in tags:
      if s > 0:
        user.adjust_experience(tag,((delta * tags_d[tag]) / s)).wait()
        
    return self.put_async()

class Tag(ndb.Model):
  """
  A tag is a byte sized, repeatable, calculable piece of information about  
  something. It can be used to describe a post, or even a user or a tag.
  """
# parent      = item being tagged
  user        = ndb.UserProperty(auto_current_user_add=True)
  title       = ndb.StringProperty()
  xp          = ndb.FloatProperty(default=1.0)
  timestamp   = ndb.DateTimeProperty(auto_now=True)
  
  @property
  def weight(self):
    """
    Get the normalized weight of a tag.
    
    TODO: Layered caching to speed this up.
    """
    self.global_tally = 0.0
    self.global_total = 1.0
    self.local_tally = 0.0
    self.local_total = 1.0
    self.user_total = 1.0
    def tally_up(tag):
      self.global_total += tag.xp
      if tag.key.parent() == self.key.parent():
        self.local_total += tag.xp
        if tag.user == self.user:
          self.user_total += 1
      if tag.title == self.title:
        self.global_tally += tag.xp
        if tag.key.parent() == self.key.parent():
          self.local_tally += tag.xp
    Tag.query().map(tally_up)
    return (self.local_tally*self.global_total) / (self.local_total*self.global_tally+self.user_total)
      
      
  @classmethod
  def weights(cls, q):
    """
    Get an associative array of tags and their weights.
    """
    result = {}
    def tag_enum(tag):
      if tag.title in result.keys():
        result[tag.title] += tag.xp
      else:
        result[tag.title] = tag.xp
    q.map(tag_enum)
    return result
  
  @classmethod
  def users(cls, q):
    """
    Get a count of tags by user.
    """
    result = {}
    def tag_enum(tag):
      if tag.user in result.keys():
        result[tag.user] += 1
      else:
        result[tag.user] = 1
    q.map(tag_enum)
    return result
      
  def is_base(self):
    """
    Check if tag is a base tag.
    """
    return self.title == ',correct' or self.title == ',incorrect'
    
  def update_experience(self):
    """
    Update experience points of tag by dereferencing against parent post.
    """
    self.xp = self.key.parent().get().dereference_experience()
      
  def eval_score_change(self):
    """
    Update our tagged post's score if we are a base tag.
    """
    if self.is_base(): # adjust the score for the poster
      # figure out the sign on the score change
      delta = self.xp
      if self.title == ',incorrect':
        delta = -delta
      # adjust the score
      post = self.key.parent().get()
      post.adjust_score(delta).wait()
    else:
      # adjust the experience for the taggers
      user = Stream.query(Stream.user==users.get_current_user()).get()
      all_futures.append(user.adjust_experience(self.title, self.weight))
      def reward_tagger(tag):
        user = Stream.query(Stream.user==tag.user).get()
        all_futures.append(user.adjust_experience(tag.title, tag.weight/tag.local_tally))
      Tag.query(Tag.title == self.title, ancestor=self.key.parent()).map(reward_tagger)
          
  def _pre_put_hook(self):
    # call eval_score_changes when tag is created
    if self.xp == 1 and self.key.parent().kind() == 'Post':
      self.update_experience()
      self.eval_score_change()

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user        = ndb.UserProperty(auto_current_user_add=True)
  timestamp   = ndb.DateTimeProperty(auto_now=True)
  
  @property
  def assignments(self):
    """
    Returns a list of post keys assigned to the user.
    """
    def tag_enum(tag):
      return tag.parent()
    return Tag.query(Tag.title == ',assignment', ancestor=post_key).map(tag_enum,keys_only=True)
  
  def assigned_children(self, post_key):
    """
    Returns a list of post keys assigned to the user under the given post key.
    """
    def tag_enum(tag):
      return tag.parent()
    return Tag.query(Tag.title == ',assignment', ancestor=post_key).map(tag_enum,keys_only=True)
  
  def get_tag(self, tag_title):
    """
    Returns the experience tag for the user.
    """
    ref_tag = Tag.query(Tag.title == tag_title, ancestor=self.key).get()
    if not ref_tag:
      ref_tag = Tag(title=tag_title, parent=self.key)
    return ref_tag
    
  def adjust_experience(self, tag_title, delta):
    """
    Adjusts the user's experience in a tag.
    """
    ref_tag = self.get_tag(tag_title)
    ref_tag.xp += delta
    return ref_tag.put_async()
    
  def get_experience(self, tag_title):
    """
    Returns the user's experience in a tag.
    """
    return self.get_tag(tag_title).xp
    