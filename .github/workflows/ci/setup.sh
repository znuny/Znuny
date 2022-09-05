#!/usr/bin/env bash

set -o errexit
set -o pipefail

a2dismod mpm_event mpm_worker
a2enmod perl deflate filter headers mpm_prefork
useradd -d /opt/otrs -c 'OTRS user' -g www-data -s /bin/bash -M otrs

# link and create files
ln -sf "$PWD" /opt/otrs
ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-enabled/zzz_otrs.conf
cp Kernel/Config.pm.dist Kernel/Config.pm
mkdir -p /opt/otrs/var/tmp

# start apache
apachectl start

# MySQL
if [ "$DB" == "mysql" ]; then
    .github/workflows/ci/config-mysql.sh
fi

# run needed scripts
/opt/otrs/bin/otrs.SetPermissions.pl
su -c "bin/otrs.CheckSum.pl -a create" - otrs
touch /opt/otrs/installed

# prepare Selenium tests
if [ "$GITHUB_JOB" == "SeleniumTest-MySQL" ]; then
chmod 777 -R /opt/otrs/scripts/test/sample
sed -i 's/\(.*\$DIBI\$.*\)/\1                                                 \
    \$Self->{"TestHTTPHostname"} = "172.18.0.2";                              \
    \$Self->{"SecureMode"} = 1;                                               \
    \$Self->{"SeleniumTestsConfig"} = {                                       \
        remote_server_addr  => "chrome",                                      \
        port                => "4444",                                        \
        platform            => "ANY",                                         \
        browser_name        => "chrome",                                      \
        extra_capabilities => {                                               \
            chromeOptions => {                                                \
                # disable-infobars makes sure window size calculations are ok \
                args => [ "disable-infobars" ],                               \
            },                                                                \
        },                                                                    \
    },\n/' /opt/otrs/Kernel/Config.pm
fi

if [ "$DB" ]; then
    su -c "bin/otrs.Console.pl Maint::Config::Rebuild" - otrs
    su -c "bin/otrs.Console.pl Admin::Config::Update --setting-name CheckEmailAddresses --value 0" - otrs
fi