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

  @classmethod
  def children(cls, key):
    """
    Return a query of children of this post.
    """
    return Post.query(cls.depth == len(key.pairs())+1, ancestor=key)
  
  @classmethod
  def sibling(cls, key):
    """
    Return a query for a sibling of this post.
    """
    return Post.query(cls.depth == len(key.pairs()), ancestor=key.parent())
  
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
  
  @classmethod
  def assign_or_die(cls, key, user=None):
    """
    Assign the current post to the current user or die if already assigned.
    """
    if not user:
      user = users.get_current_user()
    assigned = Tag.query(Tag.title==Tag.base('assignment'), Tag.user==user, ancestor=key).count(1)
    if assigned:
      return False
    else:
      t = Tag(parent=key, user=user, title=Tag.base('assignment'))
      t.put()
      return True
  
  @classmethod
  def assign_children(cls, key, user, num):
    """
    Assigns num children to the current user if num children exist.
    """
    # TODO: Improve selection of child posts
    for child in Post.children(key).order(-Post.score).iter(keys_only=True):
      if Post.assign_or_die(child, user):
        num -= 1
      if num <= 0:
        return True
    return False
  
  def get_progress(self, user):
    """
    Checks if new assignments are due, assigns them if they are.
    """
    key = self.key
    try:
      my_reply = Post.children(key).filter(Post.author==user).iter(keys_only=True).next()
      if my_reply:
        # current post depth
        depth = len(key.pairs())
        # count the current replies visible to the user
        current = Tag.query(Tag.title==Tag.base('assignment'), Tag.user==user,  Tag.depth==depth+2, ancestor=key).count()
        # return if all the replies are visible
        more = Post.query(Post.depth==depth+1, ancestor=key).count(current+1)
        if more == current:
          return 1
        # get our experience in the context of our reply
        old_xp = Tag.query(Tag.title==Tag.base('assignment'), Tag.user==user,  Tag.depth==depth+2, ancestor=my_reply).get()
        new_xp = Post.dereference_experience(my_reply)
        if old_xp.xp == 1:
          if new_xp == 1:
            old_xp.xp = 0.9
          else:
            old_xp.xp = new_xp
          old_xp.put()
        old_xp = old_xp.xp
        # run our experience points through the magic step function
        summary = Post.step_reveal(new_xp-old_xp)
        expected = summary[0]
        # assign the newly earned posts
        if expected > current:
          Post.assign_children(key, user, expected-current)
        return summary[1]
    except StopIteration:
      return 0
    except:
      raise

  @classmethod
  def step_reveal(cls, delta_xp):
    """
    Converts change in experience to expected reponse assignments.
    """
    # TODO: Improve step function
    # show 5 posts for every 25 xp
    point_step = 15
    post_step = 3
    return (((int(delta_xp)/point_step)+1)*post_step, float(delta_xp%point_step)/float(point_step))

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
  def get_or_create(cls, title, item_key, user=None):
    """
    Create a tag for an item.
    """
    if not user:
      user = users.get_current_user()
    result = Tag.query(cls.title == title, cls.user == user, ancestor=item_key).get()
    if not result:
      result = Tag(title=title,user=user,parent=item_key)
      result.put()
      if result.user != user:
        result.user = user
        result.put()
    return result
      
  @classmethod
  def base(cls, name):
    names = ['correct','incorrect','assignment']
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
    Gets current assignments, adds new ones, returns all.
    """
    def post_check(key):
      p = key.parent().get()
      p.progress = p.get_progress(self.user)
      return p
    qtime = datetime.datetime.now()
    a = self.assignments().order(Stream.timestamp).map(post_check,keys_only=True)
    def post_list(key):
      return key.parent().get()
    a += self.assignments().filter(Stream.timestamp > qtime).order(Stream.timestamp).map(post_list,keys_only=True)
    return a

  def assignments(self):
    """
    Returns a list of post keys assigned to the user.
    """
    return Tag.query(Tag.title == Tag.base('assignment'), Tag.user == self.user)
  
  def assigned_children(self, post_key):
    """
    Returns a list of post keys assigned to the user under the given post key.
    """
    return Tag.query(Tag.title == Tag.base('assignment'), Tag.user == self.user, ancestor=post_key)
  
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
  
  def assign_post(self, key):
    """
    Assigns a post to a user.
    """
    Tag.get_or_create(Tag.base('assignment'),key,self.user)
    return key
  
  def create_post(self, content, parent=None):
    """
    Creates a post from given content with optional parent.
    """
    p = Post(parent=parent,content=content)
    p.put()
    self.assign_post(p.key)
    if parent:
      parent = parent.get()
      Tag.get_or_create(Tag.base('assignment'),p.key,parent.author)
    
    return p
