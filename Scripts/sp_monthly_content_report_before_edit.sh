#!/bin/bash

# Script by : rahul dhakad
# Created from scratch on : <14-03-2018>  Track Ticket No: 
# Technical stake holder : <pravin yadav from rajeev nair team>
# Contact no of technical stake holder : <verna => 2478>
# Business stake holder : <rajeev nair>
# Purpose / Description : sp_monthly_content_report
#----------------------------------------------------
# Last modified on : 14-03-2018
# Last modified by : rahul dhakad 

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
EMAIL_ID="rahul.dhakad@justdial.com,pravinkumar.yadav@justdial.com"
HNAME="$(hostname | cut -d. -f1)"
SUBJECT="monthly_content_report process"
CITYDGT=$(/sbin/ip route | grep src |awk '{print $9}'| cut -d. -f3|head -1)
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
DATE=`date +%d-%m-%Y`
SR1="192.168.13.85"
#TBL1="temp_photo_count_unique"
TBL2="tbl_photo_count_unique"
TBL3="tbl_logo_count_unique"
TBL4="tbl_videos_count_unique"
TBL5="tbl_menu_count_unique"
#TBL6="temp_image_size"
TBL7="tbl_image_size"

#### -------------------------------- Function Define -------------------- ###
function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
else
        echo "Failed"
        echo "${SUBJECT} failed on `date`"  | mail -s "${SUBJECT} failed on `date`" ${EMAIL_ID}
        exit 1
fi
}

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $HNAME"

if [ ! -d /tmp/monthly_content_report ];
then sudo mkdir /tmp/monthly_content_report && sudo chmod -R 777 /tmp/monthly_content_report && sudo chown -R web_backup.web_backup /tmp/monthly_content_report;
else sudo rm -fv /tmp/monthly_content_report/*;sudo chown -R web_backup.web_backup /tmp/monthly_content_report;
fi
CHECK


echo "Creating directory structure on $SR1"
ssh ${SSH_ARGS} web_backup@${SR1} "if [ ! -d /tmp/monthly_content_report ]; then sudo mkdir /tmp/monthly_content_report && sudo chmod -R 777 /tmp/monthly_content_report; else sudo rm -fv /tmp/monthly_content_report/*; fi"
CHECK
##-----------------------------------------------------------------------####
echo "STEP1:Calling sp test.sp_monthly_content_report() on $SR1"
ssh ${SSH_ARGS} web_backup@${SR1}  "sudo mysql -Bse 'call test.sp_monthly_content_report();'"
CHECK

for i in $TBL2 $TBL3  $TBL4 $TBL5 $TBL7
do 
echo "STEP2:Transferring table $i from $SR1 to $HNAME"
ssh ${SSH_ARGS} web_backup@$SR1  "sudo mysqldump -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} test ${i} | gzip -fv > /tmp/monthly_content_report/${i}.sql.gz"
CHECK

echo "Transferring $i to $HNAME"
scp web_backup@${SR1}:/tmp/monthly_content_report/${i}.sql.gz /tmp/monthly_content_report/
CHECK

echo "Gunzipping ${i} on ${HNAME}"
sudo gunzip -f /tmp/monthly_content_report/${i}.sql.gz
CHECK

echo "Restoring ${i} on ${HNAME}"
sudo mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} db_reports < /tmp/monthly_content_report/${i}.sql
CHECK

done

echo "Calling SP db_reports.Sp_monthly_content_report()"
sudo mysql -Bse "CALL db_reports.Sp_monthly_content_report();"
CHECK

##-------------------------------------------------------------------------------####
echo "Process monthly_content_report Successfully completed on ${HNAME}"

echo "Sending Success Mail"
echo "${SUBJECT} completed successfully ${HNAME} on '$DATE'" | mail -s "${SUBJECT} Success" ${EMAIL_ID}
echo "DONE"
exit 0

