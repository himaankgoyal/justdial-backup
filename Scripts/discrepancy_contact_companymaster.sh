#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`
EMAIL_ADDRS="dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com,sushmitha.boddu@justdial.com "
#EMAIL_ADDRS="dhakshina.palanisamy@justdial.com,sushmitha.boddu@justdial.com "
SUBJECT="PAN India Discrepancy Cases-Contact numbers Success"
SUCCESS_CONTENT="Success Discrepancy contact companymaster from 12.219:3307 to 39.120 server"

SUBJECT_FAILURE="PAN India Discrepancy Cases-Contact numbers Failure "
FAILURE_CONTENT="Failure Discrepancy contact companymaster from 12.219:3307 to 39.120 server"

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Successfully Completed"
else
        echo "Failed"
        sudo echo -e "${FAILURE_CONTENT}" | sudo mail -a /var/log/daily_log/discrepancy_contact_companymaster.log -s "${SUBJECT_FAILURE}" ${EMAIL_ADDRS}
        exit 0
fi
}

SUCCESS () {
if [ $? -eq 0 ]; then
        echo "${SUCCESS_CONTENT} completed on `date`"
        echo "Success Discrepancy contact companymaster from 12.219:3307 to 39.120 server" | mail -s "${SUCCESS_CONTENT} process completed" ${EMAIL_ADDRS}
fi
}

if [ -f /tmp/temp_phone_summary_panindia.sql.gz ]; then sudo rm -fv /tmp/temp_phone_summary_panindia.sql.gz; else echo "file exists"; fi
if [ -f /tmp/temp_phone_data_panindia_nor.sql.gz ]; then sudo rm -fv /tmp/temp_phone_data_panindia_nor.sql.gz; else echo "file exists"; fi

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "if [ -f /tmp/temp_phone_summary_panindia.sql ]; then sudo rm -fv /tmp/temp_phone_summary_panindia.sql; else echo "file exists"; fi"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "if [ -f /tmp/temp_phone_data_panindia_nor.sql ]; then sudo rm -fv /tmp/temp_phone_data_panindia_nor.sql; else echo "file exists"; fi"


echo "------------ Step1 ------------"

echo -e "Running ${SUBJECT} process on `date`"

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20contacts%20companymaster&ProcessOwner=10104434&Flag=start > /var/log/daily_log/discrepancy_contact_companymaster_status.log 2>&1

echo "Step2: Calling SP sp_discrepancy_contacts_raw on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_contacts_raw();"
CHECK

echo "Step2.1: Removal of Existing files in tmp directory"

if [ -f /tmp/awk_normalize_phone_data_nonremote.txt ]; then sudo rm -fv /tmp/awk_normalize_phone_data_nonremote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/awk_normalize_phone_data_remote.txt ]; then sudo rm -fv /tmp/awk_normalize_phone_data_remote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/final_awk_normalize_phone_data_nonremote.txt ]; then sudo rm -fv /tmp/final_awk_normalize_phone_data_nonremote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/final_awk_normalize_phone_data_remote.txt ]; then sudo rm -fv /tmp/final_awk_normalize_phone_data_remote.txt ; else echo "file is not there" ; fi

echo "Step 3: Run Queries in 192.168.12.219 for port 3307"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "SELECT * INTO OUTFILE '/tmp/awk_normalize_phone_data_nonremote.txt' FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' FROM dbteam_temp.temp_phone_data_nonremote;"
CHECK

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "SELECT * INTO OUTFILE '/tmp/awk_normalize_phone_data_remote.txt' FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' FROM dbteam_temp.temp_phone_data_remote;"
CHECK

echo "Step 4: Calling awk Job in tmp directory"
 
sudo awk -F"|" '{ split($2,city,","); for (var in city){ print $1"|"city[var]"|"$3"|"$4"|"$5"|"$6"|"$7 } }' /tmp/awk_normalize_phone_data_nonremote.txt > /tmp/final_awk_normalize_phone_data_nonremote.txt;

sudo awk -F"|" '{ split($2,city,","); for (var in city){ print $1"|"city[var]"|"$3"|"$4"|"$5"|"$6"|"$7 } }' /tmp/awk_normalize_phone_data_remote.txt > /tmp/final_awk_normalize_phone_data_remote.txt;

echo "Step5: Calling SP sp_discrepancy_contacts_tablecreation on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_contacts_tablecreation();"
CHECK

