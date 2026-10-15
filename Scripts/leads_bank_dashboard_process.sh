#!/bin/bash
####Ticket reference : DCM-2354
#########created by : Avinash

EMAIL_ID="nikhil.pangariya@justdial.com,v.avinash@justdial.com"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOG_FILE=/var/log/daily_log/leads_bank_dashboard_process.log
SUBJECT="leads_bank_dashboard_process.sh"
date=`date +%d-%m-%Y`
passwd="C17h35coona@#"
channel_id = 'C053R2QTCCT'
message1="$SUBJECT is completed successfully \n:):):)"
message2="$SUBJECT got failed on 192.168.17.124 \n:):):)"
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


################################## Step 0 deleting the file from both servers ###################################
######## step 0.1 ######

step=0.1
echo "Step= $step"
echo "Removing dumpfile from 192.168.39.81"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo rm -fv /var/lib/mysql-files/lead_bank_qualified_docid.csv"
CHECK

######## step 0.2 #########
step=0.2
echo "Step= $step"
echo "Removing dumpfile from destination server 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo rm -fv /tmp/lead_bank_qualified_docid.csv"
CHECK

############################## Step-1 :outfile and  file transfer from 192.168.39.81 to 192.168.17.124 ####################

step=1.1
echo "Step= $step"
echo "Running select query on 192.168.39.81"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "mysql -uroot -p'${passwd}' -Bse 'SELECT AA.docid, AA.data_city, MAX(AA.dealclose_date) AS dealclose_date, MAX(AA.approval_date) AS approval_date, SUM(AA.budget) AS budget, MAX(c.end_date), GROUP_CONCAT(DISTINCT c.campaign), max(AA.duration) FROM (SELECT a.docid, a.parentid, a.data_city, DATE(MAX(a.entry_date)) AS dealclose_date, a.start_date AS approval_date, SUM(IF(a.original_budget <> 0, a.original_budget, a.budget)) AS budget, a.finance_version, a.data_src,max(a.duration)duration FROM db_finance.tbl_payment_apportioning a JOIN db_finance.tbl_campaign_dealclose_budget b ON a.parentid = b.parentid AND a.finance_version = b.finance_version AND a.data_src = b.data_src WHERE (b.is_assured & 131072) = 131072 AND a.start_date IS NOT NULL GROUP BY a.docid, a.parentid, a.data_city, a.start_date, a.finance_version, a.data_src) AA LEFT JOIN (SELECT parentid, finance_version, data_src, MAX(DATE(end_date)) AS end_date, GROUP_CONCAT(DISTINCT(IF(campaignid=1, \"package\", IF(campaignid=2, \"pdg\", IF(campaignid=10, \"national\", IF(campaignid=21, \"national_pdg\", \"other\")))))) AS campaign FROM db_finance.tbl_companymaster_finance GROUP BY parentid, finance_version, data_src) c ON AA.parentid = c.parentid AND AA.finance_version = c.finance_version AND AA.data_src = c.data_src GROUP BY AA.docid, AA.parentid, AA.data_city, AA.data_src INTO OUTFILE \"/var/lib/mysql-files/lead_bank_qualified_docid.csv\" FIELDS TERMINATED BY \",\" ENCLOSED BY \"\\\"\" LINES TERMINATED BY \"\\n\";'"
CHECK


step=1.2
echo "Step= $step"
echo "scp the file to query on 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo scp /var/lib/mysql-files/lead_bank_qualified_docid.csv web_backup@192.168.17.124:/tmp"
CHECK
ssh ${SSH_ARG} web_backup@192.168.39.81 -p 2222 "sudo rm -rf /var/lib/mysql-files/lead_bank_qualified_docid.csv"
CHECK

############################## Step-2 :TRUNCATE query and load infile on 192.168.17.124 ####################
step=2.1
echo "Step= $step"
echo "Running truncate query on 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo mysql --socket /var/lib/SQL_3307/mysqld1_3307.sock -Bse \"call dbteam_temp.lead_bank_qualified_product_p1();\""
CHECK

