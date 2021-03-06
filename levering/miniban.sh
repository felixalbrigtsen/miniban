#!/bin/bash

#Part of "Miniban project", Fall 2021, DCST1001
#Main script - watch for system authorisation events relating to SSH (secure 
#shell), keep track of the number of failures per ip address, and when this is greater than or 
#equal to 3, ban the ip address

#Filenames of helper files. BANFILE and WHITELIST could be moved to a shared config file.
BANFILE="miniban.db"
WHITELIST="miniban.whitelist"
LOCKFILE="miniban.db.lck"

INTERVAL=60 #Number of seconds between every unban test
GRACEPERIOD=$(( 60 * 10 )) #Do not count failed logins more than 10 minutes old

echo "Miniban is running"


### INITIALIZE CONFIGS ###

if [ ! -f $BANFILE ] ; then
    touch $BANFILE
fi
if [ ! -f $WHITELIST ] ; then
    echo "127.0.0.1" > $WHITELIST
fi

### UNBAN ###

#Periodically check banned IPs in miniban.db and remove them if the ban has 
#expired (10 minutes). Remove the iptables rule for the IP address

function unbanCheck() {
    unbanTime=$(( $( date +%s ) - $GRACEPERIOD ))
    
    #Read comma-separated values from the banfile
    while IFS=, read ip timeStamp ; do
    
		# If the specified IP has been banned since before unbanTime, unban it
        if [[ $timeStamp -le $unbanTime ]]; then
            flock $BANFILE ./unban.sh $ip
        fi
    done < "$BANFILE"
}


# Run unbanCheck every $INTERVAL seconds in a background loop
(
    while true ; do
        unbanCheck
        sleep $INTERVAL
    done
) &


### BAN ###

#Associative array.  Key=ip addr, value=number of occurances
declare -A IPLOG

function banCheck() {
    currentTime=$( date +%s )
    banTime=$(( $currentTime - $GRACEPERIOD ))
    
    #Step through the logfile from start to end. Alternatively, we could use journalctl
    line="$1"
    
    #The first 15 chars have the format of "Jan 01 00:00:00", parse them to unix time
    timestring=$( echo "$line" | cut -c1-16 )  
    timestamp=$( date --date "$timestring" +%s )
    if [[ $timestamp -lt $banTime ]]; then
        #This entry is older than the ban period, skip it
        return
    fi
    
    #Successful logins, reset the counter
    if [[ "$line" == *"Accepted password"* ]] ; then
        #Line looks like: "Nov 23 15:39:04 miniban sshd[44135]: Accepted password for root from 10.24.3.54 port 53514 ssh2"
        ip=$( echo $line | sed 's/.*from //; s/port.*//' ) #Get text between "from " and "port"
        #Set the ip's counter to 0. Does not fail even if the value is not already initialized
        IPLOG[$ip]=0
    fi
    #Authentication failure, increment the counter
    if [[ "$line" == *"authentication failure"* ]]; then
        

        #Use awk to look at each "column" of the line. Return the line if it starts with "rhost="
        rhost=$( echo $line | awk '{for(j=1;j<=NF;j++){if($j~/^rhost=/){print $j}}}' )
        if [[ $rhost != "rhost="* ]] ; then
            echo "Log parsing failed"
            return
        fi
        ip=${rhost#*=} #Grab everything after "="

        #Check that the ip is a valid ipv4 address
        if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
            #Invalid ip address, skip it
            return
        fi

        #First login attempt fails
        if [[ "$line" == *"pam_unix(sshd:auth): authentication failure;"* ]]; then
            ((IPLOG[$ip]++))
        fi

        #We assume that the default debian PAM configuration is in use, with maximum 3 attempts
        #and log lines matching the following two cases:

        #One additional attempt
        if [[ "$line" == *"PAM 1 more authentication"* ]]; then
            ((IPLOG[$ip]++))
        fi
        #Two additional attempt
        if [[ "$line" == *"PAM 2 more authentication"* ]]; then
            ((IPLOG[$ip] += 2))
        fi

    fi

    #Display all logged addresses
    for ip in "${!IPLOG[@]}"; do 
    	echo "$ip - ${IPLOG[$ip]}" 
		if [[ IPLOG[$ip] -ge 3 ]] ; then
            #Lock file to avoid write conflicts
			flock $BANFILE ./ban.sh $ip
		fi
    done;
}



prevLog=$( journalctl -u ssh -n 1 | grep -e "authentication failure" -e "Accepted password" )
# Continously poll the very last line of the ssh log, bancheck if it relates to password authentication
while : ; do
    newLog=$( journalctl -u ssh -n 1 | grep -e "authentication failure" -e "Accepted password" )
    # Only do something if the line changed since last time
    if [[ "$prevLog" != "$newLog" ]] ; then
        banCheck "$newLog"
    fi
    prevLog=$newLog
    sleep 0.01
done


# When this script receives one of the specified exit signals, kill all child processes (Including background processes)
trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT
