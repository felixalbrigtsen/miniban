#Part of "Miniban project", Fall 2021, DCST1001
#Ban an IP address using iptables and add the IP address together with a ban 
#timestamp to a persistent flat database file miniban.db (see format below)
BANFILE="miniban.db"

# Write line in miniban.db
# Format: ip,timestamp (unix epoch)
#Example:
    #10.0.2.15,1572887890
    #127.0.0.1,1572887940

# Make entry in iptables (INPUT )

