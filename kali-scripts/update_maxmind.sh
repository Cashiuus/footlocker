#!/bin/bash
# This product includes GeoLite data created by MaxMind, available from http://www.maxmind.com
# Credit: https://github.com/mlsecproject/combine/blob/master/data/update_maxmind.sh
#

# you can set this up in the crontab to update it daily:
# 0 0 * * * [combine_folder]/data/update_maxmind.sh

# caveat: if you do set this to update in an automated fashion, please uncomment the following line:
# cd [combine_folder]/data/

cd /usr/share/GeoIP
apt-get -qq update
apt-get -y install geoip-bin geoip-database geoip-database-extra

wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz && gunzip -f GeoIP.dat.gz

wget -q http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum2.zip && unzip -qqo GeoIPASNum2.zip && rm GeoIPASNum2.zip
