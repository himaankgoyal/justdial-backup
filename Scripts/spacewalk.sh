#!/bin/bash

centos_reg () {

echo "Registering Spacewalk client using  yum "
       #rpm -Uvh http://yum.spacewalkproject.org/2.5-client/RHEL/7/x86_64/spacewalk-client-repo-2.5-3.el7.noarch.rpm
       rpm -Uvh https://copr-be.cloud.fedoraproject.org/archive/spacewalk/2.5-client/RHEL/7/x86_64/spacewalk-client-repo-2.5-3.el7.noarch.rpm
       sed -i '/^gpgkey/d' /etc/yum.repos.d/spacewalk-client.repo
       sed -i '/^baseurl/d' /etc/yum.repos.d/spacewalk-client.repo
       sed -i '3i baseurl=http://copr-be.cloud.fedoraproject.org/archive/spacewalk/2.5/RHEL/7/$basearch/' /etc/yum.repos.d/spacewalk-client.repo
       sed -i '4i gpgkey=http://copr-be.cloud.fedoraproject.org/archive/spacewalk/RPM-GPG-KEY-spacewalk-2015' /etc/yum.repos.d/spacewalk-client.repo
       echo "Adding epel repo on client"
       sudo yum install -y epel-release

       echo " Installing osad & updating packages "
       yum -y install osad
       service osad start; chkconfig osad on; chkconfig ntpd on; chkconfig autofs on ;

       echo " Installing RHNCFG packages for Configuration Channel Management "
       yum -y install  rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin
       rhn-actions-control --enable-all

echo " Registering with Spacewalk Server "
if [ `grep 172.29.0.249 /etc/hosts | wc -l` = 0 ]; then echo "172.29.0.249  jdspacewalk.jdsat.com  jdspacewalk" >> /etc/hosts; fi
wget -O /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT http://jdspacewalk.jdsat.com/pub/RHN-ORG-TRUSTED-SSL-CERT
sed -i 's/serverURL=.*/serverURL=http:\/\/jdspacewalk.jdsat.com\/XMLRPC/g' /etc/sysconfig/rhn/up2date
sed -i 's/sslCACert=.*/sslCACert=\/usr\/share\/rhn\/RHN-ORG-TRUSTED-SSL-CERT/g' /etc/sysconfig/rhn/up2date
echo "Spacewalk Registration Option. Select from options below ( 1 ) "
echo "1 - Centos 7"
read -p "Your Choice" OS
case $OS in
        1) echo " Registering with Centos 7 Key ";
           #rhnreg_ks --force --activationkey=1-01e2cb6375e00bd3fccaed3f2e6b5f88;;
           rhnreg_ks --force --activationkey=1-4924946f120c07192fae24e370ae0ff2;;

        2) echo " Registering with Centos 7.02 Key ";
           rhnreg_ks --force --activationkey=1-67c114b47195912eed73bc110a0c3010;;

        *) echo "Invalid choice"; exit 1;;
esac
}
centos_reg

