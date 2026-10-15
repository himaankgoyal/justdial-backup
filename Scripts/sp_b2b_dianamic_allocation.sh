#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
#EMAIL="dbteam_mis@justdial.com,kundan.kumar6@justdial.com,bhavna.chalise@justdial.com,mahendra.seth2@justdial.com"
CCEMAIL="dbteam_mis@justdial.com,kundan.kumar6@justdial.com"
#EMAIL="srinivasnarasimhalu@justdial.com"
LB_user=$(cat /scripts/.load_autimation.txt | grep -i "Load_user" | awk '{print $3}')
LB_pass=$(cat /scripts/.load_autimation.txt | grep -i "Load_pass" | awk '{print $3}')
LB_IP="192.168.20.210"
MGTID=$(mysql -u ${LB_user} -p${LB_pass} -h ${LB_IP} -Bse "show variables like '%report_host%';" 2>/dev/null  | awk '{ print $2 }')
echo "load balancer IP ==  ${LB_IP}"
echo ""
echo "master server IP ==  ${MGTID}"

taigaid=$1
#echo $taigaid
#exit 0

function CHECK(){
        if [ $? -ne 0 ]
        then
        	    EMAIL="kundan.kumar6@justdial.com"
                echo "Hi team B2B Allocation of taiga_id #$taigaid is FAILED" | mail -s " B2B Allocation #$taigaid FAILED" -a /var/log/daily_log/b2b_allocation.log -c ${CCEMAIL} ${EMAIL}
                #echo -e "jdmart data block provision process FAILED" | mail -s "Dealclosed details script FAILED on 192.168.14.49" $EMAIL
                exit 1
        fi

}

function SUCCESS(){
        if [ $? -eq 0 ]
        then
		echo "PROCESS completed successfully, sending mail"
               EMAIL=`mysql -Bse "SELECT empcode FROM db_allocation.tbl_taiga_log where taigaid='${taigaid}';"`
               echo -e "Hi team B2B Allocation of taiga_id #$taigaid is SUCCESS" | mail -s "B2B Allocation #$taigaid SUCCESS"   ${EMAIL} -c ${CCEMAIL}
               exit 0
        fi
}




echo "step 1: Calling SP db_allocation.sp_b2b_dianamic_allocation on 12.80"
mysql -Bse "CALL db_allocation.sp_b2b_dianamic_allocation($taigaid);"
CHECK


echo " step 2: Dump Table  db_allocation.tbl_bp_popular_paid_data_{$taigaid}_tbd  from (192.168.12.80:3306)(db_allocation database) to 192.168.20.210 test database"

echo "step 2.1: Dump Table db_allocation.tbl_bp_popular_paid_data_$taigaid_tbd on 192.168.12.80:3306"
sudo mysqldump db_allocation tbl_bp_popular_paid_data_${taigaid}_tbd | gzip -fv > /tmp/tbl_bp_popular_paid_data_${taigaid}_tbd.sql.gz;
CHECK

echo "step:2.2 Transferring table tbl_bp_popular_paid_data_${taigaid}_tbd to 20.210"
sudo scp ${SSH_ARGS} /tmp/tbl_bp_popular_paid_data_${taigaid}_tbd.sql.gz  web_backup@${MGTID}:/tmp
CHECK

echo "step 2.3: Restore table tbl_bp_popular_paid_data ${taigaid}_tbd on 17.235"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "cd /tmp/ && sudo gunzip -f tbl_bp_popular_paid_data_${taigaid}_tbd.sql.gz && sudo mysql -u process_auto -pgr8exp9master test < /tmp/tbl_bp_popular_paid_data_${taigaid}_tbd.sql"
CHECK

echo "step 2.4: Delete Temporary tables on 12.80"
sudo rm -fv /tmp/tbl_bp_popular_paid_data_${taigaid}_tbd.sql.gz
CHECK

echo "step 2.5: Delete Temporary tables on 20.210"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} "sudo rm -fv /tmp/tbl_bp_popular_paid_data_${taigaid}_tbd.sql"
CHECK


echo "step 3: CALL db_activity.sp_b2b_dianamic_allocation(); - 192.168.20.210 online_regis1 database"
sudo ssh ${SSH_ARGS} web_backup@${MGTID} " sudo mysql -u process_auto -pgr8exp9master -e 'CALL db_activity.sp_b2b_dianamic_allocation ($taigaid)';"
CHECK

echo "step 4: Calling SP db_allocation.sp_b2b_dianamic_deletion on 12.80"
mysql -Bse "CALL db_allocation.sp_b2b_dianamic_deletion($taigaid);"
CHECK

SUCCESS
echo "All process completed"
