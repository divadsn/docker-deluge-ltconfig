FROM alpine:edge
LABEL maintainer="David Sn <divad.nnamtdeis@gmail.com>"

ARG LIBTORRENT_VERSION=2.0.11-r0
ARG DELUGE_VERSION=2.1.1

ENV USER=deluge \
    UID=101 \
    GID=101 \
    GEOIP_DB_URL="https://dl.miyuru.lk/geoip/maxmind/country/maxmind.dat.gz" \
    PYTHON_EGG_CACHE="/config/plugins/.python-eggs"

RUN set -ex && \
    # Add testing repository
    echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \

    # Install dependencies
    apk add --no-cache \
        curl geoip libtorrent-rasterbar=${LIBTORRENT_VERSION} python3 \
        py3-twisted py3-openssl py3-rencode py3-xdg py3-zope-interface \
        py3-chardet py3-setproctitle py3-pillow py3-mako py3-ifaddr \
        py3-distro py3-libtorrent-rasterbar=${LIBTORRENT_VERSION} py3-geoip@testing && \

    # Install build dependencies
    apk add --no-cache --virtual=build-dependencies build-base git python3-dev py3-pip py3-setuptools && \

    # Build deluge
    cd /tmp && \
    git clone --branch deluge-${DELUGE_VERSION} --depth 1 git://deluge-torrent.org/deluge.git && cd deluge && \
    python3 setup.py build && \
    python3 setup.py install && \

    # Build deluge-ltconfig
    cd /tmp && \
    git clone --branch 2.x --depth 1 https://github.com/ratanakvlun/deluge-ltconfig.git && \
    cd deluge-ltconfig && \
    python3 setup.py bdist_egg && \
    mkdir -p /usr/share/deluge/plugins && \
    cp dist/ltConfig-*.egg /usr/share/deluge/plugins && \

    # Fix missing geoip legacy database
    mkdir -p /usr/share/GeoIP && \
    curl -s "$GEOIP_DB_URL" | gunzip > /usr/share/GeoIP/GeoIP.dat && \
    echo "#!/bin/sh\ncurl -s \"$GEOIP_DB_URL\" | gunzip > /usr/share/GeoIP/GeoIP.dat" > /etc/periodic/monthly/geoip && \
    chmod +x /etc/periodic/monthly/geoip && \

    # Cleanup
    apk del --purge build-dependencies && \
    rm -rf /tmp/* /var/cache/apk/* /root/.cache

ADD docker-entrypoint.sh start_deluge.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 8112/tcp 53160/tcp 53160/udp 58846/tcp
VOLUME ["/config", "/data"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
