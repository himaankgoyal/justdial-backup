#!/bin/bash

SP_CALL="sp_tme_dc_log_half_yearly_dump"
DB="dbteam_temp"
SH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
EMAIL_ID="dbescalations@justdial.com,dbteam_mis@justdial.com,nitesh.nimbalkar1@justdial.com,lalji.yadav@justdial.com,yogita.ladage@justdial.com,gaurav.muley@justdial.com,abhishek.rakshe@justdial.com"
CITYNAME="ahmedabad bangalore chennai delhi hyderabad kolkata mumbai pune remotecities"

function CHECK () {
if [ $? -ne 0 ]
then
        echo "failed on step=$step"
        echo "FAILED : script_tme_dc_log_half_yearly_dump script failed on ${step}  " | mail -s "FAILED : script_tme_dc_log_half_yearly_dump script failed " $EMAIL_ID
        exit 1
fi
}

function SUCCESS () {
if [ $? -eq 0 ]
then

        echo "SRIPT EXECUTED SUCCESSFUL"
        echo "SUCCESS : script_tme_dc_log_half_yearly_dump executed successfully  " | mail -s "SUCCESS : script_tme_dc_log_half_yearly_dump executed successfully " $EMAIL_ID
fi
}

#######################################################################################################
#      Adding this by the request of Nitesh Ambalkar with the approval of Mahendra seth's         #####
#      Date: 04:04:2023, taiga id: 1603, taiga group: Linux Support                               #####
#      Edited by: Sandip Mandal                                                                   ##### 
#######################################################################################################

echo "Step 1.1-CALL below stored procedure on 12.80 3306 in db_reports database"
###sudo ssh ${SH_ARGS}  web_backup@192.168.12.80 "sudo mysql 'CAll db_reports.SP_paid_contracts_daily()';"
sudo ssh ${SH_ARGS}  web_backup@192.168.12.80 "sudo mysql -Bse 'CALL db_reports.SP_paid_contracts_daily();'"
CHECK
echo "step 1.2: Table Transfer from source to destination"
sudo ssh ${SH_ARGS} web_backup@192.168.12.80 'sudo mysqldump db_reports temp_paid_contracts_daily | gzip -fv > /tmp/temp_paid_contracts_daily.sql.gz;sudo scp /tmp/temp_paid_contracts_daily.sql.gz web_backup@172.29.0.216:/tmp'
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/temp_paid_contracts_daily.sql.gz"
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/temp_paid_contracts_daily.sql"
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -fv /tmp/temp_paid_contracts_daily.sql"
CHECK

########  calling sp from 12.219:3307       ####################
echo "New_step=1 SP call on 12.219:3307"
sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 -Bse "Call db_reports.sp_all_process_temp_docid();"
CHECK

######## Table transfer from source 12.219:3307 to destination 0.216 ##################

echo "New_Step 2 : Table Transfer from source 12.219:3307 to destination 0.216"
for i in ${CITYNAME};
do
   echo "New_Step 2 for city ${i}"
   sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock --port=3307 dbteam_temp temp_company_master_${i} | gzip -fv > /tmp/temp_company_master_${i}.sql.gz 
   CHECK
   sudo scp ${SH_ARGS} /tmp/temp_company_master_${i}.sql.gz web_backup@172.29.0.216:/tmp/
   CHECK

   sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/temp_company_master_${i}.sql.gz"
   CHECK

   sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/temp_company_master_${i}.sql"
   CHECK

   sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -rf /tmp/temp_company_master_${i}.sql "
   CHECK

   echo "Tranfer table temp_company_master_<citywise> from 12.219 3307 to 12.142 for rating review updation"
   sudo scp ${SH_ARGS} /tmp/temp_company_master_${i}.sql.gz web_backup@192.168.12.142:/tmp/
   CHECK

   sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo gunzip -fv /tmp/temp_company_master_${i}.sql.gz"
   CHECK

   sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo mysql test < /tmp/temp_company_master_${i}.sql"
   CHECK

   sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo rm -rf /tmp/temp_company_master_${i}.sql "
   CHECK

   sudo rm -rf /tmp/temp_company_master_${i}.sql.gz
   CHECK

