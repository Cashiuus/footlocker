#!/usr/bin/env python
#
# ===================================================================
# File:				portCounter.py
# Dependencies:		n/a
# Compatibility:	2.x
#
# Creation Date:	7/21/2014
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose: 			Receive project and list of ports, and keep a 
#					running count of open ports Unique folder and 
#					file for each project.
#
# ===================================================================
from __future__ import print_function
import os
from collections import Counter

DEFAULT_FILENAME = 'port_count.txt'
BASE_PATH = os.path.dirname(os.path.realpath(__file__))
NMAP_SERVICES_FILE = ' '



def count_ports(portlist=[], project='Default'):
	"""
	Call with project and a port list to create or increment a port_count file
	"""
	# The path for the file becomes current folder + project name + filename
	# TODO: Do I need to check validity of project argument?
	DEFAULT_PATH = os.path.join(BASE_PATH, project)

	# Based on the project, either create a new shell or open that project's file
	if not os.path.exists(DEFAULT_PATH):
		os.mkdir(DEFAULT_PATH)

	# Create or open the port_count.txt file
	# TODO: Switch this logic around so that the writing is done after the reading
	PORT_FILE = os.path.join(DEFAULT_PATH, DEFAULT_FILENAME)
	if not os.path.exists(PORT_FILE):
		# If the file doesn't exist, it's brand new so we can just populate it
		f = open(PORT_FILE, 'w')
		f.write('[' + project + ']\n')
		for port in portlist:
			p = str(port) + ',1\n'
			f.write(p)
	else:
		f = open(PORT_FILE, 'r')
		# But if it is pre-existing, we need to search for the port and increment the count
		# Below could probably become a list comprehension or lambda iteration
		portmap = {}
		for line in f.readlines():
			# If the line starts with bracket, it's a header
			if line.startswith('['):
				continue
			# Read the lines into a dictionary
			tmp = line.split(',')
			# Now that we've split the line by comma, port is key and count is value
			# Need to strip off the newline for the value
			portmap[tmp[0]] = int(tmp[1].rstrip())

		# Done reading file, now use it to compare to incoming list
		f.close()

		#print(portlist)
		#print(portmap)
		#exit()

		f = open(PORT_FILE, 'w')
		f.write('[' + project + ']\n')

		for port in portlist:
			port = str(port)
			# If the port exists
			if port in portmap.keys():
				# -- Port Matches an Entry
				# Update the dicionary by increasing the value by 1
				#v = int(v) + 1
				portmap[port] += 1
				#portmap.update(k=v)
			else:
				# -- Port No Match
				# This is a new port entry, so add it to the dict with value of 1
				portmap[port] = '1'


		# Done with Iteration
		# Write dictionary to file as comma-separated
		# We must do this separately to ensure entire dictionary has been incremented
		sortedportsbycount = sorted(portmap, key=portmap.get, reverse=True)
		for port in sortedportsbycount:
			# port is the port number, portmap[port] looks up the value in orig dict
			tmp = str(port) + ',' + str(portmap[port]) + '\n'
			f.write(tmp)

	f.close()
	return




def read_ports(project='Default'):
	"""
	Return 2-tuple of (port, count) for all lines in the project's port_count file
	"""
	pass
	return



# TESTING OUT ANOTHER WAY OF DOING COUNTING
# https://docs.python.org/3/library/collections.html#collections.Counter
# collections.Counter automatically returns 0 if key doesn't exist
# instead of returning an error.
# It uses a dictionary, but is not sorted
def new_counter():
	# Not in use as of yet
	c = Counter()

	return




# TESTING
def sample():
	portlist = [22, 80, 110, 443, 8080, 9443]
	# Excluding project name so these go into 'Default'
	count_ports(portlist)
	return


if __name__ == '__main__':
	sample()