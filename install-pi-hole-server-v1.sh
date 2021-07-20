#!/bin/bash
set -e
##################################################################################################################
# Author 	: 	Marco Obaid
# GitHub    :   https://github.com/marcoobaid
##################################################################################################################
#
#   This is default and well-known Pi-Hole server that most users are looking for. 
#   It is designed to be used as a DNS server for other devices on the LAN.
#
##################################################################################################################

# https://docs.pi-hole.net/main/prerequisites/
# set firewall rules for pihole
sudo iptables -I INPUT 1 -s 192.168.0.0/16 -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 1 -s 127.0.0.0/8 -p tcp -m tcp --dport 53 -j ACCEPT
sudo iptables -I INPUT 1 -s 127.0.0.0/8 -p udp -m udp --dport 53 -j ACCEPT
sudo iptables -I INPUT 1 -s 192.168.0.0/16 -p tcp -m tcp --dport 53 -j ACCEPT
sudo iptables -I INPUT 1 -s 192.168.0.0/16 -p udp -m udp --dport 53 -j ACCEPT
sudo iptables -I INPUT 1 -p udp --dport 67:68 --sport 67:68 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp -m tcp --dport 4711 -i lo -j ACCEPT
sudo iptables -I INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# ip6
sudo ip6tables -I INPUT -p udp -m udp --sport 546:547 --dport 546:547 -j ACCEPT
sudo ip6tables -I INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT



#remove conflicting dnsmasq
if pacman -Qi dnsmasq &> /dev/null; then
		sudo pacman -R dnsmasq --noconfirm 
fi

package="pi-hole-server"

#----------------------------------------------------------------------------------

#checking if application is already installed or else install with aur helpers
if pacman -Qi $package &> /dev/null; then

		echo "################################################################"
		echo "################## "$package" is already installed"
		echo "################################################################"

else

	#checking which helper is installed
	if pacman -Qi yay &> /dev/null; then

		echo "################################################################"
		echo "######### Installing with yay"
		echo "################################################################"
		yay -S --noconfirm $package

	elif pacman -Qi trizen &> /dev/null; then

		echo "################################################################"
		echo "######### Installing with trizen"
		echo "################################################################"
		trizen -S --noconfirm --needed --noedit $package

	elif pacman -Qi yaourt &> /dev/null; then

		echo "################################################################"
		echo "######### Installing with yaourt"
		echo "################################################################"
		yaourt -S --noconfirm $package

	elif pacman -Qi pacaur &> /dev/null; then

		echo "################################################################"
		echo "######### Installing with pacaur"
		echo "################################################################"
		pacaur -S --noconfirm --noedit  $package

	elif pacman -Qi packer &> /dev/null; then

		echo "################################################################"
		echo "######### Installing with packer"
		echo "################################################################"
		packer -S --noconfirm --noedit  $package

	fi

	# Just checking if installation was successful
	if pacman -Qi $package &> /dev/null; then

		echo "################################################################"
		echo "#########  "$package" has been installed"
		echo "################################################################"

	else

		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!  "$package" has NOT been installed"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

	fi

fi


### Setup Web Interface for Pi-Hole ###

echo "###########################################"
echo "## Setting up Web Interface for Pi-Hole ###"
echo "###########################################"

sudo pacman -S php-sqlite --noconfirm --needed
sudo pacman -S lighttpd --noconfirm --needed
sudo pacman -S php-cgi --noconfirm --needed

### Copy config file provided by Pi-Hole
sudo cp /usr/share/pihole/configs/lighttpd.example.conf /etc/lighttpd/lighttpd.conf

### Enable lighttpd.service ###
sudo systemctl enable lighttpd.service
sudo systemctl restart lighttpd.service

### Password-protect Web Interface ###
echo "Please enter a password to assword-protect pi-hole Web Interfce:"
sudo pihole -a -p

### Set-up PHP
echo "Extensions pdo_sqlite, sockets, and sqlite3 will be enabled in /etc/php/php.ini"
echo "extension=pdo_sqlite" | sudo tee -a /etc/php/php.ini 
echo "extension=sockets" | sudo tee -a /etc/php/php.ini 
echo "extension=sqlite3" | sudo tee -a /etc/php/php.ini 
echo "Extensions pdo_sqlite, sockets, and sqlite3 have be enabled in /etc/php/php.ini"
echo "Review /etc/php/php.ini"
echo "Restarting lighttpd service now ..."
sudo systemctl restart lighttpd.service


# as explained in the archwiki page  pihole-FTL.service is likely going to fail.
# here are some troubleshooting tweaks prescribed in the wiki to fix it
echo "disabling the stub listener  /etc/systemd/resolved.conf"
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf 
 
#Tell dnsmasq to bind to each interface explicitly, instead of the wildcard 0.0.0.0:53, by uncommenting the line bind-interfaces in /etc/dnsmasq.conf 
#This will avoid conflicting with systemd-resolved which listens on 127.0.0.53:53.
echo "bind-interfaces" | sudo tee -a /etc/dnsmasq.conf

# restart systemd-resolved.service and pihole-FTL.service.
systemctl  restart systemd-resolved.service 
systemctl enable pihole-FTL.service
systemctl start pihole-FTL.service


echo "################################################################"
echo "#########  Pi-Hole has been Configured                   #######"
echo "#########  Open your borwser and go to http://localhost/ #######"
echo "################################################################"

