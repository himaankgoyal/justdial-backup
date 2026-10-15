#!/bin/bash

DATE=$(date +"%Y-%m-%d")
HNAME="$(hostname | cut -d. -f1)"
SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
EMAIL="chandrashekhar.epilli@justdial.com,dbteam_mis@justdial.com,manisha.pai@justdial.com,hema.sutrave@justdial.com,ashish.agrawal@justdial.com,kuldeep.jaiswal@justdial.com,vivek.jha@justdial.com,neelakandan@justdial.com,priyanka.patankar@justdial.com,neethuj@justdial.com,nagilla.keerthi@justdial.com,sneha.rao@justdial.com,sudhakarsingh@justdial.com,kamini.patel@justdial.com,jeena.singh1@justdial.com,rahamath.unnissa@justdial.com,ernest.jacobs@justdial.com,purnima.sharma1@justdial.com,hemavathi.v@justdial.com,prameshjha@justdial.com,venkatesh.kuchan@justdial.com,navinkumar.yadav@justdial.com,arvind.kumar9@justdial.com,dhakshina.palanisamy@justdial.com,gomathi.pandy@justdial.com,arun8@justdial.com,ayushkumar1@justdial.com,nikhil.dad@justdial.com"
#EMAIL="sandip.mandal@justdial.com,dhakshina.palanisamy@justdial.com"

#EMAIL="dhakshina.palanisamy@justdial.com,karthickeyan.r@justdial.com,gomathi.pandy@justdial.com"

LOCAL_MYSQL_USER="XXXXXXX"
LOCAL_MYSQL_PASS="XXXXXXX"
REMOTE_MYSQL_USER="${LOCAL_MYSQL_USER}"
REMOTE_MYSQL_PASS="${LOCAL_MYSQL_PASS}"
REMOTE1="192.168.17.132"
REMOTE2="192.168.12.219"
REMOTE3="192.186.17.235"
REMOTE4="192.168.12.80"
DCREMOTE="192.168.39.120"
LB_user=$(cat /scripts/.load_autimation.txt | grep -i "Load_user" | awk '{print $3}')
LB_pass=$(cat /scripts/.load_autimation.txt | grep -i "Load_pass" | awk '{print $3}')
LB_IP="192.168.20.210"
MGTID=$(mysql -u ${LB_user} -p${LB_pass} -h ${LB_IP} -Bse "show variables like '%report_host%';" 2>/dev/null  | awk '{ print $2 }')
echo "load balancer IP ==  ${LB_IP}"
echo ""
echo "master server IP ==  ${MGTID}"

##LOGFILE="/var/log/daily_log/wfh_on_boarding_process.log"
LOGFILE="/var/log/daily_log/wfh_on_boarding_new_incremental_modify.log"

# ----- Define Function ---- #
function ERROR
{
        if [ $? -ne 0 ]
        then
                cat ${LOGFILE} | mail -s "${SUBJECT} WFH On Boarding Process Failed " $EMAIL -c "dhakshina.palanisamy@justdial.com"
                exit 1
        fi
}

function SUCCESS
{
        if [ $? -eq 0 ]
        then
               echo "Process Completed Successfully" | mail -s "${SUBJECT} WFH On Boarding Process Sucessfull" -a /tmp/dealdata_on_boarding_final.csv $EMAIL -c "dhakshina.palanisamy@justdial.com"
               exit 0
        fi
}



ERROR() {
    if [ $? -ne 0 ] ; then
        
       echo -e  "onboarding_process on 14.49 failed at $DATE" | mail -s "Failed onboarding_process on 14.49 " $MAILS
       echo "onboarding_process on 14.49 Failed at $DATE" | mail -a  ${LOGFILE}  -s "Failed onboarding_process on 14.49" $EMAIL
           exit 1
        fi
}


SUCCESS() {
      if [ $? -eq 0 ] ; then

             echo "onboarding_process on 14.49 completed successfully at $DATE" | mail -a  ${LOGFILE}  -s "Success onboarding_process on 14.49" $EMAIL
             exit 0
          fi
}


##---------------------------------#


echo "calling report_log.php start"
/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Onboarding%20WFH%20On%20Boarding%20Process&ProcessOwner=10116590&Flag=start" > /dev/null 2>&1
ERROR



echo "Step 1 : Call SP sp_onboarding_data on ${HNAME}"
sudo mysql -Bse 'Call db_allocation.sp_onboarding_data();'
ERROR

