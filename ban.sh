#!/bin/bash
#Part of "Miniban project", Fall 2021, DCST1001
#Ban an IP address using iptables and add the IP address together with a ban 
#timestamp to a persistent flat database file miniban.db (see format below)
BANFILE="miniban.db"
WHITELIST="miniban.whitelist"
TIMESTAMP=$(date +%s)
ip=$1

#Check that the first argument is a valid and reachable IP address (IPv4 or IPv6)
if ! ip route get $ip > /dev/null 2>&1 ; then
    #Go to the next line in the logfile, skip this one
    echo "Invalid arguments."
    echo "Usage: '$0 ip'"
    exit 1
fi

#Check if $ip exists as a separate line in the whitelist file
if grep -Fxq "$ip" "$WHITELIST" ; then
    echo "IP is whitelisted"
    exit 1
fi

#Check if $ip exists as a separate line in the banfile
if grep -Fq "$ip" "$BANFILE" ; then
    echo "IP is already banned"
    exit 1
fi

iptables -A INPUT -s $ip -j REJECT;
echo "$ip,$TIMESTAMP" >> $BANFILE;
echo "$ip was banned at $TIMESTAMP";

# Write line in miniban.db
# Format: <IP>,<timestamp> (unix epoch)
#Example:
    #10.0.2.15,1572887890
    #127.0.0.1,1572887940

# Make entry in iptables (INPUT)
