#!/bin/sh
#	Copyright 2013 Julian Sparber
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 3, or (at your option)
#	any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, 51 Franklin Street - Fifth Floor, Boston,
#	MA 02110-1301, USA.  */
#   
#   This script logs in automaticamente into the Unis Wifi
#   Until Now it works just with one Wifi Network (tested) stdlab
#   A shorter version of the auto login script, but untested.
#
#	Config:
#	create a config file witch includes the username= and password= and realm= one per line.

first_run()
{
        echo "Type Username"
        read username
        echo "Type Password"
        read password
        echo "Type realm"
        read realm
        
        echo "username=$username" > $DIR/config
        echo "password=$password" >> $DIR/config
        echo "realm=$realm" >> $DIR/config
}
get_gateway()
{
	GATEWAY=`ip addr show | grep "inet " | grep -v 127.0.0.1 | cut --delimiter=" " -f 6 | cut --delimiter=. -f 1-3`.1
}

load_user_data()
{
	# Verify if there is a config file, if not create that
	if [ "`ls $DIR/config 2> /dev/zero`" != "$DIR/config" ] ; then
		first_run
	fi
	path=$DIR/config
	username=`cat $path | grep username | cut -c 10-`
	realm=`cat $path | grep realm | cut -c 7-`
	password=`cat $path | grep password | cut -c 10-`
}

check_connection()
{
	echo Check connection ...
	rm prelogin
	wget  -q http://$GATEWAY:3990/prelogin
	checkInternet=`cat prelogin | grep logoff`
	if [ "$checkInternet" != "" ] ; then
		echo Internet Works
	else
		echo Internet not Works
	fi
}

logon()
{
	echo Doing login ... 
	#Download Lgoin website
	wget  -q http://$GATEWAY:3990/prelogin
	chal=`cat prelogin | grep chal | cut -c 51-82`
	url="https://radius.uniurb.it/URB/test.php?chal="$chal"&uamip="$GATEWAY"&uamport=3990&userurl=&UserName="$username"&Realm="$realm"&Password="$password"&form_id=69889&login=login"
	wget -q $url

	password=`cat test.php* | grep password | cut -c 120-151 | head -n 1`
	url="http://"$GATEWAY":3990/logon?username="$username"@"$realm"&password="$password
	wget -q $url
	echo Done
}
logon_uwic()
{
	curl --data "v=pda&username=$username&password=$password&rad=%40$realm&expire=999" https://gateway.wireless-campus.it/logincheck.php
}
logon_sad()
{
	curl --data "user=$username&auth_pass=$password&Realm=$realm&auth_user=&redirurl=%2Findex.php&accept=GO" https://sadwifi-res.uniurb.it:8001
}
logoff()
{
	echo Doing logoff ...
	wget -q http://$GATEWAY:3990/logoff
	echo Done
}
get_ap()
{
	WIFINETWORK=`iwconfig 2> /dev/zero | cut -f 2 -d '"' | head -1`
}
# Set Default Settings
WIFINETWORK=STILABWIFI
GATEWAY=172.23.198.1
# Get dir of File
DIR=`echo $0 | rev | cut  --delimiter=/ -f 2- | rev`
# Create a tmp workdir will be delied after login
WORKDIR=/tmp/tmpload_$RANDOM
mkdir $WORKDIR

get_gateway
get_ap
load_user_data
if [ "$WIFINETWORK" == "UWiC" ] ; then
	echo UWiC
	logon_uwic
else
	if [ "$WIFINETWORK" == "SAD-UNIURB" ] ; then
		echo $WIFINETWORK
		logon_sad
	else

		#Start Connecting process
		cd $WORKDIR
		logon
		check_connection
	fi
fi
#logoff
#check_connection

rm -R $WORKDIR
exit 0
