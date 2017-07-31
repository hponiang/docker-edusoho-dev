FROM 1and1internet/ubuntu-16-nginx-php-phpmyadmin:latest
MAINTAINER James Eckersall <james.eckersall@1and1.co.uk>
ARG DEBIAN_FRONTEND=noninteractive

COPY files/ /

COPY ubuntu/16.4-sources.list /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

RUN \
  groupadd mysql && \
  useradd -g mysql mysql && \
  apt-get update && \
  apt-get install -y gettext-base mariadb-server && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/lib/mysql && \
  mkdir --mode=0777 /var/lib/mysql /var/run/mysqld && \
  chown mysql:mysql /var/lib/mysql && \
#  sed -r -i -e 's/^bind-address\s+=\s+127\.0\.0\.1$/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
#  sed -r -i -e 's/^user\s+=\s+mysql$/#user = mysql/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
#  sed -i -r -e 's/^#general_log_file\s+=.*/general_log_file=\/var\/log\/mysql\/mysql.log/g' /etc/mysql/mariadb.conf.d/50-server.cnf && \
#  sed -i -r -e '/^query_cache/d' /etc/mysql/mariadb.conf.d/50-server.cnf && \
  printf '[mysqld]\nskip-name-resolve\n' > /etc/mysql/conf.d/skip-name-resolve.cnf && \
  chmod 777 /docker-entrypoint-initdb.d && \
  chmod 0777 -R /var/lib/mysql /var/log/mysql && \
  chmod 0775 -R /etc/mysql && \
  chmod 0755 /hooks/entrypoint-pre.d/50_phpmyadmin_setup /hooks/supervisord-pre.d/51_mariadb_setup && \
  chmod 0755 -R /hooks

ENV MYSQL_ROOT_PASSWORD='root' \
    DISABLE_PHPMYADMIN=0 \
    PMA_ARBITRARY=0 \
    PMA_HOST=localhost \
    MYSQL_GENERAL_LOG=0 \
    MYSQL_QUERY_CACHE_TYPE=1 \
    MYSQL_QUERY_CACHE_SIZE=16M \
    MYSQL_QUERY_CACHE_LIMIT=1M

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y nodejs \
    && ln -s /usr/bin/nodejs /usr/bin/node \
    && apt-get install -y npm \
    && npm config set registry https://registry.npm.taobao.org 

RUN  DEBIAN_FRONTEND=noninteractive \
     && npm install -g yarn \
     && yarn config set registry https://registry.npm.taobao.org \
     && apt-get install php-xdebug \
     && mkdir -p /var/www/edusoho \
     && rm /etc/nginx/sites-enabled/default \
     && cp nginx/ld.conf /etc/nginx/sites-enabled/ \
     && cp ./php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

EXPOSE 3306 8080


# FROM 1and1internet/ubuntu-16:latest
# MAINTAINER qudg@Ilingdai.com
# ARG DEBIAN_FRONTEND=noninteractive

# #init
# #COPY ubuntu/12.04-sources.list /etc/apt/sources.list


# #nginx

# RUN DEBIAN_FRONTEND=noninteractive \
#     && apt-get install --assume-yes apt-utils \
#     && apt-get update -y \
#     && apt-get autoremove -y \
#     && apt-get autoclean -y \
#     && apt-get dist-upgrade -y \
#     && apt-get upgrade -y \
#     && apt-get install -y nginx \
#     # && lineNum=`sed -n -e '/sendfile/=' /etc/nginx/nginx.conf`; sed -i $((lineNum+1))'i client_max_body_size 1024M;' /etc/nginx/nginx.conf \
#     # && sed -i '1i daemon off;' /etc/nginx/nginx.conf \
#     && mkdir -p /var/www/edusoho \
#     && rm /etc/nginx/sites-enabled/default

# COPY nginx/ld.conf /etc/nginx/sites-enabled/


# #php  mysql 
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php7.0-fpm php7.0-mysql php-dom 


# RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
#     echo 'deb http://mirrors.syringanetworks.net/mariadb/repo/5.5/ubuntu trusty main' >> /etc/apt/sources.list && \
#     echo 'deb-src http://mirrors.syringanetworks.net/mariadb/repo/5.5/ubuntu trusty main' >> /etc/apt/sources.list && \
#     apt-get update && \
#     apt-get install -y mariadb-server pwgen && \
#     rm -rf /var/lib/mysql/* && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# #change bind address to 0.0.0.0
# RUN sed -i -r 's/bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

# ADD /mysql/create_mariadb_admin_user.sh /create_mariadb_admin_user.sh
# ADD run.sh /run.sh
# RUN chmod 775 /*.sh


# RUN DEBIAN_FRONTEND=noninteractive apt-get update \
#     && apt-get install -y nodejs \
#     && ln -s /usr/bin/nodejs /usr/bin/node \
#     && apt-get install -y npm \
#     && npm config set registry https://registry.npm.taobao.org 



# RUN  DEBIAN_FRONTEND=noninteractive \
#      && npm install -g yarn \
#      && yarn config set registry https://registry.npm.taobao.org \
#      && apt-get install php-xdebug 

# COPY ./php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini
   

# # #php
# # RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php5 php5-cli php5-curl php5-fpm php5-intl php5-mcrypt php5-mysqlnd php5-gd \
# #     && sed -i "s/;*post_max_size\s*=\s*\w*/post_max_size = ${PHP_MAX_POST}/g" /etc/php5/fpm/php.ini \
# #     && sed -i "s/;*memory_limit\s*=\s*\w*/memory_limit = ${PHP_MEMORY_LIMIT}/g" /etc/php5/fpm/php.ini \
# #     && sed -i "s/;*upload_max_filesize\s*=\s*\w*/upload_max_filesize = ${PHP_MAX_UPLOAD}/g" /etc/php5/fpm/php.ini \
# #     && sed -i "s/;*display_errors\s*=\s*\w*/display_errors = On/g" /etc/php5/fpm/php.ini \
# #     && sed -i "s/;*daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf \
# #     && sed -i "s/;*listen.owner\s*=\s*www-data/listen.owner = www-data/g" /etc/php5/fpm/pool.d/www.conf \
# #     && sed -i "s/;*listen.group\s*=\s*www-data/listen.group = www-data/g" /etc/php5/fpm/pool.d/www.conf \
# #     && sed -i "s/;*listen.mode\s*=\s*0660/listen.mode = 0660/g" /etc/php5/fpm/pool.d/www.conf \
# #     && sed -i "s/;*listen\s*=\s*\w*/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf

# # #mysql
# # RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
# # RUN sed -i "s/;*max_allowed_packet\s*=\s*\w*/max_allowed_packet = 1024M/g" /etc/mysql/my.cnf

# # #utils
# # RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor \
# #     && apt-get -y autoremove \
# #     && apt-get clean \
# #     &&  usermod -d /var/lib/mysql/ mysql
    
# # COPY supervisor/ld.conf /etc/supervisor/conf.d

# COPY run.sh /usr/bin/run.sh
# RUN  chmod +x /usr/bin/run.sh 
    

# VOLUME ["/var/www/edusoho","/var/lib/mysql"]

# EXPOSE 80 3306
# # CMD ["entrypoint.sh"]