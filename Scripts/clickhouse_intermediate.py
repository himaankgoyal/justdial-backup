import sys
import clickhouse_driver as cd
import pymongo as py
from datetime import datetime, timedelta,date
import urllib
import subprocess as sp
import requests as r
import time

client = cd.Client(host='192.168.29.159',
                   user='default',
                   port =9000,
                   database='db_jd_tracker'
                )

dat = sys.argv[1]
print(dat)
dat1 = dat.replace('-','')
#dat = '2024-10-03'
username = 'db_mis_backend' #'abhishekb'
password= 'db_mis_backend#123' #'Abh!5hek#$_987'
# username = str(urllib.parse.quote_plus(user))
# password = str(urllib.parse.quote_plus(password))

hr = 24

try:
    x=client.execute('select count(1) from db_jd_tracker.tbl_event_data_test')

    if x[0][0] != 0:
         client.execute('truncate table  db_jd_tracker.tbl_event_data_test')
    else:
         print('Table already empty')


    insert_d ='clickhouse --client --host 192.168.29.159  --user "default"  --query="INSERT INTO db_jd_tracker.tbl_event_data_test(_id,ssid ,srchid ,sid ,di ,paid ,nc ,rf ,rf_flg ,rfa ,rfa_flg ,pt ,pt_flg ,evt ,evt_flg ,sevt ,sevt_flg ,uip ,ct ,d_ct ,dsrc ,ar ,pc ,jduid ,r_dt ,dv_src ,dv_id ,cat_nm ,cm_nm ,ua ,ci ,pos,d_flg ,ps_flg ,th_id ,unm ,bsrc ,bmed ,channel ,tid ,jdt_m ,jdt_ci ,utm_ci ,rfs ,vid ,vname ,lat ,long ,autopin ,app_vr ,pg ,avg_rat,rat_cnt ,tags,offers_deals,jd_verified,verified ,jd_trust ,jdlite ,udid ,pid ,jkta ,pdg ,cta_nm ,call_cta ,deal,jd_ch,mob ,ds ,env ,emp_flg,ctid ,ctname ,spos ,ty ,jtkr,bflg,misc_flg,b_ct,b_dct,b_ar,tab_id,jdt_src,is_api_call,bsids,dist,core_dist,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,tab_name,dtlpg_li,utm_src,utm_med,ld,ctas,tabs,sections,bi_lang,cdi,cat,intf,wap,usr_err,usr_err_page,new_usr,bus_usr,bd,bv,frs,ad_flg,t_dtl,trkid,srvc,jdm_elig,price,hcat,res_time,img,med_ele,tab,class,price_count,is_qn,b2b_flag,alsoserve)  FORMAT CSVWithNames SETTINGS format_csv_allow_single_quotes = 0 "  < /home/sunny/tbl_event_data_' + str(dat1) + '.csv'


    xx=sp.call(insert_d,shell=True)

    print(xx,'data inserted in the clickhouse ')

    client.execute("truncate table search_input.trd_tbl_category_master;")
    client.execute("insert into search_input.trd_tbl_category_master select national_catid,first_value(categoryname),first_value(display_product_flag),first_value(searchtype),first_value(display_product_abbr),first_value(revenue_rank),first_value(business_flag) from search_input.tbl_category_master where syn_flag = 0 group by national_catid;")

    for i in range(hr):
        try:
            print(datetime.now())
            client.execute("Truncate table db_jd_tracker.tbl_event_data_test_hour;")

            client.execute(f"insert into db_jd_tracker.tbl_event_data_test_hour select * from db_jd_tracker.tbl_event_data_test where toDate(r_dt_g) = '{dat}' and toHour(r_dt_g) = {i}")

            client.execute("truncate table search_input.trd_tbl_company_master;")
            client.execute("insert into search_input.trd_tbl_company_master select docid,hot_cat_info,primary_cat,b2b_flag,business_flag_abbr,type_flag,sub_type_flag,app_installed from search_input.tbl_company_master where docid in (select distinct di from db_jd_tracker.tbl_event_data_test_hour);")

            print(f"Inserting hour data :{i}")
            client.execute('Set max_memory_usage = 100000000000000;')
            h=client.execute("insert into db_jd_tracker.tbl_event_dataV1(_id,ssid ,srchid ,sid ,di ,paid ,nc ,rf ,rf_flg ,rfa ,rfa_flg ,pt ,pt_flg ,evt ,evt_flg ,sevt ,sevt_flg ,uip ,ct ,d_ct ,dsrc ,ar ,pc ,jduid ,r_dt ,dv_src ,dv_id ,cat_nm ,cm_nm ,ua ,ci ,pos,d_flg ,ps_flg ,th_id ,unm ,bsrc ,bmed ,channel ,tid ,jdt_m ,jdt_ci ,utm_ci ,rfs ,vid ,vname ,lat ,long ,autopin ,app_vr ,pg ,avg_rat,rat_cnt ,tags,offers_deals,jd_verified,verified ,jd_trust ,jdlite ,udid ,pid ,jkta ,pdg ,cta_nm ,call_cta ,deal,jd_ch,mob ,ds ,env ,emp_flg,ctid ,ctname ,spos ,ty ,jtkr,bflg,misc_flg,b_ct,b_dct,b_ar,tab_id,jdt_src,is_api_call,bsids,dist,core_dist,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,tab_name,dtlpg_li,utm_src,utm_med,ld,ctas,tabs,sections,bi_lang,cdi,cat,intf,wap,usr_err,usr_err_page,new_usr,bus_usr,bd,bv,frs,ad_flg,t_dtl,trkid,srvc,jdm_elig,price,hcat,res_time,img,med_ele,tab,class,price_count,is_qn,b2b_flag,alsoserve,area_type,area_type_flag,company_b2b,company_primary_cat,company_business_abbr,company_type_flag,company_sub_type_flag,company_app_installed,nc_categoryname,nc_display_product_flag,nc_searchtype,nc_display_product_abbr,nc_revenue_rank,nc_business_flag,hc_categoryname,hc_display_product_flag,hc_searchtype,hc_display_product_abbr,hc_revenue_rank,hc_business_flag,pc_categoryname,pc_display_product_flag,pc_searchtype,pc_display_product_abbr,pc_revenue_rank,pc_business_flag,nc_group_name,nc_group_rank,Hc_group_name,Hc_group_rank,pc_group_name,pc_group_rank) select _id,ssid ,srchid ,sid ,di ,toUInt32OrZero(a.paid) ,toUInt32OrZero(nc) ,rf ,rf_flg ,rfa ,rfa_flg ,pt ,pt_flg ,evt ,evt_flg ,sevt ,sevt_flg ,uip ,ct ,d_ct ,dsrc ,ar ,pc ,jduid ,r_dt ,toUInt32OrZero(dv_src) ,dv_id ,cat_nm ,cm_nm ,ua ,ci ,toUInt32OrZero(pos),d_flg ,ps_flg ,th_id ,unm ,bsrc ,bmed ,channel ,tid ,jdt_m ,jdt_ci ,utm_ci ,rfs ,vid ,vname ,lat ,long ,autopin ,app_vr ,pg ,avg_rat,rat_cnt ,tags,offers_deals,toUInt32OrZero(jd_verified),verified ,toUInt32OrZero(jd_trust) ,jdlite ,udid ,pid ,jkta ,pdg ,cta_nm ,call_cta ,toUInt32OrZero(deal),toUInt32OrZero(jd_ch),mob ,ds ,env ,toUInt32OrZero(emp_flg),ctid ,ctname ,spos ,ty ,jtkr,bflg,misc_flg,b_ct,b_dct,b_ar,tab_id,jdt_src,is_api_call,bsids,dist,core_dist,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,tab_name,dtlpg_li,utm_src,utm_med,ld,ctas,tabs,sections,bi_lang,cdi,cat,intf,wap,usr_err,usr_err_page,new_usr,bus_usr,bd,bv,frs,ad_flg,t_dtl,trkid,srvc,jdm_elig,price,hcat,res_time,img,med_ele,tab,class,price_count,is_qn,a.b2b_flag,alsoserve,b.area_type as area_type,b.type_flag as area_type_flag,c.b2b_flag as company_b2b , c.primary_cat as company_primary_cat, c.business_flag_abbr as company_business_abbr, c.type_flag as company_type_flag,c.sub_type_flag as company_sub_type_flag, c.app_installed as company_app_installed,d.categoryname as nc_categoryname,d.display_product_flag as nc_display_product_flag,d.searchtype  as nc_searchtype, d.display_product_abbr as nc_display_product_abbr,d.revenue_rank as nc_revenue_rank,d.business_flag as nc_business_flag,e.categoryname as hc_categoryname,e.display_product_flag as hc_display_product_flag,e.searchtype  as hc_searchtype, e.display_product_abbr as hc_display_product_abbr,e.revenue_rank as hc_revenue_rank,e.business_flag as hc_business_flag,f.categoryname as pc_categoryname,f.display_product_flag as pc_display_product_flag,f.searchtype  as pc_searchtype, f.display_product_abbr as pc_display_product_abbr,f.revenue_rank as pc_revenue_rank,f.business_flag as pc_business_flag,if(g.manual_group='','non grouped',g.manual_group) as  nc_group_name,if(g.group_rank=0,2859,g.group_rank) as nc_group_rank,if(h.manual_group='','non grouped',h.manual_group) as  Hc_group_name,if(h.group_rank=0,2859,h.group_rank) as Hc_group_rank,if(j.manual_group='','non grouped',j.manual_group) as  pc_group_name,if(j.group_rank=0,2859,j.group_rank) as pc_group_rank FROM db_jd_tracker.tbl_event_data_test_hour AS a LEFT JOIN search_input.tbl_area_consolidated AS b ON (a.ar = b.areaname) AND (a.d_ct = b.data_city) LEFT JOIN search_input.trd_tbl_company_master AS c ON a.di = c.docid LEFT JOIN search_input.trd_tbl_category_master AS d ON toUInt32OrZero(a.nc) = d.national_catid LEFT JOIN search_input.trd_tbl_category_master AS e ON toInt32OrZero(c.hot_cat_info) = e.national_catid LEFT JOIN search_input.trd_tbl_category_master AS f ON toInt32OrZero(substringUTF8(c.primary_cat, 1, 8)) = f.national_catid left join test.tbl_overall_group_mapping g on g.national_catid = toUInt32OrZero(a.nc) left join test.tbl_overall_group_mapping h on h.national_catid = toInt32OrZero(c.hot_cat_info) left join test.tbl_overall_group_mapping j on j.national_catid = toInt32OrZero(substringUTF8(c.primary_cat, 1, 8)) WHERE (toDate(r_dt_g) = '" + str(dat) + "');")
            print(datetime.now())
        except Exception as inner_exception:
            print(inner_exception)
            try: 
                time.sleep(30)
                print(datetime.now())
                client.execute(f"Alter table db_jd_tracker.tbl_event_dataV1 delete where toDate(r_dt_g) = '{dat}' and toHour(r_dt_g) = {i}")
                ranges = [(0,15),(16,30),(31,45),(46,60)]
                for start_min,end_min in ranges:
                    client.execute("Truncate table db_jd_tracker.tbl_event_data_test_hour;")
                    client.execute(f"insert into db_jd_tracker.tbl_event_data_test_hour select * from db_jd_tracker.tbl_event_data_test where toDate(r_dt_g) = '{dat}' and toHour(r_dt_g) = {i} and toMinute(r_dt_g) between {start_min} and {end_min};")

                    client.execute("truncate table search_input.trd_tbl_company_master;")
                    client.execute("insert into search_input.trd_tbl_company_master select docid,hot_cat_info,primary_cat,b2b_flag,business_flag_abbr,type_flag,sub_type_flag,app_installed from search_input.tbl_company_master where docid in (select distinct di from db_jd_tracker.tbl_event_data_test_hour);")

                    print(f"Inserting hour data :{i} and between {start_min} and {end_min}")
                    client.execute('Set max_memory_usage = 100000000000000;')
                    h=client.execute("insert into db_jd_tracker.tbl_event_dataV1(_id,ssid ,srchid ,sid ,di ,paid ,nc ,rf ,rf_flg ,rfa ,rfa_flg ,pt ,pt_flg ,evt ,evt_flg ,sevt ,sevt_flg ,uip ,ct ,d_ct ,dsrc ,ar ,pc ,jduid ,r_dt ,dv_src ,dv_id ,cat_nm ,cm_nm ,ua ,ci ,pos,d_flg ,ps_flg ,th_id ,unm ,bsrc ,bmed ,channel ,tid ,jdt_m ,jdt_ci ,utm_ci ,rfs ,vid ,vname ,lat ,long ,autopin ,app_vr ,pg ,avg_rat,rat_cnt ,tags,offers_deals,jd_verified,verified ,jd_trust ,jdlite ,udid ,pid ,jkta ,pdg ,cta_nm ,call_cta ,deal,jd_ch,mob ,ds ,env ,emp_flg,ctid ,ctname ,spos ,ty ,jtkr,bflg,misc_flg,b_ct,b_dct,b_ar,tab_id,jdt_src,is_api_call,bsids,dist,core_dist,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,tab_name,dtlpg_li,utm_src,utm_med,ld,ctas,tabs,sections,bi_lang,cdi,cat,intf,wap,usr_err,usr_err_page,new_usr,bus_usr,bd,bv,frs,ad_flg,t_dtl,trkid,srvc,jdm_elig,price,hcat,res_time,img,med_ele,tab,class,price_count,is_qn,b2b_flag,alsoserve,area_type,area_type_flag,company_b2b,company_primary_cat,company_business_abbr,company_type_flag,company_sub_type_flag,company_app_installed,nc_categoryname,nc_display_product_flag,nc_searchtype,nc_display_product_abbr,nc_revenue_rank,nc_business_flag,hc_categoryname,hc_display_product_flag,hc_searchtype,hc_display_product_abbr,hc_revenue_rank,hc_business_flag,pc_categoryname,pc_display_product_flag,pc_searchtype,pc_display_product_abbr,pc_revenue_rank,pc_business_flag,nc_group_name,nc_group_rank,Hc_group_name,Hc_group_rank,pc_group_name,pc_group_rank) select _id,ssid ,srchid ,sid ,di ,toUInt32OrZero(a.paid) ,toUInt32OrZero(nc) ,rf ,rf_flg ,rfa ,rfa_flg ,pt ,pt_flg ,evt ,evt_flg ,sevt ,sevt_flg ,uip ,ct ,d_ct ,dsrc ,ar ,pc ,jduid ,r_dt ,toUInt32OrZero(dv_src) ,dv_id ,cat_nm ,cm_nm ,ua ,ci ,toUInt32OrZero(pos),d_flg ,ps_flg ,th_id ,unm ,bsrc ,bmed ,channel ,tid ,jdt_m ,jdt_ci ,utm_ci ,rfs ,vid ,vname ,lat ,long ,autopin ,app_vr ,pg ,avg_rat,rat_cnt ,tags,offers_deals,toUInt32OrZero(jd_verified),verified ,toUInt32OrZero(jd_trust) ,jdlite ,udid ,pid ,jkta ,pdg ,cta_nm ,call_cta ,toUInt32OrZero(deal),toUInt32OrZero(jd_ch),mob ,ds ,env ,toUInt32OrZero(emp_flg),ctid ,ctname ,spos ,ty ,jtkr,bflg,misc_flg,b_ct,b_dct,b_ar,tab_id,jdt_src,is_api_call,bsids,dist,core_dist,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,tab_name,dtlpg_li,utm_src,utm_med,ld,ctas,tabs,sections,bi_lang,cdi,cat,intf,wap,usr_err,usr_err_page,new_usr,bus_usr,bd,bv,frs,ad_flg,t_dtl,trkid,srvc,jdm_elig,price,hcat,res_time,img,med_ele,tab,class,price_count,is_qn,a.b2b_flag,alsoserve,b.area_type as area_type,b.type_flag as area_type_flag,c.b2b_flag as company_b2b , c.primary_cat as company_primary_cat, c.business_flag_abbr as company_business_abbr, c.type_flag as company_type_flag,c.sub_type_flag as company_sub_type_flag, c.app_installed as company_app_installed,d.categoryname as nc_categoryname,d.display_product_flag as nc_display_product_flag,d.searchtype  as nc_searchtype, d.display_product_abbr as nc_display_product_abbr,d.revenue_rank as nc_revenue_rank,d.business_flag as nc_business_flag,e.categoryname as hc_categoryname,e.display_product_flag as hc_display_product_flag,e.searchtype  as hc_searchtype, e.display_product_abbr as hc_display_product_abbr,e.revenue_rank as hc_revenue_rank,e.business_flag as hc_business_flag,f.categoryname as pc_categoryname,f.display_product_flag as pc_display_product_flag,f.searchtype  as pc_searchtype, f.display_product_abbr as pc_display_product_abbr,f.revenue_rank as pc_revenue_rank,f.business_flag as pc_business_flag,if(g.manual_group='','non grouped',g.manual_group) as  nc_group_name,if(g.group_rank=0,2859,g.group_rank) as nc_group_rank,if(h.manual_group='','non grouped',h.manual_group) as  Hc_group_name,if(h.group_rank=0,2859,h.group_rank) as Hc_group_rank,if(j.manual_group='','non grouped',j.manual_group) as  pc_group_name,if(j.group_rank=0,2859,j.group_rank) as pc_group_rank FROM db_jd_tracker.tbl_event_data_test_hour AS a LEFT JOIN search_input.tbl_area_consolidated AS b ON (a.ar = b.areaname) AND (a.d_ct = b.data_city) LEFT JOIN search_input.trd_tbl_company_master AS c ON a.di = c.docid LEFT JOIN search_input.trd_tbl_category_master AS d ON toUInt32OrZero(a.nc) = d.national_catid LEFT JOIN search_input.trd_tbl_category_master AS e ON toInt32OrZero(c.hot_cat_info) = e.national_catid LEFT JOIN search_input.trd_tbl_category_master AS f ON toInt32OrZero(substringUTF8(c.primary_cat, 1, 8)) = f.national_catid left join test.tbl_overall_group_mapping g on g.national_catid = toUInt32OrZero(a.nc) left join test.tbl_overall_group_mapping h on h.national_catid = toInt32OrZero(c.hot_cat_info) left join test.tbl_overall_group_mapping j on j.national_catid = toInt32OrZero(substringUTF8(c.primary_cat, 1, 8)) WHERE (toDate(r_dt_g) = '" + str(dat) + "');")
                    print(datetime.now())
            except Exception as err:
                print('exception occured ->',err)
                msg = 'trd data insertion failed at 15min wise insert'
                x=r.get('https://www.jdomni.com/marketplace/static/php/smscredits/smsapi.php?action=send_sms&mobile=8870785665&promoLink=1&msg='+str(msg) + '&smsType=VERIFICATION&isPaid=0')



    

    print(f'data inserted in the main table ' , h)
    msg = f'trd data inserted successfully'
    x=r.get('https://www.jdomni.com/marketplace/static/php/smscredits/smsapi.php?action=send_sms&mobile=8870785665&promoLink=1&msg='+str(msg) + '&smsType=VERIFICATION&isPaid=0')

    print(x.text)
    
except Exception as err:
    print('exception occured ->',err)
    msg = 'trd data insertion failed at hour wise'
    x=r.get('https://www.jdomni.com/marketplace/static/php/smscredits/smsapi.php?action=send_sms&mobile=8870785665&promoLink=1&msg='+str(msg) + '&smsType=VERIFICATION&isPaid=0')

