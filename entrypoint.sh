#!/bin/bash

#set -eo pipefail

#check required env vars
if [ -z "$DOMAIN" ] || [ -z "$IP" ]; then
    echo >&2 'required option: -e DOMAIN="your_domain" -e IP="your_container_id"'
    exit 1
fi

hasInitd=
if [ -f "/entrypoint-initd.lock" ]; then
    hasInitd=true
else
    hasInitd=false
fi

if [ !hasInitd ]; then
    touch /entrypoint-initd.lock

    #mofidy domain for nginx vhost
    sed -i "s/{{DOMAIN}}/${DOMAIN}/g" /etc/nginx/sites-enabled/edusoho.conf
    sed -i "s/{{IP}}/${IP}/g" /etc/nginx/sites-enabled/edusoho.conf

    #init datadir if mount dir outside to /var/lib/mysql
    sed -i "s/user\s*=\s*debian-sys-maint/user = root/g" /etc/mysql/debian.cnf
    sed -i "s/password\s*=\s*\w*/password = /g" /etc/mysql/debian.cnf
    mysql_install_db

    #start services
    echo '*******************************'
    echo '* welcome to develop edusoho! *'
    echo '* ---- www.edusoho.com ------ *'
    echo '*******************************'

    echo 'starting...'
    supervisord
else
    bash
fi