step=2.2
echo "Step= $step"
echo "LOAD INFILE query on 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo chown -R mysql. /tmp/lead_bank_qualified_docid.csv"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo mysql --socket /var/lib/SQL_3307/mysqld1_3307.sock -Bse \"LOAD DATA INFILE '/tmp/lead_bank_qualified_docid.csv' INTO TABLE dbteam_temp.lead_bank_qualified_product FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\\\"' LINES TERMINATED BY '\n' ();\""
CHECK

step=2.3
echo "Step= $step"
echo "SP call query on 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo mysql --socket /var/lib/SQL_3307/mysqld1_3307.sock -Bse \"call dbteam_temp.lead_bank_qualified_product_p2();\""
CHECK

ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo rm -rf /tmp/lead_bank_qualified_docid.csv"
CHECK

step=3.1
echo "Step= $step"
echo "SELECT AND LOAD OUTFILE query on 192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo mysql --socket /var/lib/SQL_3307/mysqld1_3307.sock -Bse \"select docid,data_city,dealclose_date,approval_date,budget,campaign,end_date,hot_cat_info,hot_cat_info_name,state,zone,company_name, duration from dbteam_temp.lead_bank_qualified_product INTO OUTFILE '/tmp/lead_bank_qualified_data_p1.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\\\"' LINES TERMINATED BY '\n';\""
CHECK

step=3.2
echo "Step= $step"
echo "SCP the outfile to 192.168.42.159 and 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.17.124 " sudo scp /tmp/lead_bank_qualified_data_p1.csv web_backup@192.168.42.159:/tmp "
CHECK
ssh ${SSH_ARG} web_backup@192.168.17.124 " sudo scp /tmp/lead_bank_qualified_data_p1.csv web_backup@192.168.42.131:/tmp "
CHECK

step=4.1
echo "Step= $step"
echo "DROP query on 192.168.42.159"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \"drop table if exists test.lead_bank_qualified_product ON CLUSTER 'cluster_clicktracker';\""
CHECK

step=4.2
echo "Step= $step"
echo "CREATE query on 192.168.42.159"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \" CREATE TABLE test.lead_bank_qualified_product ON CLUSTER 'cluster_clicktracker' ( docid String CODEC(ZSTD(9)),data_city String CODEC(ZSTD(9)),dealclose_date Date CODEC(ZSTD(9)),approval_date Date CODEC(ZSTD(9)),budget Int32 CODEC(ZSTD(9)),campaign String CODEC(ZSTD(9)),end_date Date CODEC(ZSTD(9)),hot_cat_info Int64 DEFAULT 0 CODEC(ZSTD(9)),hot_cat_info_name String CODEC(ZSTD(9)),state String CODEC(ZSTD(9)),zone String CODEC(ZSTD(9)),company_name String CODEC(ZSTD(9)),duration Int32 CODEC(ZSTD(9))) ENGINE = ReplicatedMergeTree ORDER BY (docid, approval_date);\""
CHECK

step=4.3
echo "Step= $step"
echo "INSERT query on 192.168.42.159"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \"INSERT INTO test.lead_bank_qualified_product FORMAT CSV\" < /tmp/lead_bank_qualified_data_p1.csv"
CHECK

step=4.4
echo "Step= $step"
echo "SELECT and OUTFILE query on 192.168.42.159"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \"select date(lead_trigger_time)entry_date,JSONExtract((arrayJoin(JSONExtractArrayRaw(results_set))),'di','String')docid,search_city,national_catid,channel,channel_name,ld_bnk,if(JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'ded_d_dup', 'String') IN ('0', ''),0,1) AS dup,if(JSONExtract((arrayJoin(JSONExtractArrayRaw(results_set))),'ded_pd','String')in ('0',''),0,1)paid , JSON_VALUE(rfq, '$.p_detail.price') AS price,JSON_VALUE(rfq, '$.p_detail.qty') AS qty,JSON_VALUE(rfq, '$.p_detail.dl_val') deal_value from leads.tbl_category_feedback_current where date(lead_trigger_time)=yesterday() and docid in (select docid from test.lead_bank_qualified_product) \" --format CSV > /tmp/lb_lead_data.csv"
CHECK

