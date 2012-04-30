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
      posts = json.simplejson.loads(filecontents)
      for i in range(len(posts)):
        user = posts[i]['user']
        stream = BootStrap.switchToUser(user)
        ndbpost = Post.get_or_insert(filename+str(i), content=posts[i]['content'])
        stream.assign_post(ndb.Key(urlsafe=ndbpost.key.urlsafe()))
