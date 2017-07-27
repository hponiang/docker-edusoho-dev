#!/bin/bash

#set -eo pipefail
    cd /var/www/edusoho/
    service php-fpm start
    service nginx start
    #yarn
    #npm run dev
    echo '*******************************'
    echo '* welcome to develop lder! *'
    echo '*******************************

