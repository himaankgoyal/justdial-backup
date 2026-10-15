#!/bin/bash

DATE=`date +%Y%m%d --date="-15 day"`
MAILS="linux@justdial.com"

function ERROR () {
        if [ $? -ne 0 ]; then
                echo -e "Hello\n\ntbl_event_data_${DATE} backup failed\n Source: 192.168.42.104:$0" | mail -s "mongo ppp ecs_backup failed on `hostname` " ${MAILS}
                echo "Kindly check mongo backup failed"
                exit 1
        fi
}

################################################
echo "Taking mongo dump tbl_event_data_${DATE}"

mongoexport -u 'mongo-admin' -p 'P@a5swOrD' --host="core_jd_tracker/192.168.42.104:27017,192.168.42.105:27017,192.168.42.106:27017" --readPreference=secondary --authenticationDatabase admin -d db_jd_tracker_err -c tbl_event_data_${DATE} --type=json --out /tmp/tbl_event_data_${DATE}.json
ERROR

sleep 10

echo "zipping the unique csv file"
gzip /tmp/tbl_event_data_${DATE}.json
ERROR

echo "Uploading zip files to ECS"
s3cmd --no-ssl put /tmp/tbl_event_data_${DATE}.json.gz  s3://PPP_EC2/db_jd_tracker_err_tbl_event_data/  -c /root/.s3cfg-mongo --host=192.168.11.91:9020 > /tmp/upload.log 2>&1
ERROR

echo "Dropping collection past 15 days from mongod primary server"
mongo_status=`mongo --host 192.168.42.105 --username mongo-admin --password 'P@a5swOrD' --authenticationDatabase admin --eval "db.isMaster()" | grep primary | cut -d ':' -f2  | tr '^"' ' '`

echo "primary $mongo_status"



mongo --username mongo-admin --password 'P@a5swOrD'  --host ${mongo_status} --authenticationDatabase admin  db_jd_tracker_err --eval 'db.tbl_event_data_'$DATE'.drop()'


rm -fv /tmp/tbl_event_data_${DATE}.json.gz 

echo "Upload sucess for ${DATE} on ecs"


