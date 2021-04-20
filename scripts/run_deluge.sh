#!/bin/sh

export PYTHON_EGG_CACHE="/config/plugins/.python-eggs"

deluged -c /config -L info -l /config/deluged.log
deluge-web -d -c /config -L info -l /config/deluge-web.log
