#!/bin/bash
login=$(eval getent passwd \
	{$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} \
	| cut -d: -f1| head -n 1)
echo "Primary login"
echo $login
apt-get install sudo 
usermod -aG sudo $login



