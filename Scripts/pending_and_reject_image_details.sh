#!/bin/bash 

SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
EMAIL_ID="dbteam_mis@justdial.com,boddu.susmitha@justdial.com,nelsonjeyaraj@justdial.com"
#EMAIL_ID="boddu.susmitha@justdial.com"

# ------ Function Define ------ #

function CHECK () {
if [ $? -eq 0 ]; then
        echo "Success."
else
        echo "Failed on ${step}" | mail -r "From: <root@justdial.com>" -s "Failure - weekly process - pending and reject Image data" ${EMAIL_ID}
        exit 1
fi
}

step=1
echo "step=${step}"

sudo /usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Pending%20reject%20image&ProcessOwner=10093484&Flag=start"
CHECK

step=2
echo "step=${step}"
echo "call storedprocedure in 17.132"
ssh ${SSH_ARGS} web_backup@192.168.17.132 "sudo mysql -Bse 'call db_product.sp_pending_reject_images();'"
CHECK

step=3
echo "step=${step}"
for i in tbl_pending_image_details tbl_black_img_rejection;
do
echo "Taking dump of ${i} on 192.168.17.132"
ssh ${SSH_ARGS} web_backup@192.168.17.132 "sudo mysqldump test ${i} | gzip -fv > /tmp/${i}.sql.gz"

echo "Transfering table ${i} from 17.132 to 64.26"
ssh ${SSH_ARGS} web_backup@192.168.17.132 "sudo scp /tmp/${i}.sql.gz web_backup@172.29.64.26:/tmp/"
CHECK

echo "Unzipping table ${i} on 172.29.64.26"
ssh ${SSH_ARGS} web_backup@172.29.64.26 "gunzip -fv /tmp/${i}.sql.gz"
CHECK

echo "Restoring table ${i} on 172.29.64.26"
ssh ${SSH_ARGS} web_backup@172.29.64.26 "sudo mysql db_reports < /tmp/${i}.sql"
CHECK

echo "Deleting Temporary tables from 192.168.17.132 and 172.29.64.26"
ssh ${SSH_ARGS} web_backup@172.29.64.26 "sudo rm -fv /tmp/${i}.sql"
CHECK
ssh ${SSH_ARGS} web_backup@192.168.17.132 "sudo rm -fv /tmp/${i}.sql.gz"
CHECK
done

step=4
echo "step=${step}"
sudo /usr/bin/curl "http://192.168.14.48:8000/report_log.php?ProcessName=Pending%20reject%20image&ProcessOwner=10093484&Flag=end"
CHECK

echo "Sending Success Mail"
echo "Script has been Executed successfully." | mail -s "Success - weekly process - pending and reject Image data" ${EMAIL_ID}
echo "SUCCESS"
exit 0

