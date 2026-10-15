#!/bin/bash

#############################################
#  Created by Himaank Goyal on 19/04/2023   #
#############################################

EMAILID="shaikh.hussain@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="sp_bounce_factor_autoreport.sh"
SSH_ARG="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
SUBJECT_S="sp_bounce_factor_autoreport is succesfull"
SUBJECT_F="sp_bounce_factor_autoreport is failed"
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"


################################################ Function Defining Here  ###################################################

ERROR() {
      if [ $? -ne 0 ] ;then      
           echo "FAILED on $step on $DATE"
           echo "${SCRIPT_NAME} FAILED on $step at `date`" | mail -s "${SUBJECT_F}" -a ${LOGFILE} ${EMAILID}
           exit 1
      fi
}

SUCCESS() {
       if [ $? -eq 0 ] ;then      
            echo "Script : ${SCRIPT_NAME} is Executed Successfully on `date`"
            echo "${SCRIPT_NAME} executed successfully at `date`" | mail -s "${SUBJECT_S}" ${EMAILID} 
       fi
}

############################################################################################################################

step=1 
echo "Step=$step Call below sp on 14.48"
echo "step=$step : db_deduction.sp_bounce_factor_autoreport_ecs() on 192.168.14.48"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo mysql -Bse 'set sql_log_bin=0; CALL db_deduction.sp_bounce_factor_autoreport_ecs(); set sql_log_bin=1;'" 
ERROR

step=1.a
echo"step=$step" Transfer table tbl_stats_paymentmode_status_48_part from 14.48(test) to 14.49(db_hotdata)
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo mysqldump test tbl_stats_paymentmode_status_48_part > /tmp/tbl_stats_paymentmode_status_48_part.sql && sudo gzip /tmp/tbl_stats_paymentmode_status_48_part.sql;"
CHECK

sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo scp /tmp/tbl_stats_paymentmode_status_48_part.sql.gz web_backup@192.168.14.49:/tmp/;"
CHECK

sudo ssh ${SSH_ARGS} web_backup@192.168.14.49 "sudo gunzip /tmp/tbl_stats_paymentmode_status_48_part.sql.gz"
CHECK

sudo ssh ${SSH_ARGS} web_backup@192.168.14.49 "sudo mysql db_hotdata < /tmp/tbl_stats_paymentmode_status_48_part.sql"
CHECK

echo "Removing /tmp/tbl_stats_paymentmode_status_48_part.sql from 14.48"
ssh ${SSH_ARG} web_backup@192.168.14.49 "sudo rm -fv /tmp/tbl_instrument_details_less_than_100.sql"
CHECK

echo "Removing /tmp/tbl_stats_paymentmode_status_48_part.sql from 14.48"
ssh ${SSH_ARG} web_backup@192.168.14.48 "sudo rm -fv /tmp/tbl_instrument_details_less_than_100.sql.gz"
CHECK

step=2  
echo "Step=$step Call below sp on 14.49"
echo "step=$step : db_deduction.sp_bounce_factor_autoreport() on 192.168.14.49"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.49 "sudo mysql -Bse 'set sql_log_bin=0; CALL db_deduction.sp_bounce_factor_autoreport(); set sql_log_bin=1;'" 
ERROR

echo "All process completed successfully"
SUCCESS
