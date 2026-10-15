import pymongo
from pymongo import MongoClient,ASCENDING,client_session
from datetime import datetime,timedelta
import sys
from pymongo import ReadPreference
import csv
from bson.decimal128 import Decimal128
import multiprocessing as mp
import string
import clickhouse_driver as cd



myclient = MongoClient(['192.168.29.53:27017', '192.168.29.54:27017', '192.168.29.55 :27017'],username='db_mis_backend',password='DB_mis_backend#123' )

#to_date=datetime.now().replace(hour=0,second=0,minute=0,microsecond=0)+timedelta(days=-4,hours=-5,minutes=-30)

#to_date = sys.argv[1]
coll_date=(sys.argv[1]).replace('-','')

mydb=myclient["db_jdmart_tracker"]

mycol=mydb["tbl_jdmart_event_data_"+coll_date]

#get count of the dv_id 
pipe = [{ "$group" : { "_id" : "$dv_id" } }]
data1 = mycol.aggregate( pipe ,allowDiskUse= True)

data=[]

for k in data1:
    data.append(k['_id'])

print('distinct dv_id in the collection' , mycol ,'--> ', len(data))


nn = 100
data_new  = [data[i * nn:(i + 1) * nn] for i in range((len(data) + nn - 1) // nn )]

client=cd.Client(
    host ='192.168.41.244',
    user ='db_click',
    port = 9000,
    password ='dbclick123',
    database = 'db_jdmart_tracker'
)

l0=[]
l1=[]
l2=[]
l3=[]
l4=[]
l5=[]
l6=[]
l7=[]
l8=[]
l9=[]
l10=[]
for i in range(len(data_new)):
    i=str(i)
    if (i[-1])=='0':
        l0.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='1':
        l1.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='2':
        l2.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='3':
        l3.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='4':
        l4.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='5':
        l5.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='6':
        l6.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='7':
        l7.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='8':
        l8.append(i)
for i in range(len(data_new)):
    i=str(i)
    if i[-1]=='9':
        l9.append(i)


def list_thread(number):
   
    aa=0
    list_data=[]
    if number == 0:
        list_data = l0
        
    elif number ==1 :
        list_data = l1
        
    elif number ==2 :
        list_data = l2

    elif number ==3 :
        list_data = l3
    elif number ==4 :
        list_data = l4
    elif number ==5 :
        list_data = l5
    elif number ==6 :
        list_data = l6
    elif number ==7 :
        list_data = l7
    elif number ==8 :
        list_data = l8
    elif number ==9 :
        list_data = l9
    elif number == 10 :
        list_data = l10
    file = "tbl_jdmart_event_data_"+ str(coll_date) + '_' + str(number)
    filename = str(file) + ".csv"
    headers = ('_id','r_dt','ssid','srchid','di','bc_di','cm_nm','s_flg','s_bid','bb_flg','jdc_flg','bbx_flg','ty','pid','pnm','d_pid','psvnid','psvnm','pc','dc','ct','dsrc','nc','paid','rf','rf_flg','rfa','rfa_flg','pt','pt_flg','evt','evt_flg','sevt','sevt_flg','uip','ar','jduid','dv_src','dv_id','cat_nm','ci','pos','spos','bn_flg','tid','cdi','tab','jdt_src','jdt_m','jdt_ci','utm_ci','rfs','ct_el','ct_flg','fn_ci','tf_flg','emp_flg','mkp_flg','tpsc','pg','id','nm','flg','is_slav','autopin','pmrp','pprice','eta','pratings','cratings','kwbrand','uniq_seller_cnt','pratings_avg','cratings_avg','ftrs','srno','cat_flag','to_process','done_flg','pscore','pimg','qty','utm_src','utm_med','med_price','vid','jdlite','fromjdres','flow','jdmid','cimg','lat','long','lmk','email','pos_flg','vers','mob','bc','tabs','b2bhk','rel_cat','root_cid','vname','cat','tags','ctname','qinfo','qinfo_str','is_api_call','bsids','dsource','srch_str','dist','core_dist','hcif')
    # with open(filename, 'a') as csvfile:
    #             csvwriter = csv.writer(csvfile)
    #             csvwriter.writerow(headers)
    
    
    for p in list_data:
        new_list =[]
        print('this-------------------------------------------------------------------------->',p)
      
        p = int(p)
        i=data_new[p]
        print(number)
        #i = ('16666379973624783','16913439023585771','16963291467892589','16963326577996676')
        aa=+2000
        x=mycol.find({"dv_id":{"$in":(i)}})
        
        for data in x:
            #print(data)
            try:
                dist=float(str(data.get("dist")))
            except:
                dist=0.0
            try:
                vers=float(str(data.get("vers")))
                
            except:
                vers=0.0
            try:
                core_dist=float(str(data.get("core_dist")))
            except:
                core_dist=0.0
            try:
                long=float(str(data.get("long")))
            except:
                long=0.0
            try:
                lat=float(str(data.get("lat")))
            except:
                lat=0.0  
            try:
                med_price=float(str(data.get("med_price")))
            except:
                med_price=0.0
            try:
                pscore=float(str(data.get("pscore")))
            except:
                pscore=0.0
            try:
                pprice=float(str(data.get("pprice")))
            except:
                pprice=0.0
            try:
                pmrp=float(str(data.get("pmrp")))
            except:
                pmrp=0.0
            try:
                s_bid=float(str(data.get("s_bid")))
            except:
                s_bid=0.0
            try:
                ar=str(data.get("ar"))
            except:
                ar=''
            try:
                _id=str(data.get("_id"))
            except:
                _id=''
            try:
                b2bhk=str(data.get("b2bhk"))
            except:
                b2bhk=''
            try:
                bc_di=str(data.get("bc_di"))
            except:
                bc_di=''
            try:
                bsids=str(data.get("bsids"))
            except:
                bsids=''
            try:
                cat_nm=str(data.get("cat_nm"))
            except:
                cat_nm=''
            try:
                cimg=str(data.get("cimg"))
            except:
                cimg=''
            try:
                cm_nm=str(data.get("cm_nm"))
            except:
                cm_nm=''
            try:
                cratings=str(data.get("cratings"))
            except:
                cratings=''
            try:
                cratings_avg=str(data.get("cratings_avg"))
            except:
                cratings_avg=''
            try:
                ct=str(data.get("ct"))
            except:
                ct=''
            try:
                ctname=str(data.get("ctname"))
            except:
                ctname=''
            try:
                d_pid=str(data.get("d_pid"))
            except:
                d_pid=''
            try:
                dc=str(data.get("dc"))
            except:
                dc=''
            try:
                di=str(data.get("di"))
            except:
                di=''
            try:
                dsource=str(data.get("dsource"))
            except:
                dsource=''
            try:
                dsrc=str(data.get("dsrc"))
            except:
                dsrc=''
            try:
                dv_id=str(data.get("dv_id"))
            except:
                dv_id=''
            try:
                email=str(data.get("email"))
            except:
                email=''
            try:
                eta=str(data.get("eta"))
            except:
                eta=''
            try:
                evt=str(data.get("evt"))
            except:
                evt=''
            try:
                flow=str(data.get("flow"))
            except:
                flow=''
            try:
                fn_ci=str(data.get("fn_ci"))
            except:
                fn_ci=''
            try:
                ftrs=str(data.get("ftrs"))
            except:
                ftrs=''
            try:
                hcif=str(data.get("hcif")).replace("'",'"')
            except:
                hcif=''
            try:
                id=str(data.get("id"))
            except:
                id=''
            try:
                jdmid=str(data.get("jdmid"))
            except:
                jdmid='' 
            try:
                jdt_ci=str(data.get("jdt_ci"))
            except:
                jdt_ci='' 
            try:
                jdt_m=str(data.get("jdt_m"))
            except:
                jdt_m='' 
            try:
                jdt_src=str(data.get("jdt_src"))
            except:
                jdt_src='' 
            try:
                jduid=str(data.get("jduid"))
            except:
                jduid=''
            try:
                kwbrand=str(data.get("kwbrand"))
            except:
                kwbrand=''
            try:
                lmk=str(data.get("lmk"))
            except:
                lmk=''
            try:
                nm=str(data.get("nm"))
            except:
                nm=''
            try:
                pid=str(data.get("pid"))
            except:
                pid=''
            try:
                pimg=str(data.get("pimg"))
            except:
                pimg=''
            try:
                pnm=str(data.get("pnm"))
            except:
                pnm=''
            try:
                pos_flg=str(data.get("pos_flg"))
            except:
                pos_flg=''
            try:
                pratings=str(data.get("pratings"))
            except:
                pratings=''
            try:
                pratings_avg=str(data.get("pratings_avg"))
            except:
                pratings_avg=''
            try:
                psvnid=str(data.get("psvnid"))
            except:
                psvnid=''
            try:
                psvnm=str(data.get("psvnm"))
            except:
                psvnm=''
            try:
                pt=str(data.get("pt"))
            except:
                pt=''
            try:
                qinfo_str=str(data.get("qinfo_str"))
            except:
                qinfo_str=''
            try:
                rf=str(data.get("rf"))
            except:
                rf=''
            try:
                rfa=str(data.get("rfa"))
            except:
                rfa=''
            try:
                rfs=str(data.get("rfs"))
            except:
                rfs=''
            try:
                root_cid=str(data.get("root_cid"))
            except:
                root_cid=''
            try:
                sevt=str(data.get("sevt"))
            except:
                sevt=''
            try:
                srch_str=str(data.get("srch_str"))
            except:
                srch_str=''
            try:
                srchid=str(data.get("srchid"))
            except:
                srchid=''
            try:
                ssid=str(data.get("ssid"))
            except:
                ssid=''
            try:
                tab=str(data.get("tab")) 
            except:
                tab=''
            try:
                tabs=data.get("tabs",[]) #array string
            except:
                tabs=[]
            try:
                tags=data.get("tags",[]) #array string
            except:
                tags=[]
            try:
                tf_flg=str(data.get("tf_flg"))
            except:
                tf_flg=''
            try:
                tid=str(data.get("tid"))
            except:
                tid=''
            try:
                ty=str(data.get("ty")) 
            except:
                ty=''
            try:
                uip=str(data.get("uip")) 
            except:
                uip=''
            try:
                utm_ci=str(data.get("utm_ci")) 
            except:
                utm_ci=''
            try:
                utm_med=str(data.get("utm_med")) 
            except:
                utm_med=''
            try:
                utm_src=str(data.get("utm_src")) 
            except:
                utm_src=''
            try:
                vid=str(data.get("vid")) 
            except:
                vid=''
            try:
                vname=str(data.get("vname")) 
            except:
                vname=''
            try:
                autopin=int(data.get("autopin"))
            except:
                autopin=0
            try:
                bb_flg=int(data.get("bb_flg"))
            except:
                bb_flg=0
            try:
                bbx_flg=int(data.get("bbx_flg"))
            except:
                bbx_flg=0
            try:
                bc=int(data.get("bc"))
            except:
                bc=0
            try:
                bn_flg=int(data.get("bn_flg"))
            except:
                bn_flg=0
            
            try:
                ci=int(data.get("ci"))
            except:
                ci=0
            try:
                ct_el=int(data.get("ct_el"))
            except:
                ct_el=0
            try:
                ct_flg=int(data.get("ct_flg"))
            except:
                ct_flg=0
            try:
                done_flg=int(data.get("done_flg"))
            except:
                done_flg=0
            try:
                dv_src=int(data.get("dv_src"))
            except:
                dv_src=0
            try:
                emp_flg=int(data.get("emp_flg"))
            except:
                emp_flg=0
            try:
                evt_flg=int(data.get("evt_flg"))
            except:
                evt_flg=0
            try:
                flg=int(data.get("flg"))
            except:
                flg=0
            try:
                fromjdres=int(data.get("fromjdres"))
            except:
                fromjdres=0
            try:
                is_api_call=int(data.get("is_api_call"))
            except:
                is_api_call=0
            try:
                is_slav=int(data.get("is_slav"))
            except:
                is_slav=0
            try:
                jdc_flg=int(data.get("jdc_flg"))
            except:
                jdc_flg=0
            try:
                jdlite=int(data.get("jdlite"))
            except:
                jdlite=0
            try:
                r_dt=(data.get("r_dt"))
                r_dt=r_dt+timedelta(hours=5,minutes=30)
                print(r_dt)
            except:
                r_dt=0
            try:
                s_flg=data.get("s_flg")
            except:
                s_flg =""
            try:
                pc=int(data.get("pc"))
            except:
                pc=0
            try:
                nc= int(data.get("nc"))
                #if(len(nc)>10):
                #    nc =0
                #else:
                #    pass
            except:
                nc= 0
            try:
                paid=int(data.get("paid"))
            except:
                paid =0
            try:
                rf_flg= int(data.get("rf_flg"))
            except:
                rf_flg =0 
            try:
                rfa_flg= int(data.get("rfa_flg"))
            except:
                rfa_flg =0
            try:
                pt_flg= int(data.get("pt_flg"))
            except:
                pt_flg=0
            try:
                sevt_flg= int(data.get("sevt_flg"))
            except:
                sevt_flg = 0
            try:
                pos = int(data.get("pos"))
            except:
                pos=0
            try:
                spos = int(data.get("spos"))
            except:
                spos =0
            try:
                cdi= data.get("cdi")
            except:
                cdi='{}'
            try:
                mkp_flg= int(data.get("mkp_flg"))
            except:
                mkp_flg=0
            try:
                tpsc=int(data.get("tpsc"))
            except:
                tpsc=0
            try:
                pg=int(data.get("pg"))
            except:
                pg=0
            
            try:
                uniq_seller_cnt= int(data.get("uniq_seller_cnt"))
            except:
                uniq_seller_cnt=0
            try:
                srno= int(data.get("srno"))
            except:
                srno=0
            try:
                cat_flag=int(data.get("cat_flag"))
            except:
                cat_flag=0
            try:
                to_process=int(data.get("to_process"))
            except:
                to_process=0
            try:
                qty=int(data.get("qty"))
            except:
                qty=0
            try:
                mob=(int(data.get("mob")))
            except:
                mob = 0
            try:
                rel_cat=int(data.get("rel_cat"))
            except:
                rel_cat=0
            
            try:
                cat=data.get("cat")
            except:
                cat=""
            try:
                qinfo=str(data.get("qinfo")).replace("'",'"')
                print(qinfo)
            except:
                qinfo=""
            try:
                AN=str(data.get("AN"))
            except:
                AN=''
            try:
                VN=str(data.get("VN"))
            except:
                VN=''
            try:
                DVN=str(data.get("DVN"))
            except:
                DVN=''
            try:
                usr_err= str(data.get("usr_err"))
            except:
                usr_err=''
            try:
                usr_err_page= str(data.get("usr_err_page"))
            except:
                usr_err_page =''
            try:
                flt_v = data.get("flt_v",[])
            except:
                flt_v =[]
            try:
                srch_ty =str(data.get("srch_ty"))
            except:
                srch_ty=''
            try:
                txn_id = str(data.get("txn_id"))
            except:
                txn_id=""
            try:
                answ=str(data.get("answ"))
            except:
                answ =""
            try:
                qid=str(data.get("qid"))
            except:
                qid =""
            try:
                quest= str(data.get("quest"))
            except:
                quest =""
            try:
                bann_ty= str(data.get("bann_ty"))
            except:
                bann_ty =""
            try:
                bann_cta =str(data.get("bann_cta"))
            except:
                bann_cta=""
            try:
                ld_tp = str(data.get("ld_tp"))
            except:
                ld_tp = ""
            try:
                ld_pg = str(data.get("ld_pg"))
            except:
                ld_pg =""
            try:
                ld_tp_pos = str(data.get("ld_tp_pos"))
            except:
                ld_tp_pos = ""
            try:
                cl_ty = str(data.get("cl_ty")) 
            except:
                cl_ty = ""
            try:
                is_video = int(data.get("is_video"))
            except:
                is_video =0
            try:
                intf = str(data.get("intf"))
            except:
                intf = ""
            try:
                img_cnt = int(data.get("img_cnt"))
            except:
                img_cnt =0
            try:
                ld =str(data.get("ld"))
            except:
                ld ='[]'
            try:
                ua =str(data.get("ua"))
            except:
                ua ='[]'
            try:
                b2b_flag =int(data.get("b2b_flag"))
            except:
                b2b_flag =0
            try:
                jdm_elig = int(data.get("jdm_elig"))
            except:
                jdm_elig =0
            try:
                cat_flg = int(data.get("cat_flg"))
            except:
                cat_flg =0
            try:
                call_cta = int(data.get("call_cta"))
            except:
                call_cta =0
            try:
                c_ct =str(data.get("c_ct"))
            except:
                c_ct =""
            try:
                c_dct = str(data.get('c_dct'))
            except:
                c_dct =''
            
            try:
                hiconnect = int(data.get("hiconnect"))
            except:
                hiconnect = 0

            try:
                nc_org = int(data.get("nc_org"))
            except:
                nc_org = 0
            
            try:
                bflg = int(data.get("bflg"))
            except:
                bflg = 0

            ### new nodes added on 09th Dec 2024
            try:
                ip_avai = int(data.get("ip_avai"))
            except:
                ip_avai = 0

            try:
                ipcity = str(data.get("ipcity"))
            except:
                ipcity =""
            
            ### new node added on 12th Dec 2024

            try:
                us_ct = str(data.get("us_ct"))
            except:
                us_ct = ""

            ### new node added on 23th Dec 2024
            try:
                alsoserve = int(data.get("alsoserve"))
            except:
                alsoserve = 0

    
            l = {"_id":_id,"r_dt":r_dt,"ssid":ssid,"srchid":srchid,"di":di,"bc_di":bc_di,"cm_nm":cm_nm,"s_flg":s_flg,"s_bid":s_bid,"bb_flg":bb_flg,"jdc_flg":jdc_flg,"bbx_flg":bbx_flg,"ty":ty,"pid":pid,"pnm":pnm,"d_pid":d_pid,"psvnid":psvnid,"psvnm":psvnm,"pc":pc,"dc":dc,"ct":ct,"dsrc":dsrc,"nc":nc,"paid":paid,"rf":rf,"rf_flg":rf_flg,"rfa":rfa,"rfa_flg":rfa_flg,"pt":pt,"pt_flg":pt_flg,"evt":evt,"evt_flg":evt_flg,"sevt":sevt,"sevt_flg":sevt_flg,"uip":uip,"ar":ar,"jduid":jduid,"dv_src":dv_src,"dv_id":dv_id,"cat_nm":cat_nm,"ci":ci,"pos":pos,"spos":spos,"bn_flg":bn_flg,"tid":tid,"cdi":str(cdi),"tab":tab,"jdt_src":jdt_src,"jdt_m":jdt_m,"jdt_ci":jdt_ci,"utm_ci":utm_ci,"rfs":rfs,"ct_el":ct_el,"ct_flg":ct_flg,"fn_ci":fn_ci,"tf_flg":tf_flg,"emp_flg":emp_flg,"mkp_flg":mkp_flg,"tpsc":tpsc,"pg":pg,"id":id,"nm":nm,"flg":flg,"is_slav":is_slav,"autopin":autopin,"pmrp":pmrp,"pprice":pprice,"eta":eta,"pratings":pratings,"cratings":cratings,"kwbrand":kwbrand,"uniq_seller_cnt":uniq_seller_cnt,"pratings_avg":pratings_avg,"cratings_avg":cratings_avg,"ftrs":ftrs,"srno":srno,"cat_flag":cat_flag,"to_process":to_process,"done_flg":done_flg,"pscore":pscore,"pimg":pimg,"qty":qty,"utm_src":utm_src,"utm_med":utm_med,"med_price":med_price,"vid":vid,"jdlite":jdlite,"fromjdres":fromjdres,"flow":flow,"jdmid":jdmid,"cimg":cimg,"lat":lat,"long":long,"lmk":lmk,"email":email,"pos_flg":pos_flg,"vers":vers,"mob":mob,"bc":bc,"tabs":str(tabs),"b2bhk":b2bhk,"rel_cat":rel_cat,"root_cid":root_cid,"vname":vname,"cat":str(cat),"tags":str(tags),"ctname":ctname,"qinfo":str(qinfo),"qinfo_str":qinfo_str,"is_api_call":is_api_call,"bsids":bsids,"dsource":dsource,"srch_str":srch_str,"dist":dist,"core_dist":core_dist,"hcif":hcif,"AN":AN,"VN":VN,"DVN":DVN,"usr_err":usr_err,"usr_err_page":usr_err_page,"flt_v":str(flt_v),"srch_ty":srch_ty,"txn_id":txn_id,"answ":answ,"qid":qid,"quest":quest,"bann_ty":bann_ty,"bann_cta":bann_cta,
            "ld_tp":ld_tp,"ld_pg":ld_pg,"ld_tp_pos":ld_tp_pos,"cl_ty":cl_ty,"is_video":is_video,"intf":intf,"img_cnt":img_cnt,"ld":ld,"ua":ua,
            "b2b_flag":b2b_flag,"jdm_elig":jdm_elig,"cat_flg":cat_flg,"call_cta":call_cta,"c_ct":c_ct,"c_dct":c_dct,"hiconnect":hiconnect,"nc_org":nc_org,"bflg":bflg,"ip_avai":ip_avai,"ipcity":ipcity,"us_ct":us_ct,"alsoserve":alsoserve}
            new_list.append(l)
        
        client.execute("insert into db_jdmart_tracker.tbl_jdmart_event_data(_id,r_dt,ssid,srchid,di,bc_di,cm_nm,s_flg,s_bid,bb_flg,jdc_flg,bbx_flg,ty,pid,pnm,d_pid,psvnid,psvnm,pc,dc,ct,dsrc,nc,paid,rf,rf_flg,rfa,rfa_flg,pt,pt_flg,evt,evt_flg,sevt,sevt_flg,uip,ar,jduid,dv_src,dv_id,cat_nm,ci,pos,spos,bn_flg,tid,cdi,tab,jdt_src,jdt_m,jdt_ci,utm_ci,rfs,ct_el,ct_flg,fn_ci,tf_flg,emp_flg,mkp_flg,tpsc,pg,id,nm,flg,is_slav,autopin,pmrp,pprice,eta,pratings,cratings,kwbrand,uniq_seller_cnt,pratings_avg,cratings_avg,ftrs,srno,cat_flag,to_process,done_flg,pscore,pimg,qty,utm_src,utm_med,med_price,vid,jdlite,fromjdres,flow,jdmid,cimg,lat,long,lmk,email,pos_flg,vers,mob,bc,tabs,b2bhk,rel_cat,root_cid,vname,cat,tags,ctname,qinfo,qinfo_str,is_api_call,bsids,dsource,srch_str,dist,core_dist,hcif,AN,VN,DVN,usr_err,usr_err_page,flt_v,srch_ty,txn_id,answ,qid,quest,bann_ty,bann_cta,ld_tp,ld_pg,ld_tp_pos,cl_ty,is_video,intf,img_cnt,ld,ua,b2b_flag,jdm_elig,cat_flg,call_cta,c_ct,c_dct,hiconnect,nc_org,bflg,ip_avai,ipcity,us_ct,alsoserve) values" , new_list)
        #exit(1)
        # with open(filename, 'a') as csvfile:
        #     csvwriter = csv.writer(csvfile)
        #     csvwriter.writerows(new_list)
            
   

tag1=(10)
ar = list(range(0,tag1))
print(ar)
p = mp.Pool(tag1)
p.map(list_thread,ar)
p.close()
p.join() 

