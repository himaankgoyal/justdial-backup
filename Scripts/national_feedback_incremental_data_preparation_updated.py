
import clickhouse_driver as cd
import sys
import pymongo
from pymongo import *
import requests
import datetime
from datetime import datetime
from datetime import timedelta
##import argparse

today = datetime.now().strftime('%Y-%m-%d')
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')



##parser = argparse.ArgumentParser(description='Process some dates.')
##parser.add_argument('start_date', type=str, help='Start date in YYYY-MM-DD format')
##parser.add_argument('end_date', type=str, help='End date in YYYY-MM-DD format')

# Parse arguments
#args = parser.parse_args()

# Convert string arguments to datetime objects
#start_date = datetime.strptime(args.start_date, '%Y-%m-%d')
#end_date = datetime.strptime(args.end_date, '%Y-%m-%d')

# Format dates for SQL (YYYY-MM-DD HH:MM:SS)
#start_date_str = start_date.strftime('%Y-%m-%d %H:%M:%S')
#end_date_str = end_date.strftime('%Y-%m-%d %H:%M:%S')

# Print the formatted dates (for debugging purposes)
#print(f"Start Date: {start_date_str}")
#print(f"End Date: {end_date_str}")


####connect to clickhouse server
client = cd.Client(host='192.168.29.159', user='default')

client = cd.Client(host='192.168.42.159',
        #user='db_click',
        user='praneshg',
        port =9000,
        #password ='dbclick123',
        password ='pr_nesh_987',
        alt_hosts='192.168.42.107',
        database='clicktracker'
        )


client.execute("TRUNCATE TABLE test.national_feedback_dashboard_data_transfer")

