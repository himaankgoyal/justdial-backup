#!/bin/bash
INFO="
# Script by : PRATIK
# Created from scratch on : 17-08-20 
# Technical stake holder : Nidhi Patel
# Business stake holder : <Optionally name of business stake holder>
# Purpose / Description : Manage Camp Api Report

#modified by Sandip Mandal
#date: 11.01.2023
#----------------------------------------------------
"

DATE=`date +%d-%m-%Y`
EMAILIDS="vivek.jha@justdial.com,maltinegi@justdial.com,dbteam_mis@justdial.com,komal5@justdial.com,bhavna.chalise@justdial.com,ajay.kumar43@justdial.com,kundan.kumar6@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com"
SENDER_EMAIL="dbteam_mis@justdial.com"
#EMAIL="dbteam_mis@justdial.com"
HNAME="$(hostname | cut -d. -f1)"
RMSRV="192.168.12.99"
RMSRV_1="192.168.14.49"
RMSRV_2="192.168.39.81"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
SUBJECT="Manage Camp Api Report"

####### Functions

ERROR () {
if [ $? -ne 0 ]; then
        echo " $SUBJECT process failed on `date`"
        echo -e "$SUBJECT process failed \n\n\n ${INFO}" | mail -a /var/log/daily_log/manage_camp_api.log -s " $SUBJECT failed" -r ${SENDER_EMAIL} ${EMAILIDS}
        /scripts/standard_sms_sending_script.sh -m "Manage Camp Api Report process failed" -f /scripts/sms-number.txt
fi
}
SUCCESS () {
if [ $? -eq 0 ];then

echo " $SUBJECT process success on `date`"
#echo -e "$SUBJECT process success" | mail -a /var/log/daily_log/manage_camp_api.log -s " $SUBJECT success" -r ${SENDER_EMAIL} ${EMAILIDS}
echo -e " $SUBJECT is completed.\n\n\n ${INFO}" | mail -s " $SUBJECT process competed" -r ${SENDER_EMAIL} -a /tmp/manage_camp_api_details_reports.csv -a /tmp/manage_camp_summary_report.csv ${EMAILIDS}
	
fi
}



# ----- Main Body ----- #

echo "Step :- 1 Deleting Existing csv file from  ${HNAME}"
sudo rm -fv /tmp/manage_camp_api_details_reports.csv /tmp/manage_camp_summary_report.csv
ERROR

echo "calling report_log.php start"
/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Manage%20camp%20api%20report&ProcessOwner=10104434&Flag=start" > /dev/null 2>&1
ERROR

echo "Step :- 2 Calling SP() sp_call_type_np on ${RMSRV}"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV} "mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} -Bse 'call  dbteam_temp.sp_call_type_np_new();'"
ERROR

echo "Step :- 3 Taking Dump of temp_manage_camp_api_details on ${RMSRV}"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV} "mysqldump -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} dbteam_temp temp_manage_camp_api_details > /tmp/temp_manage_camp_api_details.sql"
ERROR

echo "Step :- 4 Transfering temp_manage_camp_api_details dump to ${HNAME}"
sudo scp ${SSH_ARGS} web_backup@${RMSRV}:/tmp/temp_manage_camp_api_details.sql /tmp/
ERROR

echo "Step :- 5 Restoring table temp_manage_camp_api_details on ${HNAME}"
sudo mysql db_reports < /tmp/temp_manage_camp_api_details.sql
ERROR

echo "Step :- 6 Deleting Temporary files on ${HNAME} and ${RMSRV}"
sudo rm -fv /tmp/temp_manage_camp_api_details.sql
ERROR

sudo ssh ${SSH_ARGS} web_backup@${RMSRV} "sudo rm -fv /tmp/temp_manage_camp_api_details.sql"
ERROR

echo "Step :- 7 Execiting SP() sp_call_type_source_np on ${HNAME}"
sudo mysql -Bse "call db_reports.sp_call_type_source_np();"
ERROR

echo "Step :- 8 Taking dump of temp_manage_camp_api_details from 12.219 and restoring on ${RMSRV_1}" 
   
echo "Step :- 9 Taking Dump of temp_manage_camp_api_details from ${HNAME}"
sudo mysqldump db_reports temp_manage_camp_api_details > /tmp/temp_manage_camp_api_details.sql
ERROR