step=4.5
echo "Step= $step"
echo "Transfer file from 192.168.42.159 TO 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo scp /tmp/lb_lead_data.csv web_backup@192.168.42.131:/tmp"
CHECK

step=4.6
echo "Step= $step"
echo "INSERT test.lead_bank_qualified_product query on 192.168.42.159"
#ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \"INSERT INTO leads.lead_bank_clients(docid,data_city,dealclose_date,approval_date,budget) select docid,data_city,dealclose_date,approval_date,budget from test.lead_bank_qualified_product where dealclose_date =yesterday();\""
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo clickhouse --client --host 192.168.42.159 -u default --password 'JDcl1ck@dm1n' --query \"INSERT INTO leads.lead_bank_clients(docid,data_city,dealclose_date,approval_date,budget) select docid,data_city,dealclose_date,approval_date,budget from test.lead_bank_qualified_product;\""
CHECK



step=5.1
echo "Step= $step"
echo "DROP query for test.lead_bank_qualified_product on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"drop table if exists test.lead_bank_qualified_product;\""
CHECK

step=5.2
echo "Step= $step"
echo "CREATE query for test.lead_bank_qualified_product on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"CREATE TABLE test.lead_bank_qualified_product ( docid String CODEC(ZSTD(9)),data_city String CODEC(ZSTD(9)),dealclose_date Date CODEC(ZSTD(9)),approval_date Date CODEC(ZSTD(9)),budget Int32 CODEC(ZSTD(9)),campaign String CODEC(ZSTD(9)),end_date Date CODEC(ZSTD(9)),hot_cat_info Int64 DEFAULT 0 CODEC(ZSTD(9)),hot_cat_info_name String CODEC(ZSTD(9)),state String CODEC(ZSTD(9)),zone String CODEC(ZSTD(9)),company_name String CODEC(ZSTD(9)),duration Int32 CODEC(ZSTD(9))) ENGINE = MergeTree ORDER BY (docid, approval_date);\""
CHECK

step=5.3
echo "Step= $step"
echo "INSERT query for lead_bank_qualified_product on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"INSERT INTO test.lead_bank_qualified_product FORMAT CSV \" < /tmp/lead_bank_qualified_data_p1.csv"
CHECK


step=6.1
echo "Step= $step"
echo "DROP query for lb_lead_data on 192.168.42.131 cluster"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"drop table if exists test.lb_lead_data;\""
CHECK

step=6.2
echo "Step= $step"
echo "CREATE query for lb_lead_data on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"CREATE TABLE test.lb_lead_data ( entry_Date date CODEC(ZSTD(9)),docid String CODEC(ZSTD(9)),search_city String CODEC(ZSTD(9)), national_catid UInt64 CODEC(ZSTD(9)),channel UInt32 CODEC(ZSTD(9)),channel_name String CODEC(ZSTD(9)),ld_bnk Int32 CODEC(ZSTD(9)),dup UInt8 CODEC(ZSTD(9)),paid UInt8 CODEC(ZSTD(9)),price String CODEC(ZSTD(9)),qty String CODEC(ZSTD(9)),deal_value String CODEC(ZSTD(9)) ) ENGINE = MergeTree ORDER BY docid SETTINGS index_granularity = 8192;\""
CHECK

step=6.3
echo "Step= $step"
echo "INSERT query for lb_lead_data on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"INSERT INTO test.lb_lead_data FORMAT CSV\" < /tmp/lb_lead_data.csv"
CHECK