done

########  calling sp from 1.8 on test database     ####################



echo "New_Step 3: CALL below stored procedure on 1.8 in test database"

sudo ssh ${SH_ARGS} web_backup@192.168.1.8 "sudo mysql -Bse 'CALL test.sp_search_not_found_details_incorrect_table_dump();'"
CHECK

#######  Table Transfer from 1.8 to 0.216 ################
echo "New_Step 4: Table Transfer from source 1.8 test db to destination 0.216 india_snapshot db "
sudo ssh ${SH_ARGS}  web_backup@192.168.1.8 "sudo mysqldump test temp_details_incorrect_tbd | gzip -fv > /tmp/temp_details_incorrect_tbd.sql.gz"
CHECK


sudo ssh ${SH_ARGS}  web_backup@192.168.1.8 "sudo mysqldump test temp_search_not_found_tbd | gzip -fv > /tmp/temp_search_not_found_tbd.sql.gz"
CHECK

sudo ssh ${SH_ARGS}  web_backup@192.168.1.8 "sudo scp  /tmp/temp_details_incorrect_tbd.sql.gz /tmp/temp_search_not_found_tbd.sql.gz web_backup@172.29.0.216:/tmp/"
CHECK


sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/temp_details_incorrect_tbd.sql.gz /tmp/temp_search_not_found_tbd.sql.gz "
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/temp_details_incorrect_tbd.sql"
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/temp_search_not_found_tbd.sql"
CHECK
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -rf /tmp/temp_details_incorrect_tbd.sql /tmp/temp_search_not_found_tbd.sql "
CHECK      
sudo ssh ${SH_ARGS} web_backup@192.168.1.8  "sudo rm -rf /tmp/temp_details_incorrect_tbd.sql.gz /tmp/temp_search_not_found_tbd.sql.gz"
CHECK

########  calling sp from 0.216 on india_snapshot database     ####################

echo "New_Step 5:CALL below stored procedure on 0.216 in india_snapshot database"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216  "sudo mysql -Bse 'CALL india_snapshot.sp_search_not_found_details_incorrect_table_final();'"
CHECK

###################################################################
echo "Updated parts executed successfully"                   ######
## Above updated done                                        ######
###################################################################

## step1 : calling sp  dbteam_temp.sp_tme_dc_log_half_yearly_dump on 12.142
step=1
sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo mysql -Bse 'Call ${DB}.${SP_CALL}();'"
CHECK
###step 2:transfer below tables from 192.168.12.142 to 172.29.0.216
step=2

for i in `cat /scripts/table_dc_log`
do
sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo mysqldump ${DB} ${i} | gzip -fv > /tmp/${i}.sql.gz &&  scp  /tmp/${i}.sql.gz web_backup@172.29.0.216:/tmp/"
CHECK

###step 3: gunzip ${i}.sql.gz on 172.29.0.216
step=3
echo " gunzip  ${i}.sql.gz on 172.29.0.216"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/${i}.sql.gz"
CHECK

###step4 : restoring ${i} in india_snapshot 
step=4
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/${i}.sql"
CHECK

step=5
sudo ssh ${SH_ARGS} web_backup@192.168.12.142 "sudo rm -rf /tmp/${i}.sql.gz"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -rf /tmp/${i}.sql"
 done
CHECK



#### step 6 : calling sp on panindia and remote xx.171
step=6
for j in `cat /scripts/xx.171_server | cut -d ':' -f1` 
do
sudo ssh ${SH_ARGS} web_backup@${j} "sudo mysql -Bse 'Call d_jds.sp_all_process_dump_6_m();'"
CHECK
done
CHECK


