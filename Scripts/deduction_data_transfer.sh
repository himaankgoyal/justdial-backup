#!/bin/bash

# Created by - Chaman Singh on 24-Jan-2024
# Requested by - Anurag Singh
# Modified by -

EMAIL="anurag.singh9@justdial.com"
#EMAIL="sandip.mandal@justdial.com"
SCRIPT_NAME="deduction_data_transfer"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
DESTINATION_SERVER="192.168.29.136"
#DIRECTORY="/var/lib/clickhouse/deduction_data/${DATE}"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo -e "Script : $0 is failed on `hostname` at `date`" | mail -s "Script failed" -a ${LOGFILE} ${EMAIL}
                sudo  sh /scripts/standard_sms_sending_script.sh -f /scripts/web_search_sms.txt -m "FAILED: deduction_data script failed at $DATE for $CITY on 42.243"  
                exit 1
        fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "*** SUCCESS ***\nYour Script ${SCRIPT_NAME}.sh has been Executed Sucessfully at `date` on `hostname`." | mail -s "Script is Executed successfully" ${EMAIL}
         rm -rf /tmp/deduction_data.lock
                exit 0
        fi
}


CREATE_LOCK(){
if [ -e /tmp/deduction_data.lock ];then
    echo "lockfile already exists. Exiting"
    echo "deduction_data not run on 42.243" | mail -s "Exiting: deduction_data lockfile exists $DATE"
    exit 1
else
    echo "Creating lock file"
    touch /tmp/deduction_data.lock
fi
}

echo "Checking lock file exist or not"
CREATE_LOCK

echo "Taking data into variables on 192.168.42.243 by select query"
sudo mysql -h${HOST} -p${LOCALPASSWD} -u${LOCALUSER} -Bse "SELECT id,source_server,source_port,date,city,done_flag FROM search_input.tbl_deduction_data_transfer_lookup WHERE done_flag=0 ORDER BY DATE ASC,city ASC LIMIT 1;" > /tmp/deduction_data_variables.lst
ERROR

ID=$(cat /tmp/deduction_data_variables.lst | tail -1 | awk '{print $1}')
SOURCE_SERVER=$(cat /tmp/deduction_data_variables.lst | tail -1 | awk '{print $2}')
SOURCE_PORT=$(cat /tmp/deduction_data_variables.lst | tail -1 | awk '{print $3}')
DATE=$(cat /tmp/deduction_data_variables.lst | tail -1 | awk '{print $4}')
CITY=$(cat /tmp/deduction_data_variables.lst | tail -1 | awk '{print $5}')

VARDATE=$(echo "${DATE}" | sed 's/-//g')
YEAR=$(echo "${DATE}" | awk -F "-" '{print $1}')
MONTH=$(echo "${DATE}" | awk -F "-" '{print $2}')
DATE_DAY=$(echo "${DATE}" | awk -F "-" '{print $3}')
DESTDIR="/var/lib/clickhouse/deduction_data/${DATE}"
ssh ${SSH_ARGS} web_backup@${DESTINATION_SERVER} "if [ `sudo ls -d $DESTDIR  2>/dev/null 1>/dev/null;echo $?` -ne 0 ];then echo \"create dir $DESTDIR\"; sudo mkdir -p $DESTDIR ; sudo chown -R web_backup.web_backup $DESTDIR;fi"


if [ ${MONTH} -lt 10 ];
then
	MONTH=$(echo "${MONTH}" | sed 's/0//g')
fi


###DESTINATION_COUNTS=$(ssh ${SSH_ARGS} web_backup@${DESTINATION_SERVER} "sudo zcat /tmp/testing12_3.csv.gz | wc -l")
echo -e "$ID\n$SOURCE_SERVER\n$SOURCE_PORT\n$DATE\n$CITY\n$YEAR\n$MONTH\n$DATE_DAY\n$VARDATE\n$DESTINATION_COUNTS"

echo "Run below query to update start time of lookup table on 42.243 server"
sudo mysql -Bse "update search_input.tbl_deduction_data_transfer_lookup set start_time=now() where id=${ID};"
ERROR