step=7
echo "Step= $step"
echo "Removing the Outfiles from all the servers"
echo "192.168.42.159"
ssh ${SSH_ARG} web_backup@192.168.42.159 "sudo rm -fv /tmp/lead_bank_qualified_data_p1.csv /tmp/lb_lead_data.csv"
CHECK
echo "192.168.17.124"
ssh ${SSH_ARG} web_backup@192.168.17.124 "sudo rm -rf /tmp/lead_bank_qualified_docid.csv /tmp/lead_bank_qualified_data_p1.csv"
CHECK
echo "192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo rm -fv /tmp/lead_bank_qualified_data_p1.csv /tmp/lb_lead_data.csv"
CHECK

step=8
echo "Step= $step"
echo "SELECT and OUTFILE query on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"select * from test.lb_lead_data \" --format CSV > /tmp/lb_lead_data_p2.csv"
CHECK

step=8.1
echo "Step= $step"
echo "SCP file /tmp/lb_lead_data_p2.csv to 192.168.38.27"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo scp /tmp/lb_lead_data_p2.csv web_backup@192.168.38.27:/tmp"
CHECK

step=8.2
echo "Step= $step"
echo "CALL procedue on 192.168.38.27"
ssh ${SSH_ARG} web_backup@192.168.38.27 " sudo mysql -Bse \"call test.lb_lead_data_category(1);\""
CHECK

step=8.3
echo "Step= $step"
echo "LOAD infile on 192.168.38.27"
ssh ${SSH_ARG} web_backup@192.168.38.27 " sudo cp /tmp/lb_lead_data_p2.csv /var/lib/mysql-files/"
ERROR
ssh ${SSH_ARG} web_backup@192.168.38.27 "sudo mysql -Bse  \"LOAD DATA INFILE '/var/lib/mysql-files/lb_lead_data_p2.csv' INTO TABLE test.lb_lead_data FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\\\"' LINES TERMINATED BY '\n' ();\""
CHECK
ssh ${SSH_ARG} web_backup@192.168.38.27 "sudo rm -rf /var/lib/mysql-files/lb_lead_data_p2.csv"

step=8.4
echo "Step= $step"
echo "CALL procedue on test.lb_lead_data_category on 192.168.38.27"
ssh ${SSH_ARG} web_backup@192.168.38.27 " sudo mysql -Bse \"call test.lb_lead_data_category(2);\""
CHECK

step=8.5
echo "Step= $step"
echo "LOAD outfile on 192.168.38.27"
ssh ${SSH_ARG} web_backup@192.168.38.27 "sudo mysql -Bse  \"select * from test.lb_lead_data INTO OUTFILE '/var/lib/mysql-files/lb_lead_data_cat_p2.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\\\"' LINES TERMINATED BY '\n';\""
CHECK

step=8.6
echo "Step= $step"
echo "SCP file /tmp/lb_lead_data_cat_p2.csv to 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.38.27 "sudo scp /var/lib/mysql-files/lb_lead_data_cat_p2.csv web_backup@192.168.42.131:/tmp"
CHECK
ssh ${SSH_ARG} web_backup@192.168.38.27 "sudo rm -rf /var/lib/mysql-files/lb_lead_data_cat_p2.csv"

step=8.7
echo "Step= $step"
echo "DROP query on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"drop table  test.lb_lead_data_p2;\""
CHECK

step=8.8
echo "Step= $step"
echo "CREATE query for lb_lead_data_p2 on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"CREATE TABLE test.lb_lead_data_p2(entry_Date date CODEC(ZSTD(9)),docid String CODEC(ZSTD(9)),search_city String CODEC(ZSTD(9)),national_catid UInt64 CODEC(ZSTD(9)),channel UInt32 CODEC(ZSTD(9)),channel_name String CODEC(ZSTD(9)),ld_bnk Int32 CODEC(ZSTD(9)),dup UInt8 CODEC(ZSTD(9)),paid UInt8 CODEC(ZSTD(9)),price String CODEC(ZSTD(9)),qty String CODEC(ZSTD(9)),deal_value String CODEC(ZSTD(9)),prod_avg_price Float32 CODEC(ZSTD(9)),jdmart_id Int32 CODEC(ZSTD(9)),jdmart_catname String CODEC(ZSTD(9)),category_name String CODEC(ZSTD(9)))ENGINE = MergeTree ORDER BY ( docid) SETTINGS index_granularity = 8192;\""
CHECK

