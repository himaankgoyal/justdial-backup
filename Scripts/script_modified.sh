#!/bin/bash

SSH_ARG='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
DATE=`date +%d-%m-%Y`


EMAIL_ADDRS="dbteam_mis@justdial.com, dhakshina.palanisamy@justdial.com, nitesh.nimbalkar1@justdial.com, sushmitha.boddu@justdial.com, mahendra.seth2@justdial.com, gomathi.pandy@justdial.com"
#EMAIL_ADDRS="manoj3@justdial.com,dhakshina.palanisamy@justdial.com,sushmitha.boddu@justdial.com"

SUBJECT_SUCCESS="Success - Data enrichment website timing r01l01"
SUCCESS_CONTENT="Success Data enrichment website timing r01l01r from 12.219:3307 to 39.120 server."

SUBJECT_FAILURE="Failure - Data enrichment website timing r01l01"
FAILURE_CONTENT=" Failure Data enrichment website timing r01l01 from 12.219:3307 to 39.120 server."

######################### Functions ##################################

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
else
        echo "Failed"
        sudo echo -e "${FAILURE_CONTENT}" | sudo mail -a /var/log/daily_log/dataenrichment_website_timing_r01l01.log -s "${SUBJECT_FAILURE}" ${EMAIL_ADDRS}
        exit 1
fi
}

function SUCCESS () {
if [ $? -eq 0 ]; then
        echo "${SUCCESS_CONTENT} completed on `date`"
        echo "${SUCCESS_CONTENT}" | mail -s "${SUBJECT_SUCCESS} process completed" ${EMAIL_ADDRS}
fi
}

############################################# step-1 ################################################

step=1
echo "step ${step}"
##variable = timing_count
##variable = website_count
#timing_count=$(ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse \"SELECT count(1) FROM company_mapping.tbl_data_enrichment_BP_source_process_table where done_flag=0 and timing_update=0 and (source_timing <> '') and docid <> '';\"")

#website_count=$(ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse \"SELECT count(1) FROM company_mapping.tbl_data_enrichment_BP_source_process_table where done_flag=0 and website_update=0 and (source_website <> '') and docid <> '';\"")
CHECK


ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse \"SELECT count(1) FROM company_mapping.tbl_data_enrichment_BP_source_process_table where done_flag=0 and timing_update=0 and (source_timing <> '') and docid <> '';\""

ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse \"SELECT count(1) FROM company_mapping.tbl_data_enrichment_BP_source_process_table where done_flag=0 and website_update=0 and (source_website <> '') and docid <> '';\""
################################## step-1.1 ###################
step=1.1
echo "step ${step} : call db_reports.sp_dataenrichment_contact_number_received();"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse 'call db_reports.sp_dataenrichment_contact_number_received();'"
CHECK

step=1.1.1
echo "step ${step} : call db_reports.sp_dataenrichment_contact_number_received();"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo mysql -Bse 'call db_reports.sp_dataenrichment_contact_number_received();'"
CHECK

################################## step-1.2 ###################
step=1.2
echo "step ${step} : Table transfer "

echo "Taking Dump of 'temp_dataenrichment_timing_received' on 29.65 and sending to 12.219(for 3307)"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysqldump db_reports temp_dataenrichment_timing_received | gzip -fv > /tmp/temp_dataenrichment_timing_received.sql.gz"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo scp ${SSH_ARG} /tmp/temp_dataenrichment_timing_received.sql.gz web_backup@192.168.12.219:/tmp"


echo -e "\nUnziping temp_dataenrichment_timing_received.sql.gz on 12.219(for 3307)"
ssh ${SSH_ARG} web_backup@192.168.12.219 "gunzip /tmp/temp_dataenrichment_timing_received.sql.gz"

echo "\nRestoring temp_dataenrichment_timing_received.sql on 12.219(used 3307)"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp < /tmp/temp_dataenrichment_timing_received.sql"

echo -e "\nRemoving temp_dataenrichment_timing_received.sql.gz from 29.65"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/temp_dataenrichment_timing_received.sql.gz"

