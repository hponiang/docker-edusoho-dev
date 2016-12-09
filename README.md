# docker-edusoho-dev
EduSoho Dockerfile Dev

#### Introductions

This is for edusoho developer use.
It's recommend to run one edusoho copy in each edusoho/edusoho-dev docker container.


#### Usage

##### First install docker-engine
```
Ubuntu: https://docs.docker.com/engine/installation/linux/ubuntulinux/
Mac: https://docs.docker.com/engine/installation/mac/
Windows: https://docs.docker.com/engine/installation/windows/
```

##### Step.1 pull the image

```
docker pull edusoho/edusoho-dev
```

##### Step.2 create a network to specify permanent ip for the container

```shell
docker network create --gateway 172.20.0.1 --subnet 172.20.0.0/16 esdev
docker network inspect esdev
```

Paramters

* `--gateway 172.20.0.1`: specify your gateway ip, like `172.21.0.1`
* `--subnet 172.20.0.0/16`: specify your subnet, like `172.21.0.1/16`
* `esdev`: specify your network name

> ***!!notes: the network is reusable, so this step should be only executed once***

##### Step.3 run it

```shell
mkdir -p /var/mysql/t5.edusoho.cn && \
rm -rf /var/mysql/t5.edusoho.cn/* && \
docker run --name t5.edusoho.cn -tid \
        -v /var/mysql/t5.edusoho.cn:/var/lib/mysql \
        -v /var/www/t5.edusoho.cn:/var/www/edusoho \
        -p 49122:22 \
        --network esdev \
        --ip 172.20.0.2 \
        -e DOMAIN="t5.edusoho.cn" \
        -e IP="172.20.0.2" \
        edusoho/edusoho-dev
```

Paramters

* `-v /var/mysql/t5.edusoho.cn:/var/lib/mysql`: map mysql data into a host dir
* `-v /var/www/t5.edusoho.cn:/var/www/edusoho`: map the www dir into host
* `-p 49122:22`: specify a host port for ssh login into the container
* `/var/mysql/t5.edusoho.cn`: specify a dir in host machine to store mysql database data
* `--name t5.edusoho.cn`: specify your container name, usually is your dev domain
* `--network esdev`: specify your network name, created above
* `--ip 172.20.0.2`: specify your container ip
* `-e DOMAIN="t5.edusoho.cn"`: specify your dev domain
* `-e IP="172.20.0.2"`: specify your container ip again

##### Step.4 add a vhost to nginx in host

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

Step.5 how to login ssh

```shell
ssh root@t5.edusoho.cn -p49122
```

Step.6 download edusoho source code and init

```shell
#download edusoho source code
cd /var/www
git clone https://github.com/edusoho/edusoho.git edusoho
# or
git clone http://gitlab.howzhi.net/edusoho/edusoho.git edusoho

#download vendor
git submodule init
git submodule update

#configuration
echo 'CREATE DATABASE IF NOT EXISTS `edusoho-dev` DEFAULT CHARACTER SET utf8;' | mysql
cp app/config/parameters.yml.dist app/config/parameters.yml
./bin/phpmig migrate
app/console system:init
chown -R www-data:www-data edusoho/
```

##### Step.7 how to visit

```
visit http://t5.edusoho.cn
```

#### How to manage automatically

```shell
wget https://raw.githubusercontent.com/starshiptroopers/docker-edusoho-dev/develop/docker-create-edusoho-dev.sh
mv docker-create-edusoho-dev.sh /usr/bin/
chmod +x /usr/bin/docker-create-edusoho-dev.sh
```

```shell
docker-create-edusoho-dev.sh
```

#### How to build from github source

Respo: https://github.com/starshiptroopers/docker-edusoho-dev