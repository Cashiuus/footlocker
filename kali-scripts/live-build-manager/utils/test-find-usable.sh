#!/bin/bash
# ==============================================================================
# File:     
#
# Author:   Cashiuus
# Created:  01//2016
# Revised:  
#
# Purpose:  
#
# ==============================================================================
__version__="0.1"
__author__='Cashiuus'


## ==================[ Text Colors ]===================== ##
GREEN="\033[01;32m"    # Success
BLUE="\033[01;34m"     # Heading
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


# =================================[      ]====================================
# TODO: Proper way to get primary network adapter
#NIC=$(ip addr |grep "eth")
NIC="eth0"

# =========================[ Passive Recon To Locate Subnet ]==========================
# In an unknown network, we start off without any information. We must sniff it out.
# 1. Try to locate multicast traffic
cd /tmp
tcpdump 'ip[16] >= 224' -l | tee sniff-multicast.cap
#   Example Result: 22:40:11.374799 IP 192.168.210.1.50246 > 224.0.0.252.hostmon: UDP, length 22
GW1=$(cat sniff-multicast.cap |grep -o "regexhere" |sort -u)



# If that doesn't work, broaden the capture parameters
cd /tmp
tcpdump -e -i "${NIC}" -c 20 -v -n -q -l | tee sniff-all.cap
GW1=$(cat sniff-all.cap |grep -o "regexhere")

# 224.0.0.252.5355



# ===============================[      ]=============================
# List of unique interfaces
#TODO: Exclude "Kernel" and "Iface" from the result
IFACES_LIST=$(netstat --interfaces | cut -d " " -f1)
IFACES_COUNT=$(netstat --interfaces | cut -d " " -f1 |wc -l)

# Gateway
DEFAULT_GW=$(ip -4 -oneline route |grep "default" |cut -d " " -f3)

# Get the subnet we are in
SUBNET=$(ip -4 -oneline route |grep "eth." |grep -v "default" |cut -d " " -f1)

# Get the primary IP Address
# TODO: Better extraction of the IP
PRIMARY_IP=$(ip -4 -oneline route |grep "eth." |grep -v "default" | cut -d " " -f12)


echo -e " No. of Interfaces:\t${IFACES_COUNT}"
echo -e " Default Gateway:\t${DEFAULT_GW}"
echo -e " Current Subnet\t\t${SUBNET}"
echo -e " Current IP:\t\t${PRIMARY_IP}"






# ================[ Expression Cheat Sheet ]==================================
#
#   -d      file exists and is a directory
#   -e      file exists
#   -f      file exists and is a regular file
#   -h      file exists and is a symbolic link
#   -s      file exists and size greater than zero
#   -r      file exists and has read permission
#   -w      file exists and write permission granted
#   -x      file exists and execute permission granted
#   -z      file is size zero (empty)



#   [[ $? -eq 0 ]]    Previous command was successful
#   [[ ! $? -eq 0 ]]    Previous command NOT successful
#

