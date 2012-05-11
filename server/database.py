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
import datetime

class Model:
  @ndb.ComputedProperty
  def depth(self):
    if self.key:
      return len(self.key.pairs())
    else:
      return 0

  def to_dict(self):
    result = ndb.Model.to_dict(self)
    if(self.key.parent() != None):
      result['parent'] = self.key.parent().urlsafe()
    else:
      result['parent'] = ''
    result['id'] = self.key.urlsafe()
    return result
    
  @classmethod
  def children(cls, key):
    """
    Return a query of children of this model.
    """
    return cls.query(cls.depth == len(key.pairs())+1, ancestor=key)
    
  @classmethod
  def sibling(cls, key):
    """
    Return a query for a sibling of this model.
    """
    return cls.query(cls.depth == len(key.pairs()), ancestor=key.parent())


class Post(Model, ndb.Model):
  """
  A post can be a question, it can be an answer, it can even be a statement.    
  """
  author      = ndb.UserProperty(auto_current_user_add=True)
  content     = ndb.TextProperty()
  score       = ndb.FloatProperty(default=0.0)
  timestamp   = ndb.DateTimeProperty(auto_now_add=True)

  def to_dict(self):
    result = Model.to_dict(self)
    # scrub post's score if the user hasn't voted yet
    voted = Tag.query(ndb.OR(Tag.title==Tag.base('correct'),Tag.title==Tag.base('incorrect')), Tag.user==users.get_current_user(), ancestor=self.key).count(1)
    if not voted:
      del result['score']
    return result
  
  #@ndb.ComputedProperty
  def popularity(self):
    """
    Count the number of children a post has.
    """
    return ndb.Query(ancestor=self.key).count()
  
  @classmethod
  def dereference_experience(cls, key):
    """
    Dereference a user's experience on a post.
    """
    user = Stream.query(Stream.user==users.get_current_user()).get()
    result = 0 # clear the current
    tags_d = Tag.weights(Tag.query(ancestor=key))
    # check if parent post exists
    parent = key.parent()
    if parent:
      a = tags_d
      b = Tag.weights(Tag.query(ancestor=parent))
      tags_d = dict( (n, a.get(n, 0)+b.get(n, 0)) for n in set(a)|set(b) )
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
      a = tags_d
      b = Tag.weights(Tag.query(ancestor=parent))
      tags_d = dict( (n, a.get(n, 0)+b.get(n, 0)) for n in set(a)|set(b) )
    tags = tags_d.keys()
    s = sum(tags_d.values())
    for tag in tags:
      if s > 0:
        user.adjust_experience(tag,((delta * tags_d[tag]) / s))#.wait()
        
    return self.put_async()

class TagCount(ndb.Model):
  """
  TagCount is used to keep track of tag numbers and experience. It is also
  used to keep correlational data for tags.
  """
  # keyname is (first alphabetical) tag name (',' second tag)
  count = ndb.IntegerProperty(default=0)
  xp    = ndb.FloatProperty(default=0.0)
  
  @classmethod
  def get_or_create(cls, first_tag_name, second_tag_name=None):
    """
    Fetch or create our tag count model.
    """
    keyname = first_tag_name
    if second_tag_name:
      keyname += ','.join(sorted([first_tag_name, second_tag_name]))
    return cls.get_or_insert(keyname)
  
  @classmethod
  def update_counts(cls, tag):
    """
    Update the count for the above tag along with the relevant correlational counts.
    """
    # update the tag itself
    tc = cls.get_or_create(tag.title)
    tc.count += 1
    tc.xp += tag.xp
    tc.put()
    # update the other tags in the post
    for child in Tag.children(tag.key.parent()):
      tc = cls.get_or_create(tag.title, child.title)
      tc.count += 1
      tc.xp += tag.xp
      tc.put()
    

class Tag(Model, ndb.Model):
  """
  A tag is a byte sized, repeatable, calculable piece of information about  
  something. It can be used to describe a post, or even a user or a tag.
  """
# parent      = item being tagged
  user        = ndb.UserProperty(auto_current_user_add=True)
  title       = ndb.StringProperty()
  xp          = ndb.FloatProperty(default=1.0)
  timestamp   = ndb.DateTimeProperty(auto_now_add=True)
  
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
  def get_or_create(cls, title, item_key, user=None, xp=None):
    """
    Create a tag for an item.
    """
    if xp == None:
      xp = 1
    if not user:
      user = users.get_current_user()
    result = Tag.query(cls.title == title, cls.user == user, ancestor=item_key).get()
    if not result:
      result = Tag(title=title,user=user,xp=xp,parent=item_key)
      result.put()
      if result.user != user:
        result.user = user
        result.put()
    return result
      
  @classmethod
  def base(cls, name):
    names = ['correct','incorrect']
    if not name in names:
      raise Exception('Base name not found.')
    return ',' + name
  
  @classmethod
  def weights(cls, q):
    """
    Get an associative array of tags and their weights.
    """
    result = {}
    def tag_enum(tag):
      if not tag.is_base():
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
      if not tag.is_base():
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
    return self.title[0] == ','
    
  def update_experience(self):
    """
    Update experience points of tag by dereferencing against parent post.
    """
    self.xp = Post.dereference_experience(self.key.parent())
      
  def eval_score_change(self):
    """
    Update our tagged post's score if we are a base tag.
    """
    if self.is_base(): # adjust the score for the poster
      delta = self.xp
      # figure out the sign on the score change
      if self.title == Tag.base('incorrect'):
        delta = -delta
      elif self.title != Tag.base('correct'):
        return False
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
      if self.is_base():
        TagCount.update_counts(self)

class Stream(ndb.Model):
  """
  Stores data associated with the user's stream.
  """
  user        = ndb.UserProperty(auto_current_user_add=True)
  timestamp   = ndb.DateTimeProperty(auto_now_add=True)

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

  def to_dict(self):
    result = {}
    result['id'] = self.key.urlsafe()
    result['assignments'] = self.get_assignments()
    result['tags'] = Tag.query(Tag.user == users.get_current_user())
    return result
    
  def get_assignments(self):
    """
    Returns a list of all the assignment keys.
    """
    def parent(key):
      return key.parent()
    return self.my_posts().order(Stream.timestamp).map(parent,keys_only=True)

  def my_posts(self):
    """
    Return a query for all of my posts.
    """
    return Post.query(Post.author == self.user)
  
  def get_children(self, post_key):
    """
    Returns a query for a post's children.
    """
    return Post.children(post_key)
  
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
    # update experience
    ref_tag = self.get_tag(tag_title)
    ref_tag.xp += delta
    ref_tag.put()
    
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
    p.put()
    
    return p
