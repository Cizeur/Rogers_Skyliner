#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR

croncmd="$SCRIPT_DIR/config.sh > /root/woooow"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