echo -e "\nRemoving temp_dataenrichment_timing_received.sql.gz from 12.219(used 3307)"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_dataenrichment_timing_received.sql"
CHECK
##################

echo "Taking Dump of 'temp_dataenrichment_website_received' on 29.65 and sending to 12.219(for 3307)"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysqldump db_reports temp_dataenrichment_website_received | gzip -fv > /tmp/temp_dataenrichment_website_received.sql.gz"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo scp ${SSH_ARG} /tmp/temp_dataenrichment_website_received.sql.gz web_backup@192.168.12.219:/tmp"
CHECK

echo -e "\nUnziping temp_dataenrichment_website_received.sql.gz on 12.219(for 3307)"
ssh ${SSH_ARG} web_backup@192.168.12.219 "gunzip /tmp/temp_dataenrichment_website_received.sql.gz"
CHECK

echo "\nRestoring temp_dataenrichment_website_received.sql on 12.219:3307"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp < /tmp/temp_dataenrichment_website_received.sql"
CHECK
echo -e "\nRemoving temp_dataenrichment_website_received.sql.gz from 39.120"
ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo rm -fv /tmp/temp_dataenrichment_website_received.sql.gz"
CHECK
echo -e "\nRemoving temp_dataenrichment_website_received.sql.gz from 12.219(used 3307)"
ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_dataenrichment_website_received.sql"
CHECK
##################

echo "Taking Dump of 'tbl_edit_restrict' on  39.120 and sending to 12.80"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo mysqldump db_reports tbl_edit_restrict | gzip -fv > /tmp/tbl_edit_restrict.sql.gz"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo scp ${SSH_ARG} /tmp/tbl_edit_restrict.sql.gz web_backup@192.168.12.80:/tmp"
CHECK

echo -e "\nUnziping tbl_edit_restrict.sql.gz on 12.80"
sudo gunzip /tmp/tbl_edit_restrict.sql.gz
CHECK
echo "\nRestoring tbl_edit_restrict.sql on 12.219"
sudo mysql  dbteam_temp < /tmp/tbl_edit_restrict.sql
CHECK
echo -e "\nRemoving tbl_edit_restrict.sql.gz from 39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/tbl_edit_restrict.sql.gz"
CHECK
echo -e "\nRemoving tbl_edit_restrict.sql.gz from 12.80"
sudo rm -fv /tmp/tbl_edit_restrict.sql
CHECK
#################

echo "Taking Dump of 'temp_block_number_tbd' on  39.120 and sending to 12.80"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo mysqldump db_reports temp_block_number_tbd | gzip -fv > /tmp/temp_block_number_tbd.sql.gz"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo scp ${SSH_ARG} /tmp/temp_block_number_tbd.sql.gz web_backup@192.168.12.80:/tmp"
CHECK

echo -e "\nUnziping temp_block_number_tbd.sql.gz on 12.80"
sudo gunzip /tmp/temp_block_number_tbd.sql.gz
CHECK
echo "\nRestoring temp_block_number_tbd.sql on 12.80"
sudo mysql  dbteam_temp < /tmp/temp_block_number_tbd.sql
CHECK
echo -e "\nRemoving temp_block_number_tbd.sql.gz from 39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/temp_block_number_tbd.sql.gz"
CHECK
echo -e "\nRemoving temp_block_number_tbd.sql.gz from 12.80"
sudo rm -fv /tmp/temp_block_number_tbd.sql
CHECK


###########################################################################################
######################### if timing_count >0 (step 2 to step 6) ###########################
###########################################################################################


