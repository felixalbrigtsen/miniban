#!/bin/bash
#Part of "Miniban project", Fall 2021, DCST1001
#Main script - watch for system authorisation events relating to SSH (secure 
#shell), keep track of the number of failures per ip address, and when this is greater than or 
#equal to 3, ban the ip address (see next point)

#Filenames of helper scripts
BANFILE="miniban.db"
WHTLSTFILE="miniban.whitelist"
LOGFILE="/var/log/auth.log"
#LOGFILE="auth.log"

INTERVAL=60 #Number of seconds between every unban test
#GRACEPERIOD=$((60*60*24)) #Do not count failed logins more than 24 hours old

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
#watch -n $INTERVAL ./unban.sh

#   (TODO: Reset attempts counter)


declare -A IPLOG
while read line; do
    if [[ "$line" == *"authentication failure"* ]]; then
        #We expect RHOST to be the second to last string in the line
        linearray=($line) #Split the line on whitespace
        rhost=${linearray[-2]} #Grab the second-to-last element
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
done <$LOGFILE

for ip in "${!IPLOG[@]}"; do echo "$ip - ${IPLOG[$ip]}"; done;