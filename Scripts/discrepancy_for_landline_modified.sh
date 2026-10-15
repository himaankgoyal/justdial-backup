#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`
EMAIL_ADDRS="dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com,boddu.susmitha@justdial.com,bharat.tuppad@justdial.com,maltinegi@justdial.com,subhadeep.som@justdial.com"
#EMAIL_ADDRS="boddu.susmitha@justdial.com"
SUBJECT="Discrepancy for landline - clause 11 Success"
SUCCESS_CONTENT="Discrepancy for landline - clause 11 from 12.219:3307"
SUBJECT_FAILURE="Discrepancy for landline - clause 11 Failure "
FAILURE_CONTENT="Failure Discrepancy website companymaster from 12.219:3307 "

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Successfully Completed"
else
        echo "Failed"
        sudo echo -e "${FAILURE_CONTENT}" | sudo mail -a /var/log/daily_log/discrepancy_for_landline.log -s "${SUBJECT_FAILURE}" ${EMAIL_ADDRS}
        exit 0
fi
}

function SUCCESS () {
if [ $? -eq 0 ]; then
        echo "${SUCCESS_CONTENT} completed on `date`"
        echo "${SUBJECT}" | mail -s "${SUCCESS_CONTENT} process completed" ${EMAIL_ADDRS}
fi
}


#############################################

echo "Step1: Calling db_reports.sp_discrepancy_landline_clause11_raw on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_landline_clause11_raw();"
CHECK


echo "Step2: Removal of Existing files in tmp directory"

if [ -f /tmp/temp_landline_data.txt ]; then sudo rm -fv /tmp/temp_landline_data.txt ; else echo "file is not there" ; fi
if [ -f /tmp/temp_landline_data.txt ]; then sudo rm -fv /tmp/temp_landline_data.txt ; else echo "file is not there" ; fi

echo "Step 3: Run Queries in 192.168.12.219 for port 3307"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "SELECT docid,landline,landline_display,stdcode,source INTO OUTFILE '/tmp/temp_landline_data.txt' FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' FROM dbteam_temp.temp_landline_data;"
CHECK

echo "Step 4: Calling awk Job in tmp directory"
 
awk -F"|" '{ split($2,phone,","); for (var in phone){ print $1"|"phone[var]"|"$4"|"$5"|landline"} }' /tmp/temp_landline_data.txt > /tmp/awk_norm_lanline.txt;

awk -F"|" '{ split($3,phone,","); for (var in phone){ print $1"|"phone[var]"|"$4"|"$5"|landline_display"} }' /tmp/temp_landline_data.txt > /tmp/awk_norm_landline_display.txt;


echo "Step 5: Run the below queries in 12.219 3307 port"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "LOAD DATA INFILE '/tmp/awk_norm_lanline.txt' into table dbteam_temp.temp_landline_nor  fields terminated by '\|' enclosed by '\"'(docid,phone,stdcode,source,tag);"
CHECK

echo "Step 5.1: Run the below queries in 12.219 3307 port"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse ";LOAD DATA INFILE '/tmp/awk_norm_landline_display.txt' into table dbteam_temp.temp_landline_display_nor fields terminated by '\|' enclosed by '\"'(docid,phone,stdcode,source,tag);"
CHECK

echo "Step 6: Execute SP on 12.219(3307) sp_discrepancy_landline_clause11_report"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse  "call db_reports.sp_discrepancy_landline_clause11_report();"
CHECK

echo "Step 7: Transfer table dbteam_temp.temp_landline_raw_report  (12.219:3307) TO 192.168.39.120 (amol_pise)"

sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' dbteam_temp temp_landline_raw_report > /tmp/temp_landline_raw_report.sql && sudo gzip /tmp/temp_landline_raw_report.sql
CHECK

echo "Transferring table temp_landline_raw_report from 12.219 to 39.120"

sudo scp /tmp/temp_landline_raw_report.sql.gz web_backup@192.168.39.120:/tmp
CHECK

echo "Uncompressing files on 192.168.39.120"

ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_landline_raw_report.sql.gz"
CHECK


echo "Restoring table under amol_pise database on 39.120"

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise < /tmp/temp_landline_raw_report.sql"
CHECK