if [ $timing_count -gt 0 ]
then
   ################################## step2 ######################################################
    step=2
    echo "step ${step} : call storedprocedure in 192.168.12.219:3307 "
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse 'call db_reports.sp_dataenrichment_timing_process();'"
    CHECK
   ################################## step2.1 ################
    step=2.1
    echo "step ${step} : Transfer table 'temp_timing_dataenrichment_taiga_process_tbd' from 192.168.12.219:3307 to 12.80"
   
    echo "Taking Dump of 'temp_timing_dataenrichment_taiga_process_tbd' on  12.219 and sending to 12.80"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp temp_timing_dataenrichment_taiga_process_tbd | gzip -fv > /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo scp ${SSH_ARG} /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz web_backup@192.168.12.80:/tmp"
    CHECK



    echo -e "\nUnziping temp_timing_dataenrichment_taiga_process_tbd.sql.gz on 12.80"
    sudo gunzip /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz
    CHECK

    echo "\nRestoring temp_timing_dataenrichment_taiga_process_tbd.sql on 12.80"
    sudo mysql  dbteam_temp < /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql
    CHECK

    echo -e "\nRemoving temp_timing_dataenrichment_taiga_process_tbd.sql.gz from 12.80"
    sudo rm -fv /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql
    CHECK

    echo -e "\nRemoving temp_timing_dataenrichment_taiga_process_tbd.sql.gz from 12.219"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz"
   CHECK

   ################################## step 3 ######################################################
    step=3
    echo "step ${step} : call storedprocedure in 192.168.12.80"
    sudo mysql -Bse 'call db_reports.sp_dataenrichment_timing_process();'
    CHECK

    echo "STEP=3.1"    
   
   for i in temp_de_consolidated_master_history_timing_ahm temp_de_consolidated_master_history_timing_ban temp_de_consolidated_master_history_timing_che temp_de_consolidated_master_history_timing_del temp_de_consolidated_master_history_timing_hyd temp_de_consolidated_master_history_timing_kol temp_de_consolidated_master_history_timing_mum temp_de_consolidated_master_history_timing_pun temp_de_consolidated_master_history_timing_rem ;
    do
   
    echo "STEP 3.1 taking dump on 192.168.12.80"
   
   #ssh -q ${SSH_ARG} web_backup@192.168.12.80 "sudo mysqldump dbteam_temp $i > /tmp/$i.sql && sudo gzip /tmp/$i.sql"
    ssh -q ${SSH_ARG} web_backup@192.168.12.80 "sudo mysqldump dbteam_temp $i | gzip -fv > /tmp/${i}.sql.gz"
    CHECK    
    done  

    echo "Transfering and restoring table on 171 ahmedabad bangalore chennai delhi hyderabad kolkata mumbai pune remote"

    sudo scp /tmp/temp_de_consolidated_master_history_timing_ahm.sql.gz web_backup@192.168.35.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_ban.sql.gz web_backup@192.168.44.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_che.sql.gz web_backup@192.168.45.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_del.sql.gz web_backup@192.168.43.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_hyd.sql.gz web_backup@192.168.46.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_kol.sql.gz web_backup@192.168.47.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_mum.sql.gz web_backup@192.168.39.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_pun.sql.gz web_backup@192.168.48.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_timing_rem.sql.gz web_backup@192.168.17.171:/tmp/
    CHECK

    echo "Transfering and restoring table on 192.168.35.171 ahmedabad and remove "

    ssh -q ${SSH_ARG} web_backup@192.168.35.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_ahm.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_ahm.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_ahm.sql"
CHECK


    echo "Transfering and restoring table on 192.168.44.171 Bangalore"

    ssh -q ${SSH_ARG} web_backup@192.168.44.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_ban.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_ban.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_ban.sql"
CHECK


    echo "Transfering and restoring table on 192.168.45.171 chennai"

    ssh -q ${SSH_ARGS} web_backup@192.168.45.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_che.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_che.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_che.sql"
CHECK


    echo "Transfering and restoring table on 192.168.43.171 delhi"

    ssh -q ${SSH_ARG} web_backup@192.168.43.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_del.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_del.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_del.sql"
CHECK
    
    echo "Transfering and restoring table on 192.168.46.171 hyderabad"

    ssh -q ${SSH_ARG} web_backup@192.168.46.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_hyd.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_hyd.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_hyd.sql"
CHECK


    echo "Transfering and restoring table on 192.168.47.171 kolkata"

    ssh -q ${SSH_ARG} web_backup@192.168.47.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_kol.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_kol.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_kol.sql"
