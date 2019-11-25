#!/bin/bash
echo "### UPDATE STARTED ###"
date
echo "Updating apt"
apt-get -y update

echo "Upgrading apt"
apt-get -y upgrade
apt-get -y dist-upgrade

echo "Cleaning up"
apt-get clean
apt-get -y autoremove

date
echo "### UPDATE DONE ###"
