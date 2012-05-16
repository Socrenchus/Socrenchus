import fileinput
import os
import logging
import json
from google.appengine.api import oauth
from database import *
from google.appengine.ext import ndb
class BootStrap:
  @classmethod
  def switchToUser(self, id):
    os.environ['OAUTH_EMAIL'] = 'test'+str(id)+'@example.com'
    os.environ['OAUTH_ID'] = str(id)
    os.environ['USER_EMAIL'] = os.environ['OAUTH_EMAIL']
    os.environ['USER_ID'] = os.environ['OAUTH_ID']
    return Stream.get_or_create(oauth.get_current_user())
  
  @classmethod
  def loadconfiguration(self,filename): 
    keyname = filename + "0"
    key = ndb.Key(Post, keyname)
    def post_enum(key):
      return key
    queryMap = Post.query(Post.key==key).map(post_enum)
    if queryMap.count(None) == 0:
      postkeymap = {}
      filereader = open(filename)
      filecontents = filereader.read()
      fullcontents = json.simplejson.loads(filecontents)
      posts = fullcontents[0]
      for i in range(len(posts)):
        user = posts[i]['user']
        fullid = filename+str(posts[i]['id'])
        stream = BootStrap.switchToUser(user)
        ndbpost = None
        if posts[i]['parent'] != "None":
          parentkey = postkeymap[filename + posts[i]['parent']]
          ndbpost = Post.get_or_insert(fullid, parent=parentkey, content=posts[i]['content'])
        else:
          logging.debug(posts[i]['content'])
          ndbpost = Post.get_or_insert(fullid, content=posts[i]['content'])
        postkeymap[fullid] = ndbpost.key

      tags = fullcontents[1]
      
      for i in range(len(tags)):
        user = tags[i]['user']
        stream = BootStrap.switchToUser(user)
        parentkey = postkeymap[filename + tags[i]['parent']]
        parentkey.get().add_tag(tags[i]['title'])