CHECK


    echo "Transfering and restoring table on 192.168.39.171 mumbai"


    ssh -q ${SSH_ARG} web_backup@192.168.39.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_mum.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_mum.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_mum.sql"
CHECK

    echo "Transfering and restoring table on 192.168.48.171 pune"

    ssh -q ${SSH_ARG} web_backup@192.168.48.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_pun.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_pun.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_pun.sql"
CHECK

    echo "Transfering and restoring table on 192.168.17.171 remote"

    ssh -q ${SSH_ARG} web_backup@192.168.17.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_timing_rem.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_timing_rem.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_timing_rem.sql"
CHECK


    echo "Deleting Temporary tables from 192.168.12.80"
 #    ssh ${SSH_ARG} web_backup@192.168.12.80 "sudo rm -fv /tmp/$i.sql.gz"
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_ahm.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_ban.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_che.sql.gz 
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_del.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_hyd.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_kol.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_mum.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_pun.sql.gz
    CHECK    
    sudo rm -vf /tmp/temp_de_consolidated_master_history_timing_rem.sql.gz
    CHECK


    step=3.2
    echo "step ${step}"
    echo "call storedprocedure in all 171 series servers"

    ssh -q ${SSH_ARG} web_backup@192.168.35.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.44.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.45.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.43.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.46.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.47.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.39.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.48.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.17.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_timing_process();'"
    CHECK
    ################################## step 4 ######################################################
    step=4
    echo "step ${step} : call storedprocedure in 192.168.12.80"
    sudo mysql -Bse 'call db_reports.sp_dataenrichment_timing_process_two();'
    CHECK
    ################################## step 5 ######################################################
    step=5
    echo "step ${step} : Transfer table 'temp_timing_dataenrichment_taiga_process_tbd' from 192.168.12.80(dbteam_temp) to 192.168.29.65(db_reports)"
    
    echo "Taking Dump of 'temp_timing_dataenrichment_taiga_process_tbd' on  12.80 and sending to 29.65"
    sudo mysqldump dbteam_temp temp_timing_dataenrichment_taiga_process_tbd | gzip -fv > /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz
    sudo scp ${SSH_ARG} /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz web_backup@192.168.29.65:/tmp
    CHECK
    echo -e "\nUnziping temp_timing_dataenrichment_taiga_process_tbd.sql.gz on 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "gunzip /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz"
    CHECK
    echo "\nRestoring temp_timing_dataenrichment_taiga_process_tbd.sql on 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql  db_reports < /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql"
    CHECK

    echo -e "\nRemoving tbl_edit_restrict.sql.gz from 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo rm -fv /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql"
    CHECK

    echo -e "\nRemoving tbl_edit_restrict.sql.gz from 12.80"
    sudo rm -fv /tmp/temp_timing_dataenrichment_taiga_process_tbd.sql.gz

    CHECK
    ################################## step 6 ######################################################
    step=6
    echo "step ${step} : call storedprocedure in 192.168.29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse 'call db_reports.sp_dataenrichment_timing_process();'"
   CHECK
else
    echo  "No timing data to process in data enrichment"
fi

###########################################################################################
######################### if website_count >0 (step 7 to step 11) #########################
###########################################################################################

