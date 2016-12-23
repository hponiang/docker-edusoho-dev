###############
# This bash is to backup a edusoho-dev docker container's mysql and www data
#!/bin/bash

read -p "input the docker container domain:" DOMAIN

if [ -z "$DOMAIN" ]; then
    echo >&2 'Error: please input the domain'
    exit 1
fi

is_container_exist=`docker ps -a |grep ${DOMAIN}`
if [ -z "$is_container_exist" ]; then
    echo >&2 "Error: docker container named ${DOMAIN} is not exist"
    exit 1
fi

mysql_dir=/var/mysql/${DOMAIN}
www_dir=/var/www/${DOMAIN}
if [[ ! -d "$mysql_dir" || ! -d "$www_dir" ]]; then
    echo >&2 "Error: ${mysql_dir} or ${www_dir} does not exist. Please check if the docker container was runned by docker-create-edusoho-dev.sh"
    exit 1
fi

if [ -d "${mysql_dir}_autobackup_latest" ]; then
    rm -rf ${mysql_dir}_autobackup_latest
fi
if [ -d "${www_dir}_autobackup_latest" ]; then
    rm -rf ${www_dir}_autobackup_latest
fi

is_container_running=`docker ps |grep ${DOMAIN}`

if [ -n "$is_container_running" ]; then
    echo "stopping ${DOMAIN}"
    docker stop ${DOMAIN}
fi

cp -R ${mysql_dir} ${mysql_dir}_autobackup_latest
cp -R ${www_dir} ${www_dir}_autobackup_latest

cp -R ${mysql_dir} ${mysql_dir}_autobackup_`date +%Y%m%d%H%I%M`
cp -R ${www_dir} ${www_dir}_autobackup_`date +%Y%m%d%H%I%M`

echo "starting ${DOMAIN}"
docker start ${DOMAIN}