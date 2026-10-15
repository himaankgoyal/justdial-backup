#!/bin/bash

#############################################
#  Created by Himaank Goyal on 13/03/2023   #
#############################################

EMAILID="dbteam_mis@justdial.com,umang.bhavsar@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="deduction_campwise_weekly_data.sh"
SSH_ARG="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
SUBJECT_S="Deduction campwise weekly data process is succesfull"
SUBJECT_F="Deduction campwise weekly data process is failed"
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
echo "Step=$step"
echo "step=$step : deduction_camp1_data() on 192.168.14.225"
sudo mysql -Bse "CALL dbteam_temp.deduction_camp1_data();"
ERROR

step=2
echo "Step=$step"
echo "step=$step : deduction_camp2_data() on 192.168.14.225"
sudo mysql -Bse "CALL dbteam_temp.deduction_camp2_data();"
ERROR

echo "All process completed successfully"
SUCCESS


