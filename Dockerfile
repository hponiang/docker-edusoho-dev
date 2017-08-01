FROM ubuntu:14.04
MAINTAINER qudg@Ilingdai.com
ARG DEBIAN_FRONTEND=noninteractive

#init
COPY ubuntu/16.4-sources.list /etc/apt/sources.list

#nginx
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install --assume-yes apt-utils \
    && apt-get install -y nginx \
    && mkdir -p /var/www/edusoho \
    && rm /etc/nginx/sites-enabled/default

COPY nginx/ld.conf /etc/nginx/sites-enabled/


#php   
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php7.0-fpm php-dom \
    && apt-get install php-xdebug
COPY ./php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

#mysql
RUN apt-get install -y mysql-server
ADD mysql/my.cnf /etc/mysql/conf.d/my.cnf 

# #npm yarn
# RUN DEBIAN_FRONTEND=noninteractive apt-get update \
#     && apt-get install -y nodejs \
#     && ln -s /usr/bin/nodejs /usr/bin/node \
#     && apt-get install -y npm \
#     && npm config set registry https://registry.npm.taobao.org \
#     && npm install -g yarn \
#     && yarn config set registry https://registry.npm.taobao.org 

COPY run.sh /usr/bin/run.sh
RUN  chmod +x /usr/bin/run.sh 


VOLUME ["/var/lib/mysql","/var/www/edusoho"]
EXPOSE 80 3306

# CMD ["mysqld"]