echo "Step 2 : Transfer table from ${HNAME} to ${REMOTE1}"
sudo mysqldump db_allocation tbl_dealdata_on_boarding | gzip -fv > /tmp/tbl_dealdata_on_boarding.sql.gz
ERROR

echo "Step 2.1 : Copy to remote server"
sudo scp ${SSH_ARGS} /tmp/tbl_dealdata_on_boarding.sql.gz web_backup@${REMOTE1}:/tmp/
ERROR

echo "Step 2.2 : Restore"
ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo gunzip -fv /tmp/tbl_dealdata_on_boarding.sql"
ERROR

ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo mysql test < /tmp/tbl_dealdata_on_boarding.sql"
ERROR

ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo rm -fv /tmp/tbl_dealdata_on_boarding.sql"
ERROR

sudo rm -fv /tmp/tbl_dealdata_on_boarding.sql.gz
ERROR

echo "Step 3 : Call SP on ${REMOTE1}"
ssh ${SSH_ARGS} web_backup@${REMOTE1}  "sudo mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} -Bse 'Call test.sp_onboarding_profilekyc_np();'"
ERROR

####### STEP 3.1 ######

    echo "STEP 3.1 Dropping table on 192.168.17.132 from  test tbl_dealdata_on_boarding_inc "

    ssh -q ${SSH_ARGS} web_backup@192.168.17.132 "sudo mysql -u process_auto -pgr8exp9master -Bse 'drop table if exists test.tbl_dealdata_on_boarding_inc;'"

ERROR

####### STEP 3.2 ######

    echo "STEP 3.2 Renaming  table on 192.168.17.132 from   test tbl_dealdata_on_boarding to test tbl_dealdata_on_boarding_inc; "

    ssh -q ${SSH_ARGS} web_backup@192.168.17.132 "sudo mysql -u process_auto -pgr8exp9master -Bse 'rename table test.tbl_dealdata_on_boarding to test.tbl_dealdata_on_boarding_inc;'"

ERROR

########################



#echo "Step 4 : Transfer Table from ${REMOTE1} to ${REMOTE2}"
#ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo mysqldump test tbl_dealdata_on_boarding | gzip -fv > /tmp/tbl_dealdata_on_boarding.sql.gz"
#ERROR
#
#echo "4.1"
#ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo scp /tmp/tbl_dealdata_on_boarding.sql.gz `${SSH_ARGS}` web_backup@${REMOTE2}:/tmp/"
#ERROR
#
#echo "4.2"
#ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo gunzip -fv /tmp/tbl_dealdata_on_boarding.sql.gz"
#ERROR
#
#echo "4.3"
#ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock db_reports < /tmp/tbl_dealdata_on_boarding.sql"
#ERROR
#
#echo "4.4"
#ssh ${SSH_ARGS} web_backup@${REMOTE1} "sudo rm -fv /tmp/tbl_dealdata_on_boarding.sql.gz"
#ERROR
#ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo rm -fv /tmp/tbl_dealdata_on_boarding.sql"
#ERROR


####### STEP 4.5 ######

    echo "STEP 4.5 Transfer table tbl_dealdata_on_boarding_inc  from 192.168.17.132 to  192.168.12.233"

    ssh -q ${SSH_ARGS} web_backup@192.168.17.132 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_dealdata_on_boarding_inc | gzip -f > /tmp/tbl_dealdata_on_boarding_inc.sql.gz"

ERROR

    echo "Transfering and restoring table on 192.168.12.233"

    scp -q ${SSH_ARGS} web_backup@192.168.17.132:/tmp/tbl_dealdata_on_boarding_inc.sql.gz web_backup@192.168.12.233:/tmp/

    ssh -q ${SSH_ARGS} web_backup@192.168.12.233 "sudo gunzip -fv /tmp/tbl_dealdata_on_boarding_inc.sql.gz &&  sudo mysql -u process_auto -pgr8exp9master db_reports < /tmp/tbl_dealdata_on_boarding_inc.sql"

ERROR


####### STEP 4.6 ######

   echo " STEP 4.6 Calling SPdb_reports sp_onboarding_233master_incremental on 192.168.12.233"

   ssh -q ${SSH_ARGS}  web_backup@192.168.12.233 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call db_reports.sp_onboarding_233master_incremental();'"

##########################

echo "Step 5.1 Transfer table from 192.168.12.233 to 192.168.12.219"
ssh ${SSH_ARGS} web_backup@192.168.12.233 "sudo mysqldump db_reports tbl_dealdata_on_boarding_inc_master > tbl_dealdata_on_boarding_inc_master.sql"
ERROR

