FROM daocloud.io/library/ubuntu:12.04.5

MAINTAINER Simon Wood <wuqian@howzhi.com>

ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    1024M
ENV PHP_MAX_UPLOAD      1024M
ENV PHP_MAX_POST        1024M

#init
#COPY ubuntu/precise-sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y tzdata && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo "${TIMEZONE}" > /etc/timezone

#nginx
RUN apt-get install -y nginx
RUN lineNum=`sed -n -e '/sendfile/=' /etc/nginx/nginx.conf`; sed -i $((lineNum+1))'i client_max_body_size 1024M;' /etc/nginx/nginx.conf
RUN sed -i '1i daemon off;' /etc/nginx/nginx.conf
COPY nginx/edusoho.conf /etc/nginx/sites-enabled

#php
RUN apt-get install -y php5 php5-cli php5-curl php5-fpm php5-intl php5-mcrypt php5-mysqlnd php5-gd
RUN sed -i "s/;*post_max_size\s*=\s*\w*/post_max_size = ${PHP_MAX_POST}/g" /etc/php5/fpm/php.ini
RUN sed -i "s/;*memory_limit\s*=\s*\w*/memory_limit = ${PHP_MEMORY_LIMIT}/g" /etc/php5/fpm/php.ini
RUN sed -i "s/;*upload_max_filesize\s*=\s*\w*/upload_max_filesize = ${PHP_MAX_UPLOAD}/g" /etc/php5/fpm/php.ini

#fpm
RUN sed -i "s/;*listen.owner\s*=\s*www-data/listen.owner = www-data/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i "s/;*listen.group\s*=\s*www-data/listen.group = www-data/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i "s/;*listen.mode\s*=\s*0660/listen.mode = 0660/g" /etc/php5/fpm/pool.d/www.conf

#mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

#utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install openssh-server
RUN apt-get install vim

RUN mkdir -p /var/www

RUN apt-get -y autoremove
RUN apt-get clean

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 80
CMD ["entrypoint.sh"]