#!/bin/bash

#############################################
# Created by - Himaank Goyal on 19-May-2023 #
#############################################

EMAIL="dbteam_mis@justdial.com,kundan.kumar6@justdial.com,sapna.javeri@justdial.com,himaank.goyal@justdial.com"
EMAIL_F="kundan.kumar6@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="sp_dublicate_process_paid_data"
#Date=$(date +%Y-%m-%d -d '1 day ago')
SSH_ARGS='-o StrictHostKeyERRORing=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo "Success"
                echo "Failed on STEP $STEP on 12.80" | mail -r root@justdial.com -s "Script : ${SCRIPT_NAME} Non-paid Data converted to Paid- Duplicate Data  Common Audit Process Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
                exit 1
        fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME Non-paid Data converted to Paid- Duplicate Data  Common Audit  Process successfully." | mail -r root@justdial.com -s "script is Executed successfully at `date`" ${EMAIL}
                exit 0
        fi
}

##########################################################################################################################################

echo "step 1: call sp dbteam_temp.sp_dublicate_process_paid_data(); on12.175"
ssh $SSH_ARGS -q web_backup@192.168.12.175 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call dbteam_temp.sp_dublicate_process_paid_data()\";"
ERROR

echo "step 2 : Taking Dump of tbl_extract_data_for_mismatch_area"
for i in mumbai delhi kolkata bangalore chennai pune hyderabad ahmedabad remote;
do

	TBL="temp_dublicate_paid_convertion_data_${i}"
	echo "Taking Dump of ${TBL}"
	echo "===== $i ====="
	echo "taking dump and zipping on 12.175"
	ssh $SSH_ARGS -q web_backup@192.168.12.175 "sudo mysqldump dbteam_temp ${TBL} | gzip -fv > /tmp/${TBL}.sql.gz"
	ERROR

	echo "Transfer ${TBL} to 12.80"
	ssh $SSH_ARGS -q web_backup@192.168.12.175 "sudo scp /tmp/${TBL}.sql.gz web_backup@192.168.12.80:/tmp/"
	ERROR
	     
	echo "cleanup old file from 12.175 after transfer" 
	ssh $SSH_ARGS -q web_backup@192.168.12.175 "sudo rm -fv /tmp/${TBL}.sql.gz"
	ERROR
	     
	echo "unzipping tables on 192.168.12.80"
	ssh $SSH_ARGS web_backup@192.168.12.80 "sudo gunzip /tmp/${TBL}.sql.gz"
	ERROR

	echo "Restore on 12.80 ${TBL}"
	ssh $SSH_ARGS web_backup@192.168.12.80 "sudo mysql -h$MYHST -u$MYUSR -p$PASS dbteam_temp < /tmp/${TBL}.sql"
	ERROR

	echo "Cleanup tables from 192.168.12.80 post restoration."
	ssh $SSH_ARGS web_backup@192.168.12.80 "sudo rm -fv /tmp/${TBL}.sql"
	ERROR

done

echo "step 3: call sp db_reports.sp_dublicate_process_paid_data() on 12.80"
ssh $SSH_ARGS -q web_backup@192.168.12.80 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call db_reports.sp_dublicate_process_paid_data()\";"
ERROR

echo "step 4: Curl call on 12.80"
ssh $SSH_ARGS -q web_backup@192.168.12.80 "sudo /usr/bin/curl http://192.168.12.80:88/rating_dir/estate_agent/dublicatepaiddata.php"
ERROR

echo "All Process Completed Successfully"
SUCCESS



