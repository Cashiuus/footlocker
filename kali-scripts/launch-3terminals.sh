#!/bin/bash

gnome-terminal -t "Pentest" --window --hide-menubar --geometry=82x20+20+0 --working-directory=/opt

gnome-terminal --window --hide-menubar --geometry=82x20+20+400

gnome-terminal -t "Nmap" --hide-menubar --geometry=80x50+800+20 --working-directory=/usr/share/nmap/scripts
