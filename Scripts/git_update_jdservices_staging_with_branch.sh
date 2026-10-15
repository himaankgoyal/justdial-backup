#!/bin/bash

#####
PROD_DIR="/usr/share/php/jdservices/"
TEMP_DIR="/var/www/production/tmp/jdservices/"
RSYNC_EXCLUDE_LIST="--exclude=.svn --exclude=.git --exclude=LoadBalancer_HealthCheck.php --exclude=LoadBalancer_HealthCheck.txt --exclude=ServerSet.txt --exclude=.vscode"
MODULE="jdservices_with_branch"
BRANCH="$1"

DT=$(date +%d-%m-%Y)
LOCK_FILE="/tmp/${MODULE}.lock"
echo -e "\nTaking code update on `hostname`==============================\n"
check_error() {

	if [ $? -ne 0 ];then
		echo "Failed"
		rm -f $LOCK_FILE
		exit 1
	fi
}

line() {
echo -e "\n----------------------------\n"
}

bigline() {
echo -e "\n===============================================================================\n"
}

logfile () {
tee -a /var/log/daily_log/${MODULE}_${DT}.txt
}

if [ -e ${LOCK_FILE} ]; then echo "Git Update for $0 is already in progress .... Exiting"; exit 1; else echo "Creating lock file ${LOCK_FILE}"; touch ${LOCK_FILE}; fi

bigline | logfile ; echo -e "GIT update process at $(date)" | logfile; line | logfile

echo -e "Change branch to : $BRANCH, before update\n---------------------------" | logfile
cd ${TEMP_DIR} && git checkout $BRANCH | logfile

echo -e "git info before update\n---------------------------" | logfile
cd ${TEMP_DIR} && git  log | head  | logfile
line  | logfile

echo -e "Updating code\n-----------------------"  | logfile
cd ${TEMP_DIR} && sudo git pull  | logfile
check_error
line  | logfile

echo -e "git info after code update\n--------------------"  | logfile
cd ${TEMP_DIR} && sudo git log  | head  | logfile
line  | logfile

echo -e "Syncing code...\n-----------------"  | logfile

sudo rsync -crv ${RSYNC_EXCLUDE_LIST} ${TEMP_DIR} ${PROD_DIR} | logfile

echo "Removing Lock file"
rm -rf $LOCK_FILE
