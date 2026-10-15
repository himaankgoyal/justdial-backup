#!/bin/bash

DEFAULT_INTERFACE=$(/sbin/route -n | awk '{ print $1,$8 }' | grep "0.0.0.0" | cut -d " " -f 2)
SERIP=$(/sbin/ifconfig $DEFAULT_INTERFACE | grep "inet" | awk '{ print $2 }' | cut -d ":" -f 2 | head -n1)

INFO="
# Script by : Bhavesh Prajapati
# Created from scratch on : 30-03-2021  Track Ticket No: #XXXXXXX
# Technical stake holder : Nidhi P from rajeev nair team
# Contact no of technical stake holder : Nidhi P => 2748 
# Business stake holder : Rajeev nair
# Purpose / Description : Data for weekly jdmart eligible table process
#----------------------------------------------------
# Last modified on : N/A
# Last modified by : N/A
# Modified details :
# Script Name      : $0
# Script Running on: ${SERIP}
"

#-------- Variables ------------#

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#EMAIL_TO="bhavesh.prajapati@justdial.com"
EMAIL_ID_ERR="bhavesh.prajapati@justdial.com,dbteam_mis@justdial.com"
EMAIL_TO="dbteam_mis@justdial.comi,dbteam_mis@justdial.com,bhavesh.prajapati@justdial.com"
EMAIL_CC="dbteam_mis@justdial.com,dbteam_mis@justdial.com"
#EMAIL_CC="bhavesh.prajapati@justdial.com"
EMAIL_SENDER="dbteam_mis@justdial.com"
SUBJECT="Data for weekly jdmart eligible table process"
LOCALUSER="process_auto"
LOCAL_MYSQL_USER="process_auto"
LOCAL_MYSQL_PASS="gr8exp9master"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
date=`date +%d-%m-%Y`


# ------ Function Define ------ #
function CHECK () {
if [ $? -eq 0 ]; then
                echo "${STEP} is Successfully Completed"
else
                echo "Failed"
        echo -e "${SUBJECT} is failed in step ${STEP}\n\n\n ${INFO}" | mail  -s "`echo -e \"${SUBJECT} failed\nContent-Type: text/plain\"`" ${EMAIL_ID_ERR}
                exit 1
fi
}

TIMESTAMP(){
date +"%Y-%m-%d %T"
}

SMALL_LINE(){
echo -e  "\n---------------------------------\n"
}

MED_LINE(){
echo -e  "\n====================================================================================\n"
}

BIG_LINE(){
echo -e  "\n####################################################################################\n"
}

PORT_3006='--socket=/var/lib/SQL/mysql/mysql.sock'
PORT_3007='--socket=/var/lib/SQL_07/mysql/mysql.sock'


############ Starting Main pricess ##########################
BIG_LINE

STEP="1.0"

echo "${STEP} is start at `date` "
echo "Taking Dump of Jdmart_universe_docids table."
ssh ${SSH_ARGS} web_backup@192.168.39.120 "rm -fv /tmp/Jdmart_universe_docids.sql.gz ; sudo mysqldump india_snapshot Jdmart_universe_docids | gzip -f > /tmp/Jdmart_universe_docids.sql.gz"
CHECK

STEP="1.1"
echo "Transfering table from 192.168.39.120 to 192.168.12.219"
scp ${SSH_ARGS} web_backup@192.168.39.120:/tmp/Jdmart_universe_docids.sql.gz /tmp/ && gunzip /tmp/Jdmart_universe_docids.sql.gz
CHECK

STEP="1.2"
echo "Restorint Table on 192.168.12.219"
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} ${PORT_3306} db_reports < /tmp/Jdmart_universe_docids.sql
CHECK

STEP="1.3"
echo "Cleanup restorated dump file from 192.168.12.219"
rm -fv /tmp/Jdmart_universe_docids.sql
CHECK

MED_LINE

#-------------------------------------------------------------

STEP="2.0"

echo "${STEP} is start at `date` "
echo "Calling SP call db_reports.sp_jdmart_eligibility_table_np() on 12.219 Server 3306 Port"
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} ${PORT_3306} -Bse  'use db_reports; call db_reports.sp_jdmart_eligibility_table_np();'
CHECK

MED_LINE

#-------------------------------------------------------------

STEP="3.0"

echo "--------------------- Script is Completed Sending Success email ---------------------------"

echo "Process Successfully completed on 192.168.12.219"

echo "Sending Success Mail"

echo -e "${SUBJECT} is completed successfully on ${SERIP} on '$date'\n\n\n $INFO" | mail -s "${SUBJECT} Success" -r ${EMAIL_SENDER} -c ${EMAIL_CC} -a '/var/log/daily_log/data_weekly_jdmart_eligible.log' ${EMAIL_TO}

echo "--------> All Process Completed Successfully At $(TIMESTAMP) <--------"
exit 0

