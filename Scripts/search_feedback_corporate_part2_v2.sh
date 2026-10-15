#!/bin/bash

### Variable Define ###
DATE=`date +%d-%m-%Y`
EMAILIDS="anirudh.mathur@justdial.com,dbteam_mis@justdial.com,nitesh.nimbalkar1@justdial.com"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
SUBJECT="SearchFeedback_Corporate Part2"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"
HNAME=$(hostname | cut -d. -f1)

DISABLE_LOG_NL_SRV="SET sql_log_bin = 0;"
ENABLE_LOG_NL_SRV="SET sql_log_bin = 1;"

### Function Define ###

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
else
        echo "Failed"
        echo "${SUBJECT} Failed on ${HNAME} " | mail -s "${SUBJECT} Failed on ${HNAME}" -a /var/log/daily_log/search_feedback_corporate_part2.log ${EMAILIDS}
        exit 1
fi
}


### Man Body ###

echo "Execute Drop on ${HNAME}"
sudo mysql -Bse "DROP TABLE IF EXISTS db_reports.temp_search_feedback_corporate_parentid;"
CHECK

echo "Create table temp_search_feedback_corporate_parentid on ${HNAME}"
sudo mysql -Bse "CREATE TABLE db_reports.temp_search_feedback_corporate_parentid(KEY(parentid),KEY(contract_signed_city),KEY(uptdate),KEY(data_city),KEY(city)) SELECT DISTINCT parentid,contract_signed_city,ifnull(uptdate,'0000-00-00') as uptdate,data_city,city FROM db_jd_deductioninfo.SearchFeedBack_Corporate_Parentids WHERE flag=1 ORDER BY contract_signed_city,parentid;"
CHECK

# echo "Taking dump of table temp_search_feedback_corporate_parentid on ${HNAME}"
# sudo mysqldump db_reports temp_search_feedback_corporate_parentid | gzip -fv > /tmp/temp_search_feedback_corporate_parentid.sql.gz
# CHECK

echo "Taking dump of table temp_search_feedback_corporate_parentid on ${HNAME}"
sudo mysqldump db_reports temp_search_feedback_corporate_parentid > /tmp/temp_search_feedback_corporate_parentid1.sql
CHECK

echo "Apending Bin log disable/enable to the Mysql Dump of table temp_search_feedback_corporate_parentid on ${HNAME}"
echo ${DISABLE_LOG_NL_SRV} > /tmp/disable_log_nl_srv.sql && echo ${ENABLE_LOG_NL_SRV} > /tmp/enable_log_nl_srv.sql && cat /tmp/disable_log_nl_srv.sql /tmp/temp_search_feedback_corporate_parentid1.sql /tmp/enable_log_nl_srv.sql > /tmp/temp_search_feedback_corporate_parentid.sql
CHECK

echo "Taking dump of table temp_search_feedback_corporate_parentid on ${HNAME}"
gzip -fv /tmp/temp_search_feedback_corporate_parentid.sql
CHECK

echo "Removing temp dump temp_search_feedback_corporate_parentid1 on ${HNAME}"
sudo rm -fv /tmp/temp_search_feedback_corporate_parentid1.sql
CHECK

echo "Restoring table temp_search_feedback_corporate_parentid on XX.161 and XX.171"
for i in 192.168.39.56;
do 
echo "starting first for loop."
     echo "Transferring table temp_search_feedback_corporate_parentid to $i"
        scp ${SSH_ARGS} /tmp/temp_search_feedback_corporate_parentid.sql.gz web_backup@${i}:/tmp/ 
         CHECK
  
     echo "Unzipping table temp_search_feedback_corporate_parentid on $i"
          ssh ${SSH_ARGS} web_backup@${i} "gunzip -fv /tmp/temp_search_feedback_corporate_parentid.sql.gz"
          CHECK

echo "Starting second for loop"
for j in ahmedabad bangalore chennai delhi hyderabad kolkata mumbai pune;
#for j in ahmedabad;
  do
     echo "Restoring table temp_search_feedback_corporate_parentid on ${i} in ${j}"
           ssh ${SSH_ARGS} web_backup@${i} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} db_jd_deductioninfo_${j} < /tmp/temp_search_feedback_corporate_parentid.sql"
           CHECK
   
