#!/bin/bash
#
#
# Purpose:  Monitor for remote agents connecting so
#           we know when they are accessible.
#
#

# Watch the status log for connecting clients
# TODO: How to make notification of connected clients better?
watch -n 5 -c tail /etc/openvpn/openvpn-status.log
