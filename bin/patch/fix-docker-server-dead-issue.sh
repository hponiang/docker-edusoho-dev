#!/bin/bash

# 在docker容器正常运行时，禁止去里面操作
# 
# 一定要进入patch目录后再执行该脚本，否则报attach/fix-dead.sh找不到
#
# 20170413更新的edusoho-dev版本已经不需要执行该脚本了

for i in `docker ps -a |awk '$0 ~ /edusoho-dev/ {print $1}'`

  do
  echo $i
  echo 'handling cp shell'
  docker cp attach/fix-dead.sh $i:/
  docker exec $i chmod +x /fix-dead.sh
  echo 'handling fix'
  docker exec $i /fix-dead.sh

done