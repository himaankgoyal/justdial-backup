#!/bin/bash


IPADDR=`/sbin/route -n | awk '{print $1,$8}' | grep "0.0.0.0" | cut -d " " -f2 | xargs /sbin/ifconfig | egrep "inet | inet addr"  | awk '{print $2}'| sed 's/addr://g'`
HOSTNAME=`hostname`
SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"
LINE="======================================================================================="
echo "Script to check Server Hardening Checklist"
echo " "
echo " "

echo "This is server $HOSTNAME with IP : $IPADDR"
echo " "
echo " "
sleep 2
echo "Checking the Server Hardening Checklist one by one ..."; sleep 2
echo ""

echo $LINE

echo "Server Details :: "
cat /etc/redhat-release
nginx -v 
redis-cli -v 
#mysql -v
mysql --version
echo " "
echo "Please  add more services if needed "
echo ""

echo $LINE
echo "1)/scripts/find-ip-addr.sh" 
echo "2)/scripts/find_ct_digit.sh"
if [ -f  /scripts/find-ip-addr.sh ]; then
echo -n "1) "; sh /scripts/find-ip-addr.sh
else 
scp web_backup@192.168.12.108:find-ip-addr.sh /scripts && chmod +x /scripts/find-ip-addr.sh && echo -n "1) "; sh /scripts/find-ip-addr.sh; fi
echo -n "2) ";sh /scripts/find_ct_digit.sh
echo " "
echo $LINE
echo "ulimit -n"; ulimit -n
echo " "
echo $LINE
echo "1)Ifconfig  "
echo "2)cat /proc/net/bonding/bond0"

ifconfig | grep -A1 "bond0: "
echo " "
cat /proc/net/bonding/bond0 | grep -A2 "Bonding Mode:"; cat /proc/net/bonding/bond0 | grep "Slave Interface:"
echo " "
echo $LINE
echo "crontab -l|egrep -i 'sysmon|inventory|diskspace|fetch_server_utilization|check_logrotate|linux_requisite_check|ansible_connectivity'"
crontab -l|egrep -i 'sysmon|inventory|diskspace|fetch_server_utilization|check_logrotate|linux_requisite_check|ansible_connectivity'

echo "============="
ssh $SSH_ARGS web_backup@172.29.64.64 "mysql -uroot -Bse \"select serv_ip,root_part_total,root_part_free,add_part_1_name,add_part_1_total,add_part_1_free,add_part_2_name,add_part_2_total,add_part_2_free,updatedon from db_diskspace.tbl_diskspace  where serv_ip='${IPADDR}' and updatedon like '%2018-06-17%' order by updatedon desc limit 1 ;\""
echo " "
echo "============="

echo " "
echo $LINE
echo  " " 
echo "cat /etc/nagios/nrpe.cfg" ; echo "PLease check Nagios for basic checks in place..."; sleep 4
echo " "
echo "/usr/lib64/nagios/plugins/check_nrpe -H $IPADDR -c check_disk (from 192.168.11.123)"
ssh $SSH_ARGS web_backup@192.168.11.123 "/usr/lib64/nagios/plugins/check_nrpe -H $IPADDR -c check_disk"
echo " "
echo $LINE
echo  " "
echo "1> iptables -L  "
iptables -L
echo  " "
echo "2> getenforce"
getenforce

echo " "
echo $LINE
echo  " "
echo "1) cat /home/web_backup/network_addr.txt"
echo "2) cat /home/web_backup/ipaddr.txt"
echo "3) cat /home/web_backup/city_name"
echo  " "

echo -n "1) "; cat /home/web_backup/network_addr.txt
echo -n "2) ";cat /home/web_backup/ipaddr.txt
echo -n "3) ";cat /home/web_backup/city_name
echo " "
echo $LINE
echo  " "
echo "crontab -l |grep ntpd"
crontab -l |grep ntpd
echo  " "
echo " "
echo $LINE
echo "cat /etc/hosts"
cat /etc/hosts
echo  " "
echo " "
echo $LINE
echo "date "
date
echo  " "
echo " "
echo $LINE
echo "1) ssh 192.168.12.78 -l web_backup from root"
LOGIN=`ssh $SSH_ARGS 192.168.12.78 -l web_backup "hostname"`
if [[ $LOGIN == "12-78-IDC.justdial.com" ]] ; then echo "login successfull without password for 12.78"; fi
echo  " "
echo "2) cat /etc/sudoers|grep -i web_backup"
cat /etc/sudoers|grep -i web_backup
echo  " "
echo " "
echo $LINE
echo "ansible -a "hostname" $IPADDR -u web_backup  (From 192.168.12.78) "
ANSI_SUCCESS=`ssh $SSH_ARGS web_backup@192.168.12.78 "ansible -a hostname $IPADDR -u web_backup" | grep SUCCESS | awk -F "|" '{print $2}' | tr -d ' '`
if [[ $ANSI_SUCCESS == SUCCESS ]] ; then echo `ssh $SSH_ARGS web_backup@192.168.12.78 "ansible -a hostname $IPADDR -u web_backup" `; fi
echo  " "
echo " "
echo $LINE
echo "echo "Test Mail From $IPADDR"| mail -s "Testing mail From $IPADDR" linux@justdial.com"
echo "Test Mail From $IPADDR"| mail -s "Testing mail From $IPADDR for Server Hardening Checklist" linux@justdial.com
echo " "
echo " Please check if the mail is received"; sleep 3
echo  " "
echo " "
echo $LINE
echo "service NetworkManager status and  systemctl is-enabled  NetworkManager"
service NetworkManager status ;  systemctl is-enabled  NetworkManager
echo  " "
echo " "
echo $LINE
echo "1) service rsyslog status && systemctl is-enabled rsyslog"
service rsyslog status | grep Active && systemctl is-enabled rsyslog
echo  " "
echo " "
echo $LINE
echo "2) service crond status && systemctl is-enabled crond"
service crond status | grep Active && systemctl is-enabled crond
echo " "
echo $LINE
echo  " "
echo "3) service xinetd  status && systemctl is-enabled xinetd"
service xinetd  status | grep Active && systemctl is-enabled xinetd
echo " "
echo $LINE
echo  " "
echo "4) service ntpd  status && systemctl is-enabled ntpd"
service ntpd  status | grep Active && systemctl is-enabled ntpd
echo  " "
echo " "
echo $LINE

