#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EMAIL="dbteam_mis@justdial.com,kundan.kumar6@justdial.com,bhavna.chalise@justdial.com,mahendra.seth2@justdial.com"
CCEMAIL="vivek.jha@justdial.com,nishantjain@justdial.com,kuldeep.jaiswal@justdial.com,kundan.kumar6@justdial.com,tahzeeb@justdial.com,sandhyavedavyas@justdial.com,rituranjanrawat@justdial.com"
#EMAIL="srinivasnarasimhalu@justdial.com"
LB_user=$(cat /scripts/.load_autimation.txt | grep -i "Load_user" | awk '{print $3}')
LB_pass=$(cat /scripts/.load_autimation.txt | grep -i "Load_pass" | awk '{print $3}')
LB_IP="192.168.20.210"
MGTID=$(mysql -u ${LB_user} -p${LB_pass} -h ${LB_IP} -Bse "show variables like '%report_host%';" 2>/dev/null  | awk '{ print $2 }')
echo "load balancer IP ==  ${LB_IP}"
echo ""
echo "master server IP ==  ${MGTID}"
MYUSR="xxx"
PASS="xxx"
MYHST="xxx"

function CHECK(){
        if [ $? -ne 0 ]
        then
                echo "jdmart data block provision process FAILED" | mail -s " jdmart data block provision process FAILED" -a /var/log/daily_log/sp_jdmart_data_block_provision_process.log -c ${CCEMAIL} ${EMAIL}
                #echo -e "jdmart data block provision process FAILED" | mail -s "Dealclosed details script FAILED on 192.168.14.49" $EMAIL
                exit 1
        fi

}

function SUCCESS(){
        if [ $? -eq 0 ]
        then
		echo "PROCESS completed successfully, sending mail"
                mysql -e "SELECT * FROM db_reports.tbl_jdmart_signup_data_record where create_date=CURDATE();" > /tmp/tbl_jdmart_signup_data_record.csv
                echo -e "jdmart data block provision process SUCCESS" | mail -s "jdmart data block provision process completed successfully"  -a /tmp/tbl_jdmart_signup_data_record.csv ${EMAIL} -c ${CCEMAIL}
               exit 0
        fi
}

##Before starting process calling api 

echo "Calling start api report_log.php on 192.168.14.48"
ssh $SSH_ARGS -q web_backup@192.168.14.48 "sudo /bin/curl 192.168.14.48:8000/report_log.php?ProcessName=Jd%20Mart%20Block%20Provision&ProcessOwner=10107063&Flag=start"
CHECK



# -------------------------------------- Main Process Started --------------------------------------------------------
echo "process starting"
sudo /bin/curl  "http://192.168.14.48:8000/report_log.php?ProcessName=Jd%20Mart%20Block%20Provision&ProcessOwner=10107063&Flag=start"

echo "step 1: Dump Table online_regis1.tbl_jd_mart_hot_data from 192.168.20.210 to 192.168.12.80:3306"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "sudo mysqldump -u ${MYUSR} -p${PASS} online_regis1 tbl_jd_mart_hot_data | gzip -fv > /tmp/tbl_jd_mart_hot_data.sql.gz";
CHECK

echo "step:1.1 Transferring table tbl_jd_mart_hot_data from 192.168.20.210 to 12.80"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "sudo scp ${SSH_ARGS} /tmp/tbl_jd_mart_hot_data.sql.gz  web_backup@192.168.12.80:/tmp"
CHECK

echo "step 1.2: Restore table tbl_jd_mart_hot_data on 12.80"
cd /tmp/ && sudo gunzip -f tbl_jd_mart_hot_data.sql.gz && sudo mysql -u ${MYUSR} -p${PASS} db_reports < /tmp/tbl_jd_mart_hot_data.sql
CHECK

echo "step 1.3: Delete Temporary tables on 12.80"
sudo rm -fv /tmp/tbl_jd_mart_hot_data.sql
CHECK

echo "step 1.4: Delete Temporary tables on 20.210"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "sudo rm -fv /tmp/tbl_jd_mart_hot_data.sql.gz"
CHECK

echo "step 2: Calling SP test.sp_jdmart_jda_flag_data on 14.48"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo mysql -u ${MYUSR} -p${PASS} -e 'CALL test.sp_jdmart_jda_flag_data()';"
CHECK

echo "step 3: Dump Table test.temp_jdmart_data from 14.48 to 192.168.12.80:3306"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo mysqldump -u ${MYUSR} -p${PASS} test temp_jdmart_data | gzip -fv > /tmp/temp_jdmart_data.sql.gz";
CHECK

echo "step:3.1 Transferring table test.temp_jdmart_data from 14.48 to 192.168.12.80:3306"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo scp ${SSH_ARGS} /tmp/temp_jdmart_data.sql.gz  web_backup@192.168.12.80:/tmp"
CHECK

echo "step 3.2: Restore table temp_jdmart_data on 12.80"
cd /tmp/ && sudo gunzip -f temp_jdmart_data.sql.gz && sudo mysql -u ${MYUSR} -p${PASS} db_reports < /tmp/temp_jdmart_data.sql
CHECK

echo "step 3.3: Delete Temporary tables on 12.80"
sudo rm -fv /tmp/temp_jdmart_data.sql
CHECK

echo "step 3.4: Delete Temporary tables on 20.210"
sudo ssh ${SSH_ARGS} web_backup@192.168.14.48 "sudo rm -fv /tmp/temp_jdmart_data.sql.gz"
CHECK

