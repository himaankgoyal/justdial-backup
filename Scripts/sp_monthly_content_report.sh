#!/bin/bash

# Script by : rahul dhakad
# Created from scratch on : <14-03-2018>  Track Ticket No: 
# Technical stake holder : <pravin yadav from rajeev nair team>
# Contact no of technical stake holder : <verna => 2478>
# Business stake holder : <rajeev nair>
# Purpose / Description : sp_monthly_content_report
#----------------------------------------------------
# Last modified on : 14-03-2018
# Last modified by : rahul dhakad 

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
EMAIL_ID="boddu.susmitha@justdial.com,dbteam_mis@justdial.com"
#EMAIL_ID="boddu.susmitha@justdial.com,pavan.r3@justdial.com"
HNAME="$(hostname | cut -d. -f1)"
SUBJECT="monthly_content_report process"
CITYDGT=$(/sbin/ip route | grep src |awk '{print $9}'| cut -d. -f3|head -1)
LOCALUSER="process_auto"
HOST="localhost"
LOCALPASSWD="gr8exp9master"
DATE=`date +%d-%m-%Y`
SR1="192.168.13.85"
SR2="192.168.17.132"
TBL1="temp_photo_count_unique_inactive"
TBL2="temp_rejected_deleted_images"
TBL3="tbl_logo_count_unique"
TBL4="tbl_videos_count_unique"
TBL5="tbl_menu_count_unique"

#### -------------------------------- Function Define -------------------- ###
function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success"
else
        echo "Failed"
        echo "${SUBJECT} failed on `date`"  | mail -s "${SUBJECT} failed on `date`" ${EMAIL_ID}
        exit 1
fi
}

##----------------- creating dir structure ----------------------------######
echo "Creating directory structure on $HNAME"

