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

apt-get install -qqy software-properties-common python-software-properties
add-apt-repository -y ppa:ondrej/php
apt-get -qqy update

# Install base packages
apt-get install -qqy apt-transport-https ca-certificates vim make git-core sudo wget curl procps \
python-setuptools mcrypt mysql-client zip unzip redis-tools

# Install php
apt-get install -qqy --no-install-recommends php5.6-fpm php5.6-cli php5.6-common php5.6-dev \
php5.6-mysql php5.6-curl php5.6-gd php5.6-mcrypt php5.6-sqlite php5.6-xmlrpc php5.6-ldap \
php5.6-xsl php5.6-intl php5.6-soap php5.6-mbstring php5.6-zip php5.6-bz2 php5.6-redis || exit 1 

# Install nginx
wget -O - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
apt-get -qy update
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
sudo -u www-data composer global require fxp/composer-asset-plugin:1.2.2 || exit 1

# Install node.js
curl -sL https://deb.nodesource.com/setup_4.x | bash -
apt-get install -qqy nodejs || exit 1

# Install php5 twig extension
mkdir /tmp/twig 
cd /tmp/twig
curl -fSL "https://github.com/twigphp/Twig/archive/v1.24.1.tar.gz" -o twig.tar.gz || exit 1
tar -xzv --strip-components=1 -f twig.tar.gz || exit 1
cd ext/twig && phpize || exit 1
./configure && make && make install || exit 1
cp /tmp/twig/ext/twig/modules/twig.so $(php-config --extension-dir) || exit 1
cd ~
echo 'extension=twig.so' > /etc/php/5.6/fpm/conf.d/20-twig.ini
echo 'extension=twig.so' > /etc/php/5.6/cli/conf.d/20-twig.ini
rm -Rf /tmp/twig

# Install supervisor
easy_install supervisor || exit 1
easy_install supervisor-stdout || exit 1

apt-get -qq clean
rm -rf /var/lib/apt/lists/*
