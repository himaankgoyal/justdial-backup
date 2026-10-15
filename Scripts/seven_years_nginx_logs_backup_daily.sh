#!/bin/bash

EMAIL="linux@justdial.com,systems@justdial.com"
IPADDR=$(/sbin/route -n | awk '{print $1,$8}' | grep "0.0.0.0" | cut -d " " -f2 | xargs /sbin/ifconfig | egrep "inet |inet addr"  | awk '{print $2}'| sed 's/addr://g')
DAY=$(date +%d -d "1 day ago")
YEAR=$(date +%Y -d "1 day ago")
DATE_DIR=$(date +%d-%m-%Y -d "1 day ago")
DEST_IP="192.168.42.133"
SCRIPT_NAME="seven_years_nginx_logs_backup_daily"
LOG_PATH="/var/log/nginx/BACKUP/Day${DAY}"
LOG_FILE="/var/log/daily_log/${SCRIPT_NAME}.log"
BACKUP_PATH="/nginx_logs_backup_1/7Years_Retention/$YEAR/$DATE_DIR/${IPADDR}/"
SSH_ARG="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"

function ERROR () { 
	if [ $? -ne 0 ]; then
        echo "Script : ${SCRIPT_NAME}.sh has been failed for ${IPADDR}" | mail -r jdalerts@justdial.com -s "Nginx log backup script failed for ${IPADDR}" -a $LOG_FILE ${EMAIL}
	exit 1
	fi
}

function SUCCESS () { 
        if [ $? -eq 0 ]; then
        echo -e "Script : ${SCRIPT_NAME}.sh has been successfully executed for ${IPADDR}\n\nNginx logs for date : $DATE_DIR has been transfered successfully to $DEST_IP:$BACKUP_PATH\n" | mail -r jdalerts@justdial.com -s "Nginx log backup script success on ${IPADDR}" ${EMAIL}
	exit 0
        fi
}

SIZE=$(sudo du -sb $LOG_PATH | cut -f1)
ERROR

if [ "$SIZE" -gt 50000 ]
then
	echo "Nginx logs size of $IPADDR for date $DATE_DIR is grater than 0.05 MB"
	ssh $SSH_ARG web_backup@${DEST_IP} "if [ -d $BACKUP_PATH ]; then echo \"$BACKUP_PATH already exists.\"; else echo -e \"Creating dir : $BACKUP_PATH\"; sudo mkdir -p $BACKUP_PATH && sudo chown -R web_backup:web_backup $BACKUP_PATH; fi"
	ERROR

	echo "Copying nginx logs from ${IPADDR} to ${DEST_IP}:$BACKUP_PATH"
	sudo scp -r ${LOG_PATH} web_backup@${DEST_IP}:$BACKUP_PATH
	ERROR
else 
	echo -e "Size of nginx logs of ${IPADDR} for date : $DATE_DIR is less than 0.05 MB\n\nLooks like nginx logs not backed up on server : ${IPADDR} in directory : $LOG_PATH\n\n Please check accordingly..." | mail -r jdalerts@justdial.com -s "Nginx log backup script failed on server as it is DB server : ${IPADDR}" ${EMAIL}
	exit 0

fi

echo "All Process Completed Successfully"
#SUCCESS

