apt-get install -y  bmon
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
sudo apt-get install -y -q
apt-get install -y postfix
apt-get install -y alpine
apt-get install -y nginx
apt-get install -y fail2ban
apt-get install -y ufw
