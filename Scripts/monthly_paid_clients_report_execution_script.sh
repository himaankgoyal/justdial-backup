#!/bin/bash

#############################################
# Created by - Himaank Goyal on 2-July-2024 #
#############################################

#EMAIL="somling.patil@justdial.com,jitendrakumar@justdial.com,dbfinmis@justdial.com"
EMAIL="somling.patil@justdial.com,himaank.goyal@justdial.com"
#EMAIL_F="somling.patil@justdial.com,jitendrakumar@justdial.com,dbfinmis@justdial.com"
EMAIL_F="somling.patil@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME=" monthly_paid_clients_report_execution_script.sh"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"

###################################################### Functions ###########################################################

ERROR() {
	if [ $? -ne 0 ];then
		echo "Success"
		echo "Failed on STEP $step on 39.80" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
		exit 1
	fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME is successfull " | sudo mail -s "script is Executed successfully at : `date`" ${EMAIL}
                exit 0
        fi
}

#############################################################################################################################################
step=1
echo"step=$step  Execute SP on 192.168.39.80"
sudo mysql -Bse "call dbteam_temp.sp_lastdateofmonth_5_balance_test();" 
ERROR

step=2
echo"step=$step Execute SP on 192.168.39.55"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.55 -p 2222 "sudo mysql -Bse \" call dbteam_temp.sp_lastmonth_firstdate_lastdate_deduction_test();\""
ERROR

step=3
echo"step=$step Execute SP on 192.168.39.80"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.80 -p 2222 "sudo mysql -Bse \" call dbteam_temp.sp_closing_balance_no_deduction_backend_request();\""
ERROR

step=4
echo"step=$step Table transfer from 192.168.39.80 to 192.168.39.55"
sudo mysqldump dbteam_temp tbl_closing_balance_no_deduction_backend_request > /tmp/tbl_closing_balance_no_deduction_backend_request.sql && sudo gzip /tmp/tbl_closing_balance_no_deduction_backend_request.sql;
ERROR

sudo scp /tmp/tbl_closing_balance_no_deduction_backend_request.sql.gz web_backup@192.168.39.55 -P 2222:/tmp/;
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.39.55 -p 2222 "sudo gunzip -fv /tmp/tbl_closing_balance_no_deduction_backend_request.sql.gz"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.39.55 -p 2222 "sudo mysql dbteam_temp < /tmp/tbl_closing_balance_no_deduction_backend_request.sql"
ERROR

echo "Removing /tmp/tbl_closing_balance_no_deduction_backend_request.sql from 39.80"
sudo rm -fv /tmp/tbl_closing_balance_no_deduction_backend_request.sql

echo "Removing /tmp/tbl_closing_balance_no_deduction_backend_request.sql from 39.55"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.55 -p 2222 "sudo rm -fv /tmp/tbl_closing_balance_no_deduction_backend_request.sql.gz"
ERROR

step=5
echo"step=$step Execute SP on 192.168.39.55" 
sudo ssh ${SSH_ARGS} web_backup@192.168.39.55 -p 2222 "sudo mysql -Bse \" call dbteam_temp.sp_lastmonth_firstdate_lastdate_deduction_final_step_test();\""
ERROR

SUCCESS
