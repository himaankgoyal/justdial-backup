#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'

EMAILID="dbteam_mis@justdial.com, kundan.kumar6@justdial.com"
#EMAILID="shashi.c@justdial.com,dhakshina.palanisamy@justdial.com"
LOGFILE="/var/log/daily_log/sp_iro_appoinment_data_process.log"
SUBJECT="Auto Report of IRO Appointment Data Process success"


ERROR() {
        if [ $? -ne 0 ] ; then
           echo -e "  ${SUBJECT} is Failure `date`" | mail -s "Failure - ${SUBJECT}" -a ${LOGFILE} $EMAILID
           exit 1
        fi
}


SUCCESS() {
          if [ $? -eq 0 ] ; then
             echo -e "${SUBJECT} is - completed successfully `date`" | mail -s "Success- ${SUBJECT}"  $EMAILID
             exit 0
          fi
}

/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=iro_appoinment_data_process&ProcessOwner=10107063&Flag=start"

echo "Step 1: call the below storedprocedure in 192.168.39.54 `date`"
ssh ${SSH_ARGS} web_backup@192.168.39.54 "sudo mysql -Bse 'CALL  test.sp_appointment_data();'"
ERROR

echo "Step 2: transfer the below table from 192.168.39.54(test database) to 192.168.12.80:3306(test database) `date` "
ssh ${SSH_ARGS} web_backup@192.168.39.54 "sudo mysqldump test temp_iro_appointment_data | gzip -fv > /tmp/temp_iro_appointment_data.sql.gz  && scp ${SSH_ARGS} /tmp/temp_iro_appointment_data.sql.gz web_backup@192.168.12.80:/tmp/"
ERROR

sudo rm -rfv /var/www/html/es_script/rating_dir/block_number/attachment/iro_appointment_data.csv

echo  "step 2.1: gunzip and restoring table  on 12.80 `date`"
sudo gunzip -fv /tmp/temp_iro_appointment_data.sql.gz && sudo mysql test < /tmp/temp_iro_appointment_data.sql && sudo gzip -fv /tmp/temp_iro_appointment_data.sql
ERROR 

echo "Step 3: call the below storedprocedure in 192.168.12.80 `date`"
sudo mysql -e 'call dbteam_temp.sp_appointment_panindia_update();'
ERROR

echo -e "#####################\n#####################\n#####################"


echo "step 5: curl call on 12.80 `date`"
#curl -s http://192.168.12.80:88/rating_dir/block_number/appoinment_data.php | sudo bash -s > /var/log/daily_log/appointment.log 2>&1
/usr/bin/curl "http://192.168.12.80:88/rating_dir/block_number/appoinment_data.php" > /var/log/daily_log/appointment.log 2>&1
ERROR

/usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=iro_appoinment_data_process&ProcessOwner=10107063&Flag=end"

echo "All process completed `date`"
SUCCESS
