#!/bin/bash
#Part of "Miniban project", Fall 2021, DCST1001
#Main script - watch for system authorisation events relating to SSH (secure 
#shell), keep track of the number of failures per ip address, and when this is greater than or 
#equal to 3, ban the ip address (see next point)

#Filenames of helper scripts
BANFILE="miniban.db"
WHITELIST="miniban.whitelist"
#LOGFILE="/var/log/auth.log"
LOGFILE="auth.log"

INTERVAL=60 #Number of seconds between every unban test
GRACEPERIOD=$(( 60 * 10 )) #Do not count failed logins more than 10 minutes old

#Listen for failed attempts in ssh access logs
# FAILLOGS= $(journalctl -u sshd | grep "authentication failure;")
    # Example:
    # Nov 16 15:33:04 demiurgen sshd[3067909]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:15 demiurgen sshd[3067909]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:17 demiurgen sshd[3068040]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:26 demiurgen sshd[3068040]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root

#Increment and check fail counter

# - Lag ny tom dict
# - Spol gjennom loggen, hopp frem til nå minus 10 min
# - Stepp gjennom hver linje
#     sjekk ip og status
#         fail -> += 1
#         success -> =0
#     Oppdater dict[ip]
# - For hver ip i dict
#     hvis -gt 3
#         ./ban.sh ip

#Check if ip in whitelist

#Ban ip
# ./ban.sh <ip>

#Run unban.sh periodically
#watch -n $INTERVAL unbanCheck()

#   (TODO: Reset attempts counter)


function banCheck() {
    currentTime=$( date +%s )
    banTime=$(( $currentTime - $GRACEPERIOD ))
    
    #Associative array / key-value pair. Key=ip addr, value=number of occurances
    declare -A IPLOG
    while read line; do
        if [[ "$line" == *"authentication failure"* ]]; then
            #The first 15 chars have the format of "Jan 01 00:00:00", parse them to unix time
            timestring = $( echo "$line" | cut -c0-15 )
            timestamp = $( date --date "$timestring" +%s )
            if [[ $timestamp -lt $banTime ]]; then
                #This entry is older than the ban period, skip it
                continue
            fi

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

            ###TODO, run ban.sh
        fi
    done < $LOGFILE

    #Display table
    for ip in "${!IPLOG[@]}"; do echo "$ip - ${IPLOG[$ip]}"; done;
}

banCheck

### UNBAN ##

#Periodically check banned IPs in miniban.db and remove them if the ban has 
#expired (10 minutes). Remove the iptables rule for the IP address
# BANFILE="miniban.db"

# lastTimeStamp=0

function unbanCheck() {
    unbanTime=$( date +%s ) - $GRACEPERIOD
    
     #     while read line; do
    #         if [[ "$line" == "$ip"* ]]; then
    #             lineArray=(${line//,/})
    #             lastTimeStamp=${lineArray[1]}
    #         fi
    #     done < "$BANFILE"

    #     echo $lastTimeStamp


    #iptables -D INPUT -s $ip -j REJECT
    
    # echo "$ip was unbanned"

    while read line; do 
        lineArray=(${line//,/})
        ip=${lineArray[0]}
        timeStamp=${lineArray[1]}

        if [[ $timeStamp -le $unbanTime ]]; then
            unban.sh $ip
        fi
    done < "$BANFILE"

    #For each line in miniban.db
    #If timestamp <= now - limit
    #   Remove from miniban.db
    #   Remove from iptables



}