echo "Step 5.2 Transferring table to 192.168.12.233"
ssh ${SSH_ARGS} web_backup@192.168.12.233 "sudo scp tbl_dealdata_on_boarding_inc_master.sql web_backup@${REMOTE2}:"
ERROR

echo "Step 5.3 Restoring table on 192.168.12.219"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock test < tbl_dealdata_on_boarding_inc_master.sql"
ERROR

echo "Step 5.4 Call SP on ${REMOTE2}"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo mysql --socket=/var/lib/SQL_07/mysql/mysql.sock -Bse 'Call db_reports.sp_onborading_3307_incremental_modify();'"
ERROR

echo "Step 6 : Call python script on ${REMOTE2}"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo /bin/python /scripts/dc_eligiblity_api_incremental.py"
ERROR

echo "Step 6.1 : Call python script on ${REMOTE2}"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo /bin/python /scripts/product_serv_count_incremental.py"
ERROR

echo "Step 7 : Taking dump from 3307 on ${REMOTE2}"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo mysqldump --socket=/var/lib/SQL_07/mysql/mysql.sock test tbl_dealdata_on_boarding_final > /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "Step 7.1 : Transfer table from 12.219 3307 to 3306 on ${REMOTE4}"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo scp /tmp/tbl_dealdata_on_boarding_final.sql web_backup@${REMOTE4}:/tmp"
ERROR

echo "Step 7.2 :Importing table from 12.80 3306 on ${REMOTE4}"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock dbteam_temp < /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "Step 7.3 : Removing dumps"
ssh ${SSH_ARGS} web_backup@${REMOTE2} "sudo rm -fv /tmp/tbl_dealdata_on_boarding_final.sql"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo rm -fv /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "Step 8 : Deleting Temporary csv file from 12.219"
sudo ssh ${SSH_ARGS} web_backup@192.168.12.219 "sudo rm -fv /tmp/dealdata_on_boarding_final.csv"
ERROR

echo "Step 8.1 : Call sp on ${REMOTE4} 3306"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse 'Call db_reports.sp_dealdata_on_boarding_new_incremental();'"
ERROR

echo "Step8.1.1 : Call script product_count  on ${REMOTE4}"
ssh ${SSh_ARGS} web_backup@${REMOTE4} "sudo sh /scripts/b2b_product_count.sh"
ERROR
#echo "calling b2b_product_count_old.php"
#/usr/bin/curl "http://192.168.12.219:88/rating_dir/estate_agent/b2b_product_count_old.php"
#ERROR

echo "Step 8.1.2 : update query product_count"

ssh ${SSh_ARGS} web_backup@${REMOTE4} "sudo mysql -Bse 'update dbteam_temp.temp_ob_product_count_8days_unique a join dbteam_temp.tbl_dealdata_on_boarding_final b on a.docid=b.docid set b.active_prod_count=a.product_count,b.brand_connect=if(length(a.brand_connect) > 1,1,0);'"

ssh ${SSh_ARGS} web_backup@${REMOTE4} "sudo mysql -Bse 'update dbteam_temp.temp_ob_product_count_8days_unique a join dbteam_temp.tbl_dealdata_on_boarding_final b on a.docid=b.docid set b.jdmart_eligible_flag=a.jdmart_flag, b.jdmart_eligible=IF(a.jdmart_flag IN (1,2,3,-6),1,0),b.brand_connect=if(a.brand_connect=a.docid,1,0);'"

ERROR

#echo "Step 8.2 : Transferring csv from 12.219 to ${HNAME}"
#scp ${SSH_ARGS} web_backup@192.168.12.219:/tmp/dealdata_on_boarding_final.csv  /tmp/
#ERROR

echo "Step 9 : Transfering table from ${REMOTE4} to 17.235 & 39.120"
echo "9.1"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo mysqldump --socket=/var/lib/SQL/mysql/mysql.sock dbteam_temp tbl_dealdata_on_boarding_final |gzip -fv > /tmp/tbl_dealdata_on_boarding_final.sql.gz"
ERROR


#echo "9.2"
#ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo scp /tmp/tbl_dealdata_on_boarding_final.sql.gz ${SSH_ARGS} web_backup@${MGTID}:/tmp/"
#ERROR

#ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo scp /tmp/tbl_dealdata_on_boarding_final.sql.gz web_backup@${DCREMOTE}:/tmp/"
#ERROR

