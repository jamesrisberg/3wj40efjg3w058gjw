#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
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
#
import webapp2
from google.appengine.ext import ndb
from uuid import uuid4
from os import urandom
from base64 import b64encode
import json
import urllib2

class Gif(ndb.Model):
    file_url = ndb.StringProperty()

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

class GifHandler(webapp2.RequestHandler):
    def get(self, name):
        g = ndb.Key('Gif', name).get()
        status = 503
        url = 'https://files.parsetfss.com/bf1ec351-355e-43bb-8dd8-984faf14ae43/tfss-91728182-0032-497c-8453-e3b29aebb300-Content.gif'
        if g:
            status = 200
            url = g.file_url
        self.response.content_type = 'image/gif'
        data = urllib2.urlopen(url).read()
        self.response.write(data)

class RegisterGifHandler(webapp2.RequestHandler):
    def post(self):
        name = self.request.get('name')
        file_url = self.request.get('fileUrl')
        existing = ndb.Key('Gif', name).get()
        if existing == None:
            g = Gif(id=name, file_url=file_url)
            g.put()
            self.response.write(json.dumps({"success": True}))

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/register', RegisterGifHandler),
    ('/(.+)', GifHandler)
], debug=True)
