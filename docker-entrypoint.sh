#!/bin/sh

id -u $USER &>/dev/null

# Create user if not exists
if [ "$?" -ne 0 ]; then
    addgroup -g $GID -S $USER
    adduser -S -D -u $UID -s /sbin/nologin -G $USER -g $USER $USER
    chown -R $USER:$USER /config /data
fi

# Copy latest ltConfig plugin to /config/plugins
if [ ! -d "/config/plugins" ]; then
    cp -rp /usr/share/deluge/plugins /config/plugins
    chown -R $USER:$USER /config/plugins
else
    rm -f /config/plugins/ltConfig-*.egg && cp -p /usr/share/deluge/plugins/ltConfig-*.egg /config/plugins
    chown $USER:$USER /config/plugins/ltConfig-*.egg
fi

# Start deluge
su $USER -s /bin/sh -c start_deluge.sh
