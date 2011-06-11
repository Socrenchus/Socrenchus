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

class CreateQuestion(BaseRequestHandler):
  def get(self):

    # User must be logged in to edit
    if not users.GetCurrentUser():
      self.redirect(users.CreateLoginURL(self.request.uri))
      return

    # Genertate the appropriate template
    self.generate('create.html')
    
  def post(self):
    # User must be logged in to edit
    if not users.GetCurrentUser():
      # The GET version of this URI is just the view/edit mode, which is a
      # reasonable thing to redirect to
      self.redirect(users.CreateLoginURL(self.request.uri))
      return
      
    page = Question()
      
    # Create or overwrite the page
    page.content = self.request.get('content')
      
    page.put()
    self.redirect(page.view_url())

class QuestionPage(BaseRequestHandler):
  """Our one and only request handler.

  We first determine which page we are editing, using "MainPage" if no
  page is specified in the URI. We then determine the mode we are in (view
  or edit), choosing "view" by default.

  POST requests to this handler handle edit operations, writing the new page
  to the datastore.
  """
  def get(self, page_name):
    # Load the main page by default
    if not page_name:
      page_name = '0'
    
    page = Question.get_by_id(int(page_name))

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

  def post(self, page_name):
    # User must be logged in to edit
    if not users.GetCurrentUser():
      # The GET version of this URI is just the view/edit mode, which is a
      # reasonable thing to redirect to
      self.redirect(users.CreateLoginURL(self.request.uri))
      return

    # We need an explicit page name for editing
    if not page_name:
      self.redirect('/')
      
    modes = ['edit', 'answer']
    mode = self.request.get('mode')
    # Assume edit mode if not specified
    if not mode in modes:
      mode = 'edit'

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

class Answer(db.Model):
  """ Database model for an Answer """
  content = db.StringProperty(required=True)
  correctness = db.IntegerProperty()
    
class Question(db.Model):
  """ Database model for an Question """
  content = db.StringProperty()
  answers = db.ListProperty(db.Key)

  def edit_url(self):
    return '/' + str(self.key().id()) + '?mode=edit'
    
  def answer_url(self):
    return '/' + str(self.key().id()) + '?mode=answer'

  def view_url(self):
    return '/' + str(self.key().id())


def main():
  application = webapp.WSGIApplication([
    ('/([0-9]*)', QuestionPage),
    ('/new', CreateQuestion),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)


if __name__ == '__main__':
  main()
