#!/bin/bash
# You can do some boot checks, like initial setup steps here.

# force starting daemon so we dont have to wait
service nullmailer start && service cron start
su - znuny -c "/opt/znuny/bin/Cron.sh start >> /dev/null"

# Help message on first install (no actual check atm)
echo For initial setup, please visit http://hostname:port/znuny/installer.pl
# Run CMD
exec "$@"