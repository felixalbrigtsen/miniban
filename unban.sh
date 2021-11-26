#!/bin/bash

#Part of "Miniban project", Fall 2021, DCST1001
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
#Print success message to screen if iptables exits with 0 
if iptables -D INPUT -s $ip -j REJECT ; then
    #Use sed and regex to delete lines that match
    sed -i "/$ip/d" $BANFILE

    echo "$ip was unbanned."
fi