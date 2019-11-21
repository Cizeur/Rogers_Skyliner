#!/bin/bash

###############
#CONFIG VALUES#
###############

GIT_REPO="https://github.com/Cizeur/Rogers_Skyliner"	#must contain setup.sh check postinstall.final
USER="rogers"                             		#same as password - alias for root(mail)
USER_FULL_NAME="Private Roger"				#Full name of user (mail)
HOSTNAME="valkyrie"					#Only lower case and minus 
MAIN_PARTITION=4201					#Size of the main partition
ISO_MOD="rogers.iso"					#Output iso

############
#INIT FILES#
############
sed -e "s#<GIT_REPO>#$GIT_REPO#g" postinstall.final > postinstall.sh
chmod 755 postinstall.sh
sed -e "s#<USER>#$USER#g" preseed.final > preseed.cfg
sed -i "s#<USER_FULL_NAME>#$USER_FULL_NAME#g" preseed.cfg
sed -i "s#<MAIN_PARTITION>#$MAIN_PARTITION#g" preseed.cfg
sed -i "s#<HOSTNAME>#$HOSTNAME#g" preseed.cfg
cp isolinux.final isolinux.cfg
