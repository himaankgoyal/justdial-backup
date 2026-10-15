#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
EMAIL="mohit.thadhani@justdial.com"
EMAIL_F="mohit.thadhani@justdial.com"
SCRIPT_NAME="listicals_data"
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo "Success"
                echo "Failed on STEP $step on 39.120" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
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
echo "step 1: CALL CALL spellchecks_adhocs.listicals_data(); on 39.120"
ssh ${SSH_ARGS} -q web_backup@192.168.39.120 "sudo mysql -Bse call spellchecks_adhocs.listicals_data();"
ERROR

SUCCESS
