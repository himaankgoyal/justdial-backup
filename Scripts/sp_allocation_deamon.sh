#!/bin/bash

while [ 1 ] 
do
   taigaid=`mysql -Bse  "SELECT taigaid FROM db_allocation.tbl_taiga_log WHERE approve=1 and process_flag=0 limit 1"`
   allocation_name=`mysql -Bse "SELECT allocation_name FROM db_allocation.tbl_taiga_log WHERE approve=1 and process_flag=0 limit 1"`
   allocationType=`mysql -Bse  "SELECT allocationType FROM db_allocation.tbl_taiga_log WHERE approve=1 and process_flag=0 limit 1"`
   id=`echo $taigaid`

            if [[ $allocation_name == *"b2b_allocation"* ]]; then
            echo "Calling b2b allocation script on 12.80"
            sh -x /scripts/sp_b2b_dianamic_allocation.sh $id  > /var/log/daily_log/b2b_allocation.log 2>&1
             echo $taigaid
            fi
           #echo $taigaid
            
        
    sleep 20


done
