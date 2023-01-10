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

    my $ZnunyHelperObject  = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    for my $Count ( 0 .. 3 ) {
        $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
            {
                Name          => 'UnitTestText' . $Count,
                Label         => "UnitTestText" . $Count,
                ObjectType    => 'Ticket',
                FieldType     => 'Text',
                InternalField => 0,
                Config        => {
                    DefaultValue => '',
                    Link         => '',
                },
            },
        );
    }

    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => [ 'admin', 'users' ],
    );

    $SeleniumObject->AgentInterface(
        Action      => 'AdminDynamicField',
        WaitForAJAX => 0,
    );

    for my $Element (qw(DynamicFieldImportExportWidget DynamicFieldImport DynamicFieldExport )) {
        $Self->True(
            $SeleniumObject->find_element( "#$Element", 'css' )->is_displayed(),
            "Element with ID $Element is present.",
        );
    }

    $SeleniumObject->find_element( "#DynamicFieldExport", 'css' )->click();

    $Self->True(
        $SeleniumObject->find_element( "#DynamicFieldsTable", 'css' )->is_displayed(),
        "Element with ID DynamicFieldsTable is present.",
    );

    $Self->True(
        $SeleniumObject->find_element( 'input[name="DynamicFieldConfiguration"]', 'css' )->is_displayed(),
        "Element with name DynamicFieldConfiguration is present.",
    );

    $Self->True(
        $SeleniumObject->find_element( 'input[name="DynamicFieldScreenConfiguration"]', 'css' )->is_displayed(),
        "Element with name DynamicFieldConfiguration is present.",
    );

    $SeleniumObject->find_element( "#Export", 'css' )->click();
};

$SeleniumObject->RunTest($SeleniumTest);

1;
