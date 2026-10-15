#!/bin/bash

GBOT_WWW="192.168.12.107|192.168.12.108|192.168.13.47|192.168.13.140|192.168.13.142|192.168.13.164|192.168.13.165|192.168.35.45"
GBOT_MOBILE="192.168.12.228|192.168.24.238|192.168.42.183|192.168.42.252|192.168.42.95|192.168.42.96"
GBOT_TOUCH="192.168.13.159|192.168.13.169|192.168.24.150|192.168.12.229|192.168.13.62|192.168.13.67|192.168.13.68|192.168.13.70"
GBOT_B2B="192.168.13.61 192.168.24.81 192.168.13.121"
GBOT_WEBSERVICES="192.168.13.138 192.168.17.156 192.168.12.109 192.168.11.218"
LOG_DIR="/var/log/nginx"
if [ $# -ne 1 ];then
	echo "Pass date < 202402201515 >"
	exit 1
fi
	FILE_NAME="category_api.access.log-${1}.gz"

cd $LOG_DIR

zcat ${FILE_NAME} |egrep "${GBOT_WWW}|${GBOT_MOBILE}|${GBOT_TOUCH}|${GBOT_B2B}|${GBOT_WEBSERVICES}" |awk '{print $(NF-3)}'|sed 's/"//g' | sort | uniq -c | sort -nr >/tmp/gbot_hits_data.txt
zcat ${FILE_NAME} |egrep "${GBOT_WWW}|${GBOT_MOBILE}|${GBOT_TOUCH}|${GBOT_B2B}|${GBOT_WEBSERVICES}"  > /tmp/gbot_hits_rawdata.txt
for ip in $(echo $GBOT_WWW|sed 's/|/ /g')
do

if [ `grep $ip /tmp/gbot_hits_data.txt >/dev/null;echo $?` -eq 0 ];then
	sed -i "s/$ip/$ip GBOT_WWW Sanjay/" /tmp/gbot_hits_data.txt
fi
done

for ip in $(echo "${GBOT_MOBILE}"|sed 's/|/ /g')
do
if [ `grep $ip /tmp/gbot_hits_data.txt >/dev/null;echo $?` -eq 0 ];then
        sed -i "s/$ip/$ip GBOT_MOBILE Sanjay/" /tmp/gbot_hits_data.txt
fi
done

for ip in $(echo "${GBOT_TOUCH}"|sed 's/|/ /g')
do

if [ `grep $ip /tmp/gbot_hits_data.txt >/dev/null;echo $?` -eq 0 ];then
        sed -i "s/$ip/$ip GBOT_TOUCH Rajesh Garg/" /tmp/gbot_hits_data.txt
fi

done

for ip in $(echo "${GBOT_B2B}"|sed 's/|/ /g')
do

if [ `grep $ip /tmp/gbot_hits_data.txt >/dev/null;echo $?` -eq 0 ];then
        sed -i "s/$ip/$ip GBOT_B2B Meeta/" /tmp/gbot_hits_data.txt
fi

done



for ip in $(echo "${GBOT_WEBSERVICES}"|sed 's/|/ /g')
do

if [ `grep $ip /tmp/gbot_hits_data.txt >/dev/null;echo $?` -eq 0 ];then
        sed -i "s/$ip/$ip GBOT_WEBSERVICES Sunny/" /tmp/gbot_hits_data.txt
fi

done
sed -i "1i hits are coming on NODE CATEGORY USER servers from Gbot servers" /tmp/gbot_hits_data.txt
echo "check file /tmp/gbot_hits_data.txt"
cat /tmp/gbot_hits_data.txt


echo "check sample /tmp/gbot_hits_rawdata.txt"
