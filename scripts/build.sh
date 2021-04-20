#!/bin/sh

set -x

# Install dependencies
apk --update add --no-cache \
    boost-python3 boost-system libgcc libstdc++ libffi zlib libjpeg-turbo openssl python3 py3-pip
apk --update add --no-cache --virtual=build-dependencies \
    boost-build boost-dev cmake coreutils curl g++ gcc git jq py3-setuptools python3-dev openssl-dev samurai build-base libffi-dev zlib-dev libjpeg-turbo-dev cargo

# Build libtorrent
cd /tmp
git clone --branch v${LIBTORRENT_VERSION} --depth 1 https://github.com/arvidn/libtorrent.git && cd libtorrent
git clean --force
git submodule update --depth=1 --init --recursive
PREFIX=/usr
BUILD_CONFIG="release cxxstd=14 crypto=openssl warnings=off address-model=32 -j$(nproc)"
BOOST_ROOT="" b2 ${BUILD_CONFIG} link=shared install --prefix=${PREFIX}
BOOST_ROOT="" b2 ${BUILD_CONFIG} link=static install --prefix=${PREFIX}
cd bindings/python
PYTHON_MAJOR_MINOR="$(python3 --version 2>&1 | sed 's/\(python \)\?\([0-9]\+\.[0-9]\+\)\(\.[0-9]\+\)\?/\2/i')"
echo "using python : ${PYTHON_MAJOR_MINOR} : $(command -v python3) : /usr/include/python${PYTHON_MAJOR_MINOR} : /usr/lib/python${PYTHON_MAJOR_MINOR} ;" > ~/user-config.jam
BOOST_ROOT="" b2 ${BUILD_CONFIG} install_module python-install-scope=system

# Build deluge
cd /tmp
git clone --branch deluge-${DELUGE_VERSION} --depth 1 git://deluge-torrent.org/deluge.git && cd deluge
curl -s "https://git.deluge-torrent.org/deluge/patch/?id=d6c96d629183e8bab2167ef56457f994017e7c85" | git apply
curl -s "https://git.deluge-torrent.org/deluge/patch/?id=351664ec071daa04161577c6a1c949ed0f2c3206" | git apply
pip3 install --no-cache-dir --upgrade wheel setuptools pip
pip3 install --no-cache-dir --upgrade -r requirements.txt
python3 setup.py build
python3 setup.py install

# Build deluge-ltconfig
cd /tmp
git clone --branch 2.x --depth 1 https://github.com/ratanakvlun/deluge-ltconfig.git && cd deluge-ltconfig
python3 setup.py bdist_egg
mkdir -p /usr/share/deluge/plugins
cp dist/ltConfig-*.egg /usr/share/deluge/plugins

# Cleanup
apk del --purge build-dependencies
rm -rf /tmp/* /root/.cache /root/.cargo
rm -- "$0"
