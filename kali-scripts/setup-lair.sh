#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: kali-lair.sh                 (Update: 09-16-2015) #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
#
# Usage: 
#        
#-------------------------------------------------------------#

GIT_BASE=/opt/git
LAIR_BASE=/opt/git/lair/


cd $GIT_BASE
mkdir lair
cd lair

### Call separate file to install and configure mongodb
timeout 300 /usr/bin/bash install-mongodb.sh

### Install Lair v2
wget https://github.com/lair-framework/lair/releases/download/v2.0.0/lair-v2.0.0-linux-amd64.tar.gz
tar -zxf lair-v2.0.0-linux-amd64.tar.gz
cd bundle

### Install NVM to manage NodeJS versions
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.26.1/install.sh | bash
source ~/.bashrc
nvm install v0.10.40
nvm use v0.10.40

### Install NodeJS v0.10.40
cd programs/server
npm i
cd $LAIR_BASE/bundle

## Setup ENV VARS
export ROOT_URL=http://localhost
export PORT=11014
export MONGO_URL=mongodb://localhost:27017/lair
export MONGO_OPLOG_URL=mongodb://localhost:27017/local


# Start
file=save-login
node main.js tee "${file}"
cat $file | cut -d " " -f 2
cat $file | cut -d " " -f 5

cd $LAIR_BASE
wget https://github.com/lair-framework/api-server/releases/download/v1.1.0/api-server_linux_amd64
chmod +x api-server_linux_amd64

export MONGO_URL=mongodb://localhost:27017/lair
$ export API_LISTENER=localhost:11015
$ ./api-server_linux_amd64 
