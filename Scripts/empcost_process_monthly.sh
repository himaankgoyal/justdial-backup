########### created by Himaank Goyal ###################

EMAILID=" dbteam_mis@justdial.com,dhakshina.palanisamy@justdial.com,suprajit.sardar@justdial.com,gomathi.pandy@justdial.com, kundan.kumar6@justdial.com,sandeep.vishwakarma5@justdial.com,kuldeep.jaiswal@justdial.com,sharad.rane@justdial.com,himaank.goyal@justdial.com"
EMAILID_F="dhakshina.palanisamy@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="empcost_process_monthly"
SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
MYUSR="process_auto"
PASS="gr8exp9master"
MYHST="localhost"


ERROR() {
	if [ $? -ne 0 ];then
		echo "Failure Empcost process monthly in 14.48 server" | mail -r root@justdial.com -s " Failure - Empcost process monthly" -a ${LOGFILE} ${EMAILID_F}
		exit 1
	fi
}

SUCCESS() {
        if [ $? -eq 0 ];then
                echo -e "\nSuccess Empcost process monthly in 14.48 server" | sudo mail -r root@justdial.com -s " Success -  Empcost process monthly" ${EMAILID}
                exit 0
        fi
}

#############################################################################################################################################

echo :"step 1: curl call on 14.48"
curl -s "http://192.168.14.48:8000/report_log.php?ProcessName=Empcost%20process%20monthly&ProcessOwner=10115983&Flag=start"
ERROR

echo "step 2: call sp sales.sp_empcost_process_monthly() on 14.48" 
ssh $SSH_ARG web_backup@192.168.14.48 "sudo mysql h${MYHST} -u${MYUSR} -p${PASS} -Bse \"call sales.sp_empcost_process_monthly();\""
ERROR

echo :"step 3: curl call on 14.48"
curl -s "http://192.168.14.48:8000/report_log.php?ProcessName=Empcost%20process%20monthly&ProcessOwner=10115983&Flag=end"
ERROR


echo "All Process Completed Successfully"

SUCCESS
