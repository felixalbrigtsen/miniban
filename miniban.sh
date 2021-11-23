#!/bin/bash
#Part of "Miniban project", Fall 2021, DCST1001
#Main script - watch for system authorisation events relating to SSH (secure 
#shell), keep track of the number of failures per ip address, and when this is greater than or 
#equal to 3, ban the ip address (see next point)

#Filenames of helper scripts
BANFILE="miniban.db"
WHITELIST="miniban.whitelist"
LOGFILE="/var/log/auth.log"
#LOGFILE="auth.log"

INTERVAL=60 #Number of seconds between every unban test
GRACEPERIOD=$(( 60 * 10 )) #Do not count failed logins more than 10 minutes old


#Check if ip in whitelist

#Ban ip
# ./ban.sh <ip>

#Run unban.sh periodically
#watch -n $INTERVAL unbanCheck()

function banCheck() {
    currentTime=$( date +%s )
    banTime=$(( $currentTime - $GRACEPERIOD ))
    
    #Associative array / key-value pair. Key=ip addr, value=number of occurances
    declare -A IPLOG
    #Step through the logfile from start to end
    while read line; do
    
    	#The first 15 chars have the format of "Jan 01 00:00:00", parse them to unix time
        timestring=$(echo "$line" | cut -c1-16)  
        timestamp=$( date --date "$timestring" +%s )
        if [[ $timestamp -lt $banTime ]]; then
            #This entry is older than the ban period, skip it
            continue
        fi
        
		#Successful logins, reset the counter
		if [[ "$line" == *"Accepted password"* ]] ; then
			#Line looks like: "Nov 23 15:39:04 miniban sshd[44135]: Accepted password for root from 10.24.3.54 port 53514 ssh2"
			ip=$( echo $line | sed 's/.*from//; s/port.*//' ) #Get text between "from" and "port"
			echo $ip
			#Set the ip's counter to 0. Does not fail even if the value is not already initialized
         	IPLOG[$ip]=0
		fi
    	#Authentication failure, increment the counter
        if [[ "$line" == *"authentication failure"* ]]; then
            

            #We expect RHOST to be the second to last string in the line
            linearray=($line) #Split the line on whitespace
            rhost=${linearray[-2]} #Grab the second-to-last element
            if [[ $rhost != "RHOST=*" ]] ; then
                echo "Log parsing failed"
                continue
            fi
            ip=${rhost#*=} #Grab everything after "="
            
            #Check that the ip variable is an IPv4 address
            if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                #Go to the next line in the logfile, skip this one
                continue
            fi

            #If element doesn't already exist in associative array, create it
            if [[ ! -v IPLOG[$ip] ]]; then 
                IPLOG[$ip]=0
            fi

            #First login attempt fails
            if [[ "$line" == *"pam_unix(sshd:auth): authentication failure;"* ]]; then
                ((IPLOG[$ip]++))
            fi

            #We assume that the default PAM configuration is in use, with maximum 3 attempts
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
    done < $LOGFILE

    #Display table
    for ip in "${!IPLOG[@]}"; do 
    	echo "$ip - ${IPLOG[$ip]}" 
		if [[ IPLOG[$ip] -ge 3 ]] ; then
			echo "$ip should be banned!"
			   ###TODO, run ban.sh	
		fi
    done;
}

banCheck

### UNBAN ##

#Periodically check banned IPs in miniban.db and remove them if the ban has 
#expired (10 minutes). Remove the iptables rule for the IP address

function unbanCheck() {
    unbanTime=$(( $( date +%s ) - $GRACEPERIOD ))
    
    while read line; do 
    	#Split line on the comma, ip is the first part, the rest is the timestamp
        lineArray=(${line//,/})
        ip=${lineArray[0]}
        timeStamp=${lineArray[1]}

		# If the specified IP has been banned since before unbanTime, unban it
        if [[ $timeStamp -le $unbanTime ]]; then
            unban.sh $ip
        fi
    done < "$BANFILE"
}
