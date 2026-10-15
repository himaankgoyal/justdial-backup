#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
EMAIL="mohit.thadhani@justdial.com"
EMAIL_F="mohit.thadhani@justdial.com"
SCRIPT_NAME="listicle"
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"

###################################################### Functions ###########################################################

ERROR() {
        if [ $? -ne 0 ];then
                echo "Success"
                echo "Failed on STEP $step on 39.120" | mail -s "Script : ${SCRIPT_NAME} is Failed at `date`" -a ${LOGFILE} ${EMAIL_F}
                exit 1
        fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "$SCRIPT_NAME is successfull " | sudo mail -s "script is Executed successfully at : `date`" ${EMAIL}
                exit 0
        fi
}


##############################################################################################################################################

step=1
echo"step=$step transfer table  article  from 41.111 to 39.120"
sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo mysqldump db_listicle_v1 articles > /tmp/articles.sql && sudo gzip /tmp/articles.sql;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo mysqldump  db_listicle_v1 contracts > /tmp/contracts.sql && sudo gzip /tmp/contracts.sql;"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo mysqldump  db_listicle_v1 category > /tmp/category.sql && sudo gzip /tmp/category.sql;"
ERROR

step=2
echo "step=$step scp table from 41.111 to 39.120"
sudo ssh ${SSH_ARGS} web_backup@192.168.41.111 "sudo scp /tmp/articles.sql.gz  /tmp/contracts.sql.gz /tmp/category.sql.gz  web_backup@192.168.39.120:/tmp/;"
ERROR

step=3
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo gunzip /tmp/articles.sql.gz  /tmp/contracts.sql.gz /tmp/category.sql.gz"
ERROR

step=4
sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql india_snapshot < /tmp/articles.sql"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql india_snapshot < /tmp/contracts.sql"
ERROR

sudo ssh ${SSH_ARGS} web_backup@192.168.39.120 "sudo mysql india_snapshot < /tmp/category.sql"
ERROR

step=5
echo "Removing .gz files from 41.111"
ssh ${SSH_ARG} web_backup@192.168.41.111 "sudo rm -fv /tmp/articles.sql.gz /tmp/contracts.sql.gz /tmp/category.sql.gz"
ERROR

echo "Removing .sql from 39.120"
ssh ${SSH_ARG} web_backup@192.168.39.120 "sudo rm -fv /tmp/articles.sql /tmp/contracts.sql /tmp/category.sql"
ERROR

SUCCESS
