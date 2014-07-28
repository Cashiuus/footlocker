#!/usr/bin/env python
#
# ===================================================================
# File:				cherryDBServer.py
# Dependencies:		cherrypy
# Compatibility:	2.x
#
# Creation Date:	7/27/2014
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose:			Simple web service foundation with database query
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
import sqlite3


DB_STRING = 'sessions.db'

class StringGenerator(object):
	@cherrypy.expose
	def index(self):
		return file('index.html')


class StringGeneratorWebService(object):
	exposed = True

	# sqlite does not support connections shared between threads That is 
	# why each method must have its own connect function

	@cherrypy.tools.accept(media='text/plain')
	def GET(self):
		with sqlite3.connect(DB_STRING) as c:
			c.execute("SELECT value FROM user_string WHERE session_id=?", 
				[cherrypy.session.id])
		return c.fetchone()

	def POST(self, length=8):
		session_string = ''.join(random.sample(string.hexdigits, int(length)))
		with sqlite3.connect(DB_STRING) as c:
			c.execute("INSERT INTO user_string VALUES (?, ?)", 
				[cherrypy.session.id, session_string])
		return session_string

	def PUT(self, another_string):
		with sqlite3.connect(DB_STRING) as c:
			c.execute("UPDATE user_string SET value=? WHERE session_id=?",
				[another_string, cherrypy.session.id])

	def DELETE(self):
		with sqlite3.connect(DB_STRING) as c:
			c.execute("DELETE FROM user_string WHERE session_id=?",
				[cherrypy.session.id])

# ------------------------------
def setup_database():
	"""
	Create the 'user_string' table in the database
	on server startup
	"""
	with sqlite3.connect(DB_STRING) as c:
		c.execute("CREATE TABLE user_string (session_id, value)")

def cleanup_database():
	"""
	Destroy the 'user_string' table from the database
	on server shutdown
	"""
	with sqlite3.connect(DB_STRING) as c:
		c.execute("DROP TABLE user_string")




# ------------------------------------
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

	# When server starts, setup the database
	cherrypy.engine.subscribe('start', setup_database)
	# When server shuts down, clean it up by removing tables
	cherrypy.engine.subscribe('stop', cleanup_database)

	webapp = StringGenerator()
	webapp.generator = StringGeneratorWebService()
	cherrypy.quickstart(webapp, '/', conf)
	return


if __name__ == '__main__':
	main()