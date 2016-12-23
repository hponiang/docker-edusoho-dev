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
if [ ! -d "$mysql_dir" || ! -d "$www_dir" ]; then
    echo >&2 "Error: ${mysql_dir} or ${www_dir} does not exist. Please check if the docker container was runned by docker-create-edusoho-dev.sh"
    exit 1
fi

mysql_backup=${mysql_dir}_autobackup_latest
www_backup=${www_dir}_autobackup_latest

if [ ! -d "${mysql_backup}" || ! -d "${www_backup}" ]; then
    echo >&2 "Error: backup location in ${mysql_backup} or ${www_backup} does not exist. Please use docker-backup-edusoho-dev.sh to backup first."
    exit 1
fi

is_container_running=`docker ps |grep ${DOMAIN}`

if [ -n "$is_container_running" ]; then
    echo "stopping ${DOMAIN}"
    docker stop ${DOMAIN}
fi

rm -rf ${mysql_dir}
rm -rf ${www_dir}

cp -R ${mysql_dir}_autobackup_latest ${mysql_dir}
cp -R ${www_dir}_autobackup_latest ${www_dir}

echo "starting ${DOMAIN}"
docker start ${DOMAIN}