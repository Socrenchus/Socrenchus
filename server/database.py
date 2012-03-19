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
# parent  = parent post (optional)
  author  = ndb.UserProperty(auto_current_user_add=True)
  content = ndb.TextProperty()
  score   = ndb.FloatProperty(default=0.0)
  
  def update_score(self, tags=None, remove=False):
    """
    Update this post's score
    """
    # default to all tags
    if not tags:
      tags = [t.title for t in Tag.query(Tag.title!='correct',Tag.title!='incorrect',ancestor=self.key)]
      tags = list(set(tags))
    
    # TODO: calculate user's experience in current context
    experience = 100.001
    sib_posts = Post.query(ancestor=self.key.parent())
      
    for tag in tags:
      # importance of tag on this post
      self_weight = Tag.weight(tag, self.key)
    
      # loop through all sibling posts
      for sib_post in sib_posts.iter(keys_only=True):
      
        # importance of tag on sibling post
        sib_weight = Tag.weight(tag, sib_post)
      
        if sib_weight > 0:
          # base tag correlation
          correct = Tag.query(Tag.title=='correct', ancestor=sib_post).count()
          incorrect = Tag.query(Tag.title=='incorrect', ancestor=sib_post).count()
      
          # calculate change in score
          delta = (experience*self_weight*sib_weight*(correct-incorrect))
    
          # check if the tag is being removed
          if remove:
            delta = -delta
    
          # adjust the score
          self.score += delta
            
    # store post
    self.put()
  
class Tag(ndb.Model):
  """
  A tag is a byte sized, repeatable, calculable piece of information about  
  something. It can be used to describe a post, or even a user or a tag.
  """
# parent = item being tagged
  user    = ndb.UserProperty(auto_current_user_add=True)
  title   = ndb.StringProperty()
  
  @classmethod
  def weight(cls, tag_name, post_key):
    """
    Finds the importance of a tag on a given post.
    """
    count = Tag.query(Tag.title==tag_name, ancestor=post_key).count()
    total = Tag.query(ancestor=post_key).count()
    count = float(count)
    total = float(total)
    
    if total > 0:
      return count/total
    else:
      return 0.0
      
  def update_post_scores(self, remove=False):
    """
    Find the related posts and call their update_score method.
    """
    if self.title == 'correct' or self.title == 'incorrect':
      for p in Post.query(ancestor=self.key.parent().parent()):
        p.update_score(None, remove)
    else:
      self.key.parent().get().update_score([self.title], remove)
  
  def _pre_put_hook(self):
    # call update_post_scores when tag is created
    self.update_post_scores()

  def _pre_delete_hook(self):
    # call update_score when tag is deleted
    self.update_post_scores(remove=True)

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user    = ndb.UserProperty(auto_current_user_add=True)
  posts   = ndb.KeyProperty(kind=Post, repeated=True)
  