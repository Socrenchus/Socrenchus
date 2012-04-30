import fileinput
import os
import logging
import json
from google.appengine.api import users
from database import *
from google.appengine.ext import ndb
class BootStrap:
  @classmethod
  def switchToUser(self, id):
    os.environ['USER_EMAIL'] = 'test'+str(id)+'@example.com'
    os.environ['USER_ID'] = str(id)
    return Stream.get_or_create(users.get_current_user())
  
  @classmethod
  def loadconfiguration(self,filename): 
    keyname = filename + "0"
    key = ndb.Key(Post, keyname)
    def post_enum(key):
      return key
    queryMap = Post.query(Post.key==key).map(post_enum)
    if queryMap.count(None) == 0:
      filereader = open(filename)
      filecontents = filereader.read()
      fullcontents = json.simplejson.loads(filecontents)
      posts = fullcontents[0]
      for i in range(len(posts)):
        user = posts[i]['user']
        stream = BootStrap.switchToUser(user)
        if posts[i]['parent'] != "None":
          parentkey = ndb.Key(Post, filename + posts[i]['parent'])
          ndbpost = Post.get_or_insert(filename+str(posts[i]['id']), parent=parentkey, content=posts[i]['content'])
        else:
          ndbpost = Post.get_or_insert(filename+str(posts[i]['id']), content=posts[i]['content'])
        stream.assign_post(ndb.Key(urlsafe=ndbpost.key.urlsafe()))

      tags = fullcontents[1]
      
      for i in range(len(tags)):
        user = tags[i]['user']
        stream = BootStrap.switchToUser(user)
        
        parentkey = ndb.Key(Post, filename + tags[i]['parent'])
        Tag.get_or_create(tags[i]['title'],parentkey)

  """
  @classmethod
  def loadtags(self,filename):
    keyname = filename + "0"
    key = ndb.Key(Tag, keyname)
    def post_enum(key):
      return key
    queryMap = Post.query(Tag.key==key).map(post_enum)
    if queryMap.count(None) == 0:
      filereader = open(filename)
      filecontents = filereader.read()
      tags = json.simplejson.loads(filecontents)
      for i in range(len(tags)):
  """      
      
