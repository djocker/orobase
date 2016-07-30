FROM ubuntu:14.04

COPY setup-base-system.sh /opt/bin/setup-base-system.sh
RUN /bin/bash /opt/bin/setup-base-system.sh

COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*