if [ "${SOURCE_SERVER}" == "192.168.17.216" ];
then

	echo "Now logging into source_server: $SOURCE_SERVER and source_port: $SOURCE_PORT and runing below query to take outfile"
	ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo mysql -h${HOST} -p${LOCALPASSWD} -u${LOCALUSER} --socket=/var/lib/SQL/mysql/mysql.sock -Bse \"SELECT * FROM  db_jd_deductioninfo_${CITY}.tbl_deduction_history_${MONTH}_${YEAR} WHERE deduction_date = '${DATE}' INTO OUTFILE '/tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\\\"' LINES TERMINATED BY '\n';\""
	ERROR
	SOURCE_COUNTS=$(ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "cat /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv | wc -l")
	ERROR
	TABLE_COUNTS=$(ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo mysql -h${HOST} -p${LOCALPASSWD} -u${LOCALUSER} --socket=/var/lib/SQL/mysql/mysql.sock -Bse \"select count(1) from db_jd_deductioninfo_${CITY}.tbl_deduction_history_${MONTH}_${YEAR} WHERE deduction_date = '${DATE}';\"" | tail -1)
        ERROR
	echo "Gzip and Copy file : /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz from $SOURCE_SERVER to $DESTINATION_SERVER"
        ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo gzip -fv /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv && sudo scp /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz web_backup@${DESTINATION_SERVER}:/tmp/"
        ERROR

else
	echo "Now logging into source_server: $SOURCE_SERVER and source_port: $SOURCE_PORT and runing below query to take outfile"
	ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo mysql -h${HOST} -p${LOCALPASSWD} -u${LOCALUSER} --socket=/var/lib/SQL_${SOURCE_PORT}/mysql/mysql.sock -Bse \"SELECT * FROM  db_jd_deductioninfo_${CITY}.tbl_deduction_history_${MONTH}_${YEAR} WHERE deduction_date = '${DATE}' INTO OUTFILE '/tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\\\"' LINES TERMINATED BY '\n';\""
	ERROR
	SOURCE_COUNTS=$(ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "cat /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv | wc -l")
        ERROR
	TABLE_COUNTS=$(ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo mysql -h${HOST} -p${LOCALPASSWD} -u${LOCALUSER} --socket=/var/lib/SQL_${SOURCE_PORT}/mysql/mysql.sock -Bse \"select count(1) from db_jd_deductioninfo_${CITY}.tbl_deduction_history_${MONTH}_${YEAR} WHERE deduction_date = '${DATE}';\"" | tail -1)
	ERROR
	echo "Gzip and Copy file : /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz from $SOURCE_SERVER to $DESTINATION_SERVER"
	ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo gzip -fv /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv && sudo scp /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz web_backup@${DESTINATION_SERVER}:/tmp"
        ERROR
fi

echo "Removing file from source server ${SOURCE_SERVER}"
ssh ${SSH_ARGS} web_backup@${SOURCE_SERVER} "sudo rm -fv /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz"
ERROR

echo "Moving file from /tmp to /var/lib/clickhouse/deduction_data/${DATE} on  ${DESTINATION_SERVER}"
ssh ${SSH_ARGS} web_backup@${DESTINATION_SERVER} "sudo mv /tmp/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz /var/lib/clickhouse/deduction_data/${DATE}"
ERROR


echo "Taking Destination_counts of file temp_deductioninfo_${CITY}_${VARDATE}.csv.gz on $DESTINATION_SERVER"
DESTINATION_COUNTS=$(ssh ${SSH_ARGS} web_backup@${DESTINATION_SERVER} "sudo zcat  /var/lib/clickhouse/deduction_data/${DATE}/temp_deductioninfo_${CITY}_${VARDATE}.csv.gz | wc -l")
ERROR

echo "SOURCE_COUNTS=$SOURCE_COUNTS"
echo "DESTINATION_COUNTS=$DESTINATION_COUNTS"
echo "TABLE_COUNTS=$TABLE_COUNTS"
echo "Running query to update lookup table on 192.168.42.243"
sudo mysql -Bse "update search_input.tbl_deduction_data_transfer_lookup set done_flag=1,end_time=now(),table_cnt=${TABLE_COUNTS},source_file_cnt=${SOURCE_COUNTS},destination_file_cnt=${DESTINATION_COUNTS} where id=${ID};"
ERROR

echo "All Process Completed Successfully"
SUCCESS

###select count(1) from db_jd_deductioninfo_${CITY}.tbl_deduction_history_${MONTH}_${YEAR} WHERE deduction_date = '${DATE}';


