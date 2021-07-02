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

# store test function in variable so the Selenium object can handle errors/exceptions/dies etc.
my $SeleniumTest = sub {

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $StateObject       = $Kernel::OM->Get('Kernel::System::State');
    my $SysConfigObject   = $Kernel::OM->Get('Kernel::System::SysConfig');

    $ZnunyHelperObject->_RebuildConfig();

    for my $SysConfig ('AgentTicketNote') {

        my $Success = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => "Set $SysConfig State",
            Settings => [
                {
                    Name                   => "Ticket::Frontend::$SysConfig###State",
                    EffectiveValue         => '1',
                    IsValid                => 1,
                    UserModificationActive => 1,
                },
            ],
        );
    }

    my @PendingStateIDs = $StateObject->StateGetStatesByType(
        StateType => [ 'pending reminder', 'pending auto' ],
        Result    => 'ID',
    );

    # create test user and login
    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => ['users'],
    );

    my @Tests = (
        {
            Name => "Action - AgentTicketPhone",
            Data => {
                Action => 'AgentTicketPhone',
                State  => 'NextStateID',
            },
        },
        {
            Name => "Action - AgentTicketEmail",
            Data => {
                Action => 'AgentTicketEmail',
                State  => 'NextStateID',
            },
        },
        {
            Name => "Action - AgentTicketNote",
            Data => {
                Action => 'AgentTicketNote',
                State  => 'NewStateID',
                Ticket => 1,
            },
        },
    );

    TEST:
    for my $Test (@Tests) {

        my $DisabledElement;
        my $TicketID;

        if ( $Test->{Data}->{Ticket} ) {
            $TicketID = $HelperObject->TicketCreate();
        }

        # navigate to Admin page
        $SeleniumObject->AgentInterface(
            Action      => $Test->{Data}->{Action},
            TicketID    => $TicketID,
            WaitForAJAX => 0,
        );

        my $Element = $SeleniumObject->FindElementSave(
            Selector     => "#$Test->{Data}->{State}",
            SelectorType => 'css',
        );

        for my $Field (qw(Day Year Month Hour Minute)) {

            eval {
                $DisabledElement = $SeleniumObject->find_element( "#$Field", 'css' )->is_displayed();
            };
            $Self->False(
                $DisabledElement,
                "Checking for disabled element '$Field'",
            );
        }

        my $Result = $SeleniumObject->InputSet(
            Attribute   => $Test->{Data}->{State},
            Content     => $PendingStateIDs[0],
            WaitForAJAX => 0,
            Options     => {
                KeyOrValue => 'Key',
            },
        );

        $Self->True(
            $Result,
            "Change NextStateID successfully.",
        );

        next TEST if !$Result;

        for my $Field (qw(Day Year Month Hour Minute)) {

            $Self->True(
                $SeleniumObject->find_element( "#$Field", 'css' )->is_displayed(),
                "Checking for enabled element '$Field'",
            );
        }
    }
};

# finally run the test(s) in the browser
$SeleniumObject->RunTest($SeleniumTest);

1;
