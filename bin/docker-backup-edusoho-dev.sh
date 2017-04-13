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
    echo >&2 "Error: docker container named ${DOMAIN} does not exist"
    exit 1
fi

mysql_dir=/var/mysql/${DOMAIN}
www_dir=/var/www/${DOMAIN}
if [[ ! -d "$mysql_dir" || ! -d "$www_dir" ]]; then
    echo >&2 "Error: ${mysql_dir} or ${www_dir} does not exist. Please check if the docker container was runned by docker-create-edusoho-dev.sh"
    exit 1
fi

is_container_running=`docker ps |grep ${DOMAIN}`

if [ -n "$is_container_running" ]; then
    echo "stopping ${DOMAIN}"
    docker stop ${DOMAIN}
fi

echo 'backup in progress...'
date_suffix=`_date +%Y%m%d%H%I%M`

cp -R ${mysql_dir} ${mysql_dir}_autobackup${date_suffix}
ln -s ${mysql_dir}_autobackup${date_suffix} ${mysql_dir}_autobackup_last

cp -R ${www_dir} ${www_dir}_autobackup${date_suffix}
ln -s ${www_dir}_autobackup${date_suffix} ${www_dir}_autobackup_last

echo 'backup finished'

echo "starting ${DOMAIN}"
docker start ${DOMAIN}