if [ ${website_count} -gt 0 ]
then
    ################################## step 7 ######################################################
    step=7
   echo "step ${step} : call storedprocedure in 192.168.12.219:3307"
    ssh ${SSH_ARG} web_backup@192.168.12.219 " sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 'call db_reports.sp_dataenrichment_website_process();'"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysql -uprocess_auto -pgr8exp9master --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse 'call db_reports.sp_dataenrichment_website_process();'"

    CHECK
    ################################## step 7.1 ######################################################
    step=7.1
    echo "step ${step} : Transfer table 'temp_website_dataenrichment_taiga_process_tbd' from 192.168.12.219:3307(dbteam_temp) to 192.168.12.80(dbteam_temp)"
    
    echo "Taking Dump of 'temp_website_dataenrichment_taiga_process_tbd' on  12.219 and sending to 12.80"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp temp_website_dataenrichment_taiga_process_tbd | gzip -fv > /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo scp ${SSH_ARG} /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz web_backup@192.168.12.80:/tmp"
    CHECK

    echo -e "\nUnziping temp_website_dataenrichment_taiga_process_tbd.sql.gz on 12.80"
    sudo gunzip /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz
    CHECK

    echo "\nRestoring temp_website_dataenrichment_taiga_process_tbd.sql on 12.80"
    sudo mysql  dbteam_temp < /tmp/temp_website_dataenrichment_taiga_process_tbd.sql
    CHECK

    echo -e "\nRemoving temp_website_dataenrichment_taiga_process_tbd.sql.gz from 12.80"
    sudo rm -fv /tmp/temp_website_dataenrichment_taiga_process_tbd.sql
    CHECK

    echo -e "\nRemoving temp_website_dataenrichment_taiga_process_tbd.sql.gz from 12.219"
    ssh ${SSH_ARG} web_backup@192.168.12.219 "sudo rm -fv /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz"

    CHECK


    ################################## step 8 ######################################################
    step=8
    echo "step ${step} : call storedprocedure in 192.168.12.80"
#    sudo mysql -Bse 'call db_reports.sp_dataenrichment_website_process();'
    sudo mysql -Bse 'call db_reports.sp_dataenrichment_website_process();'

    CHECK
   
    echo "STEP=8.1"    
    
for i in temp_de_consolidated_master_history_website_ahm temp_de_consolidated_master_history_website_ban temp_de_consolidated_master_history_website_che temp_de_consolidated_master_history_website_del temp_de_consolidated_master_history_website_hyd temp_de_consolidated_master_history_website_kol temp_de_consolidated_master_history_website_mum temp_de_consolidated_master_history_website_pun temp_de_consolidated_master_history_website_rem ;
do
    
    echo " Taking dump on 192.168.12.80"
    #ssh -q ${SSH_ARG} web_backup@192.168.12.80 "sudo mysqldump dbteam_temp $i > /tmp/$i.sql && sudo gzip /tmp/$i.sql"
    sudo mysqldump dbteam_temp $i | gzip -fv > /tmp/${i}.sql.gz
    CHECK
done  

    echo "Transfering and restoring table on 171 ahmedabad bangalore chennai delhi hyderabad kolkata mumbai pune remote"

    sudo scp /tmp/temp_de_consolidated_master_history_website_ahm.sql.gz web_backup@192.168.35.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_ban.sql.gz web_backup@192.168.44.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_che.sql.gz web_backup@192.168.45.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_del.sql.gz web_backup@192.168.43.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_hyd.sql.gz web_backup@192.168.46.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_kol.sql.gz web_backup@192.168.47.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_mum.sql.gz web_backup@192.168.39.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_pun.sql.gz web_backup@192.168.48.171:/tmp/
    sudo scp /tmp/temp_de_consolidated_master_history_website_rem.sql.gz web_backup@192.168.17.171:/tmp/

    


    echo "Transfering and restoring table on 192.168.35.171 ahmedabad and remove "

    ssh -q ${SSH_ARG} web_backup@192.168.35.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_ahm.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_ahm.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_ahm.sql"
CHECK


    echo "Transfering and restoring table on 192.168.44.171 Bangalore"

    ssh -q ${SSH_ARG} web_backup@192.168.44.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_ban.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_ban.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_ban.sql"
CHECK


i    echo "Transfering and restoring table on 192.168.45.171 chennai"

    ssh -q ${SSH_ARG} web_backup@192.168.45.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_che.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_che.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_che.sql"
CHECK


    echo "Transfering and restoring table on 192.168.43.171 delhi"

    ssh -q ${SSH_ARG} web_backup@192.168.43.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_del.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_del.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_del.sql"
CHECK
    
    echo "Transfering and restoring table on 192.168.46.171 hyderabad"

    ssh -q ${SSH_ARG} web_backup@192.168.46.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_hyd.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_hyd.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_hyd.sql"