client.execute('set max_memory_usage = 10000000000000000000;')
client.execute("""
insert into test.national_feedback_dashboard_data_transfer
select _id,first_value(sid)sid,first_value(search_date)search_date,first_value(search_time_1)search_time,first_value(toString(serve_date))serve_date,
first_value(ctc_dt_1)ctc_responded_date ,first_value(cdr_dt)cdr_responded_date,first_value(call_st)call_st ,first_value(rg_flg) lead_type,first_value(unm)Caller_name,
first_value(di)di,first_value(cm_nm)cm_nm,first_value(ldln)Landline,first_value(mob)Mobile ,
groupArray(distinct email)email,
first_value(strm)search_string ,first_value(cat_nm)category_name ,first_value(mg_nm)IRO_code ,first_value(ld_src)channel,
first_value(hot_intend_cat)flow,first_value(intent_type)Intent,first_value(amt) Amt_deducted,
min(toString(toDateTime((toDateTime(parseDateTimeBestEffortOrNull(com_s_t))),'Asia/Kolkata')))Sms_Sent_DateTime,
min(toString(toDateTime((toDateTime(parseDateTimeBestEffortOrNull(com_n_t))),'Asia/Kolkata')))notification_Sent_DateTime,
min(toString(toDateTime((toDateTime(parseDateTimeBestEffortOrNull(com_w_t))),'Asia/Kolkata')))WA_Sent_DateTime,
min(toString(toDateTime((toDateTime(parseDateTimeBestEffortOrNull(com_e_t))),'Asia/Kolkata')))email_Sent_DateTime,
groupArray(distinct com_s_val)unique_sms_number,
groupArray(distinct  com_n_val)unique_notification_number,
groupArray(distinct  com_w_val)unique_WA_number,
groupArray(distinct  company_email)unique_company_email,
first_value(inp)call_type,first_value(ar)area,first_value(pc)pincode,first_value(d_ct)pincity,first_value(circle)circle,
first_value(fin_campaign)fin_campaign,first_value(search_campaign)search_campaign,first_value(dup) dup from 
(
SELECT JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), '_id', 'String') AS _id,
left(toString(search_time),10)as search_date,right(toString(search_time),8)as search_time_1,lead_trigger_time as serve_date,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'ctc_dt', 'String') AS ctc_dt,
toString(toDateTime(parseDateTimeBestEffortOrNull(cdr_dt)),'Asia/Kolkata')cdr_dt,
toString(toDateTime(parseDateTimeBestEffortOrNull(ctc_dt)),'Asia/Kolkata')ctc_dt_1,
call_st,rg_flg,username as unm,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'di', 'String') AS di,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'cm_nm', 'String') AS cm_nm,
ldln,mobile as mob,email,search_string as strm,category_name as cat_nm,magic_name as mg_nm,channel as ld_src,IF(bitAnd(vn_flg, 8192) = 8192, 'hot_cat', 'intend_cat') AS hot_intend_cat,
intent  as intent_type,JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'amt', 'String') AS amt,
replace(JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'com_s', 'String'),'!!','"') AS com_s,
replace(JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'com_n', 'String'),'!!','"') AS com_n,
replace(JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'com_e', 'String'),'!!','"') AS com_e,
replace(JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'com_w', 'String'),'!!','"') AS com_w,
if(com_s = '[]',replace(com_s,'[]','[{"val":"","st_dt":{"$date":"0000-00-00T00:00:00.000Z"}}]'),com_s) com_s_u,
replace((replace((JSONExtract((arrayJoin(JSONExtractArrayRaw(com_s_u))),'st_dt','String')),'{"$date":"','')),'"}','')com_s_t,
if(com_n = '[]',replace(com_n,'[]','[{"val":"","st_dt":{"$date":"0000-00-00T00:00:00.000Z"}}]'),com_n)com_n_u,
replace((replace((JSONExtract((arrayJoin(JSONExtractArrayRaw(com_n_u))),'st_dt','String')),'{"$date":"','')),'"}','')com_n_t,
if(com_w = '[]',replace(com_w,'[]','[{"val":"","st_dt":{"$date":"0000-00-00T00:00:00.000Z"}}]'),com_w) com_w_u,
replace((replace((JSONExtract((arrayJoin(JSONExtractArrayRaw(com_w_u))),'st_dt','String')),'{"$date":"','')),'"}','')com_w_t,
if(com_e = '[]',replace(com_e,'[]','[{"val":"","st_dt":{"$date":"0000-00-00T00:00:00.000Z"}}]'),com_e)com_e_u,
replace((replace((JSONExtract((arrayJoin(JSONExtractArrayRaw(com_e_u))),'st_dt','String')),'{"$date":"','')),'"}','')com_e_t,
JSONExtract((arrayJoin(JSONExtractArrayRaw(com_s_u))),'val','String')com_s_val,
JSONExtract((arrayJoin(JSONExtractArrayRaw(com_n_u))),'val','String')com_n_val,
JSONExtract((arrayJoin(JSONExtractArrayRaw(com_w_u))),'val','String')com_w_val,
JSONExtract((arrayJoin(JSONExtractArrayRaw(com_e_u))),'val','String')company_email,
flow as inp,search_area as ar,search_pincode as pc,search_city as d_ct,search_id as sid,iro_clcr as circle,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'ded_f_ci', 'String') AS fin_campaign,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'ded_ci', 'String') AS search_campaign,
JSONExtract(arrayJoin(JSONExtractArrayRaw(results_set)), 'dup', 'String') AS dup
FROM 
    leads.tbl_category_feedback_current
WHERE 
    date(lead_trigger_time) = toDate('""" + yesterday + """')
    and dup = '0' and fin_campaign in ('10','21','91')
    )x
    
    group by _id;
""")



##date(lead_trigger_time) >= '{start_date_str}' and date(lead_trigger_time) <= '{end_date_str}'


#url='https://hooks.slack.com/services/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'

#msg='leads data migration process completed for date'+str(data_date)

#alert='{"text":"%s"}'%msg
#responce=requests.post(url,alert)
