#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: kali-mongodb.sh              (Update: 09-16-2015) #
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





### Replica Set Params
cfg="{
	_id: 'rs0',
	members: [
		{_id: 1, host: "localhost:27017"}
	]
}"



### apt-get Install MongoDB - http://docs.mongodb.org/master/tutorial/install-mongodb-on-debian/
#apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
#echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
#apt-get update
#apt-get install -y mongodb-org


### Standalone Install MongoDB Method - https://github.com/lair-framework/lair/wiki/Installation
curl -o mongodb.tgz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian71-3.0.6.tgz
tar -zxf mongodb.tgz
mkdir db
./mongodb-linux-x86_64-debian71-3.0.6/bin/mongod --dbpath=db --bind_ip=localhost --quiet --nounixsocket --replSet rs0 &
# Binds on port 27017
sleep 5
./mongodb-linux-x86_64-debian71-3.0.6/bin/mongo localhost:27017 --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : $cfg}))"
