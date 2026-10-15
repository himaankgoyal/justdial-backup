#!/bin/bash

DATE=`date +%d-%m-%Y`
MAIL_LIST="g.pranesh@justdial.com"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'

DATE_1dayago="`date +%Y-%m-%d --date="1 day ago"`"
DATE_60dayago="`date +%Y-%m-%d --date="60 day ago"`"

##################FUNCTION#################################

ERROR() {      
    if [ $? -ne 0 ]; then
        echo "FAILED on $DATE"
        echo "national_feedback_dashboard_process Failed for ${DATE_1dayago} on 29.159" | mail -s "national_feedback_dashboard_process_failed" ${MAIL_LIST}
        exit 1
    fi
}

SUCCESS() {
    if [ $? -eq 0 ]; then
        echo "national_feedback_dashboard_process completed successfully for ${DATE_1dayago} on 29.159" | mail -s "national_feedback_dashboard_process_Success" ${MAIL_LIST}
        exit 0
    fi
}

step=1
echo "step $step"    
echo "removing old csv files from 192.168.42.159"
ssh $SSH_ARGS web_backup@192.168.42.159 "sudo rm -fv /var/lib/clickhouse/national_feedback_dashboard_data.csv"
ssh $SSH_ARGS web_backup@192.168.16.71 "sudo rm -fv /tmp/national_feedback_dashboard_data.csv"
ssh $SSH_ARGS web_backup@192.168.16.71 "sudo rm -fv /var/lib/clickhouse/national_feedback_dashboard_data.csv"
ERROR

step=2
echo call less_leads.py 
/usr/bin/python3.8 /scripts/national_feedback_incremental_data_preparation_updated.py
ERROR

step=3
ssh $SSH_ARGS web_backup@192.168.42.159 "sudo clickhouse-client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n'  --query \"SELECT * FROM test.national_feedback_dashboard_data_transfer INTO OUTFILE '/var/lib/clickhouse/national_feedback_dashboard_data.csv' FORMAT CSVWithNames;\""
ERROR

step=4
echo "step 3: copying csv files from 192.168.42.159 to 192.168.16.71"
ssh $SSH_ARGS web_backup@192.168.42.159 "sudo scp /var/lib/clickhouse/national_feedback_dashboard_data.csv web_backup@192.168.16.71:/tmp"
ERROR
ssh $SSH_ARGS web_backup@192.168.16.71 "sudo cp /tmp/national_feedback_dashboard_data.csv /var/lib/clickhouse/"
ERROR


step=5
echo call less_leads.py 
/usr/bin/python3.8 /scripts/national_feedback_data_insertion.py
ERROR

step=5
echo call less_leads.py 
/usr/bin/python3.8 /scripts/national_feedback_dashboard_process_slack_notification.py
ERROR


echo "ALL PROCESSES EXECUTED SUCCESSFULLY"
SUCCESS
