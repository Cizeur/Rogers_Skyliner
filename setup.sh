#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR


CRON_FILE="/var/spool/cron/root"
if [ ! -f $CRON_FILE ]; then
   echo "cron file for root doesnot exist, creating.."
   touch $CRON_FILE
   /usr/bin/crontab $CRON_FILE
fi
croncmd="sleep 10 && $SCRIPT_DIR/config.sh > /root/woooow"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

