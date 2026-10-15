#!/bin/bash

#############################################
#  Created by Himaank Goyal on 07/03/2023   #
#############################################

EMAILID="shrikant.more1@justdial.com,somling.patil@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="sp_tbl_estate_agent_weekly_autoreport"
SSH_ARG="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
SUBJECT_S="sp_tbl_estate_agent_weekly_autoreport Success"
SUBJECT_F="sp_tbl_estate_agent_weekly_autoreport fail"
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
            echo "${SCRIPT_NAME} executed successfully at `date`" | mail -s "${SUBJECT_S}" -a /tmp/report.xlsx ${EMAILID} 
       fi
}

############################################################################################################################

step=1 
echo "Step=$step"
echo "step=$step : Calling SP sp_tbl_estate_agent_weekly() on 192.168.39.81"
sudo mysql -Bse "CALL dbteam_temp.sp_tbl_estate_agent_weekly();"
ERROR

############################################################################################################################

step=2
echo "Step=$step"
echo "step=$step : Running select query on 192.168.39.81"
sudo mysql -e "SELECT * FROM dbteam_temp.tbl_estate_agent_temp ORDER BY data_src,parentid;" > /tmp/report.xlsx
ERROR

SUCCESS
