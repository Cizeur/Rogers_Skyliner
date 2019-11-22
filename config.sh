#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR

########################
#                      #
#     VARIABLES        #
#                      #
########################

refresh () {
	USER_BASIC=$(eval getent passwd \
		{$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} \
		| cut -d: -f1| head -n 1)
	SSH_PORT=4242
	STATIC_IP="10.13.254.77/30"
	GATEWAY="$(echo $STATIC_IP | cut -f1,2,3 -d'.').254"
	INTERFACE="$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')"
	SSH_KEY_LOC="./YOUR_SSH_PUBLIC_KEY"
}

make_templates() {
	#clean up
	rm -rf REPLACEMENTS
	mkdir -p REPLACEMENTS
	#Interface Template
	sed -e "s#<INTERFACE>#$INTERFACE#g" ./templates/interfaces.TEMP > ./REPLACEMENTS/interfaces
	sed -i "s#<STATIC_IP>#$STATIC_IP#g" ./REPLACEMENTS/interfaces
	sed -i "s#<GATEWAY>#$GATEWAY#g" ./REPLACEMENTS/interfaces
	#SSH Template
	sed -e "s#<SSH_PORT>#$SSH_PORT#g" ./templates/sshd_config.TEMP > ./REPLACEMENTS/sshd_config
}

refresh
make_templates


#######################
#    INSTALL SUDO     #
#######################

install_sudo(){
	echo "Primary login"
	echo $USER_BASIC
	apt-get install sudo
	usermod -aG sudo $USER_BASIC
}

#######################
#    STATIC IP        #
#######################


reset_interface () {
	mv /etc/network/interfaces /etc/network/interfaces.old
	cp ./REPLACEMENTS/interfaces /etc/network/interfaces
	ifdown $INTERFACE && ifup $INTERFACE
}

#######################
#      SSHD SETUP     #
#######################

reset_sshd () {
	mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old
	cp ./REPLACEMENTS/sshd_config /etc/ssh/sshd_config
	systemctl restart sshd
}
reset_ssh_keys(){
	USER_SSH_DIR=/home/$USER_BASIC/.ssh
	rm -rf $USER_SSH_DIR
	mkdir -p $USER_SSH_DIR
	chmod 700 $USER_SSH_DIR
	chown -R $USER_BASIC $USER_SSH_DIR	
	for keys in $SSH_KEY_LOC/*
		do
			echo "ssh key :" $keys "added to user" $USER_BASIC
			cat $keys >>  $USER_SSH_DIR/authorized_keys
		done
}

#######################
#      FIREWALL       #
#######################

firewall_set() {
	echo "Installing Firewall"
	apt-get install ufw
	echo "Reseting rules"
	ufw reset
	echo "Setting rules"
	ufw logging high
	ufw default deny incoming
	ufw default deny outgoing
	#SSH
	ufw limit in $SSH_PORT/tcp
	ufw allow out $SSH_PORT/tcp
	#HTTPS
	ufw allow in 443/tcp
	ufw allow in 80/tcp
	ufw allow out 443/tcp
	ufw allow out 80/tcp
	#DNS
	ufw allow out 53/tcp
	#MAIL SERVER
	ufw deny in 25/tcp
	ufw deny out 25/tcp
	#TIME KEEPING
	ufw allow out 123/udp
}



#######################
#    FIRST INSTALL    #
#######################

first_install (){
	sleep 10
	refresh
	make_templates
	echo "INSTALLING SUDO"
	install_sudo
	echo "SETTING UP SSHD"
	reset_sshd
	reset_ssh_keys
	echo "RESETTING NETWORK INTERFACE $INTERFACE ADAPTER"
	reset_interface
	echo "REBOOTING"
	/sbin/reboot
}
first_install
