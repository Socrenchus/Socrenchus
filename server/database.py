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
  
  @property
  def children(self):
    """
    Return a query of children of this post.
    """
    return Post.query(ancestor=self.key)
  
  @property
  def sibling(self):
    """
    Return a query for a sibling of this post.
    """
    return Post.query(ancestor=self.key.parent())
  
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
  
  def assign_or_die(self):
    """
    Assign the current post to the current user or die if already assigned.
    """
    me = users.get_current_user()
    assigned = Tag.query(Tag.title==',assigned', Tag.user==me, ancestor=self.key).count(1)
    if assigned:
      return False
    else:
      Tag(parent=self, user=me, title=',assigned').put()
      return True
  
  def assign_children(self, num):
    """
    Assigns num children to the current user if num children exist.
    """
    # TODO: Improve selection of child posts
    me = users.get_current_user()
    user = Stream.query(Stream.user==me).get()
    for child in self.children:
      if child.assign_or_die():
        num -= 1
      if num <= 0:
        return True
    return False
    
  def verify_assignment_count(self):
    """
    Checks if new assignments are due, assigns them if they are.
    """
    me = users.get_current_user()
    my_reply = self.sibling().filter(Post.author==me).get()
    if my_reply:
      # count the current replies visible to the user
      current = Tag.query(Tag.title==',assigned', Tag.user==me, ancestor=self.key).count()
      # get our experience in the context of our reply
      old_xp = Tag.query(Tag.title==',assigned', Tag.user==me, ancestor=my_reply.key).get().xp
      new_xp = my_reply.dereference_experience()
      # run our experience points through the magic step function
      expected = Post.step_reveal(new_xp-old_xp)
      # assign the newly earned posts
      if expected > current:
        self.assign_children(expected-current)
        
  @classmethod
  def step_reveal(cls, delta_xp):
    """
    Converts change in experience to expected reponse assignments.
    """
    # TODO: Improve step function
    # show 5 posts for every 25 xp
    return (delta_xp/25)*5

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
    self._global_xp = 0.0
    self._global_xp_norm = 1.0
    self._local_xp = 0.0
    self._local_xp_norm = 1.0
    self._local_user_count = 1.0
    def tally_up(tag):
      self._global_xp_norm += tag.xp
      if tag.key.parent() == self.key.parent():
        self._local_xp_norm += tag.xp
        if tag.user == self.user:
          self._local_user_count += 1
      if tag.title == self.title:
        self._global_xp += tag.xp
        if tag.key.parent() == self.key.parent():
          self._local_xp += tag.xp
    Tag.query().map(tally_up)
    return (self._local_xp*self._global_xp_norm) / (self._local_xp_norm*self._global_xp+self._local_user_count)
      
      
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
      user.adjust_experience(self.title, self.weight)
      def reward_tagger(tag):
        user = Stream.query(Stream.user==tag.user).get()
        user.adjust_experience(tag.title, (tag.weight/tag._local_xp)*self.xp)
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
  
  @classmethod
  def get_or_create(cls, user):
    """
    Creates a new stream or finds the user's stream.
    """
    u = Stream.query(Stream.user==user).get()
    if not u:
      u = Stream(user=user)
      u.put()
    return u
  
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
    
  def create_post(self, content, parent=None):
    """
    Creates a post from given content with optional parent.
    """
    p = Post(parent=parent,content=content)
    Tag(title=',assignment', user=self.user, parent=p.put()).put()
    return p