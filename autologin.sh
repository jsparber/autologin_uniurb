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
WIFINETWORK=STILABWIFI
path=$1
echo $path
username=`cat $path | grep username | cut -c 10-`
realm=`cat $path | grep realm | cut -c 7-`
password=`cat $path | grep password | cut -c 10-`
WORKDIR=/tmp/tmpload_$RANDOM
mkdir $WORKDIR
if [ $? -eq 0 ] ; then
	cd $WORKDIR
	essisteNetwork=`iwconfig 2> /dev/null | grep $WIFINETWORK`
	if [ "$essisteNetwork" == "" ] ; then
			echo "You are not conected to the right WIFI Network"
			echo "It shut be $WIFINETWORK"
		else		
			echo "You are conected to the right WIFI Network ($WIFINETWORK)"
			
			wget -q http://172.23.198.1:3990/prelogin
			checkInternet=`cat prelogin | grep logoff`
			if [ "$checkInternet" != "" ] ; then
				echo You are conneted
				echo "Do you like to logout? (Typ Enter or CTR + C per terminare)"
				read UserIput
				wget -q http://172.23.198.1:3990/logoff
			else		   
				chal=`cat prelogin | grep chal | cut -c 51-82`
				url="https://radius.uniurb.it/URB/test.php?chal="$chal"&uamip=172.23.198.1&uamport=3990&userurl=&UserName="$username"&Realm="$realm"&Password="$password"&form_id=69889&login=login"
				wget -q $url
				password=`cat test.php* | grep password | cut -c 120-151 | head -n 1`
				url="http://172.23.198.1:3990/logon?username="$username"@"$realm"&password="$password
				wget -q $url
				checkInternet=`ping -c 2 -w 10 fsf.org`
				if [ $? -eq 0 ] ; then
					echo "Login effettuato"
				else
					echo "Login non effettuato"
				fi
				rm -R $WORKDIR
			fi
	fi
else
	echo "Can't create tmp dir"
fi
exit 0
