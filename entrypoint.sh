#!/bin/bash

#set -eo pipefail
    cd /var/www/edusoho/
    service php7.0-fpm start
    service nginx start
    service mysql start
    # yarn
    # npm run dev
    echo '*******************************'
    echo '* welcome to develop lder! *'
    echo '*******************************'