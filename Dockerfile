FROM ubuntu:12.04.5
# FROM daocloud.io/library/ubuntu:12.04.5
# FROM daocloud.io/library/ubuntu:14.04.5

MAINTAINER Simon Wood <wuqian@howzhi.com>

ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    1024M
ENV PHP_MAX_UPLOAD      1024M
ENV PHP_MAX_POST        1024M

#init
COPY ubuntu/12.04-sources.list /etc/apt/sources.list
#COPY ubuntu/14.04-sources.list /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

#nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
RUN lineNum=`sed -n -e '/sendfile/=' /etc/nginx/nginx.conf`; sed -i $((lineNum+1))'i client_max_body_size 1024M;' /etc/nginx/nginx.conf
RUN sed -i '1i daemon off;' /etc/nginx/nginx.conf
COPY nginx/edusoho.conf /etc/nginx/sites-enabled

#php
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php5 php5-cli php5-curl php5-fpm php5-intl php5-mcrypt php5-mysqlnd php5-gd
RUN sed -i "s/;*post_max_size\s*=\s*\w*/post_max_size = ${PHP_MAX_POST}/g" /etc/php5/fpm/php.ini
RUN sed -i "s/;*memory_limit\s*=\s*\w*/memory_limit = ${PHP_MEMORY_LIMIT}/g" /etc/php5/fpm/php.ini
RUN sed -i "s/;*upload_max_filesize\s*=\s*\w*/upload_max_filesize = ${PHP_MAX_UPLOAD}/g" /etc/php5/fpm/php.ini
RUN sed -i "s/;*display_errors\s*=\s*\w*/display_errors = On/g" /etc/php5/fpm/php.ini

#fpm
RUN sed -i "s/;*daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;*listen.owner\s*=\s*www-data/listen.owner = www-data/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i "s/;*listen.group\s*=\s*www-data/listen.group = www-data/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i "s/;*listen.mode\s*=\s*0660/listen.mode = 0660/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i "s/;*listen\s*=\s*\w*/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf

#mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
RUN sed -i "s/;*max_allowed_packet\s*=\s*\w*/max_allowed_packet = 1024M/g" /etc/mysql/my.cnf

#utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
RUN sed -i "s/;*PermitRootLogin\s*without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y sudo
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y iptables
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y lsof
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y xz-utils
RUN curl -o ~/.git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
RUN sed -i '$a source ~/.git-completion.bash' /etc/profile

#nodejs
RUN curl -O https://mirrors.ustc.edu.cn/node/v6.9.2/node-v6.9.2-linux-x64.tar.xz
RUN xz -d node-v6.9.2-linux-x64.tar.xz
RUN tar xvf node-v6.9.2-linux-x64.tar
RUN rm -rf node-v6.9.2-linux-x64.tar
RUN mv node-v6.9.2-linux-x64 /usr/local/node
RUN ln -s /usr/local/node/bin/node /usr/bin/
RUN ln -s /usr/local/node/bin/npm /usr/bin/

#supervisor
RUN apt-get install -y supervisor
COPY supervisor/edusoho.conf /etc/supervisor/conf.d

RUN mkdir -p /var/www/edusoho

RUN apt-get -y autoremove
RUN apt-get clean

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 80
CMD ["entrypoint.sh"]