#!/usr/bin/env python
#
# Description: Provide an input file called "scope.txt" for this to parse.
# 				Script will skip lines starting with '#'
#				For every line, it will attempt to split '/' and compare
#				the trailing subnet mask to the dictionary list of host counts.
#				Once complete, total count of all hosts is output.

import os
import re

INPUT_FILE = 'scope.txt'

SUBNET_REFERENCE = {
	'16': 65536,
	'17': 32768,
	'18': 16384,
	'19': 8192,
	'20': 4096,
	'21': 2048,
	'22': 1024,
	'23': 512,
	'24': 255,
	'25': 128,
	'26': 64,
	'27': 32,
	'28': 16,
	'29': 8,
	'30': 4,
	'31': 2,
	'32': 1,
	}



if __name__ == '__main__':
	# Load file and read
	a = 0
	with open(INPUT_FILE, 'r') as f:
		for line in f:
			if line.startswith('#'):
				continue
			try:
				s = line.strip().split('/')[1]
			except:
				# If a line doesn't have '#' or '/' it could error, this will skip those lines.
				continue
			if s in SUBNET_REFERENCE:
				a += SUBNET_REFERENCE[s]
				print(" Subnet: {} - Hosts: {}".format(line, str(SUBNET_REFERENCE[s])))
	#if a > 0:
		
	print("[*] Scope Counting Complete. Total Hosts: {}".format(str(a)))
