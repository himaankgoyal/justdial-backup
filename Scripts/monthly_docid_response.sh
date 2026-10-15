#!/bin/bash

#############################################
# Created by - Himaank Goyal on 24-May-2023 #
#############################################

EMAIL="rishav.parashar@justdial.com,anurag.singh9@justdial.com,himaank.goyal@justdial.com"
EMAIL_F="rishav.parashar@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="monthly_docid_response"
#Date=$(date +%Y-%m-%d -d '1 day ago')
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"
DATE_1=$(date -d "1 day ago")
DATE_2=$(date -d "31 day ago")

###################################################### Functions ###########################################################

ERROR() {
	if [ $? -ne 0 ];then
		echo "Success"
		echo "Failed on STEP $step on 41.111" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
		exit 1
	fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME is successfull " | sudo mail -a /tmp/tbl_docid_response_data.csv -s "script is Executed successfully at : `date`" ${EMAIL}
                exit 0
        fi
}

##########################################################################################################################################

step=1
echo "step 1: maintain log file on 42.243"
ssh $SSH_ARGS -q web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('start_date','$DATE_2')\";"
ERROR

#step=2
#echo"step=$step run mysql query on 42.243"
#sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"truncate trainee_test.tbl_docid_response_data;"
#ERROR

step=3
echo"step=$step maintain log file on 42.243"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('process started','`date`')\";"
ERROR

step=4
echo"step=$step call python script monthly_docid_response_data.py"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo python3.9 /scripts/monthly_docid_response_data.py"
ERROR

step=5
echo "step=$step maintain log file on 42.243"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('python process completed','`date`')\";"
ERROR

step=6
echo "step=$step mongo export"
sudo ssh ${SSH_ARGS} web_backup@192.168.41.138 "sudo mongoexport -h 192.168.41.138 -u mongo-admin -pP@a5swOrD --authenticationDatabase admin -d db_processing -c tbl_docid_response_data -q '' --fields _id,total_lead_cnt,response_time,response_cnt --out /tmp/tbl_docid_response_data.csv --type=csv"
ERROR

step=7
echo "step=$step maintain log file on 42.243"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('mongo export completed','`date`')\";"
ERROR

step=8
echo "step=$step transfer the file generated to 42.243 and change ownership to mysql"
sudo ssh ${SSH_ARGS} web_backup@192.168.41.138 "sudo scp /tmp/tbl_docid_response_data.csv web_backup@192.168.42.243:/tmp/ && sudo chown mysql. /tmp/tbl_docid_response_data.csv"
ERROR

step=9
echo "step=$step load data into table trainee_test.tbl_docid_response_data"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"LOAD DATA INFILE  '/tmp/tbl_docid_response_data.csv'  INTO TABLE trainee_test.tbl_docid_response_data CHARACTER SET latin1 FIELDS TERMINATED BY ','  ENCLOSED BY \"'\" LINES TERMINATED BY '\n'\";"
ERROR

step=10
echo "step=$step maintain log file on 42.243"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('data infile completed','`date`')\";"
ERROR

step=11.1
echo "step=$step tranfer table trainee_test.tbl_docid_response_data from 42.243 to 12.232 port(3307) in test database"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} trainee_test tbl_docid_response_data | gzip -vf > /tmp/tbl_docid_response_data.sql"

step=11.2
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo scp /tmp/tbl_docid_response_data.sql.gz web_backup@192.168.12.232:/tmp/"
ERROR

step=11.3
sudo ssh ${SSH_ARGS} web_backup@192.168.12.232 "sudo gunzip -fv /tmp/tbl_docid_response_data.sql.gz"
ERROR

step=11.4
sudo ssh ${SSH_ARGS} web_backup@192.168.12.232 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} test < /tmp/tbl_docid_response_data.sql"
ERROR

step=11.5
echo "Removing /tmp/tbl_docid_response_data.sql from 12.232"
ssh ${SSH_ARG} web_backup@192.168.12.133 "sudo rm -fv /tmp/tbl_docid_response_data.sql"
ERROR

step=11.6
echo "Removing /tmp/tbl_docid_qna_20230427.sql.sql from 42.243"
ssh ${SSH_ARG} web_backup@192.168.42.243 "sudo rm -fv /tmp/tbl_docid_response_data.sql.gz"
ERROR

step=12: maintain log file on 42.243
echo "step=$step" maintain log file on 42.243
sudo ssh ${SSH_ARGS} web_backup@192.168.42.243 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"insert into trainee_test.tbl_monthly_docid_response_data_lookup(reamarks,date_time) values('end date','${DATE_1}')\";"
ERROR

SUCCESS

