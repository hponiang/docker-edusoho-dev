###############
# This bash is to run a new edusoho-dev docker container and inject a nginx `proxy_pass` configuration in host's nginx if exists
###############
#!/bin/bash

set -eo pipefail

#read parameters
read -p "input domain:" DOMAIN
read -p "input docker container network name:" NETWORK
read -p "input docker container ip:" IP
read -p "input docker container ssh port:" SSH_PORT

#docker run
mkdir -p /var/mysql/${DOMAIN} && \
rm -rf /var/mysql/${DOMAIN}/* && \
docker run --name ${DOMAIN} -tid \
        -v /var/mysql/${DOMAIN}:/var/lib/mysql \
        -v /var/www/${DOMAIN}:/var/www/edusoho \
        -p ${SSH_PORT}:22 \
        --network ${NETWORK} \
        --ip ${IP} \
        -e DOMAIN="${DOMAIN}" \
        -e IP="${IP}" \
        edusoho/edusoho-dev

#inject nginx config
host='$host'
remote_addr='$remote_addr'

cat > /etc/nginx/sites-enabled/${DOMAIN} <<-EOF 
server {
     listen 80;
     server_name ${DOMAIN};
     access_log off;
     location /
     {
          proxy_set_header Host $host;
          proxy_set_header X-Real-Ip $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_pass http://${IP}:80/;
     }
}
EOF


/etc/init.d/nginx reload