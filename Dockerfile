FROM ubuntu:12.04.5
# FROM daocloud.io/library/ubuntu:12.04.5
# FROM daocloud.io/library/ubuntu:14.04.5

MAINTAINER Simon Wood <wuqian@howzhi.com>

ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    1024M
ENV PHP_MAX_UPLOAD      1024M
ENV PHP_MAX_POST        1024M

#init
#COPY ubuntu/12.04-sources.list /etc/apt/sources.list
#COPY ubuntu/14.04-sources.list /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo "Asia/Shanghai" > /etc/timezone

#nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx \
    && lineNum=`sed -n -e '/sendfile/=' /etc/nginx/nginx.conf`; sed -i $((lineNum+1))'i client_max_body_size 1024M;' /etc/nginx/nginx.conf \
    && sed -i '1i daemon off;' /etc/nginx/nginx.conf \
    && mkdir -p /var/www/edusoho
COPY nginx/edusoho.conf /etc/nginx/sites-enabled

#php
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php5 php5-cli php5-curl php5-fpm php5-intl php5-mcrypt php5-mysqlnd php5-gd \
    && sed -i "s/;*post_max_size\s*=\s*\w*/post_max_size = ${PHP_MAX_POST}/g" /etc/php5/fpm/php.ini \
    && sed -i "s/;*memory_limit\s*=\s*\w*/memory_limit = ${PHP_MEMORY_LIMIT}/g" /etc/php5/fpm/php.ini \
    && sed -i "s/;*upload_max_filesize\s*=\s*\w*/upload_max_filesize = ${PHP_MAX_UPLOAD}/g" /etc/php5/fpm/php.ini \
    && sed -i "s/;*display_errors\s*=\s*\w*/display_errors = On/g" /etc/php5/fpm/php.ini \
    && sed -i "s/;*daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf \
    && sed -i "s/;*listen.owner\s*=\s*www-data/listen.owner = www-data/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/;*listen.group\s*=\s*www-data/listen.group = www-data/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/;*listen.mode\s*=\s*0660/listen.mode = 0660/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/;*listen\s*=\s*\w*/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf

#mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
RUN sed -i "s/;*max_allowed_packet\s*=\s*\w*/max_allowed_packet = 1024M/g" /etc/mysql/my.cnf

#utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor \
    && apt-get -y autoremove \
    && apt-get clean
    
COPY supervisor/edusoho.conf /etc/supervisor/conf.d

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 80
CMD ["entrypoint.sh"]