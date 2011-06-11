#!/usr/bin/env python
#
# Copyright 2008 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A simple Google App Engine wiki application.

The main distinguishing feature is that editing is in a WYSIWYG editor
rather than a text editor with special syntax.  This application uses
google.appengine.api.datastore to access the datastore.  This is a
lower-level API on which google.appengine.ext.db depends.
"""

__author__ = 'Bret Taylor'

import cgi
import datetime
import os
import re
import sys
import urllib
import urlparse
import wsgiref.handlers

from google.appengine.api import datastore
from google.appengine.api import datastore_types
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template

# Set to true if we want to have our webapp print stack traces, etc
_DEBUG = True

class BaseRequestHandler(webapp.RequestHandler):
  """Supplies a common template generation function.

  When you call generate(), we augment the template variables supplied with
  the current user in the 'user' variable and the current webapp request
  in the 'request' variable.
  """
  def generate(self, template_name, template_values={}):
    values = {
      'request': self.request,
      'user': users.GetCurrentUser(),
      'login_url': users.CreateLoginURL(self.request.uri),
      'logout_url': users.CreateLogoutURL(self.request.uri),
      'application_name': 'Wiki',
    }
    values.update(template_values)
    directory = os.path.dirname(__file__)
    path = os.path.join(directory, os.path.join('templates', template_name))
    self.response.out.write(template.render(path, values, debug=_DEBUG))

class Answer(db.Model):
  """ Database model for an Answer """
  content = db.StringProperty(required=True)
  correctness = db.IntegerProperty()
    
class Question(db.Model,BaseRequestHandler):
  """ Database model for an Question """
  content = db.StringProperty()
  answers = db.ListProperty(db.Key)

  def edit_url(self):
    return '/' + str(self.key().id()) + '?mode=edit'
    
  def answer_url(self):
    return '/' + str(self.key().id()) + '?mode=answer'

  def view_url(self):
    return '/' + str(self.key().id())
    
  def get(self, page_name=None):
    
    if page_name:
      page = Question.get_by_id(int(page_name))
    else:
      page = None

    # Default to edit for pages that do not yet exist
    if not page:
      mode = 'edit'
    else:
      modes = ['view', 'edit', 'answer']
      mode = self.request.get('mode')
      if not mode in modes:
        mode = 'view'

    # User must be logged in to edit
    if (mode == 'edit' or mode == 'answer') and not users.GetCurrentUser():
      self.redirect(users.CreateLoginURL(self.request.uri))
      return

    # Genertate the appropriate template
    self.generate(mode + '.html', {
      'page': page,
    })
    
  def post(self, page_name=None):
    # User must be logged in to edit
    if not users.GetCurrentUser():
      # The GET version of this URI is just the view/edit mode, which is a
      # reasonable thing to redirect to
      self.redirect(users.CreateLoginURL(self.request.uri))
      return
      
    modes = ['edit', 'answer']
    mode = self.request.get('mode')
    # Assume edit mode if not specified
    if not mode in modes:
      mode = 'edit'

    if not page_name:
      page = Question()
    else:
      page = Question.get_by_id(int(page_name))
      if not page:
        page = Question()
      
    if mode == 'edit':
      # Create or overwrite the page
      page.content = self.request.get('content')
    elif mode == 'answer':
      # Post the answer
      page.content += self.request.get('content')
      
    page.put()
    self.redirect(page.view_url())


def main():
  application = webapp.WSGIApplication([
    ('/(.*)', Question),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)


if __name__ == '__main__':
  main()
