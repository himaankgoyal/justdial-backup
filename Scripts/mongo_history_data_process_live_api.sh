#!/bin/bash
# By Manish Agrawal
#set -x
#declare -a arr=( "remote")
declare -a arr=("mumbai" "delhi" "kolkata" "bangalore" "chennai" "pune" "hyderabad" "ahmedabad" "remote")
#declare -a arr=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" )
for i in "${arr[@]}"
do

echo $i

cnt=`ps aux | grep [s]h."/home/laljiy/mongo_history_data_process_daemon_live_api.sh $i $1" | wc -l`
if [ $cnt -eq 0 ]; then
    /bin/sh /home/laljiy/mongo_history_data_process_daemon_live_api.sh $i $1> /dev/null 2>&1&
elif [ "$cnt" -gt 1 ]; then
    ps aux | grep [s]h."/home/laljiy/mongo_history_data_process_daemon_live_api.sh $i $1" | awk '{print $2}' | xargs kill
    /bin/sh /home/laljiy/mongo_history_data_process_daemon_live_api.sh $i $1 > /dev/null 2>&1&
elif [ "$cnt" -eq 1 ]; then
    echo "mongo history daemon live api daemon is running!!"
fi

done

exit 0
