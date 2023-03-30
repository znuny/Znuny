# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Dumper)

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use Data::Dumper;
use Kernel::System::VariableCheck qw(:all);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $OriginalSeleniumConfig = $ConfigObject->Get('SeleniumTestsConfig');

if ( IsHashRefWithData($OriginalSeleniumConfig) ) {
    $Self->True(
        $OriginalSeleniumConfig,
        "SeleniumTestsConfig exists:\n" . Dumper( \$OriginalSeleniumConfig ),
    );
}

$OriginalSeleniumConfig = {
    remote_server_addr => 'selenium',
    port               => '4444',
    browser_name       => 'chrome',
    platform           => 'ANY',
};

if ( IsHashRefWithData($OriginalSeleniumConfig) ) {
    $Self->True(
        $OriginalSeleniumConfig,
        "New SeleniumTestsConfig exists:\n" . Dumper( \$OriginalSeleniumConfig ),
    );
}

# do not run for Github
return 1 if $ENV{PWD} eq '/__w/Znuny/Znuny';

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

my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Self->True(
    $SeleniumObject->{UnitTestDriverObject}->{ResultData}->{TestOk},
    'Selenium chromeOptions TestOk',
);

# check SeleniumTestsConfig via ObjectParamAdd
$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::UnitTest::Selenium'],
);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Selenium' => {
        SeleniumTestsConfig => {
            remote_server_addr => 'selenium',
            port               => '4444',
            browser_name       => 'chrome',
            extra_capabilities => {
                chromeOptions => {
                    args => [ "disable-gpu", "disable-infobars" ],
                },
                marionette => '',
            },
        }
    },
);

$SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

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
