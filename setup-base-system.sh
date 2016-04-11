#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
WWW_USER=${WWW_USER-"www-data"}
WWW_GROUP=${WWW_USER-"www-data"}
MEMORY_LIMIT_CLI=${MEMORY_LIMIT_CLI-"2048"}
MEMORY_LIMIT_FPM=${MEMORY_LIMIT_FPM-"2048"}
UPLOAD_LIMIT=${UPLOAD_LIMIT-"256"}

apt-get -qy update
apt-get -qqy upgrade

# install base packages
apt-get install -qqy vim git-core sudo wget curl procps python-setuptools mcrypt mysql-client \
php5-fpm php5-cli php5-dev php5-mysql php5-curl php5-gd php5-mcrypt \
php5-sqlite php5-xmlrpc php5-xsl php5-common php5-intl php5-ldap \
php5-cli php5-mongo php5-redis php-apc || exit 1


# Automatically instal the latest nginx
wget -O - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list

apt-get -qy update
apt-get install -qqy --reinstall nginx || exit 1

# install composer
(curl -sS https://getcomposer.org/installer | php) || exit 1
mv composer.phar /usr/local/bin/composer

# install node.js
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install -qqy nodejs || exit 1

# install supervisor
easy_install supervisor || exit 1
easy_install supervisor-stdout || exit 1

# configure php cli
sed -i -e "s/;date.timezone\s=/date.timezone = UTC/g" /etc/php5/cli/php.ini
sed -i -e "s/short_open_tag\s=\s*.*/short_open_tag = Off/g" /etc/php5/cli/php.ini
sed -i -e "s/memory_limit\s=\s.*/memory_limit = ${MEMORY_LIMIT_CLI}M/g" /etc/php5/cli/php.ini
sed -i -e "s/max_execution_time\s=\s.*/max_execution_time = 0/g" /etc/php5/cli/php.ini

# configure php fpm
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
sed -i -e "s/;date.timezone\s=/date.timezone = UTC/g" /etc/php5/fpm/php.ini
sed -i -e "s/short_open_tag\s=\s*.*/short_open_tag = Off/g" /etc/php5/fpm/php.ini

sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = ${UPLOAD_LIMIT}M/g" /etc/php5/fpm/php.ini
sed -i -e "s/memory_limit\s=\s.*/memory_limit = ${MEMORY_LIMIT_FPM}M/g" /etc/php5/fpm/php.ini
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = ${UPLOAD_LIMIT}M/g" /etc/php5/fpm/php.ini
sed -i -e "s/max_execution_time\s=\s.*/max_execution_time = 300/g" /etc/php5/fpm/php.ini

# php-fpm config
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

php5enmod mcrypt

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

chown ${WWW_USER}:${WWW_GROUP} /srv/app-data
chown ${WWW_USER}:${WWW_GROUP} /var/www

apt-get -qq clean
rm -rf /var/lib/apt/lists/*
