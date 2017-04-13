#!/bin/bash

for i in `docker ps -a |awk '$0 ~ /edusoho-dev/ {print $1}'`; do docker start $i;done;