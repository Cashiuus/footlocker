#!/usr/bin/env python
#
# ===================================================================
# File:				hashes.py
# Dependencies:		n/a
# Compatibility:	2.7+
#
# Creation Date:	10/2/2014
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose: 			Generate various hash formats for user input password
#					
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
#
# ===================================================================
from __future__ import print_function
import binascii
import hashlib
from hmac import compare_digest

MD5_ROCKYOU_TXT = '9076652d8ae75ce713e23ab09e10d9ee'
MD5_ROCKYOU_GZ = 'bac63ce5ab2ffb05f01763f8c5ec789d'
MD5_PHPBB_PWD = 'cb4f2ad633d8d8347db2adba5af66ccb'
MD5_top50000_PWD = '74e573f979650757a96e28663164b765'
MD5_JTR_PWD = '94285091d17941000add51e00542c584'
MD5_MYSPACE_PWD = '1e6c3a5e34d5e8192be6b4c40045fabc'

def do_hash(pw):
	hashes = {}
	hashes['MD-5'] = hashlib.md5(pw.encode('utf-8')).hexdigest()
	hashes['SHA-1'] = hashlib.sha1(pw.encode('utf-8')).hexdigest()
	hashes['SHA-256'] = hashlib.sha256(pw.encode('utf-8')).hexdigest()
	hashes['SHA-512'] = hashlib.sha512(pw.encode('utf-8')).hexdigest()
	
	# Calculate NTLM Hash
	hash = hashlib.new('md4', pw.encode('utf-16le')).digest()
	hashes['NTLM'] = binascii.hexlify(hash)
	
	# Calculate Lanman (LM) Hash
	lm_magic = b("KGS!@#$%")
	hash = hashlib.new('lm', pw.encode('cp437')
	hashes['LM'] = binascii.hexlify(hash).decode('ascii')
	return hashes



# Find wordlists and compare them to known MD5 sums. If they match, use them
	# compare_digest(a, b)


if __name__ == '__main__':
	clearpass = raw_input("\n\n[+] Enter password to hash: ")
	hashes = do_hash(clearpass)
	for k, v in hashes.items():
		print(" - %s Hash:\t%s" % (k, v))

