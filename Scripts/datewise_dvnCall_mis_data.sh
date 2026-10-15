#!/bin/bash


EMAILID="mallappa.chikanal@justdial.com,rohit.tondon@justdial.com,jitendrakumar@justdial.com,ajay.bhulawat@justdial.com,pravinkucha@justdial.com"
EMAILF="mallappa.chikanal@justdial.com,rohit.tondon@justdial.com,jitendrakumar@justdial.com,ajay.bhulawat@justdial.com,pravinkucha@justdial.co"
DATE=$(date +"%Y-%m-%d")
START_DATE=$(date +"%Y%m" -d "1 day ago")
SSH_ARG='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
SCRIPT_NAME="datewise_dvnCall_mis_data"
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"

ERROR() {
      if [ $? -ne 0 ] ;then
                echo "datewise_dvnCall_mis_data for $DATE FAILED on  `hostname`"
                echo  "datewise_dvnCall_mis_data  FAILED" | mail -r "From: <reports@justdial.com>" -s "datewise_dvnCall_mis_data failed for $DATE"  -a ${LOGFILE} ${EMAILF} 
             		exit 1
      fi
}

SUCCESS() {

       if [ $? -eq 0 ] ;then
                echo "datewise_dvnCall_mis_data  for $DATE Compleated"
                echo  "Hi, datewise_dvnCall_mis_data successfully executed on `hostname`" | mail -r "From: <reports@justdial.com>" -s "datewise_dvnCall_mis_data  for $DATE" ${EMAILIF}
        fi
}

echo "step 1: Call sp_datewise_dvnCall_mis_data on 39.55;"
ssh $SSH_ARGS -q web_backup@192.168.39.55 "sudo mysql -Bse \"call db_iro_central.sp_datewise_dvnCall_mis_data('$DATE');\""
ERROR

echo "All process completed"
SUCCESS