echo "5) service sendmail  status && systemctl is-enabled sendmail"
service sendmail  status | grep Active && systemctl is-enabled sendmail
echo " "
echo $LINE
echo  " "
echo "Check all the service status !! " #Press enter to go further once checked."
#read p
echo " "
echo " "
echo " "
echo $LINE
df -hT
echo "cat /etc/fstab"
cat /etc/fstab
echo  " "
echo " "
echo $LINE
echo "1) mount |grep /var/log/nginx"
echo "2) mount |grep /var/www/production/www.justdial.com/Sitemap"
echo "3) mount |grep /var/lib/SQL"
echo "4) mount |grep /var/lib/elasticsearch"
echo "5) mount |grep /var/lib/mongo"
echo  " "
echo "1) "; mount |grep /var/log/nginx
echo "2) ";mount |grep /var/www/production/www.justdial.com/Sitemap
echo "3) ";mount |grep /var/lib/SQL
echo "4) ";mount |grep /var/lib/elasticsearch
echo "5) ";mount |grep /var/lib/mongo
echo " "
echo $LINE
echo "1) cat /etc/logrotate.d/nginx_hourly"
cat /etc/logrotate.d/nginx_hourly | grep  " rotate "
echo  " "
echo $LINE
echo  " "
echo "2) cat /etc/logrotate.d/nginx"
cat /etc/logrotate.d/nginx | grep  " rotate "
echo " "
echo $LINE
echo  " "
echo "3) cat /etc/logrotate.d/php-fpm"
cat /etc/logrotate.d/php-fpm | grep  " rotate "
echo " "
echo $LINE
echo  " "
echo "4) cat /etc/logrotate.d/redis"
cat /etc/logrotate.d/redis | grep  " rotate "
echo " "
echo $LINE
echo  " "
echo "5) cat /etc/logrotate.d/syslog"
cat /etc/logrotate.d/syslog | grep  " rotate "
echo  " "
echo " "
echo "6) cat /etc/logrotate.d/mysql"
cat /etc/logrotate.d/mysql | grep  " rotate "
echo " "
echo "7) cat /etc/logrotate.d/mongo"
cat /etc/logrotate.d/mongo | grep  " rotate "

echo " "
echo "7) cat /etc/logrotate.d/sphinx"
cat /etc/logrotate.d/sphinx | grep  " rotate "
echo $LINE
echo "cat /etc/anacrontab | egrep -i ‘RANDOM_DELAY|START_HOURS_RANGE’"
cat /etc/anacrontab | egrep -i 'RANDOM_DELAY|START_HOURS_RANGE'
echo  " "
echo " "
echo $LINE
echo "cat /etc/sysctl.conf |grep -v '^#'|grep -v '^$'"
cat /etc/sysctl.conf |grep -v '^#'|grep -v '^$'
echo  " "
echo " "
echo $LINE
echo "All necessary application checks are available (Nginx/php-fpm/redis)"
echo  " "
echo " "
echo $LINE
echo "cat /proc/net/bonding/bond0  |egrep 'Slave Interface|Speed'"
cat /proc/net/bonding/bond0  |egrep 'Slave Interface|Speed'
echo  " "
echo " "
echo $LINE
echo "cat /etc/multipath.conf"
multipath -ll >> /tmp/multipathfile 
cp -pr /etc/multipath.conf /etc/multipath.conf_inplace
cat /etc/multipath.conf | egrep 'IBM|DGC|HUAWEI'
ssh $SSH_ARGS web_backup@192.168.12.101 "sudo scp $SSH_ARGS /etc/multipath.conf web_backup@$IPADDR:"
mv /home/web_backup/multipath.conf /etc/multipath.conf
service multipathd restart
sleep 3
echo  " "
echo " "
echo $LINE
echo "systemctl list-unit-files redis.service php-fpm.service nginx.service mysqld.service elasticsearch.service mongod.service"
systemctl list-unit-files redis.service php-fpm.service nginx.service mysqld.service elasticsearch.service mongod.service
echo  " "

echo " "
echo $LINE
echo "cat /etc/sysctl.conf"
cat /etc/sysctl.conf
echo  " "
echo " "
echo $LINE
echo "sudo cat /etc/sudoers | grep mumbainoc"
sudo cat /etc/sudoers | grep mumbainoc
echo  " "
echo " "
echo $LINE
echo " "
echo $LINE