echo "step 4.1: Calling SP db_reports.sp_create_jdmarts_detail_table on 12.80"
mysql -u ${MYUSR} -p${PASS} -e 'CALL db_reports.sp_create_jdmarts_detail_table();'
CHECK

echo "step 4.2: Calling SP db_reports.sp_update_jdmarts_detail_panindia_signup on 12.80"
mysql -u ${MYUSR} -p${PASS} -e 'call db_reports.sp_update_jdmarts_detail_panindia_signup();'
CHECK

echo "step 5: Calling SP db_reports.sp_add_live_jdmart_hot_data on 12.80"
mysql -u ${MYUSR} -p${PASS} -e 'call db_reports.sp_add_live_jdmart_hot_data();'
CHECK

echo " step 6: Dump Table  db_reports.temp_jdmart_signup_data  from (192.168.12.80:3306)(test database) to 192.168.20.210 test database"

echo "step 6.1: Dump Table db_reports.temp_jdmart_signup_data on 192.168.12.80:3306"
sudo mysqldump -u ${MYUSR} -p${PASS} db_reports temp_jdmart_signup_data | gzip -fv > /tmp/temp_jdmart_signup_data.sql.gz;
CHECK

echo "step:6.2 Transferring table temp_jdmart_signup_data to 20.210"
sudo scp ${SSH_ARGS} /tmp/temp_jdmart_signup_data.sql.gz  web_backup@${MGTID}:/tmp
CHECK

echo "step 6.3: Restore table temp_jdmart_signup_data on 17.235"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "cd /tmp/ && sudo gunzip -f temp_jdmart_signup_data.sql.gz && sudo mysql -u ${MYUSR} -p${PASS} test < /tmp/temp_jdmart_signup_data.sql"
CHECK

echo "step 6.4: Delete Temporary tables on 12.80"
sudo rm -fv /tmp/temp_jdmart_signup_data.sql.gz
CHECK

echo "step 6.5: Delete Temporary tables on 20.210"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "sudo rm -fv /tmp/temp_jdmart_signup_data.sql"
CHECK


echo "step 7: CALL online_regis1.sp_add_live_jdmart_hot_data(); - 192.168.20.210 online_regis1 database"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} " sudo mysql -u ${MYUSR} -p${PASS} -e 'CALL online_regis1.sp_add_live_jdmart_hot_data()';"
CHECK

echo "Step 8: Taking dump and scp table from 17.235 online_regis1.tbl_jd_mart_new_cont_data  to 192.168.12.80:3306"
ssh $SSH_ARGS -q web_backup@192.168.17.235 "sudo mysqldump online_regis1 tbl_jd_mart_new_cont_data | gzip -fv > /tmp/tbl_jd_mart_new_cont_data.sql.gz  && scp /tmp/tbl_jd_mart_new_cont_data.sql.gz web_backup@192.168.12.80:/tmp/"
CHECK

echo  "step 8.1: gunzip and restoring table  on 12.80"
sudo gunzip -fv /tmp/tbl_jd_mart_new_cont_data.sql.gz && sudo mysql db_reports < /tmp/tbl_jd_mart_new_cont_data.sql && sudo gzip -fv /tmp/tbl_jd_mart_new_cont_data.sql
CHECK

echo "Step 9: calling Two sp db_reports.sp_create_jdmarts_detail_table_rajprocess() and db_reports.sp_update_jdmarts_detail_panindia_signup() on 192.168.12.80"
sudo mysql -Bse 'call db_reports.sp_create_jdmarts_detail_table_rajprocess();' && sudo mysql -Bse 'call db_reports.sp_update_jdmarts_detail_panindia_signup();'
CHECK

echo "Step 10: calling sp db_reports.sp_add_live_jdmart_hot_data() on 192.168.12.80"
sudo mysql -Bse 'call db_reports.sp_add_live_jdmart_hot_data();'
CHECK



echo "Step 11: Taking dump and scp table from 12.80:3306 test.temp_jdmart_signup_data  to 192.168.20.210:3306"
sudo mysqldump db_reports temp_jdmart_signup_data | gzip -fv > /tmp/temp_jdmart_signup_data.sql.gz  && scp /tmp/temp_jdmart_signup_data.sql.gz web_backup@192.168.17.235:/tmp/
CHECK

echo  "step 11.1: gunzip and restoring table  on 20.210"
ssh $SSH_ARGS -q web_backup@192.168.17.235 "sudo gunzip -fv /tmp/temp_jdmart_signup_data.sql.gz && sudo mysql dbteam_temp < /tmp/temp_jdmart_signup_data.sql && sudo gzip -fv /tmp/temp_jdmart_signup_data.sql"
CHECK

echo "Step 12: calling sp online_regis1.sp_add_live_jdmart_hot_data() on 192.168.20.210"
ssh $SSH_ARGS -q web_backup@192.168.17.235 "sudo mysql -Bse 'call online_regis1.sp_add_live_jdmart_hot_data();'"
CHECK


echo "Calling End api report_log.php on 192.168.14.48"
#ssh $SSH_ARGS -q web_backup@192.168.14.48 "sudo /bin/curl 192.168.14.48:8000/report_log.php?ProcessName=Jd%20Mart%20Block%20Provision&ProcessOwner=10107063&Flag=end"
sudo /bin/curl  "http://192.168.14.48:8000/report_log.php?ProcessName=Jd%20Mart%20Block%20Provision&ProcessOwner=10107063&Flag=end"
CHECK


SUCCESS
echo "All process completed"


