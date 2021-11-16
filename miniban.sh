#Part of "Miniban project", Fall 2021, DCST1001
#Main script - watch for system authorisation events relating to SSH (secure 
#shell), keep track of the number of failures per IP address, and when this is greater than or 
#equal to 3, ban the IP address (see next point)

#Filenames of helper scripts
BANFILE="miniban.db"
WHTLSTFILE="miniban.whitelist"


INTERVAL=60 #Number of seconds between every unban test
GRACEPERIOD=$((60*60*24)) #Do not count failed logins more than 24 hours old

#Listen for failed attempts in ssh access logs
# FAILLOGS= $(journalctl -u sshd | grep "authentication failure;")
    # Example:
    # Nov 16 15:33:04 demiurgen sshd[3067909]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:15 demiurgen sshd[3067909]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:17 demiurgen sshd[3068040]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root
    # Nov 16 15:33:26 demiurgen sshd[3068040]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=222.187.254.41  user=root

#Increment and check fail counter

# - Lag ny tom dict
# - Spol gjennom loggen, hopp frem til nå minus ett døgn
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
