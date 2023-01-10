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

my $SeleniumTest = sub {

    # perform request to the login page
    $SeleniumObject->AgentRequest();

    my %ExistingElement = (
        Selector     => '#User',
        SelectorType => 'css',
    );
    $SeleniumObject->FindElementSave(%ExistingElement);
    $SeleniumObject->ElementExists(%ExistingElement);

    my %NotExistingElement = (
        Selector     => "This Element doesn't exist but the request won't die",
        SelectorType => 'link_text',
    );

    $SeleniumObject->FindElementSave(%NotExistingElement);
    $SeleniumObject->ElementExistsNot(%NotExistingElement);
};

$SeleniumObject->RunTest($SeleniumTest);

1;
