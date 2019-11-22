#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR


CRON_FILE="/var/spool/cron/root"
if [ ! -f $CRON_FILE ]; then
   echo "cron file for root doesnot exist, creating.."
   touch $CRON_FILE
   /usr/bin/crontab $CRON_FILE
fi
### LAUNCH CONFIG SCRIPT ON REBOOT ###
croncmd="$SCRIPT_DIR/config.sh > /root/woooow"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

### REMOVE CONFIG SCRIPT FROM CRON ###
croncmd="crontab -l | grep -v -F "$croncmd" | crontab -"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
