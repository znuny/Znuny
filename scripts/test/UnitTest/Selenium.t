# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Dumper)

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use Data::Dumper;
use Kernel::System::VariableCheck qw(:all);

my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
my $HelperObject   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

my $OriginalSeleniumConfig = $ConfigObject->Get('SeleniumTestsConfig');

if ( IsHashRefWithData($OriginalSeleniumConfig) ) {
    $Self->True(
        $OriginalSeleniumConfig,
        "SeleniumTestsConfig exists:\n" . Dumper( \$OriginalSeleniumConfig ),
    );

}
else {
    $OriginalSeleniumConfig = {
        remote_server_addr => 'localhost',
        port               => '4444',
        browser_name       => 'firefox',
        platform           => 'ANY',
        extra_capabilities => {
            marionette => \0,
        },
    };
}

# new with chromeOptions
$ConfigObject->Set(
    Key   => 'SeleniumTestsConfig',
    Value => {
        %{$OriginalSeleniumConfig},
        browser_name       => 'chrome',
        extra_capabilities => {
            chromeOptions => {
                args => [ "disable-gpu", "disable-infobars" ],
            },
            marionette => '',
        },
    }
);

$Self->True(
    $SeleniumObject->{UnitTestDriverObject}->{ResultData}->{TestOk},
    'Selenium chromeOptions TestOk',
);

# with default config
$ConfigObject->Set(
    Key   => 'SeleniumTestsConfig',
    Value => {
        %{$OriginalSeleniumConfig},
    }
);

$Self->True(
    $SeleniumObject->{UnitTestDriverObject}->{ResultData}->{TestOk},
    'Selenium default config TestOk',
);

if ( !$SeleniumObject->{SeleniumTestsActive} ) {
    $Self->True(
        1,
        'Selenium testing is not active, skipping tests.',
    );
    return 1;
}

# new Selenium test config
my $NewSeleniumConfig = $ConfigObject->Get('SeleniumTestsConfig');

$Self->True(
    $NewSeleniumConfig,
    "SeleniumTestsConfig exists:\n" . Dumper( \$NewSeleniumConfig ),
);

# GetTestHTTPHostname
my $BaseURL          = $ConfigObject->Get('HttpType') . '://';
my $TestHTTPHostname = $HelperObject->GetTestHTTPHostname();
$BaseURL .= $TestHTTPHostname;

$Self->True(
    $TestHTTPHostname,
    "TestHTTPHostname: $TestHTTPHostname",
);

$Self->Is(
    $SeleniumObject->{BaseURL},
    $BaseURL,
    "BaseURL: $BaseURL",
);

1;
