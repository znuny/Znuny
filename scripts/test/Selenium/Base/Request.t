# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

my $SeleniumTestAgent = sub {

    # perform request to the login page
    $SeleniumObject->AgentRequest();

    $SeleniumObject->PageContains(
        String => 'LoginButton',
    );
};

my $SeleniumTestCustomer = sub {

    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    # customer self-registration is disabled by default, enable it so the 'Signup' link is rendered
    $HelperObject->ConfigSettingChange(
        Valid => 1,
        Key   => 'CustomerPanelCreateAccount',
        Value => 1,
    );

    # perform request to the login page
    $SeleniumObject->CustomerRequest();

    $SeleniumObject->PageContains(
        String => 'Signup',
    );

    # restore default so the public test runs with self-registration disabled
    $HelperObject->ConfigSettingChange(
        Valid => 0,
        Key   => 'CustomerPanelCreateAccount',
    );
};

my $SeleniumTestPublic = sub {

    # perform request to the login page
    $SeleniumObject->PublicRequest();

    $SeleniumObject->PageContainsNot(
        String => 'LoginButton',
    );
    $SeleniumObject->PageContainsNot(
        String => 'Signup',
    );
};

$SeleniumObject->RunTest($SeleniumTestAgent);
$SeleniumObject->RunTest($SeleniumTestCustomer);
$SeleniumObject->RunTest($SeleniumTestPublic);

1;
