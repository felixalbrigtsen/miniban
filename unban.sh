#!/bin/bash

#Part of "Miniban project", Fall 2021, DCST1001
BANFILE="miniban.db"

ip=$1
#Check that the first argument is a valid and reachable IP address (IPv4 or IPv6)
if ! ip route get $ip > /dev/null 2>&1 ; then
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