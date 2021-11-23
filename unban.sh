#Part of "Miniban project", Fall 2021, DCST1001
#Periodically check banned IPs in miniban.db and remove them if the ban has 
#expired (10 minutes). Remove the iptables rule for the IP address
BANFILE="miniban.db"
ip=$1

iptables -D INPUT -s $ip -j REJECT
echo "$ip was unbanned"



#For each line in miniban.db
#If timestamp <= now - limit
#   Remove from miniban.db
#   Remove from iptables
