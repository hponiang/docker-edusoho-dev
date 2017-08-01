#!/bin/bash
set -e

# chown -R mysql:mysql /var/lib/mysql
# mysql_install_db --user=mysql --basedir=/var/mysql/ --datadir=/var/lib/mysql/ > /dev/null

# MYSQL_ROOT_PASSWORD="root"
# MYSQL_DATABASE="edu"
# MYSQL_USER="root"
# MYSQL_PASSWORD="root"

# tfile=`mktemp`
# if [[ ! -f "$tfile" ]]; then
#     return 1
# fi

# cat << EOF > $tfile
# USE mysql;
# FLUSH PRIVILEGES;
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
# UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
# EOF

# if [[ $MYSQL_DATABASE != "" ]]; then
#     echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

#     if [[ $MYSQL_USER != "" ]]; then
#         echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
#     fi
# fi

# /usr/sbin/mysqld --bootstrap --verbose=0 < $tfile
# rm -f $tfile

# exec /usr/sbin/mysqld

    
cd /var/www/edusoho/
usermod -d /var/lib/mysql/ mysql
# service php7.0-fpm start
# service nginx start
# service mysql start
#yarn
#npm run dev
echo '*******************************'
echo '* welcome to develop lder! *'
echo '*******************************'