if [ ! -d /tmp/monthly_content_report ];
then sudo mkdir /tmp/monthly_content_report && sudo chmod -R 755 /tmp/monthly_content_report && sudo chown -R web_backup.web_backup /tmp/monthly_content_report;
else sudo rm -fv /tmp/monthly_content_report/*;sudo chown -R web_backup.web_backup /tmp/monthly_content_report;
fi
CHECK


#echo "Creating directory structure on $SR1"
#ssh ${SSH_ARGS} web_backup@${SR1} "if [ ! -d /tmp/monthly_content_report ]; then sudo mkdir /tmp/monthly_content_report && sudo chmod -R 755 /tmp/monthly_content_report && sudo chown -R web_backup.web_backup /tmp/monthly_content_report; else sudo rm -fv /tmp/monthly_content_report/*; fi"
#CHECK
###-----------------------------------------------------------------------####
#           ## ------------ Pravin Changes Part 1-------- ##
#echo "Execute Outfile1 on ${SR1}"
#ssh ${SSH_ARGS} web_backup@${SR1} "sudo sh /scripts/sp_monthly_content_report_part1.sh"
#CHECK
#
#echo "Transferring files temp_catalogue_details.txt and temp_image_info.txt to ${HNAME}"
#scp web_backup@${SR1}:/tmp/temp_catalogue_details.txt /tmp/
#CHECK
#
#scp web_backup@${SR1}:/tmp/temp_image_info.txt /tmp/
#CHECK
#
#echo "Deleting files temp_catalogue_details.txt and temp_image_info.txt from ${SR1}"
#ssh ${SSH_ARGS} web_backup@${SR1} "sudo rm -fv /tmp/temp_catalogue_details.txt"
#CHECK
#
#ssh ${SSH_ARGS} web_backup@${SR1} "sudo rm -fv /tmp/temp_image_info.txt"
#CHECK
#              ## -------- Ends Part 1 -------- ##
#
#echo "STEP1:Calling sp test.sp_monthly_content_report() on $SR2"
#ssh ${SSH_ARGS} web_backup@${SR2}  "sudo mysql -Bse 'call db_product.sp_monthly_content_report();'"
#CHECK
#
for i in $TBL1 $TBL2  $TBL3 $TBL4 $TBL5 
do 
echo "STEP2:Transferring table $i from $SR2 to $HNAME"
ssh ${SSH_ARGS} web_backup@${SR2}  "sudo mysqldump  test ${i} | gzip -fv > /tmp/monthly_content_report/${i}.sql.gz"
CHECK

echo "Transferring $i to $HNAME"
scp web_backup@${SR2}:/tmp/monthly_content_report/${i}.sql.gz /tmp/monthly_content_report/
CHECK

echo "Gunzipping ${i} on ${HNAME}"
sudo gunzip -f /tmp/monthly_content_report/${i}.sql.gz
CHECK

echo "Restoring ${i} on ${HNAME}"
sudo mysql -h${HOST} -u${LOCALUSER} -p${LOCALPASSWD} db_reports < /tmp/monthly_content_report/${i}.sql
CHECK

done

           ## ------------ Pravin Changes Part 2-------- ##

echo "Deleting table tbl_catalogue_details_snapshot on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "drop table if exists dbteam_temp.tbl_catalogue_details_snapshot;"
CHECK

echo "Create table tbl_catalogue_details_snapshot on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "CREATE TABLE dbteam_temp.tbl_catalogue_details_snapshot (docid varchar(100) NOT NULL,catalogue_id INT unsigned NOT NULL,product_id int(10) unsigned NOT NULL AUTO_INCREMENT,create_date datetime DEFAULT NULL,product_position tinyint(4) unsigned DEFAULT '0',upload_by varchar(50) DEFAULT NULL,delete_flag tinyint(1) unsigned NOT NULL DEFAULT '0',approved tinyint(1) unsigned NOT NULL DEFAULT '0',display_flag tinyint(1) unsigned NOT NULL DEFAULT '1',product_description text,product_name varchar(100) DEFAULT NULL,Lcontract varchar(45) DEFAULT NULL,display_order int(11) DEFAULT NULL,product_label varchar(100) DEFAULT NULL,photo_type_flag int(11) DEFAULT '0' COMMENT 'photo interior-exterior view flag',photo_type int(11) DEFAULT '0' COMMENT 'Hotel Room Types',modified_date datetime DEFAULT NULL,module_type tinyint,PRIMARY KEY(product_id),KEY idx_create_date(create_date),KEY idx_modified_date(modified_date),KEY idx_approved(approved),KEY idx_display_flag(display_flag),KEY idx_delete_flag(delete_flag),KEY idx_product_position(product_position)) ENGINE = INNODB;"
CHECK


echo "Load infile temp_catalogue_details.txt on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "LOAD DATA INFILE '/tmp/temp_catalogue_details.txt' INTO TABLE dbteam_temp.tbl_catalogue_details_snapshot FIELDS TERMINATED BY '|'  ENCLOSED BY '\"' LINES TERMINATED BY '\n' (docid,catalogue_id,product_id,create_date,product_position,upload_by,delete_flag,approved,display_flag,product_description,product_name,Lcontract,display_order,product_label,photo_type_flag,photo_type,modified_date,module_type);"
CHECK

echo "Deletig Temporary Files from ${HNAME}"
sudo rm -fv /tmp/temp_catalogue_details.txt
CHECK

echo "Deleting table tbl_catalogue_details_snapshot on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "drop table if exists dbteam_temp.temp_image_size;"
CHECK

echo "Create table temp_image_size on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "CREATE TABLE dbteam_temp.temp_image_size (id int(10) unsigned NOT NULL DEFAULT '0',product_id int(11) NOT NULL,docid varchar(50) NOT NULL,city varchar(50) NOT NULL,width int(11) DEFAULT NULL,height int(11) DEFAULT NULL,process_flag tinyint(2) DEFAULT '0',process_datetime datetime DEFAULT NULL,active tinyint(4) DEFAULT '0',delete_reject tinyint(4) DEFAULT '0',source varchar(60) DEFAULT NULL,paid_flag tinyint(4) DEFAULT '0',photo_400 tinyint(4) DEFAULT '0',vertical varchar(60) DEFAULT NULL,PRIMARY KEY (id),KEY docid (docid),KEY width (width),KEY height (height),KEY process_datetime (process_datetime),KEY idx_active (active),KEY idx_delete_reject (delete_reject),KEY idx_product_id (product_id),KEY idx_source (source),KEY idx_paid (paid_flag),KEY idx_photo_400 (photo_400),KEY idx_vertical (vertical)) ENGINE=INNODB DEFAULT CHARSET=latin1;"
CHECK

echo "Load infile temp_image_info.txt on ${HNAME}"
sudo mysql --socket=/var/lib/SQL/mysql/mysql.sock -Bse "LOAD DATA INFILE '/tmp/temp_image_info.txt' INTO TABLE dbteam_temp.temp_image_size FIELDS TERMINATED BY '|'  ENCLOSED BY '\"' LINES TERMINATED BY '\n' (id,product_id,docid,city,width,height,process_flag,process_datetime);"
CHECK

echo "Deletig Temporary Files from ${HNAME}"
sudo rm -fv /tmp/temp_image_info.txt
CHECK


                         ## -------- Ends Part 2 -------- ##

echo "Calling SP db_reports.Sp_monthly_content_report()"
sudo mysql -Bse "CALL db_reports.Sp_monthly_content_report();"
CHECK

#echo "Deletig Temporary Files from ${HNAME}"
#sudo rm -fv /tmp/temp_image_info.txt
#CHECK
#
#sudo rm -fv /tmp/temp_catalogue_details.txt
#CHECK

##-------------------------------------------------------------------------------####
echo "Process monthly_content_report Successfully completed on ${HNAME}"

echo "Sending Success Mail"
echo "${SUBJECT} completed successfully ${HNAME} on '$DATE'" | mail -s "${SUBJECT} Success" ${EMAIL_ID}
echo "DONE"
exit 0
