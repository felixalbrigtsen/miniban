#Part of "Miniban project", Fall 2021, DCST1001
#Ban an IP address using iptables and add the IP address together with a ban 
#timestamp to a persistent flat database file miniban.db (see format below)
BANFILE="miniban.db"
ip=$1
# Check if IP is in miniban.whitelist ? Abort : Continue
iptables -A INPUT -s $IP -j REJECT;
TIMESTAMP=$(date +%s)
#echo "$IP, $TIMESTAMP" >> $BANFILE;
echo "$ip was banned at $TIMESTAMP";

# echo $ip, $TIMESTAMP >> $BANFILE
# Write line in miniban.db
# Format: <IP>,<timestamp> (unix epoch)
#Example:
    #10.0.2.15,1572887890
    #127.0.0.1,1572887940

# Make entry in iptables (INPUT)

