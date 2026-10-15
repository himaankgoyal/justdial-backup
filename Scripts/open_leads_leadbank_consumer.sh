#!/bin/bash
# Name :- Rajveer singh
# Date :- 2 June 2022
# Milestone :- To check process running or not
# Stake :- Meeta . B / Pravin Kucha / Linux
#

## Variables 
DEFNIC=$(/sbin/ip route show | awk '{if(/default\ via/){for(i=1;i<=NF;i++){if($i == "dev"){print $(i+1)}}}}')
MYIP=$(/sbin/ip route show | awk -v nic=${DEFNIC} '{if(( $0 ~ nic && /src/)){for(i=1;i<=NF;i++){if( $i == "src")print $(i +1)}}}')
IP_OCTET3=`echo ${MYIP} | cut -d "." -f 3`
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`
CITY=`sh /scripts/find_ct_digit.sh`
SENDMAIL_USER="jdalerts@justdial.com"
EMAIL="pravinkucha@justdial.com"

FILEDIR="/var/www/production/jds_pincodewise_uat_staging/mvc/cron/python"
FILENAME="open_leads_leadbank_consumer.py"
LOGFILE="/var/log/daily_log/${FILENAME}_${DATE}.log"

COUNT=$( ps -ef | grep "[p]ython3.9 ${FILEDIR}/${FILENAME}" -c)
if [ $COUNT -eq 0 ];then
        echo "Starting the ${FILENAME} process at `date`"
        cd $FILEDIR
        python3.9 $FILEDIR/${FILENAME} >> ${LOGFILE} 2>&1 &

        echo -e "Started the ${FILENAME} process at `date`\nsource script: $0\nServer IP: $MYIP" | mail -s "Started: ${FILENAME} process on $MYIP at `date`" -r $SENDMAIL_USER $EMAIL
###        sh /scripts/standard_sms_sending_script.sh -n 9972202533 -m "Started the ${FILENAME} process at `date`\nsource script: $0\nServer IP: $MYIP"
else
        echo "Process ${FILENAME} already running checked at `date`"
fi


