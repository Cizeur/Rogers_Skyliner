#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR

########################
#                      #
#     VARIABLES        #
#                      #
########################

./extra_packages.sh  >> log_packages_install
cp -r /root/autoconf/script /script

refresh () {
	USER_BASIC=$(eval getent passwd \
		{$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} \
		| cut -d: -f1| head -n 1)
	
	INTERFACE="$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')"
	STATIC_IP="10.13.254.77/30"
	GATEWAY="$(echo $STATIC_IP | cut -f1,2,3 -d'.').254"

	SSH_KEY_LOC="./YOUR_SSH_PUBLIC_KEY"
	SSH_PORT=4242
	IP="$(hostname -I | awk '{print $1}')"
	WEBSITE="www.WEBSITE.dev"
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
	#FAIL2BAN Template
	sed -e "s#<STATIC_IP>#$STATIC_IP#g" ./templates/jail.local.TEMP > ./REPLACEMENTS/jail.local
	sed -i "s#<GATEWAY>#$GATEWAY#g" ./REPLACEMENTS/jail.local
	cp -r ./templates/filter.d ./REPLACEMENTS/filter.d
	#NGINX Template
	sed -e "s#<IP>#$IP#g" ./templates/SITE.conf.TEMP > ./REPLACEMENTS/$WEBSITE.conf
	sed -i "s#<WEBSITE>#$WEBSITE#g" ./REPLACEMENTS/$WEBSITE.conf
}

refresh
make_templates

################################
#    REDIRECTING ROOT MAIL     #
################################

echo "root@localhost, $USER_BASIC@localhost" > /root/.forward

#######################
#    INSTALL SUDO     #
#######################

install_sudo(){
	echo "Primary login"
	echo $USER_BASIC
	apt-get install sudo
	/sbin/usermod -aG sudo $USER_BASIC
}

#######################
#    STATIC IP        #
#######################


reset_interface () {
	mv /etc/network/interfaces /etc/network/interfaces.old
	cp ./REPLACEMENTS/interfaces /etc/network/interfaces
	/sbin/ifdown $INTERFACE && /sbin/ifup $INTERFACE
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
	systemctl restart ufw
	echo "Reseting rules"
	/sbin/ufw disable
	/sbin/ufw --force reset
	echo "Setting rules"
	/sbin/ufw logging high
	/sbin/ufw default deny incoming
	/sbin/ufw default deny outgoing
	#SSH
	/sbin/ufw limit in $SSH_PORT/tcp
	/sbin/ufw allow out $SSH_PORT/tcp
	#HTTPS
	/sbin/ufw allow in 443/tcp
	/sbin/ufw allow in 80/tcp
	/sbin/ufw allow out 443/tcp
	/sbin/ufw allow out 80/tcp
	#DNS
	/sbin/ufw allow out 53/udp
	#MAIL SERVER
	/sbin/ufw deny in 25/tcp
	/sbin/ufw deny out 25/tcp
	#TIME KEEPING
	/sbin/ufw allow out 123/udp
	#BLOCK ICMP
	cp /etc/ufw/before.rules /etc/ufw/before.rules.old
	cp /etc/ufw/before6.rules /etc/ufw/before6.rules.old
	sed -i '/\bicmp\b/ s/\bACCEPT\b/DROP/g' /etc/ufw/before.rules
	sed -i '/\bicmp\b/ s/\bACCEPT\b/DROP/g' /etc/ufw/before6.rules
	/sbin/ufw enable
}

#######################
#      FAIL2BAN       #
#######################

fail2ban_set() {
	echo "Adding jail.local"
	mv  /etc/fail2ban/jail.local  /etc/fail2ban/jail.local.old
	mv ./REPLACEMENTS/jail.local /etc/fail2ban/jail.local
	echo "Adding filter"
	cp -r /etc/fail2ban/filter.d /etc/fail2ban/filter.d.old
	mv ./REPLACEMENTS/filter.d/* /etc/fail2ban/filter.d/
	echo "creating empty logs if missing"
	touch /var/log/auth.log
	touch /var/log/ufw.log
	touch /var/log/nginx/access.log
	echo "Restarting FAIL2BAN"
	systemctl restart fail2ban.service 
}

#######################
#      CRONTAB        #
#######################

add_to_cron() {	
	croncmd=$2
	cronjob="$1 $croncmd"
	( crontab -l | grep -v -F "$cronjob" ; echo "$cronjob" ) | crontab -
	systemctl restart cron.service
}

crontab_set(){
	crontab -r
	add_to_cron "0 4 * * 2" "/script/update.sh | tee -a  /var/log/update_script.log 2>&1"
	add_to_cron "@reboot" "/script/update.sh | tee -a  /var/log/update_script.log 2>&1"
	add_to_cron "0 4 * * 5" "/script/manlog.sh"
	add_to_cron "0 0 * * *" "/script/change_monitor.sh"
}

#######################
# 	SERVICES      #
#######################

#Checked with systemctl list-unit-files | grep enabled
## auto_vt || getty  needed to have a terminal on the vm side
## syslog provide needed for rsyslog
## rsyslog manages /var/logs files
## procps contain process commands  kill, pkill, ps sysctl,  top, uptime for example
## dbus needed for systemctl 

service_disable(){
	systemctl mask apparmor
	systemctl mask systemd-fsck-root.service
	systemctl mask kmod
	systemctl mask udev
	systemctl mask apt-daily-upgrade.timer 
	systemctl mask apt-daily.timer
	systemctl mask logrotate.timer  
	systemctl mask man-db.timer 
}

#######################
#       NGINX         #
#######################

nginx_set() {
	echo 'Adding new website'
	#addind new and disabling
	mv /etc/nginx/sites-available/$WEBSITE.conf /etc/nginx/sites-available/$WEBSITE.conf.old	
	cp ./REPLACEMENTS/$WEBSITE.conf /etc/nginx/sites-available/$WEBSITE.conf
	ln -s /etc/nginx/sites-available/$WEBSITE.conf /etc/nginx/sites-enabled/$WEBSITE.conf

	echo 'Disabling default'
	rm /etc/nginx/sites-enabled/default

	echo 'Setting up content'
	#Set up content
	mkdir -p /website/$WEBSITE
	cp -r ./website_content/* /website/$WEBSITE/

	echo 'Adding SSL'
	#Create SSL
	./openssl_key_gen.sh $WEBSITE
	mkdir -p /website/ssl
	mv -f $WEBSITE.crt $WEBSITE.key /website/ssl/

	echo 'Restarting Nginx'
	systemctl restart nginx
}

#######################
#    FIRST INSTALL    #
#######################

countdown() {
  secs=$1
  shift
  MSG=$2
  while [ $secs -gt 0 ]
  do
    printf "\rThis is a VIOLENT script if unaware of it's action press Ctrl-C you have %.d seconds" $((secs--))
    sleep 1
  done
  echo
}

first_install (){
	countdown "20" 
	echo "STARTING"
	refresh
	make_templates
	echo "INSTALLING SUDO"
	install_sudo	
	echo "DISABLING SERVICES"
	service_disable	
	echo "SETTING UP SSHD"
	reset_sshd
	reset_ssh_keys
	echo "SET UP FIREWALL"
	firewall_set
	echo "SET UP FAIL2BAN"
	fail2ban_set
	echo "SET UP NGINX"
	nginx_set
	echo "SET UP CRONTAB"
	crontab_set
	echo "RESETTING NETWORK INTERFACE $INTERFACE ADAPTER"
	reset_interface
}
first_install