step=8.8
echo "Step= $step"
echo "INSERT query for lb_lead_data_p2 on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"INSERT INTO test.lb_lead_data_p2 FORMAT CSV\"< /tmp/lb_lead_data_cat_p2.csv"
CHECK

step=9.1
echo "Step= $step"
echo "remove file  lb_final_data.csv if exist on 42.131 /tmp & 16.72/tmp"
ssh ${SSH_ARG} web_backup@192.168.42.131  "sudo rm -fv /tmp/lb_final_data.csv"
ssh ${SSH_ARG} web_backup@192.168.16.72  "sudo rm -fv /tmp/lb_final_data.csv"
CHECK

step=9.2
echo "Step= $step"
echo "SELECT and OUTFILE query on 192.168.42.131"
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo clickhouse --client --host 192.168.42.131 --query \"SELECT docid, yesterday() AS entry_date, channel AS lead_src, channel_name, data_city, national_catid, category_name AS cat_name, if(ld_bnk = 1, 'lead_bank', '') AS type, if(dup = 0 AND paid = 1, 1, 0) AS upls, if(dup = 0 AND paid = 1 AND deal_value != '', 1, 0) AS upls_with_deal_value, if(deal_value = '', 0, toInt32OrZero(deal_value)) AS actual_deal_value, jdmart_id, jdmart_catname AS jdmart_name, company_name AS companyname, b.data_city AS contract_data_city, state AS contract_state, zone AS contract_zone, hot_cat_info, hot_cat_info_name, budget, toDecimal64(round(budget / nullIf(dateDiff('day', dealclose_date, end_date), 0), 4), 4) AS budget_per_day, if(budget <= 60000, 1, round(budget / 60000, 2)) AS lead_bank_quota_per_day, 1 AS quota_per_day, dealclose_date AS lead_bank_start_date, if(toFloat64OrZero(a.deal_value) > 0 AND b.budget > 0, toFloat64OrZero(a.deal_value) / b.budget, 0) AS roi, multiIf(campaign LIKE '%package%' AND campaign LIKE '%national%', 'Super_Sixer-Both', campaign LIKE '%package%', 'Super_Sixer-Package', campaign LIKE '%national%', 'Super_Sixer-National', 'other') AS paid_type, if(deal_value != '', toFloat64OrZero(deal_value), greatest(if(toFloat64OrZero(qty) > 0, toFloat64(qty), 1) * toFloat64(prod_avg_price), 1000)) AS total_deal_value, end_date AS lead_bank_end_date FROM test.lb_lead_data_p2 a JOIN test.lead_bank_qualified_product b ON a.docid = b.docid \" --format CSV > /tmp/lb_final_data.csv"
CHECK
ssh ${SSH_ARG} web_backup@192.168.42.131 "sudo scp /tmp/lb_final_data.csv web_backup@192.168.16.72:/tmp"
CHECK

step=9.3
echo "Step= $step"
echo "INSERT query for lead_bank_lead_data_final on 192.168.16.72"
ssh ${SSH_ARG} web_backup@192.168.16.72 "sudo clickhouse-client -h 192.168.16.72 -u default --password 'JDcl1ck@dm1n' --query \"INSERT INTO leads.lead_bank_lead_data_final FORMAT CSV\"< /tmp/lb_final_data.csv"
CHECK	

echo " leads_bank_dashboard_process completed successfully on `date`"
echo "sending success email..."

SUCCESS

