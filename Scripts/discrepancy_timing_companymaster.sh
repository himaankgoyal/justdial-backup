#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`

##EMAIL_ADDRS="dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com,amol.pise@justdial.com,boddu.susmitha@justdial.com"
##EMAIL_ADDRS="dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,kundam.kumar6@justdial.com,boddu.susmitha@justdial.com"
EMAIL_ADDRS="dhakshina.palanisamy@justdial.com,pavan.r3@justdial.com"

SUBJECT="PAN India Discrepancy Cases–Timings Success"
SUCCESS_CONTENT="Success PAN India Discrepancy Cases – Timings from 12.219:3307 to 39.120 server"

SUBJECT_FAILURE="PAN India Discrepancy Cases-Timings Failure "
FAILURE_CONTENT="Failure PAN India Discrepancy Cases – Timings from  12.219:3307 to 39.120 server"

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Successfully Completed"
else
        echo "Failed"
        sudo echo -e "${FAILURE_CONTENT}" | sudo mail -a /var/log/daily_log/discrepancy_timing_companymaster.log -s "${SUBJECT_FAILURE}" ${EMAIL_ADDRS}
        exit 0
fi
}

function SUCCESS () {
if [ $? -eq 0 ]; then
        echo "${SUCCESS_CONTENT} completed on `date`"
        echo "${SUBJECT}" | mail -s "${SUCCESS_CONTENT} process completed" ${EMAIL_ADDRS}
fi
}

if [ -f /tmp/temp_timing_summary_panindia.sql.gz ]; then sudo rm -fv /tmp/temp_timing_summary_panindia.sql.gz; else echo "file exists"; fi

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "if [ -f /tmp/temp_timing_summary_panindia.sql ]; then sudo rm -fv /tmp/temp_timing_summary_panindia.sql; else echo "file exists"; fi"


echo "------------ Step1 ------------"

echo -e "Running ${SUBJECT} process on `date`"

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20timing%20companymaster&ProcessOwner=10093484&Flag=start  > /var/log/daily_log/discrepancy_timing_companymaster.log 2>&1

echo "Step2: Calling SP sp_discrepancy_timing_raw on 192.168.12.219 for port 3307"
sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_timing_raw();"
CHECK



echo "Step3: Calling SP sp_discrepancy_timing_report on 192.168.12.219 for port 3307"
sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_timing_report();"
CHECK

echo "Step4: Calling SP sp_discrepancy_timing_report_extracolumn on 192.168.12.219 for port 3307"
sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse  "call db_reports.sp_discrepancy_timing_report_extracolumn();"
CHECK

echo "Step5: Taking mysqldump of table temp_timing_summary_panindia"
sudo mysqldump -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 test temp_timing_summary_panindia > /tmp/temp_timing_summary_panindia.sql && sudo gzip -fv /tmp/temp_timing_summary_panindia.sql
CHECK

echo "Transferring table temp_timing_summary_panindia from 12.219 to 39.120"
sudo scp /tmp/temp_timing_summary_panindia.sql.gz web_backup@192.168.39.120:/tmp
CHECK


echo "Uncompressing files on 192.168.39.120"
ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/temp_timing_summary_panindia.sql.gz"
CHECK


echo "Restoring table under amol_pise database on 39.120"
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' amol_pise < /tmp/temp_timing_summary_panindia.sql"
CHECK

echo "Step6: Calling SP sp_discrepancy_timing_report on 192.168.39.120"

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql -u'process_auto' -p'gr8exp9master' -Bse \"call db_reports.sp_discrepancy_timing_report();\""
CHECK

echo "Step7: Running curl call on 192.168.12.219 server"
/usr/bin/curl 'http://192.168.12.219:88/rating_dir/estate_agent/discrepancy_timing_companymaster.php' >> /var/log/daily_log/discrepancy_timing_companymaster_status.log 2>&1
CHECK

echo "Step8: Running curl call on 192.168.14.48 server"

/usr/bin/curl http://192.168.14.48:8000/report_log.php?ProcessName=Discrepancy%20timing%20companymaster&ProcessOwner=10093484&Flag=end >> /var/log/daily_log/discrepancy_timing_companymaster.log 2>&1
CHECK

SUCCESS
