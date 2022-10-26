#!/usr/bin/env bash

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