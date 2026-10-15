import clickhouse_driver as cd
import sys
import pymongo
from pymongo import *
import requests
import datetime
from datetime import datetime
from datetime import *

##connect to clickhouse server


client = cd.Client(host='192.168.16.71',
        ##user='db_click',
        user='gp_10128526',
        port =9000,
        ##password ='dbclick123',
        password ='pr@nesh_987',
        #alt_hosts='192.168.42.107',
        database='leads_feedback_data'
        )

a=datetime.now().date()+timedelta(days=-1)

b=str(a)
y=b[:4]
m=b[5:7]

table_date=y+m
print(table_date)

today = datetime.now().strftime('%Y-%m-%d')
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

print(yesterday)

#client.execute("""
#INSERT INTO leads_feedback_data.national_feedback_dashboard_data_"+table_date +" select * from test.national_feedback_dashboard_data_transfer where date(serve_date) = toDate('""" + yesterday + """');
#""")

client.execute("INSERT INTO leads_feedback_data.national_feedback_dashboard_data_"+table_date +" select * from test.national_feedback_dashboard_data_transfer where date(serve_date) = '"+str(yesterday)+"';")

