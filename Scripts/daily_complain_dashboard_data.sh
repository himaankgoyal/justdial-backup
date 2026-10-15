#!/bin/bash
SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#EMAIL_ID="arun8@justdial.com,dbteam_mis@justdial.com"
EMAIL_ID="arun8@justdial.com,himaank.goyal@justdial.com"
DATE=$(date +%d-%m-%Y)
SSUBJECT="Success daily complain dashboard data on 12.219"
FSUBJECT="Failed daily complain dashboard data on 12.219"
LOG="/var/log/daily_log/daily_complain_dashboard_data.log"
#preveous_date_1=$(date +%Y%m%d -d '1 day ago')


######
CHECK () {
	if [ $? -ne 0 ]
	then
		echo "failed on step=$step"
		echo "FAILED : ${FSUBJECT}" | mail -s "FAILED :${FSUBJECT} $DATE" -a $LOG $EMAIL_ID
		exit 1
	fi
}

SUCCESS () {
	if [ $? -eq 0 ]
	then
		echo "success"
		echo "SUCCESS : ${SSUBJECT}" | mail -s "SUCCESS : ${SSUBJECT} $DATE"  $EMAIL_ID             
                exit 0
	fi
}

###############################################################################################################################################

step=1 
echo "  Run  SP call on server 192.168.12.219"
ssh $SSH_ARGS -q web_backup@192.168.12.219 "sudo mysql -Bse 'CALL complain_dashboard.sp_complain_dashboard_view_data();'"
CHECK

echo "All process is completed successfully"
SUCCESS

