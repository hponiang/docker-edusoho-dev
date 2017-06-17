#!/bin/bash

set -e

#input parameters
read -p "input domain:" DOMAIN

if [ -z "$DOMAIN" ]; then
    echo >&2 'Error: please input main domain'
    exit 1
fi

read -p "input another domain (optional):" DOMAIN2

#validate nginx
NGINX_SITE_ENABLE_DIR='/etc/nginx/sites-enabled'
if [ ! -d "$NGINX_SITE_ENABLE_DIR" ]; then  
    echo >&2 "Error: $NGINX_SITE_ENABLE_DIR does not exsit, please check if the host has nginx installed or you can change the dir in this source code"
    exit 1
fi

service nginx status
if [ $? -ne 0 ]; then
    echo >&2 'Error: service nginx status execute error, please check if the host has nginx installed' 
    exit 1
fi

#init
WORK_DIR='/var/www/letsencrypt'
if [ ! -d "$WORK_DIR" ]; then  
    mkdir -p ${WORK_DIR}
fi

ACCOUNT_KEY=${WORK_DIR}/account.key
if [ ! -f "$ACCOUNT_KEY" ]; then  
    openssl genrsa 4096 > ${ACCOUNT_KEY}
fi

NGINX_SITE_CONFIG=${NGINX_SITE_ENABLE_DIR}/${DOMAIN}

DOMAIN_DIR=${WORK_DIR}/${DOMAIN}
CHALLENGES_DIR=${WORK_DIR}/${DOMAIN}/challenges/
ACME_TINY_PY=${WORK_DIR}/acme_tiny.py
INTERMEDIATE_PEM=${WORK_DIR}/intermediate.pem
ROOT_PEM=${WORK_DIR}/root.pem

DOMAIN_KEY=${DOMAIN_DIR}/domain.key
DOMAIN_CSR=${DOMAIN_DIR}/domain.csr
SIGNED_CRT=${DOMAIN_DIR}/signed.crt
CHAINED_PEM=${DOMAIN_DIR}/chained.pem


if [ -d "$DOMAIN_DIR" ]; then  
    echo >&2 "Error: $DOMAIN_DIR already exsit"
    exit 1
fi

mkdir -p ${DOMAIN_DIR}

#generate a domain private key
openssl genrsa 4096 > ${DOMAIN_KEY}

if [ -z "$DOMAIN2" ]; then
    #for a single domain
    openssl req -new -sha256 -key ${DOMAIN_KEY} -subj "/CN=${DOMAIN}" > ${DOMAIN_CSR}
else
    #for multiple domains (use this one if you want both www.yoursite.com and yoursite.com)
    openssl req -new -sha256 -key ${DOMAIN_KEY} -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:${DOMAIN},DNS:${DOMAIN2}")) > ${DOMAIN_CSR}
fi

mkdir -p ${CHALLENGES_DIR}

cat > ${NGINX_SITE_CONFIG} <<-EOF 
server {
    listen 80; 
    server_name ${DOMAIN} ${DOMAIN2};
    
    location /.well-known/acme-challenge/ {
        alias ${CHALLENGES_DIR};
        try_files \$uri =404;
    }
}
EOF

echo 'nginx reloading...'
nginx -t 
nginx -s reload
echo 'nginx reload succeed'

#签名
if [ ! -f "$ACME_TINY_PY" ]; then  
    wget -O ${ACME_TINY_PY} https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
fi
python ${ACME_TINY_PY} --account-key ${ACCOUNT_KEY} --csr ${DOMAIN_CSR} --acme-dir ${CHALLENGES_DIR} > ${SIGNED_CRT}

#合并Let's Encrypt的中间证书
if [ ! -f "$INTERMEDIATE_PEM" ]; then  
    wget -O ${INTERMEDIATE_PEM} https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
fi
cat ${SIGNED_CRT} ${INTERMEDIATE_PEM} > ${CHAINED_PEM}

#支持OCSP Stapling
if [ ! -f "$ROOT_PEM" ]; then  
    wget -O ${ROOT_PEM} https://letsencrypt.org/certs/isrgrootx1.pem
fi
cat ${INTERMEDIATE_PEM} ${ROOT_PEM} > ${WORK_DIR}/full_chained.pem

echo '*******************'
echo '*     all done!   *'
echo '*******************'

echo "${DOMAIN_KEY}"
echo "${DOMAIN_CSR}"
echo "${SIGNED_CRT}"
echo "${CHAINED_PEM}"