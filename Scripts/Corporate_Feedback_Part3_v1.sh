#Created by = Akshay kumar B R
#!/bin/bash
SSH_ARG='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=$(date "+%D %r")
SUBJECT="Corporate_Feedback_Part3"
MAILS="anirudh.mathur@justdial.com,dbteam_mis@justdial.com"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"
HNAME=$(hostname | cut -d. -f1)
FEEDBACK_SERVER="192.168.35.196"


ERROR(){
        if [ $? -ne 0 ]; then echo "process $SUBJECT failed on ${HNAME} on $DATE"

        echo "${SUBJECT} Failed on ${HNAME}" | mail -s "${SUBJECT} error on ${HNAME} $DATE" ${MAILS}
        exit 1 ;
        fi
}

SUCCESS() {
        if [ $? -eq 0 ] ;then
                echo "Corporate_Feedback_Part3 COMPLETED "
                echo  "Corporate_Feedback_Part3 COMPLETED for $DATE on ${HNAME}" | mail -s "Corporate_Feedback_Part3 COMPLETED on ${HNAME}" ${MAILS}
                exit 0
        fi
}

echo "STEP-1 Move out file from {FEEDBACK_SERVER} to 192.168.12.219"

ssh  ${SSH_ARGS} web_backup@${FEEDBACK_SERVER} "sudo mysqldump -h${MYHST} -u${MYUSR} -p${PASS}  --socket=/var/lib/SQL_3311/mysql/mysql_3311.sock --port=3311 db_corporate_feedback SearchFeedBack_Corporate_Parentids  | gzip -fv > /tmp/SearchFeedBack_Corporate_Parentids.sql.gz"
ERROR

echo "STEP-2 Scp to 192.168.12.219"
scp ${SSH_ARG} web_backup@${FEEDBACK_SERVER}:/tmp/SearchFeedBack_Corporate_Parentids.sql.gz /tmp/
ERROR

echo "STEP-3 Restoring on 192.168.12.219"
gunzip -fv /tmp/SearchFeedBack_Corporate_Parentids.sql.gz && sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock --port=3306 dbteam_temp < /tmp/SearchFeedBack_Corporate_Parentids.sql
ERROR


rm -fv /tmp/SearchFeedBack_Corporate_Parentids.sql
ERROR

ssh ${SSH_ARG} web_backup@${FEEDBACK_SERVER} "sudo rm -fv /tmp/SearchFeedBack_Corporate_Parentids.sql.gz"
ERROR

echo "STEP-4 Calling SP sp_corporate_data_update on 192.168.12.219"
sudo mysql -uroot --socket=/var/lib/SQL/mysql/mysql.sock --port=3306  -e "CALL db_category.sp_corporate_data_update();"
ERROR

echo "STEP-5 Move out file from 192.168.12.219 to ${FEEDBACK_SERVER}"
sudo mysqldump --socket=/var/lib/SQL/mysql/mysql.sock --port=3306 dbteam_temp SearchFeedBack_Corporate_Parentids | gzip -fv > /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql.gz && scp  ${SSH_ARG} /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql.gz web_backup@${FEEDBACK_SERVER}:/tmp/
ERROR

#sudo chown web_backup.web_backup /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql.gz /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql

sudo rm -fv /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql.gz
ERROR

echo "STEP-6 Restoring on ${FEEDBACK_SERVER}"

ssh -q ${SSH_ARG} web_backup@${FEEDBACK_SERVER} "gunzip -fv /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql.gz"
ERROR

ssh -q ${SSH_ARG} web_backup@${FEEDBACK_SERVER} "sed -i 's/SearchFeedBack_Corporate_Parentids/temp_Updated_SearchFeedBack_Corporate_Parentids/g' /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql" 
ERROR

ssh  ${SSH_ARGS} web_backup@${FEEDBACK_SERVER} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} --socket=/var/lib/SQL_3311/mysql/mysql_3311.sock --port=3311 db_corporate_feedback < /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql"
ERROR

echo "STEP-6 Calling SP sp_client_companyname_updation on ${FEEDBACK_SERVER}"
ssh -q ${SSH_ARG} web_backup@${FEEDBACK_SERVER} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} --socket=/var/lib/SQL_3311/mysql/mysql_3311.sock --port=3311 -Bse 'CALL db_corporate_feedback.sp_client_companyname_updation();'"
ERROR

ssh -q ${SSH_ARG} web_backup@${FEEDBACK_SERVER} "sudo rm -fv /tmp/temp_Updated_SearchFeedBack_Corporate_Parentids.sql"
ERROR

SUCCESS
