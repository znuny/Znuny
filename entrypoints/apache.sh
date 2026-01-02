#!/bin/bash
# You can do some boot checks, like initial setup steps here.
# Vars
external_port="${external_port:-80}"
PERSISTENT_CFG="/persistent/Config.pm"
ZNUNY_CFG="/opt/znuny/Kernel/Config.pm"

# Welcome message
echo Listening on port ${external_port}


# Setup persistence
if [ -f "$PERSISTENT_CFG" ]; then
    echo "Using persistent Config.pm"
else
    echo "Persistent Config.pm not found, seeding it"
    cp "$ZNUNY_CFG" "$PERSISTENT_CFG"
fi
ln -sf "$PERSISTENT_CFG" "$ZNUNY_CFG"

# Move to Main process
exec gosu www-data "$@"