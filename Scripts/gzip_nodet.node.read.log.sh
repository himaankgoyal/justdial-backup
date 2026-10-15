#!/bin/bash

step=1
echo"step=$step  Execute find command  on 192.168.13.62"
echo"zipping started for nodet.node.read.log"
sudo find /var/log/container_logs/nginx/tpro_jd002 -type f -name "nodet.node.read.log-" ! -name ".gz" -mtime +1  -exec gzip -fv {} \; 
echo"zipping completed for nodet.node.read.log"





