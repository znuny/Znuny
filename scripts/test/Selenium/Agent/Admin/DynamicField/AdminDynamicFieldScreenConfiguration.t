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
    my $SysConfigObject    = $Kernel::OM->Get('Kernel::System::SysConfig');

    # Add dynamic fields
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

        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
            Name => 'Test' . $Count,
        );

        my $IsResult = $Self->True(
            $DynamicField,    # test data
            "DynamicField: 'UnitTestText$Count' was created succussfully.",
        );
    }

    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => [ 'admin', 'users' ],
    );

    $SeleniumObject->AgentInterface(
        Action      => 'Admin',
        WaitForAJAX => 0,
    );

    $SeleniumObject->ElementExists(
        Selector     => '[data-module="AdminDynamicFieldScreenConfiguration"]',
        SelectorType => 'css',
    );

    $SeleniumObject->AgentInterface(
        Action      => 'AdminDynamicFieldScreenConfiguration',
        WaitForAJAX => 0,
    );

    $Self->True(
        $SeleniumObject->find_element( '#AgentTicketNote', 'css' )->is_displayed(),
        "Screen 'AgentTicketNote' is visible",
    );

    $Self->True(
        $SeleniumObject->find_element( '#AgentTicketQueue', 'css' )->is_displayed(),
        "Default columns for screen 'AgentTicketQueue' are visible",
    );

    for my $Count ( 0 .. 3 ) {
        $Self->True(
            $SeleniumObject->find_element( "#UnitTestText$Count", 'css' )->is_displayed(),
            "Dynamic field 'UnitTestText$Count' is visible",
        );
    }

    $Self->True(
        $SeleniumObject->find_element( '#AgentTicketNote', 'css' )->is_displayed(),
        "Screen 'AgentTicketNote' is visible",
    );

    my %ScreenMapping = (
        AgentTicketNote  => 'DynamicField',
        AgentTicketQueue => 'DefaultColumns',
    );

    SCREEN:
    for my $Screen (qw(AgentTicketNote AgentTicketQueue)) {

        $SeleniumObject->AgentInterface(
            Action      => 'AdminDynamicFieldScreenConfiguration',
            WaitForAJAX => 0,
        );

        $SeleniumObject->find_element( "#$Screen", 'css' )->click();

        for my $Count ( 0 .. 3 ) {
            $Self->True(
                $SeleniumObject->find_element( "#UnitTestText$Count", 'css' )->is_displayed(),
                "Dynamic field 'UnitTestText$Count' is visible",
            );
        }

        # Move UnitTestText0 to disabled elements
        $SeleniumObject->find_element( "#UnitTestText0 input[type='checkbox']", 'css' )->click();
        $SeleniumObject->find_element( '#AssignSelectedToDisabledElements',     'css' )->click();

        # Move UnitTestText1 to assigned elements
        $SeleniumObject->find_element( "#UnitTestText1 input[type='checkbox']", 'css' )->click();
        $SeleniumObject->find_element( '#AssignSelectedToAssignedElements',     'css' )->click();

        # Move UnitTestText2 to assigned required elements
        $SeleniumObject->find_element( "#UnitTestText2 input[type='checkbox']",     'css' )->click();
        $SeleniumObject->find_element( '#AssignSelectedToAssignedRequiredElements', 'css' )->click();

        # submit form
        $SeleniumObject->find_element( '#Form > div.Field.SpacingTop > button[type="submit"]', 'css' )->click();

        # wait for submit to reload page
        sleep(5);

        $ZnunyHelperObject->_RebuildConfig();

        # make sure to use a new config object
        $Kernel::OM->ObjectsDiscard(
            Objects => ['Kernel::Config'],
        );

        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $Config       = $ConfigObject->Get("Ticket::Frontend::$Screen");

        my $Prefix = '';
        if ( $ScreenMapping{$Screen} eq 'DefaultColumns' ) {
            $Prefix = 'DynamicField_';
        }

        for my $Count ( 0 .. 3 ) {

            # UnitTestText3 is a completely unassigned dynamic field whose status
            # must be handled as undefined
            my $ExpectedValue = $Count;
            if ( $Count == 3 ) {
                $ExpectedValue = undef;
            }

            $Self->Is(
                $Config->{ $ScreenMapping{$Screen} }->{ $Prefix . "UnitTestText" . $Count },
                $ExpectedValue,
                "Dynamic field 'UnitTestText$Count' was correctly set for screen '$Screen'.",
            );
        }

        # create test ticket and articles
        my $TicketID = $HelperObject->TicketCreate();

        my $ArticleIDFirst = $HelperObject->ArticleCreate(
            TicketID => $TicketID,
        );

        my $ArticleIDSecond = $HelperObject->ArticleCreate(
            TicketID => $TicketID,
        );

        # navigate to created test ticket in AgentTicketNote page
        $SeleniumObject->AgentInterface(
            Action      => $Screen,
            TicketID    => $TicketID,
            WaitForAJAX => 0,
        );

        if ( $ScreenMapping{$Screen} eq 'DefaultColumns' ) {
            last SCREEN;
        }

        for my $Count ( 1 .. 2 ) {
            $Self->True(
                $SeleniumObject->find_element( "#LabelDynamicField_UnitTestText$Count", 'css' )->is_displayed(),
                "Dynamic field 'UnitTestText$Count' is visible",
            );
        }
    }

    for my $SettingName (
        'Ticket::Frontend::AgentTicketNote###DynamicField',
        'Ticket::Frontend::AgentTicketQueue###DefaultColumns'
        )
    {
        my %Setting = $SysConfigObject->SettingGet(
            Name      => $SettingName,
            Translate => 0,
        );

        my $Guid = $SysConfigObject->SettingLock(
            UserID    => 1,
            DefaultID => $Setting{DefaultID},
            Force     => 1,
        );
        $Self->True(
            $Guid,
            "Lock setting before reset($SettingName).",
        );

        my $Success = $SysConfigObject->SettingReset(
            Name              => $SettingName,
            ExclusiveLockGUID => $Guid,
            UserID            => 1,
        );
        $Self->True(
            $Success,
            "Setting $SettingName reset to the default value.",
        );

        $SysConfigObject->SettingUnlock(
            DefaultID => $Setting{DefaultID},
        );
    }

    $ZnunyHelperObject->_RebuildConfig();
};

$SeleniumObject->RunTest($SeleniumTest);

1;
