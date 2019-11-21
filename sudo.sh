#!/bin/bash
login=$1
echo "Primary login"
echo $login
apt-get install sudo 
usermod -aG sudo $login



