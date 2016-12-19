## 一键生成EduSoho本地开发及线上测试环境

#### 说明

* 本镜像仅供edusoho开发人员使用.
* 最佳实践是每个容器只跑一个edusoho程序.
* debian/ubuntu上已经测试.


#### 使用方法

##### 先看几行Dockerfile中的注释

```
#大概位于前两行
# 本地编译先注释掉第一行，不然下载很慢
FROM ubuntu:12.04.5

# 想要用php53开启这行
# FROM daocloud.io/library/ubuntu:12.04.5

# 想要用php56开启这行
# FROM daocloud.io/library/ubuntu:14.04.5
```

```
#大概位于十来行

# 想要用php53再开启这行
#COPY ubuntu/12.04-sources.list /etc/apt/sources.list

# 想要用php56再开启这行
#COPY ubuntu/14.04-sources.list /etc/apt/sources.list
```

##### 前期准备：在物理机上安装docker
```
Ubuntu: https://docs.docker.com/engine/installation/linux/ubuntulinux/
Mac: https://docs.docker.com/engine/installation/mac/
Windows: https://docs.docker.com/engine/installation/windows/
```

##### 前期准备：在物理机上安装nginx
```
Ubuntu: apt-get install nginx
Mac: brew install nginx
Windows: 请自行解决
```

>在物理机上安装nginx是为了多个docker容器能共享物理机80端口

##### 初次使用请先编译镜像

```
docker build -t edusoho/edusoho-dev .
```

```
#也可以从docker官方仓库下载，由于官方的网络连接太慢，不推荐此方式
#官方hub只有php53
#docker pull edusoho/edusoho-dev
```

##### ubuntu用户，至此可以借助脚本直接运行新容器了

```shell
mv docker-create-edusoho-dev.sh /usr/bin/
chmod +x /usr/bin/docker-create-edusoho-dev.sh
docker-create-edusoho-dev.sh
```

>以后每次需要新建一个开发测试站，只要运行docker-create-edusoho-dev.sh
即可

===============手动配置说明===============

##### windows用户，需要手动启动新容器，当然也适用于ubuntu用户想折腾一下的

##### 先创建一个网络，以便固定住容器的ip

```shell
docker network create --gateway 172.20.0.1 --subnet 172.20.0.0/16 esdev
docker network inspect esdev
```

参数说明

* `--gateway 172.20.0.1`: 为新网络指定一个网关地址
* `--subnet 172.20.0.0/16`: 设置子网掩码
* `esdev`: 新网络的名称

> ***!!注意: 网络一般常见一次就够了，多个容器都挂到这个网络下即可***

##### 运行新容器

```shell
mkdir -p /var/mysql/t5.edusoho.cn && \
rm -rf /var/mysql/t5.edusoho.cn/* && \
docker run --name t5.edusoho.cn -tid \
        -v /var/mysql/t5.edusoho.cn:/var/lib/mysql \
        -v /var/www/t5.edusoho.cn:/var/www/edusoho \
        -p 49122:22 \
        --cpuset-cpus 2 \
        --memory 2048m \
        --network esdev \
        --ip 172.20.0.2 \
        -e DOMAIN="t5.edusoho.cn" \
        -e IP="172.20.0.2" \
        edusoho/edusoho-dev
```

参数说明

* `-v /var/mysql/t5.edusoho.cn:/var/lib/mysql`: 把一个本机目录映射到容器中的mysql数据目录，以便保证数据库数据不会丢失
* `-v /var/www/t5.edusoho.cn:/var/www/edusoho`: 映射代码目录，以便在本机用sublime做开发，文件是软连接形式映射
* `-p 49122:22`: 配置一个ssh远程登录端口，测试服务器上可以用，本地开发可以不用
* `--name t5.edusoho.cn`: 指定域名为容器的名字，便于管理
* `--network esdev`: 指定在前一步你创建好的网络名称
* `--ip 172.20.0.2`: 为新容器分配一个固定IP，以便在本机做80端口转发
* `-e DOMAIN="t5.edusoho.cn"`: 指定域名
* `-e IP="172.20.0.2"`: 再次指定一下新容器的IP

##### 在物理机的nginx里添加一个vhost

```
server {
     listen 80;
     server_name t5.edusoho.cn;
     access_log off;
     location /
     {
          proxy_set_header Host $host;
          proxy_set_header X-Real-Ip $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_pass http://172.20.0.2:80/;
     }
}
```

>坑：Windows和Mac下，无法用物理机ping通172.20.0.2，解决办法：
>在docker run的时候添加一个 -p 18080:80，然后nginx的proxy_pass改成http://127.0.0.1:18080/

##### 修改容器中root密码

```shell
docker exec -ti t5.edusoho.cn passwd root
```

##### 尝试远程登录管理

```shell
ssh root@t5.edusoho.cn -p49122
```

```shell
#容器内管理php/mysql/fpm
supervisorctl restart nginx
supervisorctl restart mysql
supervisorctl restart php5-fpm
#mysql root密码默认为空
mysql
```

===============以下是部署edusoho教程===============

##### 下载edusoho源码和配置edusoho

```shell
#download edusoho source code
cd /var/www
git clone https://github.com/edusoho/edusoho.git edusoho
# or
git clone http://gitlab.howzhi.net/edusoho/edusoho.git edusoho

#download vendor
cd edusoho
git submodule init
git submodule update

#configuration
echo 'CREATE DATABASE IF NOT EXISTS `edusoho-dev` DEFAULT CHARACTER SET utf8;' | mysql
cp app/config/parameters.yml.dist app/config/parameters.yml
./bin/phpmig migrate
app/console system:init
chown -R www-data:www-data /var/www/edusoho

#npm develop
cnpm install
npm run dev
```

##### 访问一下

```
visit http://t5.edusoho.cn
```