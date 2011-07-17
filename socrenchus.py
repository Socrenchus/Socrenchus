#!/usr/bin/env python
#
# Copyright 2011 Bryan Goldstein
#

"""A crowd sourced system for directed learning

This tool is designed to be a one stop shop for discovering
new and interesting topics, sharing knowledge, and learning
at a cost much lower then at a university.
"""

__author__ = 'Bryan Goldstein'

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
      modes = ['view', 'edit']
      mode = self.request.get('mode')
      if not mode in modes:
        mode = 'view'

    # User must be logged in to edit
    if mode == 'edit' and not users.GetCurrentUser():
      self.redirect(users.CreateLoginURL(self.request.uri))
      return
	
	# Format the answers
    answers = [Answer.get(a).content for a in page.answers]
    #answers = reduce(lambda a,b: a+b,answers)

    # Genertate the appropriate template
    self.generate('question/'+mode + '.html', {
      'page': page,
      'answers': answers,
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
      answer = Answer(content=self.request.get('content'),parent=page)
      answer.put()
      page.answers.append(answer.key())
      
    page.put()
    self.redirect(page.view_url())


def main():
  application = webapp.WSGIApplication([
    ('/(.*)', Question),
  ], debug=_DEBUG)
  wsgiref.handlers.CGIHandler().run(application)


if __name__ == '__main__':
  main()
