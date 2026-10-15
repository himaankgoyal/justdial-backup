#!/bin/bash


EMAILID="rishav.parasar@justdial.com,himaank.goyal@justdial.com"
SCRIPT_NAME="mongo_data_extraction"
SSH_ARG="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
SUBJECT_S="mongo_data_extraction is succesfull"
SUBJECT_F="mongo_data_extraction is failed"
LOGFILE="/var/log/daily_log/${SCRIPT_NAME}.log"
#-u 'mongo-admin' -p 'P@a5swOrD'
#MYUSR="mongo-admin"
#PASS="P@a5swOrD"
#DATE=$(date +"%Y-%m-%d")
#DATE_T="`date +%Y%m%d --date="1 day ago"`"
#DATE_1="`date +%Y-%m-%d --date="1 day ago"`"
#DATE_2="`date +%Y --date="present year"`"
#DATE_2=$(date +"%Y")
#DATE_3="`date +%Y-%m-%d --date="2 day ago"`"
#MONTH="`date "+%b" --date="1 day ago" | awk '{print tolower($0)}'`"

START_DATE="2023-06-01"
END_DATE="2023-06"
################################################ Function Defining Here  ###################################################

ERROR() {
      if [ $? -ne 0 ] ;then      
           echo "FAILED on $step on $DATE"
           echo "${SCRIPT_NAME} FAILED on $step at `date`" | mail -s "${SUBJECT_F}" -a ${LOGFILE} ${EMAILID}
           exit 1
      fi
}

SUCCESS() {
       if [ $? -eq 0 ] ;then      
            echo "Script : ${SCRIPT_NAME} is Executed Successfully on `date`"
            echo "${SCRIPT_NAME} executed successfully at `date`" | mail -s "${SUBJECT_S}" ${EMAILID} 
       fi
}

############################################################################################################################

COUNT=1
COUNT_1=0
DATE="2023-06-30"
DATE_1=$(date -d "$DATE -1 day" '+%F')

while [ ${COUNT} -le 29 ]
do

DATE=$(date -d "$DATE -${COUNT_1} day" '+%F')
DATE_1=$(date -d "$DATE -${COUNT} day" '+%F')
DT_1=$(echo $DATE_1 | awk -F"-" '{print $NF}')
DT=$(echo $DATE | awk -F"-" '{print $NF}')

step=1 
echo "Step=$step running mongo export query on 42.105"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo mongoexport -h 192.168.42.105 -u 'mongo-admin' -p'P@a5swOrD' --authenticationDatabase admin -d db_jd_tracker -c tbl_tags_sevt_nc_device_pos_202306 -q '{\"dt\":{\"\$gte\":{\"\$date\":\"2023-06-${DT_1}T18:30:00.000Z\"}, \"\$lt\":{\"\$date\":\"2023-06-${DT}T18:30:00.000Z\"}}}' --fields _id,pos,dv_src,emp_flg,sevt,tags,nc,dc,u_clks,u_imp,t_clks,t_imp,u_clks_rats_gt45_cnt,u_imp_rats_gt45_cnt,t_clks_rats_gt45,t_imp_rats_gt45,u_clks_rats_gt4_cnt,u_imp_rats_gt4_cnt,t_clks_rats_gt4,t_imp_rats_gt4,u_clks_rats_gt3_cnt,u_imp_rats_gt3_cnt,t_clks_rats_gt3,t_imp_rats_gt3,u_clks_rats_gt2_cnt,u_imp_rats_gt2_cnt,t_clks_rats_gt2,t_imp_rats_gt2,u_clks_rats_gt1_cnt,u_imp_rats_gt1_cnt,t_clks_rats_gt1,t_imp_rats_gt1,u_clks_jd_verified_cnt,u_imp_jd_verified_cnt,t_clks_cnt_jd_verified,t_imp_jd_verified,u_clks_non_jd_verified_cnt,u_imp_non_jd_verified_cnt,t_clks_non_jd_verified,t_imp_non_jd_verified,u_clks_jd_trust_cnt,u_imp_jd_trust_cnt,t_clks_cnt_jd_trust,t_imp_jd_trust,u_clks_non_jd_trust_cnt,u_imp_non_jd_trust_cnt,t_clks_non_jd_trust,t_imp_non_jd_trust,u_clicks_deal_cnt,u_imp_deal,t_clks_deal,t_imp_deal,u_clks_non_deal,u_imp_non_deal,t_clks_non_deal,t_imp_non_deal,u_clks_jdcash,u_imp_jdcash,t_clks_jdcash,t_imp_jdcash,u_clks_non_jdcash,u_imp_non_jdcash,t_clks_non_jdcash,t_imp_non_jdcash,dt,app_vr --out /tmp/tbl_tags_sevt_nc_device_pos_202306${DT}.csv --type=csv" 

sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo mongoexport -h 192.168.42.105 -u 'mongo-admin' -p'P@a5swOrD' --authenticationDatabase admin -d db_jd_tracker -c tbl_tags_sevt_dc_device_pos_202306 -q '{\"dt\":{\"\$gte\":{\"\$date\":\"2023-06-${DT_1}T18:30:00.000Z\"}, \"\$lt\":{\"\$date\":\"2023-06-${DT}T18:30:00.000Z\"}}}' --fields _id,pos,dv_src,emp_flg,sevt,tags,dc,u_clks,u_imp,t_clks,t_imp,u_clks_rats_gt45_cnt,u_imp_rats_gt45_cnt,t_clks_rats_gt45,t_imp_rats_gt45,u_clks_rats_gt4_cnt,u_imp_rats_gt4_cnt,t_clks_rats_gt4,t_imp_rats_gt4,u_clks_rats_gt3_cnt,u_imp_rats_gt3_cnt,t_clks_rats_gt3,t_imp_rats_gt3,u_clks_rats_gt2_cnt,u_imp_rats_gt2_cnt,t_clks_rats_gt2,t_imp_rats_gt2,u_clks_rats_gt1_cnt,u_imp_rats_gt1_cnt,t_clks_rats_gt1,t_imp_rats_gt1,u_clks_jd_verified_cnt,u_imp_jd_verified_cnt,t_clks_cnt_jd_verified,t_imp_jd_verified,u_clks_non_jd_verified_cnt,u_imp_non_jd_verified_cnt,t_clks_non_jd_verified,t_imp_non_jd_verified,u_clks_jd_trust_cnt,u_imp_jd_trust_cnt,t_clks_cnt_jd_trust,t_imp_jd_trust,u_clks_non_jd_trust_cnt,u_imp_non_jd_trust_cnt,t_clks_non_jd_trust,t_imp_non_jd_trust,u_clicks_deal_cnt,u_imp_deal,t_clks_deal,t_imp_deal,u_clks_non_deal,u_imp_non_deal,t_clks_non_deal,t_imp_non_deal,u_clks_jdcash,u_imp_jdcash,t_clks_jdcash,t_imp_jdcash,u_clks_non_jdcash,u_imp_non_jdcash,t_clks_non_jdcash,t_imp_non_jdcash,dt,app_vr --out /tmp/tbl_tags_sevt_dc_device_pos_202306${DT}.csv --type=csv"

sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo mongoexport -h 192.168.42.105 -u 'mongo-admin' -p'P@a5swOrD' --authenticationDatabase admin -d db_jd_tracker -c tbl_tags_cta_nc_device_pos_202306 -q '{\"dt\":{\"\$gte\":{\"\$date\":\"2023-06-${DT_1}T18:30:00.000Z\"}, \"\$lt\":{\"\$date\":\"2023-06-${DT}T18:30:00.000Z\"}}}' --fields _id,pos,dv_src,emp_flg,tags,cta_name,dc,nc,u_clks,u_imp,t_clks,t_imp,u_clks_rats_gt45_cnt,u_imp_rats_gt45_cnt,t_clks_rats_gt45,t_imp_rats_gt45,u_clks_rats_gt4_cnt,u_imp_rats_gt4_cnt,t_clks_rats_gt4,t_imp_rats_gt4,u_clks_rats_gt3_cnt,u_imp_rats_gt3_cnt,t_clks_rats_gt3,t_imp_rats_gt3,u_clks_rats_gt2_cnt,u_imp_rats_gt2_cnt,t_clks_rats_gt2,t_imp_rats_gt2,u_clks_rats_gt1_cnt,u_imp_rats_gt1_cnt,t_clks_rats_gt1,t_imp_rats_gt1,u_clks_jd_verified_cnt,u_imp_jd_verified_cnt,t_clks_cnt_jd_verified,t_imp_jd_verified,u_clks_non_jd_verified_cnt,u_imp_non_jd_verified_cnt,t_clks_non_jd_verified,t_imp_non_jd_verified,u_clks_jd_trust_cnt,u_imp_jd_trust_cnt,t_clks_cnt_jd_trust,t_imp_jd_trust,u_clks_non_jd_trust_cnt,u_imp_non_jd_trust_cnt,t_clks_non_jd_trust,t_imp_non_jd_trust,u_clicks_deal_cnt,u_imp_deal,t_clks_deal,t_imp_deal,u_clks_non_deal,u_imp_non_deal,t_clks_non_deal,t_imp_non_deal,u_clks_jdcash,u_imp_jdcash,t_clks_jdcash,t_imp_jdcash,u_clks_non_jdcash,u_imp_non_jdcash,t_clks_non_jdcash,t_imp_non_jdcash,dt,app_vr --out /tmp/tbl_tags_cta_nc_device_pos_202306${DT}.csv --type=csv"

sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo mongoexport -h 192.168.42.105 -u 'mongo-admin' -p'P@a5swOrD' --authenticationDatabase admin -d db_jd_tracker -c tbl_tags_cta_dc_device_pos_202306 -q '{\"dt\":{\"\$gte\":{\"\$date\":\"2023-06-${DT_1}T18:30:00.000Z\"}, \"\$lt\":{\"\$date\":\"2023-06-${DT}T18:30:00.000Z\"}}}' --fields _id,pos,dv_src,emp_flg,tags,cta_name,dc,u_clks,u_imp,t_clks,t_imp,u_clks_rats_gt45_cnt,u_imp_rats_gt45_cnt,t_clks_rats_gt45,t_imp_rats_gt45,u_clks_rats_gt4_cnt,u_imp_rats_gt4_cnt,t_clks_rats_gt4,t_imp_rats_gt4,u_clks_rats_gt3_cnt,u_imp_rats_gt3_cnt,t_clks_rats_gt3,t_imp_rats_gt3,u_clks_rats_gt2_cnt,u_imp_rats_gt2_cnt,t_clks_rats_gt2,t_imp_rats_gt2,u_clks_rats_gt1_cnt,u_imp_rats_gt1_cnt,t_clks_rats_gt1,t_imp_rats_gt1,u_clks_jd_verified_cnt,u_imp_jd_verified_cnt,t_clks_cnt_jd_verified,t_imp_jd_verified,u_clks_non_jd_verified_cnt,u_imp_non_jd_verified_cnt,t_clks_non_jd_verified,t_imp_non_jd_verified,u_clks_jd_trust_cnt,u_imp_jd_trust_cnt,t_clks_cnt_jd_trust,t_imp_jd_trust,u_clks_non_jd_trust_cnt,u_imp_non_jd_trust_cnt,t_clks_non_jd_trust,t_imp_non_jd_trust,u_clicks_deal_cnt,u_imp_deal,t_clks_deal,t_imp_deal,u_clks_non_deal,u_imp_non_deal,t_clks_non_deal,t_imp_non_deal,u_clks_jdcash,u_imp_jdcash,t_clks_jdcash,t_imp_jdcash,u_clks_non_jdcash,u_imp_non_jdcash,t_clks_non_jdcash,t_imp_non_jdcash,dt,app_vr --out /tmp/tbl_tags_cta_dc_device_pos_202306${DT}.csv --type=csv"
ERROR

##############################################################################################################################################

step=2
echo "Step=$step zipping the file on 42.105"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo gzip -fv /tmp/tbl_tags_sevt_nc_device_pos_202306${DT}.csv /tmp/tbl_tags_sevt_dc_device_pos_202306${DT}.csv /tmp/tbl_tags_cta_nc_device_pos_202306${DT}.csv /tmp/tbl_tags_cta_dc_device_pos_202306${DT}.csv"
ERROR

step=3
echo "Step=$step transfer file from 42.105 to 29.159"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo scp /tmp/tbl_tags_sevt_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_sevt_dc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_dc_device_pos_202306${DT}.csv.gz web_backup@192.168.29.159:/tmp/" 
ERROR

step=4 : Remove these files from 42.105
echo "Step=$step Remove these files from 42.105"
sudo ssh ${SSH_ARGS} web_backup@192.168.42.105 "sudo rm -rf /tmp/tbl_tags_sevt_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_sevt_dc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_dc_device_pos_202306${DT}.csv.gz"
ERROR

ssh ${SSH_ARGS} web_backup@192.168.29.159 "sudo mv /tmp/tbl_tags_sevt_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_sevt_dc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_nc_device_pos_202306${DT}.csv.gz /tmp/tbl_tags_cta_dc_device_pos_202306${DT}.csv.gz /var/lib/clickhouse/"

COUNT=$(($COUNT+1))
COUNT_1=$(($COUNT_1+1))

done

SUCCESS
