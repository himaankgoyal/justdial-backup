#!/bin/bash

#############################################
# Created by - Himaank Goyal on 03-May-2023 #
#############################################

EMAIL="saket.parashar@justdial.com,himaank.goyal@justdial.com"
EMAIL_F="saket.parashar@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="top_question_n_answer_daily.sh"
Date=$(date +%Y-%m-%d -d '1 day ago')
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo "Success"
                echo "Failed on STEP $STEP on 41.111" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
                exit 1
        fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME is successfull " | sudo mail -a /tmp/tbl_company_consolidated_autosuggest.csv -s "script is Executed successfully at : `date`" ${EMAIL}
                exit 0
        fi
}

##########################################################################################################################################

Step=1
echo "step 1: call sp test.tbl_docid_qna('$Date'); on 41.111"
ssh $SSH_ARGS -q web_backup@192.168.41.111 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call test.tbl_docid_qna()\";"
ERROR

step=2
echo"step=$step" Transfer tbl_docid_qna_20230427 from 41.111(test) to 12.133(processing)
sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo mysqldump -h${MYHST} -u${MYUSR} -p${PASS} test tbl_docid_qna_20230427 > /tmp/tbl_docid_qna_20230427.sql && sudo gzip /tmp/tbl_docid_qna_20230427.sql;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo scp /tmp/tbl_docid_qna_20230427.sql.gz web_backup@192.168.12.133:/tmp/;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.12.133 "sudo gunzip /tmp/tbl_docid_qna_20230427.sql.gz"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.12.133 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} processing < /tmp/tbl_docid_qna_20230427.sql"
ERROR

echo "Removing /tmp/tbl_docid_qna_20230427.sql from 12.133"
ssh ${SSH_ARG} web_backup@192.168.12.133 "sudo rm -fv /tmp/tbl_docid_qna_20230427.sql"
ERROR

echo "Removing /tmp/tbl_docid_qna_20230427.sql.sql from 41.111"
ssh ${SSH_ARG} web_backup@192.168.14.48 "sudo rm -fv /tmp/tbl_docid_qna_20230427.sql.gz"
ERROR

Step=3
echo "step 3: call sp processing.top_question_n_answer_daily('$Date'); on 12.133"
ssh $SSH_ARGS -q web_backup@192.168.12.133 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call processing.top_question_n_answer_daily()\";"
ERROR

Step=4
echo -e "hot_category_name\tTotal_questions_posted\tTotal_answers_given\tNew_questions_posted\tNew_answers_given" > /tmp/tbl_company_consolidated_autosuggest.csv
echo "convrting into csv file"
ssh $SSH_ARGS -q web_backup@192.168.12.133 "sudo mysql -h${MYHST} -u${MYUSR} -p${PASS} -Bse \"SELECT 'Overall' AS hot_category_name,COUNT(question) AS Total_questions_posted ,SUM(IF( answer="",0,1)) AS Total_answers_given,SUM(IF(DATE(question_time) = CURRENT_DATE - INTERVAL 1 DAY ,1,0)) New_questions_posted,SUM(IF(DATE(answer_time) = CURRENT_DATE - INTERVAL 1 DAY   AND  answer <>"",1,0)) New_answers_given FROM processing.tbl_docid_qna_20230427 UNION ALL SELECT DISTINCT a.hotcategory,b.question_count,b.answer_count,b.yesterday_question_count,b.yesterday_answer_count FROM db_company.'tbl_company_consolidated_autosuggest' a JOIN processing.tbl_docid_qna_temp_20230501 b ON a.docid = b.docid AND a.synid =b.docid;\"" >> /tmp/tbl_company_consolidated_autosuggest.csv
ERROR

SUCCESS

