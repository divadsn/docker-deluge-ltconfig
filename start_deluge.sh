#!/bin/sh

deluged -c /config -L info -l /config/deluged.log
deluge-web -d -c /config -L info -l /config/deluge-web.log
