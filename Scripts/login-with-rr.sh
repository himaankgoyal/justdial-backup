SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q'
case $1 in 
0|8|26|32|50|56|64|67|86|87|84) sshpass -p 'ju5tD1@lcr0mA' ssh ${SSH_ARGS} rajveer@172.29.$1.$2
;;
1|6|7|11|12|13|14|15|17|51|22|23|24|25|29|31|37|38|35|39|40|41|42|44|16) sshpass -p 'ju5tD1@lcr0mA' ssh ${SSH_ARGS}  rajveer@192.168.$1.$2
;;
176)sshpass -p 'ju5tD1@lcr0mA' ssh ${SSH_ARGS} rajveer@10.72.$1.$2
;;
10|11)sshpass -p 'ju5tD1@lcr0mA' ssh ${SSH_ARGS} rajveer@10.32.$1.$2
;;
20)sshpass -p 'ju5tD1@lcr0mA' ssh ${SSH_ARGS} rajveer@172.16.$1.$2
;;
esac
