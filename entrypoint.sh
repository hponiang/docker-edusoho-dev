#!/bin/bash

#set -eo pipefail

#check required env vars
if [ -z "$DOMAIN" ] || [ -z "$IP" ]; then
    echo >&2 'required option: -e DOMAIN="your_domain" -e IP="your_container_ip"'
    exit 1
fi

init_nginx(){
    #mofidy domain for nginx vhost
    sed -i "s/{{DOMAIN}}/${DOMAIN}/g" /etc/nginx/sites-enabled/edusoho.conf
}

init_mysql(){
    
    local socket='/var/run/mysqld/mysqld.sock'
  
    #init datadir if mount dir outside to /var/lib/mysql
    sed -i "s/user\s*=\s*debian-sys-maint/user = root/g" /etc/mysql/debian.cnf
    sed -i "s/password\s*=\s*\w*/password = /g" /etc/mysql/debian.cnf
    sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
    sed -i "s/#*socket\s*=\s*\w*/socket = ${socket}/g" /etc/mysql/my.cnf
    
    echo 'Initializing database'
    mysql_install_db
    echo 'Database initialized'
    
    mysqld --skip-networking --socket="${socket}" &
    pid="$!"

    echo "pid: ${pid}"

    mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${socket}" )

    for i in {30..0}; do
      	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
      		  break
      	fi
      	echo 'MySQL init process in progress...'
      	sleep 1
    done
    
    if [ "$i" = 0 ]; then
      	echo >&2 'MySQL init process failed.'
      	exit 1
    fi
    
    if [ "$MYSQL_DATABASE" ]; then
      	echo "Database ${MYSQL_DATABASE} creating..."
      	echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
    fi

    "${mysql[@]}" <<-EOSQL
      	CREATE USER 'root'@'%';
      	GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
      	FLUSH PRIVILEGES ;
EOSQL

    if ! kill -s TERM "$pid" || ! wait "$pid"; then
      	echo >&2 'MySQL init process failed.'
      	exit 1
    fi

    echo 'MySQL init process done.'
}

disable_commands(){
    #disable some commands to avoid docker container deaded after execute these commands
    bad_commands=(
        '/etc/init.d/mysql'
        '/etc/init.d/php5-fpm'
        '/etc/init.d/nginx'
        '/usr/bin/mysql'
    )
    for command in ${bad_commands[@]};
    do  
        if [ -f "$command" ]; then
            echo "mv ${command}..."
            mv $command ${command%/*}/_${command##*/}
        fi
    done
}

hasInitd=
if [ -f "/.entrypoint-initd.lock" ]; then
    hasInitd=true
else
    hasInitd=false
fi

if [ ! $hasInitd ]; then
    touch /.entrypoint-initd.lock
    
    #add host
    echo "${IP} ${DOMAIN}.local" >> /etc/hosts
    
    init_nginx
    init_mysql
    disable_commands
    
    #start services
    echo '*******************************'
    echo '* welcome to develop edusoho! *'
    echo '* ---- www.edusoho.com ------ *'
    echo '*******************************'

    echo 'starting...'
    supervisord -n
else
    bash
fi

