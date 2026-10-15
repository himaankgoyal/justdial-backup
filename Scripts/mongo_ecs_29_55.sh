#!/bin/bash

DATE=`date +%Y%m%d --date="-15 day"`
MAILS="linux@justdial.com"

function ERROR () {
        if [ $? -ne 0 ]; then
                echo -e "Hello\n\ntbl_jdmart_event_data , tbl_event_data , tbl_mp_event_data and tbl_event_data backup failed\n Source: 192.168.29.55:$0" | mail -s "mongo ppp ecs_backup failed on `hostname` " ${MAILS}
                echo "Kindly check mongo backup failed"
                exit 1
        fi
}

################################################
echo "Taking mongo dump tbl_jdmart_event_data_${DATE}"

mongoexport -u 'admin' -p 'admin@123' --host="mp_mis/192.168.29.53:27017,192.168.29.54:27017,192.168.29.55:27017" --readPreference=secondary --authenticationDatabase admin -d db_jdmart_tracker_err -c tbl_jdmart_event_data_${DATE} --type=json --out /tmp/tbl_jdmart_event_data_${DATE}.json
ERROR

sleep 10

echo "zipping the unique csv file"
gzip /tmp/tbl_jdmart_event_data_${DATE}.json
ERROR

########################################################################################

echo "taking dump of tbl_event_data_${DATE}"

mongoexport -u 'admin' -p 'admin@123' --host="mp_mis/192.168.29.53:27017,192.168.29.54:27017,192.168.29.55:27017" --readPreference=secondary --authenticationDatabase admin -d  db_corejd_tracker_err -c tbl_event_data_${DATE} --type=json --out /tmp/tbl_event_data_${DATE}.json
ERROR

sleep 10

echo "zipping the tbl_event_data json file"
gzip /tmp/tbl_event_data_${DATE}.json
ERROR

########################################################################################

echo "taking dump of tbl_mp_event_data_${DATE}"

mongoexport -u 'admin' -p 'admin@123' --host="mp_mis/192.168.29.53:27017,192.168.29.54:27017,192.168.29.55:27017" --readPreference=secondary --authenticationDatabase admin -d  db_marketplace_passbook_err -c tbl_mp_event_data_${DATE} --type=json --out /tmp/tbl_mp_event_data_${DATE}.json
ERROR

sleep 10

echo "zipping the tbl_mp_event_data json file"
gzip /tmp/tbl_mp_event_data_${DATE}.json
ERROR

#########################################################################################

echo "taking dump of   tbl_event_data_${DATE}"

mongoexport -u 'admin' -p 'admin@123' --host="mp_mis/192.168.29.53:27017,192.168.29.54:27017,192.168.29.55:27017" --readPreference=secondary --authenticationDatabase admin -d db_re_tracker_err -c  tbl_event_data_${DATE} --type=json --out /tmp/tbl_event_data_${DATE}.json
ERROR

sleep 10

echo "zipping the tbl_event_data json file"
gzip /tmp/tbl_event_data_${DATE}.json
ERROR

####################################################################################################################

echo "Uploading zip files to ECS"
s3cmd --no-ssl put /tmp/tbl_jdmart_event_data_${DATE}.json.gz  s3://PPP_EC2/db_jdmart_tracker_err_tbl_jdmart_event_data/  -c /root/.s3cfg-mongo --host=192.168.11.91:9020 > /tmp/upload.log 2>&1
ERROR


s3cmd --no-ssl put /tmp/tbl_event_data_${DATE}.json.gz  s3://PPP_EC2/db_corejd_tracker_err_tbl_event_data/  -c /root/.s3cfg-mongo --host=192.168.11.91:9020 > /tmp/upload.log 2>&1
ERROR

s3cmd --no-ssl put /tmp/tbl_mp_event_data_${DATE}.json.gz  s3://PPP_EC2/db_marketplace_passbook_err_tbl_mp_event_data/  -c /root/.s3cfg-mongo --host=192.168.11.91:9020 > /tmp/upload.log 2>&1
ERROR

s3cmd --no-ssl put /tmp/tbl_event_data_${DATE}.json.gz  s3://PPP_EC2/db_re_tracker_err_tbl_event_data/  -c /root/.s3cfg-mongo --host=192.168.11.91:9020 > /tmp/upload.log 2>&1
ERROR

######################################################################################################################

echo "Dropping collection past 15 days from mongod primary server"
mongo_status=`mongo --host 192.168.29.55 --username admin --password 'admin@123' --authenticationDatabase admin --eval "db.isMaster()" | grep primary | cut -d ':' -f2  | tr '^"' ' '`

echo "primary $mongo_status"



mongo --username admin --password 'admin@123'  --host ${mongo_status} --authenticationDatabase admin  db_jdmart_tracker_err --eval 'db.tbl_jdmart_event_data_'$DATE'.drop()'

mongo --username admin --password 'admin@123'  --host ${mongo_status} --authenticationDatabase admin  db_corejd_tracker_err --eval 'db.tbl_event_data_'$DATE'.drop()'

mongo --username admin --password 'admin@123'  --host ${mongo_status} --authenticationDatabase admin  db_marketplace_passbook_err --eval 'db.tbl_mp_event_data_'$DATE'.drop()'

mongo --username admin --password 'admin@123'  --host ${mongo_status} --authenticationDatabase admin  db_re_tracker_err --eval 'db.tbl_event_data_'$DATE'.drop()'

rm -fv /tmp/tbl_jdmart_event_data_${DATE}.json.gz 
rm -fv /tmp/tbl_event_data_${DATE}.json.gz
rm -fv /tmp/tbl_mp_event_data_${DATE}.json.gz
rm -fv /tmp/tbl_event_data_${DATE}.json.gz   

echo "Upload sucess for ${DATE} on ecs"

