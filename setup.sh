#!/usr/bin/env bash
localedef -c -f UTF-8 -i en_US en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

locale-gen en en_US en_US.UTF-8
dpkg-reconfigure locales

export LC_ALL='en_US.UTF-8'
export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'

apt-get -qy update
apt-get -qqy upgrade

# Install tools
apt-get install -qqy software-properties-common python-software-properties python-setuptools

# Install base packages
apt-get install -qqy apt-transport-https ca-certificates vim make git-core wget curl procps \
mcrypt mysql-client zip unzip redis-tools netcat-openbsd

# Install php
apt-get install -qqy --no-install-recommends php-fpm php-cli php-common php-dev \
php-mysql php-curl php-gd php-mcrypt php-xmlrpc php-ldap \
php-xsl php-intl php-soap php-mbstring php-zip php-bz2 php-redis php-tidy || exit 1

# Install nginx
apt-get install -qqy --reinstall nginx || exit 1

# Install composer
(curl -sS https://getcomposer.org/installer | php) || exit 1
mv composer.phar /usr/local/bin/composer.phar

# Create composer home dirs
mkdir -p -m 0744 /opt/composer/root
mkdir -p -m 0744 /opt/composer/www-data
chown www-data:www-data /opt/composer/www-data

# Create composer wrapper
echo '#!/usr/bin/env bash' >> /usr/local/bin/composer
echo 'COMPOSER_HOME=/opt/composer/$(whoami) /usr/local/bin/composer.phar $@' >> /usr/local/bin/composer
chmod 0755 /usr/local/bin/composer

# Install required composer-plugins
runuser -s /bin/sh -c 'composer global require fxp/composer-asset-plugin:1.2.2' www-data || exit 1

# Install node.js
apt-get install -qqy nodejs || exit 1

# Install supervisor
easy_install supervisor || exit 1
easy_install supervisor-stdout || exit 1

apt-get -qq clean
rm -rf /var/lib/apt/lists/*
