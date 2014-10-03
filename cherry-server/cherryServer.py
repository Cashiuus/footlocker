#!/usr/bin/env python
#
# ===================================================================
# File:				cherryServer.py
# Dependencies:		cherrypy
# Compatibility:	2.x
#
# Creation Date:	7/27/2014
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose:			Simple server foundation
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




class MyServer(object):

	@cherrypy.expose
	def index(self):
		return "Hello, World"



	@cherrypy.expose
	def generate(self, length=8):
		# url.com/generate?length=16 will make this return 16 digits hex
		return ''.join(random.sample(string.hexdigits, int(length)))


	@cherrypy.expose
	def forms(self):
		# Upon submitting, user will be directed to "generate" with length
		return """<html><head>
			<link href="/static/css/style.css" rel="stylesheet">
			</head>
			<body>
				<form method="get" action="generate">
					<input type="text" value="8" name="length" />
					<button type="submit">Submit</button>
				</form>
			</body>
			</html>"""








def main():
	server_conf = {
		'/': {
			'tools.sessions.on': True,
			# Incidate root directory for ALL static content
			# MUST be an absolute path
			'tools.staticdir.root': os.path.abspath(os.getcwd())
		},
		# Indicate that all paths with '/static' will be static content
		'/static': {
			'tools.staticdir.on': True,
			'tools.staticdir.dir': './public'
		}
	}
	cherrypy.quickstart(MyServer(), '/', server_conf)
	return



if __name__ == '__main__':
	main()