#!/bin/bash
# Created By Rajveer Singh
# Created Date: 1st Dec 2021
#Stake Holder: Rajeev K Nair
#Purpose : Sending talktime_daily_report
 
log="/var/log/daily_log/active_listing_data_count_weekly.log"
#MAILS="dbescalations@justdial.com, dbteam_mis@justdial.com, kuldeep.jaiswal@justdial.com, dbteam_mis@justdial.com, "
MAILS="kuldeep.jaiswal@justdial.com,bhavna.chalise@justdial.com,vivek.jha@justdial.com,dhakshina.palanisamy@justdial.com, gomathi.pandy@justdial.com, kundan.kumar6@justdial.com,dbteam_mis@justdial.com"
#MAILS="m.sreedhar@justdial.com,dhakshina.palanisamy@justdial.com"
#MAILS="dhakshina.palanisamy@justdial.com,chaman.singh1@justdial.com"
SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ERROR(){

	if [ $? -ne  0 ];then
        echo "Faild on $step"
	echo "FAILED :- Active listing data count weekly is failed" | mail -s "FAILED :- Active listing data count weekly is failed `date`" -a $log  root@justdial.com $MAILS
	exit 1
	fi
}

SUCCESS(){
	echo "SUCCESS :- Active listing data count weekly is success\nPlease find the attached report" | mail -s "SUCCESS :- Active listing data count weekly  at `date`" -a /tmp/active_paid_expired.csv -a /tmp/active_listing_data.csv  $MAILS
        
#	rm -f /tmp/active_paid_expired.csv  /tmp/active_listing_data.csv
	exit 0
}

echo "Removing old csv files"
rm -rfv /tmp/active_paid_expired.csv /tmp/active_listing_data.csv 
ERROR

echo "Calling report_log.php start"
/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Active%20listing%20datacount%20weekly&ProcessOwner=10104434&Flag=start" > /dev/null 2>&1
ERROR

step=1
echo "Step : $step"
echo "Calling Call storedprocedure in 14.49"
mysql -Bse "Call db_allocation.sp_active_listing_data_weekly();"
ERROR
#TOTAL_RECORDS=$(mysql -Bse "select count(Date) as Number_of_records from test.temp_talktime_daily_report;")

step=2
echo "Step : $step"
echo "Taking Dump of temp_active_listing_data_weekly_report_two on 14.49"
sudo mysqldump test temp_active_listing_data_weekly_report_two | gzip -fv > /tmp/temp_active_listing_data_weekly_report_two.sql.gz && scp /tmp/temp_active_listing_data_weekly_report_two.sql.gz web_backup@192.168.12.80:/tmp/
ERROR

echo "Unzipping and Restore on 12.80"
ssh $SSH_ARGS -q web_backup@192.168.12.80 "sudo gunzip -fv /tmp/temp_active_listing_data_weekly_report_two.sql.gz && sudo mysql dbteam_temp < /tmp/temp_active_listing_data_weekly_report_two.sql && sudo gzip -fv  /tmp/temp_active_listing_data_weekly_report_two.sql"
ERROR

step=3
echo "Step : $step"
echo "Calling SP sp_active_listing_data_weekly() on 12.80 and Copy /tmp/active_listing_data.csv from 12.80 to 14.49"
ssh $SSH_ARGS -q web_backup@192.168.12.80 "sudo mysql -Bse 'call db_reports.sp_active_listing_data_weekly();'"
ERROR

ssh $SSH_ARGS -q web_backup@192.168.12.80 "sudo chown -R rajveer. /tmp/active_listing_data.csv && sudo scp /tmp/active_listing_data.csv web_backup@192.168.14.49:/tmp/"
ERROR

echo "Calling report_log.php end"
/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Active%20listing%20datacount%20weekly&ProcessOwner=10104434&Flag=end"  > /dev/null 2>&1
ERROR

echo "All process completed successfully"
SUCCESS

