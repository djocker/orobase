#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
export COMPOSER_PROCESS_TIMEOUT=3600

APP_DIR=/var/www
[[ -d ${APP_DIR} ]] || mkdir -p ${APP_DIR}

function info {
    printf "\033[0;36m${1}\033[0m \n"
}
function note {
    printf "\033[0;33m${1}\033[0m \n"
}
function success {
    printf "\033[0;32m${1}\033[0m \n"
}
function warning {
    printf "\033[0;95m${1}\033[0m \n"
}
function error {
    printf "\033[0;31m${1}\033[0m \n"
    exit 1
}

mkdir -p /tmp/src
cd /tmp/src

if [[ ! -z ${SSH_PRIVATE_KEY} ]]; then
    mkdir ~/.ssh
    echo 'Host *' > ~/.ssh/config
    echo 'StrictHostKeyChecking no' >> ~/.ssh/config
    # Add private ssh key for git clone
    echo ${SSH_PRIVATE_KEY} | base64 -d > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    # Starting ssh agent
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
fi

if [[ ! -z ${GITHUB_TOKEN} ]]; then
    echo "Add GitHub token to composer"
    composer config --global github-oauth.github.com ${GITHUB_TOKEN}
fi

git init
git remote add origin ${GIT_URI}

if [[ 0 -eq $(expr match "${GIT_REF}" "tags/") ]];then
    git fetch origin ${GIT_REF}
else
    git fetch origin ${GIT_REF}:${GIT_REF}
fi

[[ 0 -lt $? ]] && error "Can't fetch ${GIT_URI} ${GIT_REF}"

git checkout -f ${GIT_REF} || error "Can't checkout ${GIT_URI} ${GIT_REF}"

# If ssh key not present try to download submodules via https
if [[ -f .gitmodules ]] && [[ -z ${SSH_PRIVATE_KEY} ]]; then
    sed -i -e "s/git@github.com:/https:\/\/github.com\//g" .gitmodules
fi

git submodule update --init

# Export source code
git-archive-all $(find . -name ".*" -size 0  | while read -r line; do printf '%s ' '--extra '$line; done) /tmp/source.tar
tar -xf /tmp/source.tar --strip-components=1 -C ${APP_DIR}

# Fix for wrong file system check
sed -i -e "s/return \$fileLength == 255;/return \$fileLength > 200;/g" ${APP_DIR}/app/OroRequirements.php

# If is composer application
if [[ -f ${APP_DIR}/composer.json ]]; then
    if [[ ! -f ${APP_DIR}/composer.lock ]]; then
        composer update --no-interaction --lock -d ${APP_DIR} || error "Can't update lock file"
    fi
    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader -d ${APP_DIR} || error "Can't install dependencies"
else
    error "${APP_DIR}/composer.json not found!"
fi

rm -rf /tmp/*
rm -rf ~/.ssh
rm -rf ~/.composer
