#!/bin/bash

SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
MAIL_ID="animesh.khamesra@justdial.com,ratan.dhaker@justdial.com,vipin.kumar9@justdial.com,deepak17@justdial.com,dipesh.malode@justdial.com,manas.pradhan@justdial.com,jitendra.nayak@justdial.com,sfspoc@justdial.com,data_enrichment@justdial.com,dbescalations@justdial.com,globalmis@justdial.com,datagrowth@justdial.com,Ashwin.sawai@justdial.com,sudeep.pathak@justdial.com"
#MAIL_ID="vipin.kumar9@justdial.com,akash.patil2@justdial.com"


ERROR()
{
	if [ $? -ne 0 ]; then
		echo "marketplace tables error on 29.116 Tables: 
		`cat /tmp/marketplace_tbls.txt`" | mail -s "ERROR: marketplace tables error on 29.116"  -a "/var/log/daily_log/marketplace_tbls.log" ${MAIL_ID}
		exit 0
	fi
}

SUCCESS()
{
	echo "marketplace tables SUCCESS on 29.116 Tables: 
		`cat /tmp/marketplace_tbls.txt`" | mail -s "SUCCESS: marketplace tables on 29.116" ${MAIL_ID}
}


IPS="192.168.24.118"
# IPS="192.168.39.120"
#AllTables="db_category_bank.tbl_psv_master db_category_bank.tbl_keyword_master db_category_bank.tbl_keyword_synonym db_category_bank.tbl_psv_synonym db_category_bank.tbl_psv_parentinfo db_category_bank.tbl_psv_generalinfo db_category_bank.tbl_keyword_pattern_creation db_product_bank.tbl_brand_master db_product_bank.tbl_spec_master db_product_bank.tbl_spec_mapping db_product_bank.tbl_generic_products_ncid_elastic"

AllTables="db_category_bank.tbl_keyword_master db_category_bank.tbl_keyword_synonym db_category_bank.tbl_psv_parentinfo db_category_bank.tbl_psv_generalinfo db_category_bank.tbl_keyword_pattern_creation db_product_bank.tbl_brand_master_v2 db_product_bank.tbl_spec_master db_product_bank.tbl_spec_mapping db_product_bank.tbl_generic_products_ncid_elastic db_log.tbl_keyword_master_del_backup db_category_bank.tbl_keyword_master_deleted_merging db_category_bank.tbl_hsn_gst_master db_category_bank.tbl_psv_data_detail_tracker"

# AllTables="db_category_bank.tbl_psv_parentinfo db_category_bank.tbl_psv_generalinfo db_category_bank.tbl_keyword_pattern_creation db_product_bank.tbl_brand_master db_product_bank.tbl_spec_master"   # TESTING


date
echo "Calling SP db_processing.sp_product_master_extract_making on 29.116"
sudo mysql -uroot -p'c17h35coona' -e 'call db_processing.sp_product_master_extract_making();' & pids_1+=($!)
ERROR


echo "COMPLETED TABLE TRANSFER FROM 29.116==>" > /tmp/marketplace_tbls.txt


TABLE_TRANSFER()
{
    Table=$1
    echo ${Table} >> /tmp/marketplace_tbls.txt
    echo ${Table}
    IFS="."
    read -ra arr <<< "${Table}"
    DB=${arr[0]}
    Tbl=${arr[1]}
    
    echo "Removing old /tmp/${Tbl}.sql"
    rm -fv /tmp/${Tbl}.sql /tmp/${Tbl}.sql.gz

    echo "taking dump of a table ${DB} ${Tbl} on 29.116"
    sudo mysqldump -uroot -p'c17h35coona' ${DB} ${Tbl} > /tmp/${Tbl}.sql && gzip -fv /tmp/${Tbl}.sql
    ERROR
    
    IFS=" "
    # Requested by (Animesh) animesh.khamesra@justdial.com
    for Ip in $IPS
    do
        echo "Removing Old tables"
        ssh $SSH_ARGS web_backup@${Ip} "sudo rm -fv /tmp/${Tbl}.sql"
        ERROR
        echo "transfering the table ${DB} ${Tbl} to ${Ip}"
        sudo scp /tmp/${Tbl}.sql.gz web_backup@${Ip}:/tmp
        ERROR

        echo "unzipping & restoring the table ${DB} ${Tbl} on ${Ip}"
        ssh $SSH_ARGS web_backup@${Ip} "sudo gunzip -fv /tmp/${Tbl}.sql.gz && sudo mysql db_product_operations < /tmp/${Tbl}.sql && rm -fv /tmp/${Tbl}.sql"
        ERROR
    done

   # ssh $SSH_ARGS web_backup@192.168.39.120 "sudo mysql -e 'drop table if exists db_product_operations.${Tbl} ;'"
    #ERROR
#    ssh $SSH_ARGS web_backup@192.168.39.120 "sudo mysql -e 'rename table db_product_operations.${Tbl} to global_mis.${Tbl} ;'"
#    ERROR


    # Requested by (Karnish) karnish.master1@justdial.com
    if [[ "$Table" == "temp_product_master_extract" ]]; then
        sudo scp /tmp/temp_product_master_extract.sql.gz web_backup@192.168.29.119:/tmp
        ERROR

        echo "unzipping dump file and restoring ${Table} on 192.168.29.119"
        ssh $SSH_ARG web_backup@192.168.29.119 "sudo gunzip -fv /tmp/${Table}.sql.gz && sudo mysql db_porting < /tmp/${Table}.sql && rm -fv /tmp/${Table}.sql"
        ERROR
    fi

    # Remove dump files from 29.116
    sudo rm -fv /tmp/${Table}.sql.gz
}



AllTablesNew=""
cnt=0
thread=5    # Same time dump & restore
for Table in $AllTables
do
    cnt=$((cnt+1))
    AllTablesNew="${AllTablesNew} ${Table}"
    if [[ "${cnt}" == "${thread}" ]]
    then
        echo ${AllTablesNew} ${cnt}
        for TableNew in $AllTablesNew
        do
            TABLE_TRANSFER ${TableNew} & pids+=($!)
            ERROR
        done
        echo "pids : " $pids
        ERROR
        wait "${pids[@]}"

        AllTablesNew=""
        cnt=0
    fi
done


if [[ ${cnt}!=0 || "${cnt}" == "${thread}" ]]
then
    echo ${AllTablesNew} ${cnt}
    for TableNew in $AllTablesNew
    do
        TABLE_TRANSFER ${TableNew} & pids+=($!)
        ERROR
    done
    echo "pids : " $pids
    ERROR
    wait "${pids[@]}"

    AllTablesNew=""
    cnt=0
fi


echo "pids_1 : " $pids_1
ERROR
wait "${pids_1[@]}"
date
Table="db_processing.temp_product_master_extract"
TABLE_TRANSFER ${Table}
ERROR


echo "All Process Successfully"
SUCCESS

