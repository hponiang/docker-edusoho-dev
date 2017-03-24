#!/bin/bash

# 在docker容器正常运行时，禁止去里面操作

for i in `docker ps -a |awk '$0 ~ /edusoho-dev/ {print $1}'`

  do
  docker cp attach/fix-dead.sh $i:/
  docker exec $i chmod +x /fix-dead.sh
  docker exec $i /fix-dead.sh

done