echo "Step 6: Run queries in 12.219 for port 3307"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "LOAD DATA INFILE '/tmp/final_awk_normalize_phone_data_nonremote.txt' into table dbteam_temp.temp_phone_data_nonremote_nor fields terminated by '\|' enclosed by '\"'(docid,phone,stdcode,source,tag);"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "LOAD DATA INFILE '/tmp/final_awk_normalize_phone_data_remote.txt' into table dbteam_temp.temp_phone_data_remote_nor fields terminated by '\|' enclosed by '\"'(docid,phone,stdcode,source,tag);"

echo "Step 7: Running Update queries in 12.219 for port 3307"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "insert into test.temp_phone_summary_clause4(docid,phone,source,Tag,clause,clause_name) select docid,phone,source,Tag,'clause 4','Landline starting not 2_7' as clause_name from dbteam_temp.temp_phone_data_nonremote_nor where tag in ('Landline Number','Landline Display Number') and left(phone,1) not in ('2','3','4','5','6','7');"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "insert into test.temp_phone_summary_clause4(docid,phone,source,Tag,clause,clause_name) select docid,phone,source,Tag,'clause 4','Landline starting not 2_7' as clause_name from dbteam_temp.temp_phone_data_remote_nor where tag in ('Landline Number','Landline Display Number') and left(phone,1) not in ('2','3','4','5','6','7');"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "update dbteam_temp.temp_phone_data_remote_nor set phone=concat(stdcode,phone) where tag in ('Landline Number','Landline Display Number');"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "update dbteam_temp.temp_phone_data_remote_nor set phone=TRIM(LEADING '0' FROM phone);"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "update dbteam_temp.temp_phone_data_nonremote_nor set phone=concat(stdcode,phone) where tag in ('Landline Number','Landline Display Number');"

sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -u'process_auto' -p'gr8exp9master' -Bse "update dbteam_temp.temp_phone_data_nonremote_nor set phone=TRIM(LEADING '0' FROM phone);"

echo "Step8: Calling SP sp_discrepancy_contacts_report on 192.168.12.219 for port 3307"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_contacts_report();"
CHECK


echo "call db_reports.sp_discrepancy_contacts_report_extracolumn();"

sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_contacts_report_extracolumn();"
CHECK

echo "Step9: Taking mysqldump of table temp_phone_summary_nonremote and temp_phone_summary_remote"

sudo mysqldump -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 test temp_phone_summary_panindia > /tmp/temp_phone_summary_panindia.sql && sudo gzip /tmp/temp_phone_summary_panindia.sql
CHECK

sudo mysqldump -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 test temp_phone_data_panindia_nor > /tmp/temp_phone_data_panindia_nor.sql && sudo gzip /tmp/temp_phone_data_panindia_nor.sql
CHECK

echo "Transferring table temp_phone_summary_nonremote and temp_phone_summary_remote from 12.219 to 39.120"

sudo scp /tmp/temp_phone_summary_panindia.sql.gz web_backup@192.168.39.120:/tmp
CHECK
sudo scp /tmp/temp_phone_data_panindia_nor.sql.gz web_backup@192.168.39.120:/tmp
CHECK
 
echo "Uncompressing files on 192.168.39.120"

ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_phone_summary_panindia.sql.gz"
CHECK
ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_phone_data_panindia_nor.sql.gz"
CHECK

echo "Restoring table under test database on 39.120"
 
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise  < /tmp/temp_phone_summary_panindia.sql"
CHECK
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise < /tmp/temp_phone_data_panindia_nor.sql"
CHECK

echo "Step10: Calling sp on 39.120"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' -Bse \"call db_reports.sp_discrepancy_contacts_report();\""

###############Removing text files#####################
echo "Removing text files"
if [ -f /tmp/awk_normalize_phone_data_nonremote.txt ]; then sudo rm -fv /tmp/awk_normalize_phone_data_nonremote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/awk_normalize_phone_data_remote.txt ]; then sudo rm -fv /tmp/awk_normalize_phone_data_remote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/final_awk_normalize_phone_data_nonremote.txt ]; then sudo rm -fv /tmp/final_awk_normalize_phone_data_nonremote.txt ; else echo "file is not there" ; fi
if [ -f /tmp/final_awk_normalize_phone_data_remote.txt ]; then sudo rm -fv /tmp/final_awk_normalize_phone_data_remote.txt ; else echo "file is not there" ; fi


echo "Step11: Running curl call on 192.168.12.219 server"
/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20contacts%20companymaster&ProcessOwner=10104434&Flag=end >> /var/log/daily_log/discrepancy_contact_companymaster_status.log 2>&1
CHECK

echo "Step11: Running curl call on 192.168.12.219 server"
/usr/bin/curl 'http://192.168.12.219:88/rating_dir/estate_agent/discrepancy_contact_companymaster.php' >> /var/log/daily_log/discrepancy_contact_companymaster_status.log 2>&1
CHECK

SUCCESS
