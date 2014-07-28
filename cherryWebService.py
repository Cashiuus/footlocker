#!/usr/bin/env python
#
# ===================================================================
# File:				cherryWebService.py
# Dependencies:		cherrypy
# Compatibility:	2.x
#
# Creation Date:	7/27/2014
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose:			Simple web service foundation
#
# ===================================================================
## Copyright (C) 2014 Cashiuus@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ===================================================================

import cherrypy
import os
import random
import string


class JSONPage(object):
	@cherrypy.expose
	def index(self):
		# This will serve the file as the root of the site
		return file('index.html')



class GeneratorWebService(object):
	exposed = True

	@cherrypy.tools.accept(media='text/plain')
	def GET(self):
		return cherrypy.session['mystring']

	def POST(self, length=8):
		some_string = ''.join(random.sample(string.hexdigits, int(length)))
		cherrypy.session['mystring'] = some_string
		return some_string

	def PUT(self, another_string):
		cherypy.session['mystring'] = another_string

	def DELETE(self):
		cherrypy.session.pop('mystring', None)


def main():
	conf = {
		'/': {
			'tools.sessions.on': True,
			'tools.staticdir.root': os.path.abspath(os.getcwd())
		},
		'/generator': {
			'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
			'tools.response_headers.on': True,
			'tools.response_headers.headers': [('Content-Type', 'text/plain')]
		},
		'/static': {
			'tools.staticdir.on': True,
			'tools.staticdir.dir': './public'
		}
	}
	webapp = JSONPage()
	webapp.generator = GeneratorWebService()
	cherrypy.quickstart(webapp, '/', conf)


if __name__ == '__main__':
	main()