echo "9.2"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo scp -P 2222 /tmp/tbl_dealdata_on_boarding_final.sql.gz `${SSH_ARGS}` web_backup@${MGTID}:/tmp/"
ERROR

ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo scp /tmp/tbl_dealdata_on_boarding_final.sql.gz `${SSH_ARGS}` web_backup@192.168.24.118:/tmp/"
ERROR


echo "9.3"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo gunzip -fv /tmp/tbl_dealdata_on_boarding_final.sql.gz"
ERROR

echo "9.3.1"

ssh ${SSH_ARGS} web_backup@192.168.24.118 "sudo gunzip -fv /tmp/tbl_dealdata_on_boarding_final.sql.gz"
ERROR

echo "9.4"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "9.4.1"
ssh ${SSH_ARGS} web_backup@192.168.24.118 "sudo mysql jdmart_operations < /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR


echo "9.5"
ssh ${SSH_ARGS} web_backup@${REMOTE4} "sudo rm -fv /tmp/tbl_dealdata_on_boarding_final.sql.gz"
ERROR

echo "9.6"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo rm -fv /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "9.6.1"

ssh ${SSH_ARGS} web_backup@192.168.24.118 "sudo rm -fv /tmp/tbl_dealdata_on_boarding_final.sql"
ERROR

echo "Step 10 : Call SP on ${MGTID}"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master -Bse 'Call online_regis1.sp_final_data_onboarding_incremental();'"
ERROR
#-------------------------------------------------------------#

echo "Step 11 : deleting  dealdata_on_boarding_final.csv on ${MGTID}"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo rm -fv /tmp/dealdata_on_boarding_final.csv"

echo "Step 11.a : deleting dealdata_on_boarding_final.csv on ${HNAME}"
sudo rm -fv /tmp/dealdata_on_boarding_final.csv


###########################################################################
####################### SP STARTS ON ALL CITIES ########################
###########################################################################
####### STEP 12.1 ######

 echo " STEP 12.1 Calling SP on MUMBAI 192.168.39.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.39.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"


####### STEP 12.2 ######

 echo "STEP 12.2 Calling SP on DELHI 192.168.43.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.43.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.3 ######

 echo "STEP 12.3 Calling SP on KOLKAT  192.168.47.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.47.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"


####### STEP 12.4 ######

 echo "STEP 12.4 Calling SP on BANGALORE 192.168.44.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.44.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.5 ######

 echo "STEP 12.5 Calling SP on CHENNAI 192.168.45.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.45.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.6 ######

 echo "STEP 12.6 Calling SP on PUNE 192.168.48.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.48.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.7 ######

 echo "STEP 12.7 Calling SP on HYDERABAD 192.168.46.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.46.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.8 ######

 echo "STEP 12.8 Calling SP on AHMEDABAD 192.168.35.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.35.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"

####### STEP 12.9 ######

 echo "STEP 12.9 Calling SP on REMOTE CITY 192.168.17.171"

    ssh -q ${SSH_ARGS}  web_backup@192.168.17.171 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call test.sp_corporate_contract_daily();'"


###########################################################################
####################### TABLE TRANSFER STARTS HERE ########################
###########################################################################
####### STEP 13.1 ######

    echo "STEP 13.1 Transfer table tbl_corporate_contracts_daily_mum  from 192.168.39.171 to  ${MGTID}"

    ssh -q ${SSH_ARGS}  web_backup@192.168.39.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_mum  > /tmp/tbl_corporate_contracts_daily_mum.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"
    scp -q ${SSH_ARGS} web_backup@192.168.39.171:/tmp/tbl_corporate_contracts_daily_mum.sql /tmp/

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_mum.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222  web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_mum.sql"

ERROR

####### STEP 13.2 ######

    echo "STEP 13.2 Transfer table tbl_corporate_contracts_daily_del  from 192.168.43.171 to ${MGTID}"

    ssh -q ${SSH_ARGS}  web_backup@192.168.43.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_del > /tmp/tbl_corporate_contracts_daily_del.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.43.171:/tmp/tbl_corporate_contracts_daily_del.sql /tmp/ 
    
    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_del.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_del.sql"

ERROR


####### STEP 13.3 ######

    echo "STEP 13.3 Transfer table tbl_corporate_contracts_daily_kol  from 192.168.47.171 to ${MGTID}"

  ssh -q ${SSH_ARGS}  web_backup@192.168.47.171 "sudo  mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_kol > /tmp/tbl_corporate_contracts_daily_kol.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.47.171:/tmp/tbl_corporate_contracts_daily_kol.sql /tmp/ 

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_kol.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_kol.sql"

