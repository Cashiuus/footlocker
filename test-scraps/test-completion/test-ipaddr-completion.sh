#!/bin/bash
# ==============================================================================
# File:     
# Author:   cashiuus@gmail.com
# Created:  10/10/2015
# Revised:  
#
# Purpose:  
#
# ==============================================================================
__version__="0.1"

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight

RST="\033[00m"       # Normal
H1="\033[01;32m"        # Green for Header 1



# DEBUG: Get a list of all completion bindings currently in use
#complete -p
# Add a completion binding e.g. adding hostname to xvncviewer - complete -F _known_hosts xvncviewer
# or a file can be placed within /etc/bash_completion.d/

_isobuilds() 
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    #
    #  The basic options we'll complete.
    #
    opts="create list"


    #
    #  Complete the arguments to some of the basic commands.
    #
    case "${prev}" in
        console)
            local running=$(for x in `xm list --long | grep \(name | grep -v Domain-0 | awk '{ print $2 }' | tr -d \)`; do echo ${x} ; done )
            COMPREPLY=( $(compgen -W "${running}" -- ${cur}) )
            return 0
            ;;
        create)
            local names=$(for x in `ls -1 /etc/xen/*.cfg`; do echo ${x/\/etc\/xen\//} ; done )
            COMPREPLY=( $(compgen -W "${names}" -- ${cur}) )
            return 0
            ;;
        *)
        ;;
    esac

   COMPREPLY=($(compgen -W "${opts}" -- ${cur}))  
   return 0
}

complete -F _isobuilds isobuilds


