#! /bin/bash
DATE=$(date +%Y%m%d --date="1 days ago")

zcat $(ls -1 /var/log/nginx/jds_pincodewise_iro.access.log-$DATE*.gz) | awk -F 'HTTP/1.1"' '{print $1}' |awk -F '?' '{print $2}' | grep auto_call > /tmp/monthauto-${DATE}.txt


echo "call php"
echo "/bin/php /var/www/production/jds_pincodewise_iro/mvc/cron/auto_parser.php ${city_id} file_path="/tmp/" file_name="monthauto-${DATE}.txt" debug="1" date=${DATE}" > /tmp/auto_parser_month.log
/bin/php /var/www/production/jds_pincodewise_iro/mvc/cron/auto_parser_momth.php 0 file_path="/tmp/" file_name="monthauto-${DATE}.txt" debug="1" date=${DATE} >> /tmp/auto_parser_month.log
