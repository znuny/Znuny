#!/bin/bash
set -e

PERSISTENT_CFG="/persistent/Config.pm"
ZNUNY_CFG="/opt/znuny/Kernel/Config.pm"
ZNUNY_HOME="/opt/znuny"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_NAME="${DB_NAME:-znuny}"
DB_USER="${DB_USER:-znuny}"
DB_USER_PASS="${DB_USER_PASS:-some-pass}"

service nullmailer start
service cron start

if [ -f "$PERSISTENT_CFG" ]; then
    echo "Using persistent Config.pm"
else
    echo "Persistent Config.pm not found, seeding it"
    cp "$ZNUNY_CFG" "$PERSISTENT_CFG"
fi
ln -sf "$PERSISTENT_CFG" "$ZNUNY_CFG"

# Setup Config.pm
sed -i "s/\$Self->{DatabaseHost} = '127\.0\.0\.1';/\$Self->{DatabaseHost} = '$DB_HOST';/" $PERSISTENT_CFG
sed -i "s/\$Self->{Database} = 'znuny';/\$Self->{Database} = '$DB_NAME';/" $PERSISTENT_CFG
sed -i "s/\$Self->{DatabaseUser} = 'znuny';/\$Self->{DatabaseUser} = '$DB_USER';/" $PERSISTENT_CFG
sed -i "s/\$Self->{DatabasePw} = 'some-pass';/\$Self->{DatabasePw} = '$DB_USER_PASS';/" $PERSISTENT_CFG

chown -R znuny:www-data /persistent/Config.pm
chmod -R 770 /persistent/Config.pm
cd "$ZNUNY_HOME"

echo "For initial setup, visit http://hostname:port/znuny/installer.pl"
$ZNUNY_HOME/bin/znuny.SetPermissions.pl

exec gosu znuny "$@"