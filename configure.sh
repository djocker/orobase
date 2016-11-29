#!/usr/bin/env bash
localedef -c -f UTF-8 -i en_US en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

WWW_USER=${WWW_USER-"www-data"}
WWW_GROUP=${WWW_GROUP-"www-data"}
MEMORY_LIMIT_CLI=${MEMORY_LIMIT_CLI-"2048"}
MEMORY_LIMIT_FPM=${MEMORY_LIMIT_FPM-"2048"}
UPLOAD_LIMIT=${UPLOAD_LIMIT-"256"}

# configure php cli
sed -i -e "s/;date.timezone\s=/date.timezone = UTC/g" /etc/php/5.6/cli/php.ini
sed -i -e "s/short_open_tag\s=\s*.*/short_open_tag = Off/g" /etc/php/5.6/cli/php.ini
sed -i -e "s/memory_limit\s=\s.*/memory_limit = ${MEMORY_LIMIT_CLI}M/g" /etc/php/5.6/cli/php.ini
sed -i -e "s/max_execution_time\s=\s.*/max_execution_time = 0/g" /etc/php/5.6/cli/php.ini

# configure php fpm
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/5.6/fpm/php.ini
sed -i -e "s/;date.timezone\s=/date.timezone = UTC/g" /etc/php/5.6/fpm/php.ini
sed -i -e "s/short_open_tag\s=\s*.*/short_open_tag = Off/g" /etc/php/5.6/fpm/php.ini

sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = ${UPLOAD_LIMIT}M/g" /etc/php/5.6/fpm/php.ini
sed -i -e "s/memory_limit\s=\s.*/memory_limit = ${MEMORY_LIMIT_FPM}M/g" /etc/php/5.6/fpm/php.ini
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = ${UPLOAD_LIMIT}M/g" /etc/php/5.6/fpm/php.ini
sed -i -e "s/max_execution_time\s=\s.*/max_execution_time = 300/g" /etc/php/5.6/fpm/php.ini

# php-fpm config
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/5.6/fpm/php-fpm.conf
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/5.6/fpm/pool.d/www.conf
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/5.6/fpm/pool.d/www.conf
sed -i -e "s/listen\s=\s\/run\/php\/php5.6-fpm.sock/listen = \/var\/run\/php5-fpm.sock/g" /etc/php/5.6/fpm/pool.d/www.conf

find /etc/php/5.6/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Configure nginx
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size ${UPLOAD_LIMIT}m/" /etc/nginx/nginx.conf
echo "daemon off;" >> /etc/nginx/nginx.conf
# Remove defaults
rm /etc/nginx/conf.d/default.conf
rm -rf /var/www

# Create data folder
mkdir -p /srv/app-data
mkdir -p /var/www

mkdir -p /var/run/php
ln -s /usr/sbin/php-fpm5.6 /usr/sbin/php5-fpm
ln -s /usr/sbin/php-fpm5.6 /usr/sbin/php-fpm

chown ${WWW_USER}:${WWW_GROUP} /srv/app-data
chown ${WWW_USER}:${WWW_GROUP} /var/www

apt-get -qq clean
rm -rf /var/lib/apt/lists/*
