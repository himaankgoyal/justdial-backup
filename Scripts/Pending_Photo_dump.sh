#! /bin/bash 

# Script by : rahul dhakad
# Created from scratch on : <13-07-2018>  Track Ticket No: 
# Technical stake holder : <Nitesh Nimbalkar from rajeev nair team>
# Contact no of technical stake holder : <Nitesh Nimbalkar => 4180>
# Business stake holder : <Rajeev nair>
# Purpose / Description : paid_data_dump
#----------------------------------------------------

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#EMAIL_ID="nitesh.nimbalkar@justdial.com,pravinkumar.yadav@justdial.com,mahendra.seth1@justdial.com"
EMAIL_ID="rahul.dhakad@justdial.com,pravinkumar.yadav@justdial.com,ketaki.choudhary@justdial.com,dbteam_mis@justdial.com,gomathi.pandy@justdial.com,contentspoc@justdial.com,nelsonjeyaraj@justdial.com"
#EMAIL_ID_csv="nitesh.nimbalkar@justdial.com,mumbaidatacontent@justdial.com,dbteam_mis@justdial.com"

#EMAIL_ID="rahul.dhakad@justdial.com,nitesh.nimbalkar@justdial.com"
HNAME="$(hostname | cut -d. -f1)"
SUBJECT="Pending_Photo_dump_Script"
CITYDGT=$(/sbin/ip route | grep src |awk '{print $9}'| cut -d. -f3|head -1)
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
date=`date +%d-%m-%Y`
remote="192.168.17.132"
remote1="172.29.64.26"

SERIP=`/sbin/ifconfig $DEFAULT_INTERFACE | grep "inet" | awk '{ print $2 }' | cut -d ":" -f 2 | head -n1`

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
#        /scripts/standard_sms_sending_script.sh -m " ${SUBJECT} completed sucessfully on 192.168.14.49 " -f /scripts/sms-number_campaign_report.txt
else
        echo "Failed"
	LOGFILE=`tail -n 500 /var/log/daily_log/Pending_Photo_dump_Script.log`
     #   /scripts/standard_sms_sending_script.sh -m " ${SUBJECT} failed on 192.168.14.49 " -f /scripts/sms-number_campaign_report.txt
        ####rahul###echo "VN MIS PROCESS Failed"| mail -a /var/log/daily_log/VN_MIS_PROCESS.log -s "VN MIS PROCESS Failed" ${EMAIL_ID}
	echo -e "${LOGFILE}" | mail  -s "`echo -e \"Pending Photo Dump Script Process Failed\nContent-Type: text/plain\"`" ${EMAIL_ID}
        exit 1
fi
}


##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $HNAME"

if [ ! -d /tmp/Pending_Photo_dump ]; 
then sudo mkdir /tmp/Pending_Photo_dump && sudo chmod -R 777 /tmp/Pending_Photo_dump && sudo chown -R web_backup.web_backup /tmp/Pending_Photo_dump;
else sudo rm -fv /tmp/Pending_Photo_dump/*;sudo chown -R web_backup.web_backup /tmp/Pending_Photo_dump; 
fi
CHECK

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "if [ ! -d /tmp/Pending_Photo_dump/ ]; then sudo mkdir /tmp/Pending_Photo_dump && sudo chmod -R 777 /tmp/Pending_Photo_dump/; else sudo rm -fv /tmp/Pending_Photo_dump/*; fi"
CHECK

echo "Step1 :Calling SP db_reports.Sp_pending_photo_logo_video_menu on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysql -Bse 'call db_reports.Sp_pending_photo_logo_video_menu();'"
CHECK

for i in temp_pending_photos_new temp_pending_videos_new  temp_pending_menu_new temp_pending_logo_new
do 

echo "Taking dump and zipping table ${i} on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysqldump test ${i} | gzip -fv > /tmp/Pending_Photo_dump/${i}.sql.gz"
CHECK

echo "Copying ${i} from $remote to $HNAME"
scp ${SSH_ARGS} web_backup@${remote}:/tmp/Pending_Photo_dump/${i}.sql.gz /tmp/Pending_Photo_dump/
CHECK

echo "Unzipping table ${i} on  $HNAME"
sudo gunzip -f /tmp/Pending_Photo_dump/${i}.sql.gz
CHECK

echo "Restoring table ${TBL1} on $HNAME in DB test"
sudo mysql dbteam_temp < /tmp/Pending_Photo_dump/${i}.sql
CHECK


done

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $remote1"
ssh ${SSH_ARGS} web_backup@${remote1} "if [ ! -d /tmp/Pending_Photo_dump/ ]; then sudo mkdir /tmp/Pending_Photo_dump && sudo chmod -R 777 /tmp/Pending_Photo_dump/; else sudo rm -fv /tmp/Pending_Photo_dump/*; fi"
CHECK

echo "Step 1: Calling sp db_reports.Sp_pending_photos on $HNAME"
sudo mysql -Bse 'Call db_reports.Sp_pending_photos();'
CHECK

for TBL1 in temp_pending_photos_new temp_pending_videos_new  temp_pending_menu_new temp_pending_logo_new
do

echo "Taking dump and zipping table ${TBL1} on $HNAME"
sudo mysqldump dbteam_temp ${TBL1} | gzip -fv > /tmp/Pending_Photo_dump/${TBL1}.sql.gz
CHECK

echo "Copying ${TBL1} from $HNAME to $remote1"
sudo scp /tmp/Pending_Photo_dump/${TBL1}.sql.gz  `${SSH_ARGS}` web_backup@${remote1}:/tmp/Pending_Photo_dump/
CHECK

echo "Unzipping table ${TBL1} on  $remote1"
ssh ${SSH_ARGS} web_backup@${remote1} "sudo gunzip -f /tmp/Pending_Photo_dump/${TBL1}.sql.gz"
CHECK

echo "Restoring table ${TBL1} on  $remote1 in DB db_reports"
ssh ${SSH_ARGS} web_backup@${remote1} "sudo mysql db_reports < /tmp/Pending_Photo_dump/${TBL1}.sql"
CHECK

done

##----------------- creating dir structure ----------------------------######
echo "Process Successfully completed on ${HNAME}"


echo "Sending Success Mail"
echo "${SUBJECT} completed successfully on ${SERIP} on '$date'" | mail -s "${SUBJECT} Success" ${EMAIL_ID}
#echo "${SUBJECT} completed  ${HNAME} on '$date'" | mail -s "${SUBJECT} Success"  -a /var/tmp/high_end_star_hotel_data.csv.zip ${EMAIL_ID_csv}
#/scripts/standard_sms_sending_script.sh -m " ${SUBJECT} completed sucessfully on 192.168.14.49 " -f /scripts/sms-number_campaign_report.txt
echo "DONE"
exit 0
