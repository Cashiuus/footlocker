#!/usr/bin/env python

# File: myip.py

# This script will get the IP Address assigned to the specified interface
# without using any external libraries
# Ref: http://stackoverflow.com/questions/24196932/how-can-i-get-the-ip-address-of-eth0-in-python

import socket
import fcntl
import struct

CONST_IFACE = 'eth0'

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

myip = get_ip_address(CONST_IFACE)  # '192.168.0.110'

print("[*] IP Address: {}".format(myip))
