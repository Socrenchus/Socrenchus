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
  age     = ndb.IntegerProperty(default=0)
  
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
    return count/total
  
  def update_scores(self, remove=False):
    """
    Update score of affected posts
    """
    
    base = Tag.query(ndb.OR(Tag.title == 'correct', Tag.title == 'incorrect'), ancestor=self.key.parent()).get()
    
    # check if we are a base tag
    if self.title == 'correct' or self.title == 'incorrect':
      # check if another base tag exists
      if base:
        raise Exception('base tag already exists')
      # loop through all the tags in our parent and call update_scores
      q = Tag.query(Tag.title!=self.title, ancestor=self.key.parent())
      for tag in q:
        tag.update_scores()
    elif base:
      # TODO: calculate user's experience on current tag
      experience = 0.001
      sib_posts = Post.query(ancestor=self.key.parent().parent())
      # loop through all sibling posts with matching tag
      for sib_post in sib_posts.iter(keys_only=True):
        tag = Tag.query(Tag.title==self.title, ancestor=sib_post).get()
        if tag:
          # importance of tag on current post
          this_weight =Tag.weight(self.title, self.key.parent())
          # importance of tag on sibling post
          sib_weight = Tag.weight(self.title, sib_post)
          # age of sibling post's score
          sib_post = sib_post.get()
          age = float(1 + sib_post.age)
          # calculate change in score
          delta = (experience*this_weight*sib_weight)/age
          
          # check if we are being added
          if not remove:
            # increment age
            sib_post.age += 1
            # check if our base tag is positive
            if base.title == 'correct':
              # add to sibling post's score
              sib_post.score += delta
            else:
              # subtract from sibling post's score
              sib_post.score -= delta
          else:
            # decrement age
            sib_post.age -= 1
            # check if our base tag is positive
            if base.title == 'correct':
              # subtract from sibling post's score
              sib_post.score -= delta
            else:
              # add to sibling post's score
              sib_post.score += delta
              
          # store sib_post
          sib_post.put_async()
  
  def _pre_put_hook(self):
    # call update_scores when tag is created
    self.update_scores()

  def _pre_delete_hook(self):
    # call update_scores when tag is deleted
    self.update_scores(remove=True)

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user    = ndb.UserProperty(auto_current_user_add=True)
  posts   = ndb.KeyProperty(kind=Post, repeated=True)
  