#     echo "Deleting table temp_search_feedback_corporate_parentid.sql from ${i}"
#           ssh ${SSH_ARGS} web_backup@${i} "sudo rm -fv /tmp/temp_search_feedback_corporate_parentid.sql"
#           CHECK
#TEST_QRY="SET sql_log_bin = 0; DELETE FROM db_jd_deductioninfo_${j}.temp_search_feedback_corporate_parentid WHERE city<>(\"${j}\");SET sql_log_bin = 1;"
     echo "Execute delete query on ${i}"
#           ssh ${SSH_ARGS} web_backup@${i} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin = 0; DELETE FROM db_jd_deductioninfo_${j}.temp_search_feedback_corporate_parentid WHERE city<>("${j}");SET sql_log_bin = 1;'"
          ssh ${SSH_ARGS} web_backup@${i} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin = 0; DELETE FROM db_jd_deductioninfo_${j}.temp_search_feedback_corporate_parentid WHERE city<>(\"${j}\");SET sql_log_bin = 1;'"
          CHECK

    echo "Execute Insert query on ${i}"
	#ssh ${SSH_ARGS} web_backup@${i} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin = 0; INSERT IGNORE INTO db_jd_deductioninfo_${j}.tbl_search_feedback_corporate_parentid(parentid,contract_signed_city,uptdate,data_city,city) SELECT parentid,contract_signed_city,uptdate,data_city,city FROM db_jd_deductioninfo_${j}.temp_search_feedback_corporate_parentid WHERE city=(\${j}\); SET sql_log_bin = 1;'"
	ssh ${SSH_ARGS} web_backup@${i} "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'INSERT IGNORE INTO db_jd_deductioninfo_${j}.tbl_search_feedback_corporate_parentid(parentid,contract_signed_city,uptdate,data_city,city) SELECT parentid,contract_signed_city,uptdate,data_city,city FROM db_jd_deductioninfo_${j}.temp_search_feedback_corporate_parentid WHERE city=(\"${j}\");'"
          CHECK
echo "Completed second loop"
done

echo "Deleting table temp_search_feedback_corporate_parentid.sql from ${i}"
          ssh ${SSH_ARGS} web_backup@${i} "sudo rm -fv /tmp/temp_search_feedback_corporate_parentid.sql"
          CHECK
echo "Completed first loop."
done

############# Remote City Execution #######################

    echo "Transferring table temp_search_feedback_corporate_parentid to 192.168.39.56"
          scp /tmp/temp_search_feedback_corporate_parentid.sql.gz web_backup@192.168.39.56:/tmp/
          CHECK
   
    echo "Unzipping table temp_search_feedback_corporate_parentid on 192.168.39.56"
          ssh ${SSH_ARGS} web_backup@192.168.39.56 "gunzip /tmp/temp_search_feedback_corporate_parentid.sql.gz"
          CHECK

    echo "Restoring table temp_search_feedback_corporate_parentid on 192.168.39.56"
           ssh ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} db_jd_deductioninfo_rcity < /tmp/temp_search_feedback_corporate_parentid.sql"
           CHECK
   
    echo "Deleting table temp_search_feedback_corporate_parentid.sql from 192.168.39.56"
           ssh ${SSH_ARGS} web_backup@192.168.39.56 "sudo rm -fv /tmp/temp_search_feedback_corporate_parentid.sql"
           CHECK

    echo "Execute delete query on 192.168.39.56 - for remote"
           ssh ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin = 0; DELETE FROM db_jd_deductioninfo_rcity.temp_search_feedback_corporate_parentid WHERE city<>(\"remote\"); SET sql_log_bin = 1;'"
           CHECK

    echo "Execute Insert query on 192.168.39.56"
          ssh ${SSH_ARGS} web_backup@192.168.39.56 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse 'SET sql_log_bin = 0;INSERT IGNORE INTO db_jd_deductioninfo_rcity.tbl_search_feedback_corporate_parentid(parentid,contract_signed_city,uptdate,data_city,city) SELECT parentid,contract_signed_city,uptdate,data_city,city FROM db_jd_deductioninfo_rcity.temp_search_feedback_corporate_parentid WHERE city=(\"remote\"); SET sql_log_bin = 1;'"
          CHECK

echo "Deleting Temporary Table from ${HNAME}"
sudo rm -fv /tmp/temp_search_feedback_corporate_parentid.sql.gz
CHECK

echo "Sending Success Mail"
echo "${SUBJECT} completed successfully on ${HNAME}"  | mail -s "${SUBJECT}" ${EMAILIDS}
exit 0
