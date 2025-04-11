#!/usr/bin/env bash

set -o errexit
set -o pipefail

a2dismod mpm_event mpm_worker
a2enmod perl deflate filter headers mpm_prefork
useradd -d /opt/znuny -c 'Znuny user' -g www-data -s /bin/bash -M znuny

# link and create files
ln -sf "$PWD" /opt/znuny
ln -s /opt/znuny/scripts/apache2-httpd.include.conf /etc/apache2/sites-enabled/zzz_znuny.conf
cp Kernel/Config.pm.dist Kernel/Config.pm
mkdir -p /opt/znuny/var/tmp

# start apache
apachectl start

# MySQL
if [ "$DB" == "mysql" ]; then
    .github/workflows/ci/config-mysql.sh
fi

# run needed scripts
/opt/znuny/bin/znuny.SetPermissions.pl
su -c "bin/znuny.CheckSum.pl -a create" - znuny
touch /opt/znuny/installed

# prepare Selenium tests
if [[ "$GITHUB_JOB" =~ ^Selenium ]]; then
    .github/workflows/ci/config-selenium.sh
fi

if [ "$DB" ]; then
    su -c "bin/znuny.Console.pl Maint::Config::Rebuild" - znuny
    su -c "bin/znuny.Console.pl Admin::Config::Update --setting-name CheckEmailAddresses --value 0" - znuny
fi
