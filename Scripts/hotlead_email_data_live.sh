#!/bin/bash

#############################################
# Created by - Himaank Goyal on 25-May-2023 #
#############################################

EMAIL="pravinkumar.yadav@justdial.com,himaank.goyal@justdial.com"
EMAIL_F="pravinkumar.yadav@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="hotlead_email_data"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo "Success"
                echo "Failed on STEP $step on 41.90" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
                exit 1
        fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME is successfull " | sudo mail -s "script is Executed successfully at : `date`" ${EMAIL}
                exit 0
        fi
}


##############################################################################################################################################

step=1
echo"step=$step transfer table  tmp_user_feedback_daily_counts  from 6.131   server(sms_email_sending database)  to 16.129( dbteam_temp database)"
sudo ssh ${SSH_ARGS} web_backup@192.168.6.131 "sudo mysqldump -h${MYHST} -u${MYUSR} -p${PASS} sms_email_sending tmp_user_feedback_daily_counts > /tmp/tmp_user_feedback_daily_counts.sql && sudo gzip /tmp/tmp_user_feedback_daily_counts.sql;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.6.131 "sudo scp /tmp/tmp_user_feedback_daily_counts.sql.gz web_backup@192.168.16.129:/tmp/;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.16.129 "sudo gunzip /tmp/tmp_user_feedback_daily_counts.sql.gz"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.16.129 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} dbteam_temp < /tmp/tmp_user_feedback_daily_counts.sql"
ERROR

echo "Removing /tmp/tmp_user_feedback_daily_counts.sql from 16.129"
ssh ${SSH_ARG} web_backup@192.168.16.129 "sudo rm -fv /tmp/tmp_user_feedback_daily_counts.sql"
ERROR

echo "Removing /tmp/tmp_user_feedback_daily_counts.sql.sql from 6.131"
ssh ${SSH_ARG} web_backup@192.168.6.131 "sudo rm -fv /tmp/tmp_user_feedback_daily_counts.sql.gz"
ERROR

Step=2
echo "step 2: CALL CALL db_hotleads.Sp_email_data_insert(); on 16.129"
ssh ${SSH_ARGS} -q web_backup@192.168.16.129 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call db_hotleads.Sp_email_data_insert()\";"
ERROR

SUCCESS
