#!/bin/bash

#Part of "Miniban project", Fall 2021, DCST1001
#Removes th

BANFILE="miniban.db"

ip=$1
#Check that the ip is a valid ipv4 address
if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
    #Go to the next line in the logfile, skip this one
    echo "Invalid arguments."
    echo "Usage: '$0 ip'"
    exit 1
fi

#Errors from iptables is automatically thrown to stdout when run manually
#If the ban entry is successfully removed from iptables 
if iptables -D INPUT -s $ip -j REJECT ; then
    #Use sed to delete regex-matched lines in the database file
    sed -i "/$ip/d" $BANFILE

    echo "$ip was unbanned."
fi