FROM ubuntu:14.04

COPY setup-base-system.sh /opt/bin/setup-base-system.sh
RUN /bin/bash /opt/bin/setup-base-system.sh

COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

COPY conf/nginx.conf          /etc/nginx/nginx.conf
COPY conf/nginx-bap.conf      /etc/nginx/sites-enabled/bap.conf
COPY conf/supervisord.conf    /etc/supervisord.conf

VOLUME ["/srv/app-data"]
EXPOSE 443 80 8080

CMD ["run.sh"]


