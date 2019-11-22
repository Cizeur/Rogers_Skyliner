apt-get install -y  bmon
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix
apt-get install -y fail2ban
apt-get install -y ufw
