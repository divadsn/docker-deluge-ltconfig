FROM alpine:edge
LABEL maintainer="David Sn <divad.nnamtdeis@gmail.com>"

ARG LIBTORRENT_VERSION=1.2.10
ARG DELUGE_VERSION=2.0.3

ENV USER=deluge \
    UID=101 \
    GID=101

ADD scripts/*.sh docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && build.sh

EXPOSE 8112/tcp 53160/tcp 53160/udp 58846/tcp
VOLUME ["/config", "/data"]
ENTRYPOINT ["docker-entrypoint.sh"]