#### step 7 : Transfer tables from xx.171 to 172.29.0.216
#step=7
#
#for k in `cat /home/utsav/citywise_temp_table`
#do
#for l in `cat /home/utsav/city_name`
#do
#sudo ssh ${SH_ARGS} web_backup@${j} "sudo mysqldump d_jds ${k}_${l} | gzip -fv > /tmp/${k}_${l}.sql.gz && scp  /tmp/${k}_${l}.sql.gz web_backup@172.29.0.216:/tmp/"
#
#done

####step 8: gunzip ${k}_${l}.sql.gz on 172.29.0.216
#step=8
#
#echo " gunzip  ${k}_${l}.sql.gz on 172.29.0.216"
#sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip /tmp/${k}_${l}.sql.gz"
#

####step 9 : restoring ${k}_${l} in india_snapshot
#sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/${k}_${l}.sql"
#
#sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -rf /tmp/${k}_${l}.sql"
#done

### STEP 7 transfer below tables from respective 171 server to 172.29.0.216
step=7
echo "Transferring tables from xx.171 to 0.216"

for j in `cat /home/utsav/xx.171_server`

do
ip=$(echo $j | cut -d ':' -f1)
city=$(echo $j | cut -d ':' -f2)

   for k in `cat /scripts/citywise_temp_table`
   do
      sudo ssh ${SH_ARGS} web_backup@${ip} "sudo mysqldump d_jds ${k}_${city} | gzip -fv > /tmp/${k}_${city}.sql.gz && sudo scp  /tmp/${k}_${city}.sql.gz web_backup@172.29.0.216:/tmp/"
      CHECK

      sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/${k}_${city}.sql.gz"
      CHECK

      sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/${k}_${city}.sql"
      CHECK

      sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -rf /tmp/${k}_${city}.sql"
      CHECK
      sudo ssh ${SH_ARGS} web_backup@${ip} "sudo rm -rf /tmp/${k}_${city}.sql.gz"
	CHECK	
   done
done

step=8
echo " Call india_snapshot.sp_tme_dc_log_dump_data(); sp on 172.29.0.216"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql -Bse 'Call india_snapshot.sp_tme_dc_log_dump_data();'"
CHECK

SUCCESS

########step 9: calling sp from 1.169 on test database     ####################

echo "New_Step 9:CALL below stored procedure on 1.169 in test database"
sudo ssh ${SH_ARGS} web_backup@192.168.1.169  "sudo mysql -Bse 'CAll test.sp_edit_listing_dump();'"
CHECK

###step 10:transfer tables from 192.168.1.169 to 172.29.0.216

sudo ssh ${SH_ARGS} web_backup@192.168.1.169 "sudo mysqldump test temp_editlisting_daily |sudo gzip -fv > /tmp/temp_editlisting_daily.sql.gz"
CHECK

sudo scp web_backup@192.168.1.169:/tmp/temp_editlisting_daily.sql.gz web_backup@172.29.0.216:/tmp/
CHECK

sudo ssh ${SH_ARGS} web_backup@192.168.1.169 "sudo rm -fv /tmp/temp_editlisting_daily.sql.gz"

### gunzip temp_editlisting_daily.sql.gz on 172.29.0.216

echo "gunzip temp_editlisting_daily.sql.gz on 172.29.0.216"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo gunzip -fv /tmp/temp_editlisting_daily.sql.gz"
CHECK

### restoring temp_editlisting_daily in test

sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo mysql india_snapshot < /tmp/temp_editlisting_daily.sql"
CHECK

sudo ssh ${SH_ARGS} web_backup@172.29.0.216 "sudo rm -fv /tmp/temp_editlisting_daily.sql"


########step 11:calling sp from 172.29.0.216 on india_snapshot database ####################

echo "New_Step 11:CALL below stored procedure on 0.216 in india_snapshot database"
sudo ssh ${SH_ARGS} web_backup@172.29.0.216  "sudo mysql -Bse 'CAll india_snapshot.sp_editlisting_dump();'"
CHECK




