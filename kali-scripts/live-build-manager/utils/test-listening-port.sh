#!/bin/bash




echo -e "Test if apt-cache is running by looking for its listener in netstat"
netstat -antpl | grep -q "3142" && echo -e "RUNNING" && echo -e "2nd command"



