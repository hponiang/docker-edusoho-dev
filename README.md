# 一键生成EduSoho开发测试环境

## 基本说明

* 本镜像仅供edusoho开发人员使用.
* 最佳实践是每个容器只跑一个edusoho程序.
* debian/ubuntu上已经测试.

## 重要提示

容器正常运行后最好不要进入容器内部去操作，比如查询mysql数据、npm编译等.
所以开启docker的ssh服务仅供参考，实践中不要用ssh登录进docker，操作都在物理机上做.

<!-- ## 使用方法

### 先看几行Dockerfile中的注释

```
# 想要用php53开启这行
# FROM ubuntu:12.04.5

# 想要用php55开启这行
# FROM ubuntu:14.04.5
``` -->

### 前期准备：在物理机上安装docker
```
Ubuntu: https://docs.docker.com/engine/installation/linux/ubuntulinux/
Mac: https://docs.docker.com/engine/installation/mac/ (请下载docker.dmg包，不要下载toolbox版本)
Windows: https://docs.docker.com/engine/installation/windows/
```

<!-- 
### 前期准备：在物理机上安装nginx
```
Ubuntu: apt-get install nginx
Mac: brew install nginx
``` -->

>在物理机上安装nginx是为了多个docker容器能共享物理机80端口

### 初次使用请先编译镜像

```bash
#若由于网络不给力，请自行配合docker加速器
docker build -t edusoho/edusoho-dev:5.3 .
```
<!-- 
### ubuntu用户，至此可以借助脚本直接运行新容器了

```bash
mv docker-create-edusoho-dev.sh /usr/bin/
chmod +x /usr/bin/docker-create-edusoho-dev.sh
docker-create-edusoho-dev.sh

输入域名
输入php版本，默认5.3
```
>以后每次需要新建一个开发测试站，只要运行docker-create-edusoho-dev.sh
即可 -->

### 容器内管理php/mysql/php-fpm

```bash
supervisorctl restart nginx
supervisorctl restart mysql
supervisorctl restart php5-fpm
#mysql root密码默认为空
mysql
```

### 从物理机连接到docker的mysql

```bash
mysql -h ld.dev -uroot
#其中 ld.dev.local 表示进t5的docker，在域名后面加上 .local 即可
#账号默认是 root，密码 空
#注意：这是用docker-create-edusoho-dev.sh脚本生成的
```

```yml
#项目中数据库连接配置示例
parameters:
    database_driver: pdo_mysql
    database_host: ld.dev.local
    database_port: 3306
    database_name: edusoho-dev
    database_user: root
    database_password:
```

## 手动配置说明

### 先创建一个网络，以便固定住容器的ip

```bash
docker network create --gateway 172.20.0.1 --subnet 172.20.0.0/16 esdev
docker network inspect esdev
```

参数说明

* `--gateway 172.20.0.1`: 为新网络指定一个网关地址
* `--subnet 172.20.0.0/16`: 设置子网掩码
* `esdev`: 新网络的名称

> ***注意: 网络一般常见一次就够了，多个容器都挂到这个网络下即可***

### 运行新容器

```bash
mkdir -p /var/www/ld.dev && \
mkdir -p /var/mysql/ld.dev && \
rm -rf /var/mysql/ld.dev/* && \
docker run --name ld.dev -tid \
        -v /var/mysql/ld.dev:/var/lib/mysql \
        -v /var/www/ld.dev:/var/www/edusoho \
        --network esdev \
        --ip 172.20.0.2 \
        -e DOMAIN="ld.dev" \
        -e IP="172.20.0.2" \
        edu

```

```bash
docker run --name ld.dev -tid -v /Users/apple/Desktop/wwwroot/dockerroot/mysql:/var/lib/mysql -v /Users/apple/Desktop/wwwroot/dockerroot/html:/var/www/edusoho --memory 2048m --network esdev         --ip 172.20.0.2 -e DOMAIN="ld.dev"         -e IP="172.20.0.2" edu
```


参数说明

* `-v /var/mysql/ld.dev:/var/lib/mysql`: 把一个本机目录映射到容器中的mysql数据目录，以便保证数据库数据不会丢失
* `-v /var/www/ld.dev:/var/www/edusoho`: 映射代码目录，以便在本机用sublime做开发，文件是软连接形式映射
* `--name ld.dev`: 指定域名为容器的名字，便于管理
* `--network esdev`: 指定在前一步你创建好的网络名称
* `--ip 172.20.0.2`: 为新容器分配一个固定IP，以便在本机做80端口转发
* `-e DOMAIN="ld.dev"`: 指定域名
* `-e IP="172.20.0.2"`: 再次指定一下新容器的IP

### 在物理机的nginx里添加一个vhost

```
server {
     listen 80;
     server_name ld.dev;
     access_log off;
     location /
     {
          proxy_set_header Host $host;
          proxy_set_header X-Real-Ip $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_buffer_size 128k;
          proxy_buffers 32 32k;
          proxy_busy_buffers_size 128k;
          proxy_pass http://172.20.0.2:80/;
     }
}
```

>坑：Windows和Mac下，无法用物理机ping通172.20.0.2，解决办法：
>在docker run的时候添加一个 -p 18080:80，然后nginx的proxy_pass改成http://127.0.0.1:18080/

## 测试

```
访问 http://ld.dev 一切正常的话会显示"File not found"，接下来只要在物理机的/var/www/ld.dev目录部署代码即可
```