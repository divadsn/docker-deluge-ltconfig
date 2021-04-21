#!/bin/sh

set -x

# Add testing repository
echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update

# Install dependencies
apk add --no-cache \
    curl geoip libgcc libstdc++ libffi libjpeg-turbo libtorrent-rasterbar@testing openssl python3 py3-pip py3-libtorrent-rasterbar@testing tzdata zlib
apk add --no-cache --virtual=build-dependencies \
    build-base cargo geoip-dev git libffi-dev libjpeg-turbo-dev openssl-dev python3-dev zlib-dev

# Build deluge
cd /tmp
git clone --branch deluge-${DELUGE_VERSION} --depth 1 git://deluge-torrent.org/deluge.git && cd deluge
curl -s "https://git.deluge-torrent.org/deluge/patch/?id=d6c96d629183e8bab2167ef56457f994017e7c85" | git apply
curl -s "https://git.deluge-torrent.org/deluge/patch/?id=351664ec071daa04161577c6a1c949ed0f2c3206" | git apply
pip3 install --no-cache-dir -U wheel setuptools pip
pip3 install --no-cache-dir -U -r requirements.txt geoip
python3 setup.py build
python3 setup.py install

# Build deluge-ltconfig
cd /tmp
git clone --branch 2.x --depth 1 https://github.com/ratanakvlun/deluge-ltconfig.git && cd deluge-ltconfig
python3 setup.py bdist_egg
mkdir -p /usr/share/deluge/plugins
cp dist/ltConfig-*.egg /usr/share/deluge/plugins

# Fix missing geoip legacy database
curl -s "https://dl.miyuru.lk/geoip/maxmind/country/maxmind.dat.gz" | gunzip > /usr/share/GeoIP/GeoIP.dat
cat << EOF > /etc/periodic/monthly/geoip
#!/bin/sh
curl -s "https://dl.miyuru.lk/geoip/maxmind/country/maxmind.dat.gz" | gunzip > /usr/share/GeoIP/GeoIP.dat
EOF

# Cleanup
apk del --purge build-dependencies
rm -rf /tmp/* /var/cache/apk/* /root/.cache /root/.cargo
rm -- "$0"
