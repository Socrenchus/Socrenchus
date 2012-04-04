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
  
  @property
  def potential(self):
    """
    Quantify the value of a user-post pairing.
    """
    # potential is zero unless our response is a sibling
    # TODO: Calculate the potential points that can be earned by acting on any given post
      
    return result
  
  @property
  def visible(self):
    """
    Step function to determine if the user can see this post.
    """
    pass
  
  def dereference_experience(self):
    """
    Dereference a user's experience on a post.
    """
    user = Stream.query(Stream.user==users.get_current_user()).iter(keys_only=True).next()
    result = 0 # clear the current
    tags_d = Tag.weights(Tag.query(ancestor=self.key))
    # check if parent post exists
    parent = self.key.parent()
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
        result += ((ref_tag.xp * tags_d[tag]) / s)
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
    user = Stream.query(Stream.user==self.author).iter(keys_only=True).next()
    tags_d = Tag.weights(Tag.query(ancestor=self.key))
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
    
  def children(self):
    """
    Poll for the next page of visible children.
    """
    # TODO: Finish implementation of this children function

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
    return self.title == 'correct' or self.title == 'incorrect'
    
  def update_experience(self):
    """
    Update experience points of tag by dereferencing against parent post.
    """
    # check if experience was manually set
    if self.xp == 1.0:
      # if not, dereference the experience
      self.xp = self.key.parent().get().dereference_experience()
      
  def eval_score_change(self):
    """
    Update our tagged post's score if we are a base tag.
    """
    # check that we meet the conditions for a score adjustment
    if self.key.parent().kind() == 'Post':
      if self.is_base(): # adjust the score for the poster
        # figure out the sign on the score change
        delta = self.xp
        if self.title == 'incorrect':
          delta = -delta
        # adjust the score
        post = self.key.parent().get()
        post.adjust_score(delta)
      else: # adjust the experience for the taggers
        user = Stream.query(Stream.user==users.get_current_user()).iter(keys_only=True).next()
        post_tags = Tag.weights(Tag.query(ancestor=self.key.parent()))
        user_tag_count = Tag.query(Tag.user == users.User(), ancestor=self.key.parent()).count()
        all_tags = Tag.weights(Tag.query()) # TODO: cache this query somewhere
        ref_tag = Tag.query(Tag.title == self.title, ancestor=user).get()
        if not ref_tag:
          ref_tag = Tag(title=self.title, parent=user)
        # calculate change in xp for current user
        post_norm = sum(post_tags.values()) + 1
        all_norm = sum(all_tags.values()) + 1
        user_norm = user_tag_count + 1
        if self.title in all_tags:
          delta = (all_tags[self.title] / all_norm)
          # apply the change to the current user
          if self.title in post_tags:
            ref_tag.xp += (delta * (post_tags[self.title] / post_norm) / user_norm)
            ref_tag.put()
            # calculate the change for other taggers
            delta *= (self.xp / post_norm)
            user_counts = Tag.users(Tag.query(ancestor=self.key.parent()))
            ref_tag = None
            for user in user_counts.keys():
              norm = user_counts[user] + 1
              user = Stream.query(Stream.user==user).iter(keys_only=True).next()
              ref_tag = Tag.query(Tag.title == self.title, ancestor=user).get()
              if not ref_tag:
                ref_tag = Tag(title=self.title, parent=user)
              ref_tag.xp += (delta / norm)
              ref_tag.put()
          
  
  def _pre_put_hook(self):
    # call eval_score_changes when tag is created
    self.update_experience()
    self.eval_score_change()

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user        = ndb.UserProperty(auto_current_user_add=True)
  posts       = ndb.KeyProperty(kind=Post, repeated=True)
  timestamp   = ndb.DateTimeProperty(auto_now=True)
  