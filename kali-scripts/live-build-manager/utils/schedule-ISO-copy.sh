#!/bin/bash
# ==============================================================================
# File:     schedule-ISO-copy.sh
# Author:   cashiuus@gmail.com
# Created:  10/10/2015
# Revised:  10/10/2015
#
# Purpose:  Setup a schedule to copy all updated ISO's to the public server
#
# ==============================================================================
__version__="0.1"

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

# Create a crontab pointing to this file on first run



# Locate all ISO's within the builds folder


# cp them if they are newer than those already in that folder
[[ ! -d /var/www/html/iso ]] && mkdir -p /var/www/html/iso
cp -u ${ISO_SOURCE} /var/www/html/iso
