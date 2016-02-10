FROM ubuntu:14.04
VOLUME ["/srv/app-data"]
EXPOSE 443 80 8080

COPY bin/* /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN setup-base-system.sh

COPY conf/nginx.conf          /etc/nginx/nginx.conf
COPY conf/nginx-bap.conf      /etc/nginx/sites-enabled/bap.conf
COPY conf/supervisord.conf    /etc/supervisord.conf