ERROR



####### STEP 13.4 ######

    echo "STEP 13.4 Transfer table tbl_corporate_contracts_daily_ban  from 192.168.44.171 to ${MGTID}"

  ssh -q ${SSH_ARGS}  web_backup@192.168.44.171 "sudo  mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_ban > /tmp/tbl_corporate_contracts_daily_ban.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.44.171:/tmp/tbl_corporate_contracts_daily_ban.sql /tmp/ 

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_ban.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_ban.sql"

ERROR


####### STEP 13.5 ######

    echo "STEP 13.5 Transfer table tbl_corporate_contracts_daily_che  from 192.168.45.171 to ${MGTID}"

   ssh -q ${SSH_ARGS}  web_backup@192.168.45.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_che > /tmp/tbl_corporate_contracts_daily_che.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.45.171:/tmp/tbl_corporate_contracts_daily_che.sql /tmp/  

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_che.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_che.sql"

ERROR


####### STEP 13.6 ######

    echo "STEP 13.6 Transfer table tbl_corporate_contracts_daily_pun  from 192.168.48.171 to ${MGTID}"

   ssh -q ${SSH_ARGS}  web_backup@192.168.48.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_pun > /tmp/tbl_corporate_contracts_daily_pun.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.48.171:/tmp/tbl_corporate_contracts_daily_pun.sql /tmp/ 

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_pun.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222  web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_pun.sql"

ERROR


####### STEP 13.7 ######

    echo "STEP 13.7 Transfer table tbl_corporate_contracts_daily_hyd  from 192.168.46.171 to ${MGTID}"

   ssh -q ${SSH_ARGS}  web_backup@192.168.46.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_hyd > /tmp/tbl_corporate_contracts_daily_hyd.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.46.171:/tmp/tbl_corporate_contracts_daily_hyd.sql /tmp/ 

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_hyd.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS}  -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_hyd.sql"

ERROR



####### STEP 13.8 ######

    echo "STEP 13.8 Transfer table tbl_corporate_contracts_daily_ahm  from 192.168.35.171 to ${MGTID}"

   ssh -q ${SSH_ARGS}  web_backup@192.168.35.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_ahm > /tmp/tbl_corporate_contracts_daily_ahm.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.35.171:/tmp/tbl_corporate_contracts_daily_ahm.sql /tmp/ 
   
    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_ahm.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222  web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_ahm.sql"

ERROR



###### STEP 13.9 ######

    echo "STEP 13.9 Transfer table tbl_corporate_contracts_daily_rem  from 192.168.17.171 to ${MGTID}"

   ssh -q ${SSH_ARGS}  web_backup@192.168.17.171 "sudo mysqldump -u process_auto -pgr8exp9master test tbl_corporate_contracts_daily_rem > /tmp/tbl_corporate_contracts_daily_rem.sql"

ERROR

    echo "Transfering and restoring table on ${MGTID}"

    scp -q ${SSH_ARGS} web_backup@192.168.17.171:/tmp/tbl_corporate_contracts_daily_rem.sql /tmp/ 

    sudo scp -P 2222 /tmp/tbl_corporate_contracts_daily_rem.sql web_backup@${MGTID}:/tmp/

    ssh -q ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master dbteam_temp < /tmp/tbl_corporate_contracts_daily_rem.sql"

ERROR



echo "Step 14 : Call SP call online_regis1.sp_department_np() on ${MGTID}"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master -Bse 'call online_regis1.sp_department_np();'"
ERROR

echo "Step 14.1: Transferring csv from ${MGTID} to ${HNAME}"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo scp /tmp/dealdata_on_boarding_final.csv web_backup@192.168.14.49:/tmp/"
ERROR

#echo "Step 14.2 : Call SP call online_regis1.sp_final_data_onboarding_incremental_data() on ${MGTID}"
#ssh -p 2222 ${SSH_ARGS} web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master -Bse 'call online_regis1.sp_final_data_onboarding_incremental_data();'"
#ERROR
############################################################

echo "Calling 1st PHP Page "
##old##/usr/bin/curl "http://192.168.17.118:811/services/reminder_notification_service.php?action=dumpyesterdayapprovedcontract&trace=0"  > /var/log/daily_log/reminder_notification_service_dumpyesterdayapprovedcontract.log 2>&1
/usr/bin/curl "http://192.168.1.199:81/cron/notification/reminder_notification_service.php?action=dumpyesterdayapprovedcontract&trace=0"  > /var/log/daily_log/reminder_notification_service_dumpyesterdayapprovedcontract.log 2>&1
ERROR

