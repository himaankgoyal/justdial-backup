#! /bin/bash
#DATE=$(date +%Y%m%d --date="1 days ago")
DATE=$(date +%Y%m%d)
#DATE="$1"
#date="202002051300"

function error {
               if [ $? -ne 0 ]; then
               echo "auto_calluid failed for $DATE"
               exit 1
               fi 
}               

#for city in hyderabad mumbai ahmedabad
for city in mumbai
do 

case ${city} in
        ahmedabad)
        city_id='35'
        ;;
        hyderabad)
        city_id='50'
        ;;
        mumbai)
        city_id='0'
        ;;
        pune)
        city_id='40'
        ;;
        
esac
              
echo "Extracting the logs $date"
#zcat /var/log/nginx/jds_pincodewise_central_mumbai.access.log-$DATE*.gz | awk -F 'HTTP/1.1"' '{print $1}' |awk -F '?' '{print $2}' | grep auto_call > /tmp/auto_call_uid.txt
for day in 6 5 4 3 2 1 0 
do
#DATE=$(date +%Y%m%d --date="$day days ago")

if [ "${city}" = "mumbai" ];
then 
zcat $(ls -1 /var/log/nginx/jds_pincodewise_iro.access.log-$DATE*.gz) | awk -F 'HTTP/1.1"' '{print $1}' |awk -F '?' '{print $2}' | grep auto_call > /tmp/auto_call_uid.txt
error
else
zcat $(ls -1 /var/log/nginx/jds_pincodewise_iro.access.log-$DATE*.gz) | awk -F 'HTTP/1.1"' '{print $1}' |awk -F '?' '{print $2}' | grep auto_call > /tmp/auto_call_uid.txt
error 
fi

echo "call php"
echo "/bin/php /var/www/production/jds_pincodewise_iro/mvc/cron/auto_parser.php ${city_id} file_path="/tmp/" file_name="auto_call_uid.txt" debug="1" " > /tmp/auto_parser.log
/bin/php /var/www/production/jds_pincodewise_iro/mvc/cron/auto_parser.php ${city_id} file_path="/tmp/" file_name="auto_call_uid.txt" debug="1" >> /tmp/auto_parser.log
error
done 
done