echo "Removing /tmp/temp_landline_raw_report.sql from 39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/temp_landline_raw_report.sql"
CHECK

echo "Removing /tmp/temp_landline_raw_report.sql from 12.219"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_landline_raw_report.sql.gz"
CHECK


echo "Step 8: Calling SP db_reports.sp_discrepancy_landline_clause11_report on 192.168.39.120"

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' -Bse \"call db_reports.sp_discrepancy_landline_clause11_report();\""
CHECK

################################################################################################################################

step=9
echo "Step=$step"
echo "Step1: Calling db_reports.sp_discrepancy_blank_contactnumber_daily on 192.168.12.219 for port 3307"
sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_landline_clause11_raw();"
CHECK

step=10
echo "Step=$step"
echo "Step 2: Taking dump on 12.219:3307(dbteam_temp) to 12.80(db_reports)"
sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp temp_discrepancy_blank_contactnumber > /tmp/temp_discrepancy_blank_contactnumber.sql && sudo gzip /tmp/temp_discrepancy_blank_contactnumber.sql
CHECK

echo "Transferring table temp_discrepancy_blank_contactnumber from 12.219 to 12.80"
sudo scp /tmp/temp_discrepancy_blank_contactnumber.sql.gz web_backup@192.168.12.80:/tmp
CHECK

echo "Uncompressing files on 192.168.12.80"
ssh ${SSH_ARGS} web_backup@192.168.12.80 "sudo gunzip /tmp/temp_discrepancy_blank_contactnumber.sql.gz"
CHECK

echo "Restoring table under db_reports database on 12.80"
sudo ssh ${SSH_ARGS} web_backup@192.168.12.80 "sudo mysql db_reports < /tmp/temp_discrepancy_blank_contactnumber.sql"
CHECK

echo "Removing /tmp/temp_discrepancy_blank_contactnumber.sql from 12.80"
ssh ${SSH_ARG} web_backup@192.168.12.80 "sudo rm -fv /tmp/temp_discrepancy_blank_contactnumber.sql"
CHECK

echo "Removing /tmp/temp_discrepancy_blank_contactnumber.sql from 12.219"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_discrepancy_blank_contactnumber.sql.gz"
CHECK

step=11
echo "Step=$step"
echo "Step 3: Running update query on 12.80:3306"
ssh ${SSH_ARGS} web_backup@192.168.12.80 'sudo mysql -e "update db_reports.temp_discrepancy_blank_contactnumber a join db_data_farm.temp_paid_listing_consolidate b on a.docid=b.docid set a.paid=b.paid_flag;'"


step=12
echo "Step=$step"
echo "Step 3: Taking dump on 12.80:3306"
ssh ${SSH_ARGS} web_backup@192.168.12.80 "sudo mysqldump db_reports temp_discrepancy_blank_contactnumber > /tmp/temp_discrepancy_blank_contactnumber.sql

echo "Transferring table temp_discrepancy_blank_contactnumber from 12.80 to 39.120
sudo ssh ${SSH_ARGS} web_backup@192.168.12.80 "sudo scp /tmp/temp_discrepancy_blank_contactnumber.sql.gz web_backup@192.168.39.120:/tmp"
CHECK

echo "Uncompressing files on 192.168.39.120"
ssh ${SSH_ARGS} web_backup@192.168.39.120  sudo gunzip /tmp/temp_discrepancy_blank_contactnumber.sql.gz"
CHECK

echo "Restoring table under amol_pise database on 39.120"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql amol_pise < /tmp/temp_discrepancy_blank_contactnumber.sql"
CHECK

echo "Removing /tmp/temp_discrepancy_blank_contactnumber.sql from 12.80"
ssh ${SSH_ARG} web_backup@192.168.12.80 "sudo rm -fv /tmp/temp_discrepancy_blank_contactnumber.sql"
CHECK

echo "Removing /tmp/temp_discrepancy_blank_contactnumber.sql from 39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/temp_discrepancy_blank_contactnumber.sql.gz"
CHECK

step=13
echo "Step=$step"
echo "Step 5: Calling db_reports.sp_discrepancy_blank_contactnumber_daily on 192.168.39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 'sudo mysql -Bse "call db_reports.sp_discrepancy_blank_contactnumber_daily();"'
CHECK


SUCCESS
