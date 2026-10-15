#/bin/bash
arg=$1
echo "checking stake details"
curl http://192.168.13.102:999/api2.php?ip=$1

echo -e "\n\n\n"

echo "checking lb details"
curl http://192.168.13.102:920/lb_module-cli?ip=$1 | grep $1
