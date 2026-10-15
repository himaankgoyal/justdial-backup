#!/bin/bash

# MySQL Credentials
MYSQL_USER="root"
MYSQL_PASS="C17h35coona@#"

# Backup Directories
BACKUP_DIR="/backup/mysql"
FULL_BACKUP_DIR="$BACKUP_DIR/full"
INCREMENTAL_BACKUP_DIR="$BACKUP_DIR/incremental"

# Log File
LOG_FILE="/var/log/mysql_backup.log"

# Date Variables
CURRENT_DATE=$(date '+%Y-%m-%d')
DAY_OF_MONTH=$(date '+%d')

# Email Notification
EMAILIDS="himaank.goyal@justdial.com,linux@justdial.com"
SCRIPT_NAME="mysql_backup.sh"

# Create directories if not exist
mkdir -p "$FULL_BACKUP_DIR" "$INCREMENTAL_BACKUP_DIR"

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Send error email if backup fails
ERROR() {
    if [ $? -ne 0 ]; then
        echo "Script : ${SCRIPT_NAME} failed at step $1 on $IPADDR" | mail -s "MySQL Backup Failed" ${EMAILIDS} -a $LOG_FILE
        exit 1
    fi
}

# Take a FULL BACKUP every 5th day
if (( DAY_OF_MONTH % 5 == 0 )); then
    log_message "Starting full backup..."
    FULL_BACKUP_PATH="$FULL_BACKUP_DIR/full_backup_${CURRENT_DATE}.mbi"
    
    mysqlbackup --user=$MYSQL_USER --password=$MYSQL_PASS \
        --backup-dir=$FULL_BACKUP_DIR --backup-image=$FULL_BACKUP_PATH \
        --compress --compress-level=4 backup-to-image
    ERROR "Full Backup"

    log_message "Full backup completed: $FULL_BACKUP_PATH"
fi

# Take an INCREMENTAL BACKUP every day
log_message "Starting incremental backup..."
INCREMENTAL_BACKUP_PATH="$INCREMENTAL_BACKUP_DIR/incremental_backup_${CURRENT_DATE}.mbi"

mysqlbackup --user=$MYSQL_USER --password=$MYSQL_PASS \
    --backup-dir=$INCREMENTAL_BACKUP_DIR --backup-image=$INCREMENTAL_BACKUP_PATH \
    --incremental --incremental-base=dir:$FULL_BACKUP_DIR --compress --compress-level=4 backup-to-image
ERROR "Incremental Backup"

log_message "Incremental backup completed: $INCREMENTAL_BACKUP_PATH"

# Delete full backups older than 5 days
log_message "Cleaning up old full backups..."
find $FULL_BACKUP_DIR -type f -name "full_backup_*.mbi" -mtime +5 -exec rm -f {} \;
ERROR "Full Backup Cleanup"

# Delete incremental backups older than 5 days (one by one)
log_message "Cleaning up old incremental backups..."
find $INCREMENTAL_BACKUP_DIR -type f -name "incremental_backup_*.mbi" -mtime +5 -exec rm -f {} \;
ERROR "Incremental Backup Cleanup"

log_message "Backup process completed successfully!"

