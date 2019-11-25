#!/bin/bash
MAIL_CLIENT="/usr/sbin/sendmail"
FILE="/etc/crontab"
LOGS="/script/cron_change_log"
MODIF_DATE=$(stat /etc/crontab | grep Mod |  cut -d' '  -f2,3,4)
MAIL_SUBJECT="/etc/crontab was MODIFIED"
ADRESSEE="root@localhost"


if [ !  -f "$LOGS" ] || [ "$(wc -c "$LOGS" | awk '{print $1}')" -lt "2" ]
then
        touch $LOGS
	chmod 644 $LOGS
	echo $(shasum $FILE | awk '{ print $1 }') > $LOGS
        echo $MODIF_DATE >>  $LOGS
	(echo "Subject: $MAIL_SUBJECT"; echo ; echo "Modification log for $FILE was missing check for changes, monitoring started") | $MAIL_CLIENT $ADRESSEE
else
	PREV_SHASUM=$(tail -2 $LOGS | head -1)
	CUR_SHASUM=$(shasum $FILE | awk '{ print $1 }')
	OLD_DATE=$(tail -n 1 $LOGS)
        D_MODIF=$(date -d "$MODIF_DATE" +"%s")
        D_OLD=$(date -d "$OLD_DATE" +"%s")
        if [ "$D_MODIF" != "$D_OLD" ] || [ "$CUR_SHASUM" != "$PREV_SHASUM" ]
        then
		(echo "Subject: $MAIL_SUBJECT"; echo ; echo "$FILE was modified on $MODIF_DATE check for changes") | $MAIL_CLIENT  $ADRESSEE
		echo $CUR_SHASUM >> $LOGS
        	echo $MODIF_DATE >>  $LOGS
       	fi

fi
