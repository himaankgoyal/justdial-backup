#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`

EMAIL_ADDRS="dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com,boddu.susmitha@justdial.com"
##EMAIL_ADDRS="boddu.susmitha@justdial.com,dhakshina.palanisamy@justdial.com"

SUBJECT="PAN India Discrepancy Cases-Website Success"
SUCCESS_CONTENT="Success Discrepancy website companymaster from 12.219:3307 to 39.120 server"

SUBJECT_FAILURE="PAN India Discrepancy Cases-Website Failure "
FAILURE_CONTENT="Failure Discrepancy website companymaster from 12.219:3307 to 39.120 server"

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Successfully Completed"
else
        echo "Failed"
        sudo echo -e "${FAILURE_CONTENT}" | sudo mail -a /var/log/daily_log/discrepancy_website_companymaster.log -s "${SUBJECT_FAILURE}" ${EMAIL_ADDRS}
        exit 0
fi
}

function SUCCESS () {
if [ $? -eq 0 ]; then
        echo "${SUCCESS_CONTENT} completed on `date`"
        echo "${SUBJECT}" | mail -s "${SUCCESS_CONTENT} process completed" ${EMAIL_ADDRS}
fi
}

if [ -f /tmp/temp_website_summary_panindia.sql.gz ]; then sudo rm -fv /tmp/temp_website_summary_panindia.sql.gz; else echo "file exists"; fi
if [ -f /tmp/temp_website_data_panindia_nor.sql.gz ]; then sudo rm -fv /tmp/temp_website_data_panindia_nor.sql.gz; else echo "file exists"; fi

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "if [ -f /tmp/temp_website_summary_panindia.sql ]; then sudo rm -fv /tmp/temp_website_summary_panindia.sql; else echo "file exists"; fi"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "if [ -f /tmp/temp_website_data_panindia_nor.sql ]; then sudo rm -fv /tmp/temp_website_data_panindia_nor.sql; else echo "file exists"; fi"


echo "------------ Step1 ------------"

echo -e "Running ${SUBJECT} process on `date`"

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20website%20companymaster&ProcessOwner=10104434&Flag=start  > /var/log/daily_log/discrepancy_website_companymaster.log 2>&1

echo "Step2: Calling SP sp_discrepancy_website_raw on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_website_raw();"
CHECK

echo "Step2.1: Removal of Existing files in tmp directory"

if [ -f /tmp/awk_normalize_website_data_nonremote.txt ]; then sudo rm -fv /tmp/awk_normalize_website_data_nonremote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/final_awk_normalize_website_data_nonremote.txt ]; then sudo rm -fv /tmp/final_awk_normalize_website_data_nonremote.txt ; else echo "file is not there" ; fi

echo "Step 3: Run Queries in 192.168.12.219 for port 3307"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "SELECT * INTO OUTFILE '/tmp/awk_normalize_website_data_nonremote.txt' FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' FROM dbteam_temp.temp_website_data_nonremote;"
CHECK

echo "Step 4: Calling awk Job in tmp directory"
 
awk -F"|" '{ split($2,city,","); for (var in city){ print $1"|"city[var]"|"$3"|"$4"|"$5"|"$6"|"$7 } }' /tmp/awk_normalize_website_data_nonremote.txt > /tmp/final_awk_normalize_website_data_nonremote.txt; 


echo "Step 5: Run the below queries in 12.219 3307 port"

#sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "LOAD DATA INFILE '/tmp/final_awk_normalize_website_data_nonremote.txt' into table dbteam_temp.temp_website_data_nonremote_nor fields terminated by '\|' enclosed by '\"'(docid,website,source,tag);"
sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "LOAD DATA INFILE '/tmp/final_awk_normalize_website_data_nonremote.txt' into table dbteam_temp.temp_website_data_nonremote_nor fields terminated by '\|' enclosed by '\"'(docid,website,parentid,companyname,source,tag);"
CHECK

echo "Step 6: Calling SP sp_discrepancy_website_report on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_website_report();"
CHECK


echo "Step 6.1: Calling SP sp_discrepancy_website_report_extracolumns on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_website_report_extracolumn();"
CHECK




echo "Step7: Taking mysqldump of table temp_website_summary_panindia and temp_website_data_panindia_nor"

sudo mysqldump -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 test temp_website_summary_panindia > /tmp/temp_website_summary_panindia.sql && sudo gzip /tmp/temp_website_summary_panindia.sql
CHECK

sudo mysqldump -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 test temp_website_data_panindia_nor > /tmp/temp_website_data_panindia_nor.sql && sudo gzip /tmp/temp_website_data_panindia_nor.sql
CHECK

echo "Transferring table temp_website_summary_panindia and temp_website_data_panindia_nor from 12.219 to 39.120"

sudo scp /tmp/temp_website_summary_panindia.sql.gz web_backup@192.168.39.120:/tmp
CHECK
sudo scp /tmp/temp_website_data_panindia_nor.sql.gz web_backup@192.168.39.120:/tmp
CHECK

echo "Uncompressing files on 192.168.39.120"

ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_website_summary_panindia.sql.gz"
CHECK
ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_website_data_panindia_nor.sql.gz"
CHECK

echo "Restoring table under amol_pise database on 39.120"

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise < /tmp/temp_website_summary_panindia.sql"
CHECK
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise < /tmp/temp_website_data_panindia_nor.sql"
CHECK


echo "Step 8: Calling SP sp_discrepancy_website_report on 192.168.39.120"

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' -Bse \"call db_reports.sp_discrepancy_website_report();\""
CHECK

echo "Step8.1: Running curl call on 192.168.12.219 server"
/usr/bin/curl 'http://192.168.12.219:88/rating_dir/estate_agent/discrepancy_website_companymaster.php' >> /var/log/daily_log/discrepancy_website_companymaster_status.log 2>&1
CHECK

echo "Step9: Running curl call on 192.168.14.48 server"

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20website%20companymaster&ProcessOwner=10104434&Flag=end >> /var/log/daily_log/discrepancy_website_companymaster.log 2>&1
CHECK

SUCCESS
