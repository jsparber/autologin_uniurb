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
	path=$DIR/config
	username=`cat $path | grep username | cut -c 10-`
	realm=`cat $path | grep realm | cut -c 7-`
	password=`cat $path | grep password | cut -c 10-`
}

check_connection()
{
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
	echo Logon
	chal=`cat prelogin | grep chal | cut -c 51-82`
	url="https://radius.uniurb.it/URB/test.php?chal="$chal"&uamip="$GATEWAY"&uamport=3990&userurl=&UserName="$username"&Realm="$realm"&Password="$password"&form_id=69889&login=login"
	wget -q $url

	password=`cat test.php* | grep password | cut -c 120-151 | head -n 1`
	url="http://"$GATEWAY":3990/logon?username="$username"@"$realm"&password="$password
	wget -q $url
}

logoff()
{
	wget -q http://$GATEWAY:3990/logoff
}

WIFINETWORK=STILABWIFI
GATEWAY=172.23.198.1
echo $0
DIR=`echo $0 | rev | cut  --delimiter=/ -f 2- | rev`
echo $DIR/config
WORKDIR=/tmp/tmpload_$RANDOM
mkdir $WORKDIR

get_gateway
if [ "`ls $DIR/config 2> /dev/zero`" != "$DIR/config" ] ; then
	first_run
fi

load_user_data
cd $WORKDIR
wget  -q http://$GATEWAY:3990/prelogin
logon
check_connection

#logoff
#check_connection

rm -R $WORKDIR
exit 0