echo "Step :- 10 Transfering dump to ${RMSRV_1}"
sudo scp $SSH_ARGS /tmp/temp_manage_camp_api_details.sql web_backup@${RMSRV_1}:/tmp/
ERROR

echo "Step :- 11 Restoring table temp_manage_camp_api_details on ${RMSRV_1}"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_1} "sudo mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD}  dbteam_temp < /tmp/temp_manage_camp_api_details.sql"
ERROR

echo "Step :- 12 Deleting Temporary files on ${HNAME} and ${RMSRV_1}"
sudo rm -fv /tmp/temp_manage_camp_api_details.sql
ERROR

sudo ssh ${SSH_ARGS} web_backup@${RMSRV_1} "sudo rm -fv /tmp/temp_manage_camp_api_details.sql"
ERROR

echo "Step :- 13 Calling sp on ${RMSRV_1}"
sudo ssh  ${SSH_ARGS} web_backup@${RMSRV_1} "sudo mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} -Bse 'call dbteam_temp.sp_dealclose_budget_call_type_np();'"
ERROR

echo "Step :- 14 Taking dump of temp_manage_camp_api_details from ${RMSRV_1} and restoring on ${RMSRV_2}"
echo "Start taking dump on $RMSRV_1"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_1} "sudo mysqldump dbteam_temp temp_manage_camp_api_details > /tmp/temp_manage_camp_api_details.sql"
ERROR

echo "Transfering dump to $RMSRV"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_1} "sudo scp ${SSH_ARGS} /tmp/temp_manage_camp_api_details.sql web_backup@${RMSRV_2}:/tmp/"
ERROR

echo "Restoring table temp_manage_camp_api_details  on ${RMSRV_2}" 
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_2} "sudo mysql  dbteam_temp < /tmp/temp_manage_camp_api_details.sql"
ERROR
   
echo "Deleting Temporary files on ${RMSRV_1} ${RMSRV_2}"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_1} "sudo rm -fv /tmp/temp_manage_camp_api_details.sql"
ERROR

sudo ssh ${SSH_ARGS} web_backup@${RMSRV_2} "sudo rm -fv /tmp/temp_manage_camp_api_details.sql"
ERROR


echo "Executing SP() sp_monthly_ecs_call_type_np on ${RMSRV_2}" 
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_2} "mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} -Bse 'call dbteam_temp.sp_monthly_ecs_call_type_np();'"
ERROR  

echo "Step :- 15 Taking dump of temp_manage_camp_api_details from ${RMSRV_2} and restoring on ${HNAME}"

echo "Start taking dump on ${RMSRV_2}"
sudo ssh ${SSH_ARGS} web_backup@${RMSRV_2} "sudo mysqldump dbteam_temp temp_manage_camp_api_details | gzip -fv > /tmp/temp_manage_camp_api_details.sql.gz"
ERROR

echo "Transfering dump to $HNAME"
sudo scp ${SSH_ARGS} web_backup@${RMSRV_2}:/tmp/temp_manage_camp_api_details.sql.gz /tmp/
ERROR

echo "Unzipping table temp_manage_camp_api_details.sql.gz"
sudo gunzip -fv /tmp/temp_manage_camp_api_details.sql.gz
ERROR

echo "Restoring table temp_manage_camp_api_details.sql on ${HNAME}"
sudo mysql db_reports < /tmp/temp_manage_camp_api_details.sql
ERROR

echo "Deleting Temporary files on ${HNAME} and ${RMSRV_2}"
sudo rm -fv /tmp/temp_manage_camp_api_details.sql
ERROR

sudo ssh ${SSH_ARGS} web_backup@${RMSRV_2} "sudo rm -fv /tmp/temp_manage_camp_api_details.sql.gz"
ERROR

echo "Executing SP() sp_manage_campiagn_report_np on ${HNAME}"
sudo mysql -Bse "call db_reports.sp_manage_campiagn_report_np();"
ERROR

echo "calling report_log.php end"
/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Manage%20camp%20api%20report&ProcessOwner=10104434&Flag=end" > /dev/null 2>&1
ERROR

# ----- Process Complete -------- #
echo " $SUBJECT completed on `date`"
#echo -e " $SUBJECT is completed.\n\n\n ${INFO}" | mail -s " $SUBJECT process competed" -r ${SENDER_EMAIL} -a /tmp/manage_camp_api_details_reports.csv -a /tmp/manage_camp_summary_report.csv ${EMAILIDS} 
SUCCESS

