apt-get install -y  bmon
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
apt-get install -y postfix
apt-get install -y alpine
apt-get install -y nginx
apt-get install -y fail2ban
apt-get install -y ufw
