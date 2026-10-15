#!/bin/bash
####Ticket reference : DCM-2379
#########created by : Himaank

EMAIL_ID="nikhil.pangariya@justdial.com,himaank.goyal@justdial.com"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOG_FILE=/var/log/daily_log/Leadbank_runtime.log
SUBJECT="Leadbank_runtime.sh"
date=`date +%d-%m-%Y`
passwd="C17h35coona@#"
channel_id='C053R2QTCCT'
message1="$SUBJECT is completed successfully \n:):):)"
message2="$SUBJECT got failed on 192.168.6.180 \n:):):)"
webhook_url="https://hooks.slack.com/services/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"

payload1="{\"text\": \"$message1\"}"
payload2="{\"text\": \"$message2\"}"

##################### Functions ########################
CHECK() {
    if [ $? -ne 0 ]; then
        echo -e "${SUBJECT} failed at $(date) on $(hostname)" | mail -s "${SUBJECT} process is Failed" -a ${LOGFILE} $EMAIL_ID
        curl -X POST -H 'Content-type: application/json' --data "$payload2" "$webhook_url"
        exit 1
    fi
}

SUCCESS() {
    if [ $? -eq 0 ]; then
        echo -e "${SUBJECT} success at $(date) on $(hostname) \n\n\n\n$INFO"  | mail -s "${SUBJECT} Process is Successfull." $EMAIL_ID
        curl -X POST -H 'Content-type: application/json' --data "$payload1" "$webhook_url"
        exit 0
    fi
}

################################################################################################


Step=1
echo "Step= $step"
echo "Running select query on 192.168.39.81"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo mysql -uroot -p'${passwd}' -Bse 'SELECT
    AA.docid,AA.parentid,AA.data_city,MAX(AA.dealclose_date)dealclose_date,MAX(AA.approval_date)approval_date,SUM(AA.budget)budget,
    MAX(c.end_date),GROUP_CONCAT(DISTINCT c.campaign)
FROM (    SELECT a.docid, a.parentid, a.data_city, DATE(MAX(a.entry_date)) AS dealclose_date, a.start_date AS approval_date,
        SUM(IF(a.original_budget <> 0, a.original_budget, a.budget)) AS budget, a.finance_version, a.data_src
    FROM db_finance.tbl_payment_apportioning a JOIN db_finance.tbl_campaign_dealclose_budget b
        ON a.parentid = b.parentid  AND a.finance_version = b.finance_version AND a.data_src = b.data_src
    WHERE (b.is_assured & 131072) = 131072 – AND a.entry_date >= '2026-05-20' 
     AND a.start_date IS NOT NULL
    GROUP BY  a.docid, a.parentid, a.data_city, a.start_date, a.finance_version,  a.data_src ) AA
LEFT JOIN
( SELECT parentid, finance_version, data_src,  MAX(DATE(end_date)) AS end_date,
GROUP_CONCAT(DISTINCT(IF(campaignid =1,\'package\',IF(campaignid=2,\'pdg\',IF(campaignid=10,\'national\',IF(campaignid=21,\'national_pdg\',\'other\'))))))campaign FROM db_finance.tbl_companymaster_finance GROUP BY parentid, finance_version, data_src
) c  ON AA.parentid = c.parentid  AND AA.finance_version = c.finance_version  AND AA.data_src = c.data_src GROUP BY parentid,AA.data_src  INTO OUTFILE '/tmp/lead_bank_hourly_data.csv' FIELDS TERMINATED BY \',\' ENCLOSED BY \'\"\' LINES TERMINATED BY \'\n\';'"
CHECK

Step=2
echo "Step= $step"
echo "scp the file to 192.168.6.180"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo scp /tmp/lead_bank_hourly_data.csv web_backup@192.168.6.180:/tmp"
CHECK
echo "remove file from 39.81"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo rm -rf /tmp/lead_bank_hourly_data.csv"
CHECK

Step=3
echo "Step= $step"
echo "call procedure on 6.180"
ssh ${SSH_ARG} web_backup@192.168.6.180 "sudo mysql --socket=/var/lib/SQL/mysql_6_180/mysql.sock -Bse \"CALL ashwin_processing.lb_part1();\""
CHECK

Step=4
echo "Step= $step"
echo "infile in 6.180"
ssh ${SSH_ARG} web_backup@192.168.6.180 "sudo chown -R mysql. /tmp/lead_bank_hourly_data.csv"
ssh ${SSH_ARG} web_backup@192.168.6.180 "sudo mysql --socket=/var/lib/SQL/mysql_6_180/mysql.sock -Bse \"LOAD DATA INFILE '/tmp/lead_bank_hourly_data.csv' INTO TABLE ashwin_processing.lead_bank_qualified_product  TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\\\"' LINES TERMINATED BY '\n' ();\""
CHECK

Step=5
echo "Step= $step"
echo "call procedure on 6.180"
ssh ${SSH_ARG} web_backup@192.168.6.180 "sudo mysql --socket=/var/lib/SQL/mysql_6_180/mysql.sock -Bse \"CALL ashwin_processing.lb_part2();\""
CHECK

Step=6
echo "Step= $step"
echo "run python script on 6.180"
sudo python3 /scripts/lb_hourly.py > /var/log/daily_log/lb_hourly_${date}.log 2>&1
CHECK

Step=7
echo "Step= $step"
echo "call procedure on 6.180"
ssh ${SSH_ARG} web_backup@192.168.6.180 "sudo mysql --socket=/var/lib/SQL/mysql_6_180/mysql.sock -Bse \"CALL ashwin_processing.lb_part3();\""
CHECK

echo " Leadbank_runtime.sh completed successfully on `date`"
echo "sending success email..."

SUCCESS
