#!/bin/bash

#web application firewall designed for ratelimiting traffic that is malicious using iptables and traffic inspection techniques
clear
apt update -y
apt install net-tools iptables tcpdump lolcat screen -y
clear
mkdir attacklogs
touch logs.txt

function ascii {
	echo -e "╔═╗╦ ╦╔═╗╦  ╦     ╦ ╦╔═╗╔═╗"
	echo -e "╚═╗╠═╣║╣ ║  ║ ─── ║║║╠═╣╠╣"
	echo -e "╚═╝╩ ╩╚═╝╩═╝╩═╝   ╚╩╝╩ ╩╚ "
	echo -e "ShellWAF Developed By Xor"
}

clear
ascii | lolcat
echo
echo "Welcome To ShellWAF, A Tool Designed To Block L7 Attacks."
sleep 7
clear

ascii | lolcat
echo
read -p "Enter Your Interface (most likely eth0): " interface
echo
read -p "How Long Do You Want UAM To Last Before The Script Restarts? (in seconds): " uamz
echo
read -p "How Many Connections Before UAM Starts? : " conns
echo
read -p "What Do You Want The Website To Say When UAM? : " wordz
clear

while :
	do
		clear
		echo "Monitoring Traffic.."
		netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | head > logs.txt #constantly reading the tmp file looking for the trigger amount of connections
		numoflines=$(cat -n logs.txt | tail -n 1 | cut -f1 | xargs) #the most annoying fucking debugging I have ever done finding how to make this work
		sleep 1 #limiting the time before it checks again so your server doesnt die
	if [[ "$numoflines" -gt "$conns" ]] #if the number of lines in the ips logged in the text file exceeds your gaven input it then runs the UAM
		then
			clear
			ascii | lolcat
			echo
			echo "ATTACK DETECTED, UAM ACTIVATING.."
			sleep 2
	iptables -I INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --set #ratelimit iptables
	iptables -I INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --update --seconds 250 --hitcount 3 -j DROP
	mkdir temp
	mv /var/www/html/* temp
	cd /var/www/html
	touch index.html #adding a cute little uam page thats sorta customizable
	echo '
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>ShellWAF-UAM</title>
</head>
<body>

	<style>
		p {
			text-align: center;
		}
	</style>

	<p>'$wordz'</p>

</body>
</html>
	' > index.html
	cd
	sleep 3
	tcpdump -i "$interface" -c 1000 -w /root/attacklogs/attack.pcap
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | head > /root/attacklogs/ips.txt
	clear

	ascii | lolcat
	echo
	echo "Blocking Malicious Traffic.."
	sleep "$uamz"

		#cleaning shit up..
		sleep 3

	truncate -s 0 /root/logs.txt
	rm /var/www/html/index.html
	mv /root/temp/* /var/www/html
	rmdir temp

	iptables -P INPUT ACCEPT #clearing the ratelimit rules
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -t raw -P PREROUTING ACCEPT
	iptables -t mangle -P PREROUTING ACCEPT
	iptables -F
	iptables -t nat -F
	iptables -t mangle -F
	iptables -t raw -F
	iptables -X
	iptables -t nat -X
	iptables -t mangle -X
	iptables -t raw -X
	iptables -Z
	iptables -t nat -Z
	iptables -t mangle -Z
	iptables -t raw -Z

	sleep 3

  fi
done