# miniban
Small ip-banning utility for DCST1001
Find the full description in [project-miniban.pdf](this pdf).

## Summary
miniban - a lightweight version of fail2ban
fail2ban is a software package written in Python and released under the GNU Public License 2.0 
that bans an IP address after repeated failed login attempts. It normally runs as a daemon process. 
The objective of this part of the project is to write a simple verison of fail2ban, called miniban, 
using the Bash scripting language.
There are three parts to miniban:
* miniban.sh Main script - watch for system authorisation events relating to SSH (secure 
shell), keep track of the number of failures per IP address, and when this is greater than or 
equal to 3, ban the IP address (see next point)
* ban.sh Ban an IP address using iptables and add the IP address together with a ban 
timestamp to a persistent flat database file miniban.db (see format below)
* unban.sh Periodically check banned IPs in miniban.db and remove them if the ban has 
expired (10 minutes). Remove the iptables rule for the IP address
Write a separate Bash script for each point above. Separating functionality into three scripts allows 
an administrator to ban or unban IP addresses manually.

