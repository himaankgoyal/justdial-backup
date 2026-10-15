#!/bin/bash
LDAPUSER="himaankg-10122969"
LDAPPASS="Ju\$td!@lg0y@l@987"
SHELLUSER="urvesh"
SHELLPASS="ju5tD1@lcr0mA"

if [ $# -ne 2 ];then
	echo "Please pass the ARG 1 and 2 for Loging on 192.168.12.101, e.g sh $0 12 101"
	exit 1
fi

case $1 in 
	1|6|7|11|12|13|14|15|16|17|22|23|24|25|26|27|28|29|31|32|35|37|38|39|40|41|42|43|44|45|46|47|48|51|56|151)
	echo "Logging on 192.168.$1.$2"
	
	sshpass -p "$LDAPPASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no PubkeyAcceptedKeyTypes=ssh-rsa -o UserKnownHostsFile=/dev/null -q ${LDAPUSER}@192.168.$1.$2
#	echo "client_loop: send disconnect: Broken pipe ERROR: $?";
	if [ "$?" == "5" ]
	then
	        sshpass -p "$SHELLPASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -q ${SHELLUSER}@192.168.$1.$2
	fi
	;;
	
	0|8|64|66|67|80|81|86)
		sshpass -p "$SHELLPASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -q ${SHELLUSER}@172.29.$1.$2 ;;
	
esac

