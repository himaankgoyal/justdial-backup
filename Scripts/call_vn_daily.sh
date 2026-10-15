#!/bin/bash

S_EMAILID="rishav.parasar@justdial.com,anurag.singh9@justdial.com,shravan.katti@justdial.com"
F_EMAILID="rishav.parasar@justdial.com,anurag.singh9@justdial.com,eslavath.mohith@justdial.com"
DATE=$(date +%Y-%m-%d -d '1 day ago')
SSH_ARG='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

ERROR() {
      if [ $? -ne 0 ] ;then
                echo "call vn daily report FAILED on 11.149"
                echo -e "call vn daily report FAILED" |mail -r "From: <reports@justdial.com>" -s "call vn daily report for $DATE" ${F_EMAILID}
                /bin/bash /scripts/standard_sms_sending_script.sh -m "call vn daily report FAILED on 192.168.11.149" -f /scripts/clickTracker.txt
		exit 0
      fi
}

SUCCESS() {

       if [ $? -eq 0 ] ;then
                echo "call vn daily report Compleated"
                echo "call vn daily report executed successfully at `date`" | mail -s "call vn daily report for $DATE" ${S_EMAILID}
                 fi
}

###########################################################################################################################################

echo "step=1 calling SP:search_input.sp_call_data() on 11.149"
ssh $SSH_ARGS -q web_backup@192.168.11.149 "sudo mysql -Bse \"CALL trainee_test.sp_call_vn_data(:wq$DATE');\""
ERROR

echo "All process completed successfully"
SUCCESS