CHECK


    echo "Transfering and restoring table on 192.168.47.171 kolkata"

    ssh -q ${SSH_ARG} web_backup@192.168.47.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_kol.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_kol.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_kol.sql"
CHECK


    echo "Transfering and restoring table on 192.168.39.171 mumbai"


    ssh -q ${SSH_ARG} web_backup@192.168.39.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_mum.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_mum.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_mum.sql"
CHECK

    echo "Transfering and restoring table on 192.168.48.171 pune"

    ssh -q ${SSH_ARG} web_backup@192.168.48.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_pun.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_pun.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_pun.sql"
CHECK

    echo "Transfering and restoring table on 192.168.17.171 remote"

    ssh -q ${SSH_ARG} web_backup@192.168.17.171 "sudo gunzip -fv /tmp/temp_de_consolidated_master_history_website_rem.sql.gz && sudo mysql d_jds < /tmp/temp_de_consolidated_master_history_website_rem.sql && sudo rm -fv /tmp/temp_de_consolidated_master_history_website_rem.sql"
CHECK


    echo "Deleting Temporary tables from 192.168.12.80"
   # ssh ${SSH_ARG} web_backup@192.168.12.80 "sudo rm -fv /tmp/$i.sql.gz"
   # CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_ahm.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_ban.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_che.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_del.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_hyd.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_kol.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_mum.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_pun.sql.gz
    CHECK
    sudo rm -vf /tmp/temp_de_consolidated_master_history_website_rem.sql.gz
    CHECK
    step=8.2
    echo "call storedprocedure in all 171 series servers"

    ssh -q ${SSH_ARG} web_backup@192.168.35.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.44.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.45.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.43.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.46.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.47.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.39.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.48.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ssh -q ${SSH_ARG} web_backup@192.168.17.171 "sudo mysql -Bse 'call d_jds.sp_dataenrichment_website_process();'"
    CHECK

    ################################## step 9 ######################################################
    step=9
    echo "step ${step} : call storedprocedure in 192.168.12.80"
    sudo mysql -Bse 'call db_reports.sp_dataenrichment_website_process_two();'
    CHECK

    ################################## step 10 ######################################################
    step=10
    echo "step ${step} : Transfer table 'temp_website_dataenrichment_taiga_process_tbd' from 192.168.12.80(dbteam_temp) to 192.168.29.65(db_reports)"

    echo "Taking Dump of 'temp_website_dataenrichment_taiga_process_tbd' on  12.80 and sending to 29.65"
    sudo mysqldump dbteam_temp temp_website_dataenrichment_taiga_process_tbd | gzip -fv > /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz
    sudo scp ${SSH_ARG} /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz web_backup@192.168.29.65:/tmp
    CHECK

    echo -e "\nUnziping temp_website_dataenrichment_taiga_process_tbd.sql.gz on 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "gunzip /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz"
    CHECK

    echo "\nRestoring temp_website_dataenrichment_taiga_process_tbd.sql on 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql  db_reports < /tmp/temp_website_dataenrichment_taiga_process_tbd.sql"
    CHECK

    echo -e "\nRemoving temp_website_dataenrichment_taiga_process_tbd.sql.gz from 29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo rm -fv /tmp/temp_website_dataenrichment_taiga_process_tbd.sql"
    CHECK

    echo -e "\nRemoving temp_website_dataenrichment_taiga_process_tbd.sql.gz from 29.65"
    sudo rm -fv /tmp/temp_website_dataenrichment_taiga_process_tbd.sql.gz


    CHECK

    ################################## step 11 ######################################################
    step=11
    echo "step ${step} : call storedprocedure in 192.168.29.65"
    ssh ${SSH_ARG} web_backup@192.168.29.65 "sudo mysql -Bse 'call db_reports.sp_dataenrichment_website_process();'"
    CHECK
else
    echo "No website data to process in data enrichment"
fi
SUCCESS

################################## done ######################################################

