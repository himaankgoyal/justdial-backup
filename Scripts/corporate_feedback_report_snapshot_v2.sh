#!/bin/bash

### Variable Define ###
DATE=`date +%d-%m-%Y`
EMAILIDS="anirudh.mathur@justdial.com,mahendra.seth2@justdial.com,rakesh.s1@justdial.com,dbteam_mis@justdial.com,nitesh.nimbalkar1@justdial.com"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
SUBJECT="CorporateFeedback Report Snapshot"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"
HNAME=$(hostname | cut -d. -f1)

DISABLE_LOG_NL_SRV="SET sql_log_bin = 0;"
ENABLE_LOG_NL_SRV="SET sql_log_bin = 1;"

### Function Define ###

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
else
        echo "Failed"
        echo "${SUBJECT} Failed on ${HNAME} " | mail -s "${SUBJECT}" -a /var/log/daily_log/corporate_feedback_report_snapshot.log ${EMAILIDS}
        exit 1
fi
}

### Main Body ###
CITY="mumbai delhi kolkata bangalore chennai pune hyderabad ahmedabad remote"

for CITYNAME in $CITY

do
case $CITYNAME in

mumbai) CITYID=192.168.39.56
        CT="mumbai"
;;

delhi) CITYID=192.168.39.56
       CT="delhi"
;;

kolkata) CITYID=192.168.39.56
         CT="kolkata"
;;

bangalore) CITYID=192.168.39.56
           CT="bangalore"
;;

chennai) CITYID=192.168.39.56
         CT="chennai"
;;

pune)   CITYID=192.168.39.56
        CT="pune"
;;

hyderabad) CITYID=192.168.39.56
           CT="hyderabad"
;;

ahmedabad) CITYID=192.168.39.56
           CT="ahmedabad"
;;


remote) CITYID=192.168.39.56
        CT="rcity"
        CTT="remote"
;;

esac

echo "Calling SP Sp_Corporate_Feedback_Report_Snapshot on ${CITYID}"
ssh  ${SSH_ARGS} web_backup@${CITYID} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin=0;  CALL db_jd_deductioninfo_${CT}.Sp_Corporate_Feedback_Report_Snapshot(); SET sql_log_bin=1 ;'"
CHECK

echo "Taking dump of table temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${CITYID}"
ssh  ${SSH_ARGS} web_backup@${CITYID} "sudo mysqldump --set-gtid-purged=OFF -h${MYHST} -u${MYUSR} -p${PASS} db_jd_deductioninfo_${CT} temp_SearchFeedBackDetails_Pan_India_snapshot_small > /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql"
CHECK

echo "Zip table temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${CITYID}"
ssh  ${SSH_ARGS} web_backup@${CITYID} "sudo gzip -fv /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql"
CHECK

echo "Transferring table temp_SearchFeedBackDetails_Pan_India_snapshot_small from ${CITYID} to ${HNAME}"
scp ${SSH_ARGS} web_backup@${CITYID}:/var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql.gz  /var/tmp/
CHECK

echo "Deleting table dump of temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${CITYID}"
ssh -t ${SSH_ARGS} web_backup@${CITYID} "sudo rm -fv /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql.gz"
CHECK

echo "Gunzipping table temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME}"
sudo gunzip -fv /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql.gz
CHECK

##### New Requirement MahendraSeth1 #####
if [ ${CT} = 'rcity' ];then

echo "Appending city name on temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME}"
sudo sed -i "s/temp_SearchFeedBackDetails_Pan_India_snapshot_small/temp_SearchFeedBackDetails_Pan_India_snapshot_small_${CTT}/g" /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

echo "Replace utf8mb4 to utf8 in temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME} [ Mysql Version Mismatch ]" 
sed -i 's/utf8mb4/utf8/g'  /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

else

echo "Appending city name on temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME}"
sudo sed -i "s/temp_SearchFeedBackDetails_Pan_India_snapshot_small/temp_SearchFeedBackDetails_Pan_India_snapshot_small_${CT}/g" /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

echo "Replace utf8mb4 to utf8 in temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME} [ Mysql Version Mismatch ]" 
sed -i 's/utf8mb4/utf8/g'  /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

fi

echo "Restoring Table temp_SearchFeedBackDetails_Pan_India_snapshot_small on ${HNAME}"
sudo mysql db_reports < /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

echo "Deleting table temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql from ${HNAME}"
sudo rm -fv /var/tmp/temp_SearchFeedBackDetails_Pan_India_snapshot_small.sql
CHECK

done

#############nitesh_requirement#############

echo " Transferring table  temp_blank_data_city_corporate_remote_tbd from 192.168.39.56 to 192.168.12.219"
ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo rm -rfv /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz"
ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysqldump --set-gtid-purged=OFF db_jd_deductioninfo_rcity temp_blank_data_city_corporate_remote_tbd | gzip -fv > /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz"
CHECK

echo "Transferring table  temp_blank_data_city_corporate_remote_tbd to 192.168.12.219"
ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo scp /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz web_backup@192.168.12.219:/tmp/"
CHECK


############due to ssh issue on 81 34 we are calling function 39 56 for 12 210 ssh ####

ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo sh /scripts/CorporateFeedback_Report_Snapshot.sh "
CHECK



ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo gunzip -f /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz"
CHECK

ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysql db_jd_deductioninfo_rcity < /tmp/temp_blank_data_city_corporate_remote_tbd.sql && sudo rm -fv /tmp/temp_blank_data_city_corporate_remote_tbd.sql"
CHECK

ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysqldump --set-gtid-purged=OFF db_jd_deductioninfo_rcity temp_blank_data_city_corporate_remote_tbd | gzip -fv > /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz"
CHECK

ssh -q ${SSH_ARGS} web_backup@192.168.39.56 "sudo scp /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz web_backup@172.29.81.34:/tmp/"
CHECK

echo "Restoring  temp_blank_data_city_corporate_remote_tbd on 172.29.81.34"
sudo gunzip -f /tmp/temp_blank_data_city_corporate_remote_tbd.sql.gz
CHECK

sudo sed -i 's/utf8mb4/utf8/g' /tmp/temp_blank_data_city_corporate_remote_tbd.sql
CHECK

sudo mysql  test < /tmp/temp_blank_data_city_corporate_remote_tbd.sql 
CHECK

sudo rm -fv /tmp/temp_blank_data_city_corporate_remote_tbd.sql
CHECK


echo "Calling SP Sp_Pan_India_Data_Dump on ${HNAME}"
sudo mysql -Bse "CALL db_reports.Sp_Pan_India_Data_Dump_New();"
CHECK

echo "Sending Success Mail"
echo "${SUBJECT} completed successfully on ${HNAME}"  | mail -s "${SUBJECT}" ${EMAILIDS}
exit 0