echo "Calling 2nd PHP Page "
##old##/usr/bin/curl "http://192.168.17.118:811/services/reminder_notification_service.php?action=validationremmsg2&trace=0"  > /var/log/daily_log/reminder_notification_service_validationremmsg2.log 2>&1
##new##/usr/bin/curl "http://192.168.1.199:81/cron/notification/reminder_notification_service.php?action=validationremmsg2&trace=0"  > /var/log/daily_log/reminder_notification_service_validationremmsg2.log 2>&1
ERROR

echo "Calling 3rd PHP Page "
/usr/bin/curl "http://192.168.1.199:81/OnbAlloc_process/onboarding_process.php"  > /var/log/daily_log/onboarding_process_php.log 2>&1
ERROR

echo "calling report_log.php end"
/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Onboarding%20WFH%20On%20Boarding%20Process&ProcessOwner=10116590&Flag=end"  > /dev/null 2>&1
ERROR

echo "Step 14 : Call SP call online_regis1.sp_department_np() on ${MGTID}"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysql -u process_auto -pgr8exp9master -Bse 'call online_regis1.sp_department_np_final();'"
ERROR

echo "Step 14.1 : table from ($MGTID) dbteam_temp to 172.29.64.221(onboarding_content)"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysqldump -u process_auto -pgr8exp9master dbteam_temp temp_categoryinfo_onbcontentallocation_3days | gzip -fv > /tmp/temp_categoryinfo_onbcontentallocation_3days.sql.gz && sudo scp /tmp/temp_categoryinfo_onbcontentallocation_3days.sql.gz web_backup@172.29.64.221:/tmp && sudo rm -fv /tmp/temp_categoryinfo_onbcontentallocation_3days.sql.gz"
ERROR

ssh ${SSH_ARGS} web_backup@172.29.64.221 "sudo gunzip -fv /tmp/temp_categoryinfo_onbcontentallocation_3days.sql.gz && sudo mysql onboarding_content < /tmp/temp_categoryinfo_onbcontentallocation_3days.sql && sudo rm -fv /tmp/temp_categoryinfo_onbcontentallocation_3days.sql"
ERROR



echo "Step 14.2 : Call SP call jdmart_operations.sp_final_data_onboarding_incremental() on 64.26"
ssh ${SSH_ARGS} web_backup@192.168.24.118 "sudo mysql -Bse 'call jdmart_operations.sp_final_data_onboarding_incremental();'"
ERROR

echo "Step 14.2 : Call SP call onboarding_content.sp_categoryinfo_onbcontentallocation() on 172.29.64.221"
ssh ${SSH_ARGS} web_backup@172.29.64.221 "sudo mysql -Bse 'call onboarding_content.sp_categoryinfo_onbcontentallocation();'"
ERROR


echo "Step 15.1 : transfer table 'temp_onboarding_data_3days_omni' from ($MGTID) dbteam_temp to 192.168.23.54(omni_db)"
ssh ${SSH_ARGS} -p 2222 web_backup@${MGTID} "sudo mysqldump -u process_auto -pgr8exp9master dbteam_temp temp_onboarding_data_3days_omni | gzip -fv > /tmp/temp_onboarding_data_3days_omni.sql.gz && sudo scp /tmp/temp_onboarding_data_3days_omni.sql.gz web_backup@192.168.23.54:/tmp && sudo rm -fv /tmp/temp_onboarding_data_3days_omni.sql.gz"

ERROR

ssh ${SSH_ARGS} web_backup@192.168.23.54 "sudo gunzip -fv /tmp/temp_onboarding_data_3days_omni.sql.gz && sudo mysql -u process_auto -pgr8exp9master omni_db < /tmp/temp_onboarding_data_3days_omni.sql && sudo rm -fv /tmp/temp_onboarding_data_3days_omni.sql"
ERROR

echo "Step 15.2 : Call SP call omni_db.sp_final_data_onboarding_allocation() on 192.168.23.54"
ssh ${SSH_ARGS} web_backup@192.168.23.54 "sudo mysql -u process_auto -pgr8exp9master -Bse 'call omni_db.sp_final_data_onboarding_allocation();'"
ERROR
##-------------------------------------------------------------#
echo "Process Successfully completed on ${HNAME}"
SUCCESS

