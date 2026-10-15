#!/bin/bash

# ----------------------------------------------- #
# Script by : Lijo Jacob
# Created on : 03072020  Track Ticket No: #128916
# Technical stake holder : Ketaki C
# Contact no of technical stake holder : ext-4487 
# Business stake holder : Rajeev Nair
# Purpose / Description : Three Plus Mobile Contracts
# ----------------------------------------------- #

# ----- Define Variables ------ #

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EMAIL="dbteam_mis@justdial.com,dbescalations@justdial.com"
SUBJECT="Three Plus Mobile Contracts"
HNAME="$(hostname | cut -d. -f1)"
dbhost="localhost"
dbuser="process_auto"
dbpass="gr8exp9master"
LOGFILE="/var/log/daily_log/three_plus_mobile_contracts.log"
IP="192.168.12.175"
# ----- Define Function ---- #
function ERROR
{
        if [ $? -ne 0 ]
        then
                cat ${LOGFILE} | /bin/mail -s "${SUBJECT} Failed " $EMAIL
                exit 1
        fi
}

function SUCCESS
{
        if [ $? -eq 0 ]
        then
               echo "Process Completed Successfully" | /bin/mail -s "${SUBJECT} Sucessfull " -a /tmp/three_plus_mobile_contracts.csv $EMAIL 
               exit 0
        fi
}


## ----- Main Body ---- #

echo "Execute SP() sp_five_plus on ${IP}"
sudo ssh ${SSH_ARGS} web_backup@${IP} "sudo mysql -h${dbhost} -u${dbuser} -p${dbpass} -Bse 'call test.sp_five_plus();'"
ERROR

echo "Take Dump of temp_five_plus_mobile on ${HNAME}"
sudo ssh ${SSH_ARGS} web_backup@${IP} "sudo mysqldump test temp_five_plus_mobile > /tmp/temp_five_plus_mobile.sql"
ERROR

echo "Transfer temp_five_plus_mobile to 12.219"
sudo scp ${SSH_ARGS} web_backup@${IP}:/tmp/temp_five_plus_mobile.sql /tmp/
ERROR

echo "Restoring temp_five_plus_mobile on 12.219"
sudo mysql db_reports < /tmp/temp_five_plus_mobile.sql
ERROR

echo "Deleting Temporary Tables from ${HNAME} and ${IP}"
ssh  ${SSH_ARGS} web_backup@${IP} "sudo rm -fv /tmp/temp_five_plus_mobile.sql"
ERROR

sudo rm -fv /tmp/temp_five_plus_mobile.sql
ERROR

echo "Deleting Temporary csv file from 12.219"
sudo rm -fv /tmp/three_plus_mobile_contracts.csv
ERROR

echo "Execute SP() sp_dealdata_on_boarding on ${HNAME}"
sudo mysql -Bse 'CALL db_reports.sp_five_plus_mobile_contracts();'
ERROR

echo "Sending Success Mail"
SUCCESS
