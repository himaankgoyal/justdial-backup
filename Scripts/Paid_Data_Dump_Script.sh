#! /bin/bash 

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
EMAIL_ID="rahul.dhakad@justdial.com,pravinkumar.yadav@justdial.com,ketaki.choudhary@justdial.com,boddu.susmitha@justdial.com,himaank.goyal@justdial.com"
HNAME="$(hostname | cut -d. -f1)"
SUBJECT="Paid_Data_Dump_Script"
CITYDGT=$(/sbin/ip route | grep src |awk '{print $9}'| cut -d. -f3|head -1)
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
date=`date +%d-%m-%Y`
remote="192.168.12.40"
remote2="172.29.64.26"
#remote3="172.29.0.218"

SERIP=`/sbin/ifconfig $DEFAULT_INTERFACE | grep "inet" | awk '{ print $2 }' | cut -d ":" -f 2 | head -n1`
TBL1="temp_paid_data_dump"
TBL2="temp_paid_img_data_dump"
# ------ Function Define ------ #

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
#        /scripts/standard_sms_sending_script.sh -m " ${SUBJECT} completed sucessfully on 192.168.14.49 " -f /scripts/sms-number_campaign_report.txt
else
        echo "Failed"
	LOGFILE=`tail -n 500 /var/log/daily_log/Paid_Data_Dump_Script.log`
     #   /scripts/standard_sms_sending_script.sh -m " ${SUBJECT} failed on 192.168.14.49 " -f /scripts/sms-number_campaign_report.txt
        ####rahul###echo "VN MIS PROCESS Failed"| mail -a /var/log/daily_log/VN_MIS_PROCESS.log -s "VN MIS PROCESS Failed" ${EMAIL_ID}
	echo -e "${LOGFILE}" | mail  -s "`echo -e \"Paid Data Dump Script Process Failed\nContent-Type: text/plain\"`" ${EMAIL_ID}
        exit 1
fi
}

/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=paid_data_image_process&ProcessOwner=10093484&Flag=start" 

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $HNAME"

if [ ! -d /tmp/Paid_Data_Dump ]; 
then sudo mkdir /tmp/Paid_Data_Dump && sudo chmod -R 777 /tmp/Paid_Data_Dump && sudo chown -R web_backup.web_backup /tmp/Paid_Data_Dump;
else sudo rm -fv /tmp/Paid_Data_Dump/*;sudo chown -R web_backup.web_backup /tmp/Paid_Data_Dump; 
fi
CHECK

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "if [ ! -d /tmp/Paid_Data_Dump/ ]; then sudo mkdir /tmp/Paid_Data_Dump && sudo chmod -R 777 /tmp/Paid_Data_Dump/; else sudo rm -fv /tmp/Paid_Data_Dump/*; fi"
CHECK

echo "Creating directory structure on $remote2"
ssh ${SSH_ARGS} web_backup@${remote2} "if [ ! -d /tmp/Paid_Data_Dump/ ]; then sudo mkdir /tmp/Paid_Data_Dump && sudo chmod -R 777 /tmp/Paid_Data_Dump/; else sudo rm -fv /tmp/Paid_Data_Dump/*; fi"
CHECK

##----------------- creating dir structure ----------------------------######
echo "Step 1: Calling sp db_reports.Sp_paid_data_dump on $HNAME"
sudo mysql -Bse 'Call db_reports.Sp_paid_data_dump();'
CHECK

echo "Taking dump and zipping table ${TBL1} on $HNAME"
sudo mysqldump db_reports ${TBL1} | gzip -fv > /tmp/Paid_Data_Dump/${TBL1}.sql.gz
CHECK

echo "Copying ${TBL1} from $HNAME to $remote"
sudo scp /tmp/Paid_Data_Dump/${TBL1}.sql.gz  `${SSH_ARGS}` web_backup@${remote}:/tmp/Paid_Data_Dump/
CHECK

echo "Unzipping table ${TBL1} on  $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo gunzip -f /tmp/Paid_Data_Dump/${TBL1}.sql.gz"
CHECK

echo "Restoring table ${TBL1} on  $remote in DB test"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysql test < /tmp/Paid_Data_Dump/${TBL1}.sql"
CHECK

##----------------- creating dir structure ----------------------------######

echo "Creating directory structure on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "if [ ! -d /tmp/Paid_Data_Dump/ ]; then sudo mkdir /tmp/Paid_Data_Dump && sudo chmod -R 777 /tmp/Paid_Data_Dump/; else sudo rm -fv /tmp/Paid_Data_Dump/*; fi"
CHECK

echo "Step2 :Calling SP db_product.Sp_paid_data_dump_2() on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysql -Bse 'call db_product.Sp_paid_data_dump_2();'"
CHECK

echo "Taking dump and zipping table ${TBL1} on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysqldump test ${TBL1} | gzip -fv > /tmp/Paid_Data_Dump/${TBL1}.sql.gz"
CHECK


echo "Copying ${TBL1} from $remote to $remote2"
#sudo scp /tmp/Paid_Data_Dump/${TBL1}.sql.gz  `${SSH_ARGS}` web_backup@${remote}:/tmp/Paid_Data_Dump/
ssh ${SSH_ARGS} web_backup@${remote} "sudo scp /tmp/Paid_Data_Dump/${TBL1}.sql.gz `${SSH_ARGS}` web_backup@${remote2}:/tmp/Paid_Data_Dump/"
CHECK

echo "Unzipping table ${TBL1} on  $remote2"
ssh ${SSH_ARGS} web_backup@${remote2} "sudo gunzip -f /tmp/Paid_Data_Dump/${TBL1}.sql.gz"
CHECK

echo "Restoring table ${TBL1} on  $remote2 in DB db_reports"
ssh ${SSH_ARGS} web_backup@${remote2} "sudo mysql db_reports < /tmp/Paid_Data_Dump/${TBL1}.sql"
CHECK

echo "Taking dump and zipping table ${TBL2} on $remote"
ssh ${SSH_ARGS} web_backup@${remote} "sudo mysqldump test ${TBL2} | gzip -fv > /tmp/Paid_Data_Dump/${TBL2}.sql.gz"
CHECK

echo "Copying ${TBL2} from $remote to $remote2"
#sudo scp /tmp/Paid_Data_Dump/${TBL2}.sql.gz  `${SSH_ARGS}` web_backup@${remote}:/tmp/Paid_Data_Dump/
ssh ${SSH_ARGS} web_backup@${remote} "sudo scp /tmp/Paid_Data_Dump/${TBL2}.sql.gz `${SSH_ARGS}` web_backup@${remote2}:/tmp/Paid_Data_Dump/"
CHECK

echo "Unzipping table ${TBL2} on  $remote2"
ssh ${SSH_ARGS} web_backup@${remote2} "sudo gunzip -f /tmp/Paid_Data_Dump/${TBL2}.sql.gz"
CHECK

echo "Restoring table ${TBL2} on  $remote2 in DB db_reports"
ssh ${SSH_ARGS} web_backup@${remote2} "sudo mysql db_reports < /tmp/Paid_Data_Dump/${TBL2}.sql"
CHECK

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=paid_data_image_process&ProcessOwner=10093484&Flag=end

##----------------- creating dir structure ----------------------------######
echo "Process Successfully completed on ${HNAME}"
echo "Sending Success Mail"
echo "${SUBJECT} completed successfully on ${SERIP} on '$date'" | mail -s "${SUBJECT} Success" ${EMAIL_ID}
echo "DONE"
exit 0



