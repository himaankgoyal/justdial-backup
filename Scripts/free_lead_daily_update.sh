#! /bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
MAIL_ID="nikhil.pangariya@justdial.com"
HOST_IP=`hostname -I | awk '{print $1}'`
Subject="free_lead_daily_update"
SCRIPT_NAME="free_lead_daily_update"
LOG_FILE="/var/log/daily_log/${SCRIPT_NAME}.log"

##########################################################################################################################

ERROR()
{
        if [ $? -ne 0 ]; then
                echo "${Subject} process Failed on ${HOST_IP}" | mail -s "FAILED: ${Subject} process Failed on ${HOST_IP}" ${MAIL_ID} -a ${LOG_FILE}
                exit 0
        fi
}

SUCCESS()
{
    echo "${Subject} process SUCCESS on ${HOST_IP}" | mail -s "SUCCESS: ${Subject} process SUCCESS on ${HOST_IP}" ${MAIL_ID} -a ${LOG_FILE}
}


##############################################################################################################################
step=1
echo "step $step = Run free_lead_daily.py python Script on 192.168.42.131 " 
/usr/bin/python3.6 /scripts/free_lead_daily.py > /var/log/daily_log/free_lead_daily.log 2>&1
ERROR

step=2
echo "step $step = Run free_lead_daily_update.py python Script on 192.168.42.131 " 
/usr/bin/python3.6 /scripts/free_lead_daily_update.py > /var/log/daily_log/free_lead_daily_update.log 2>&1
ERROR



echo "ALL PROCESSES EXECUTED SUCCESSFULLY"
SUCCESS

