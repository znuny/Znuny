# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # enable tool bar AgentTicketEscalationView
        my %AgentTicketEscalationView = (
            AccessKey => 'w',
            Action    => 'AgentTicketEscalationView',
            Block     => 'ToolBarOverviews',
            CssClass  => 'EscalationView',
            Icon      => 'fa fa-exclamation',
            Link      => 'Action=AgentTicketEscalationView',
            Module    => 'Kernel::Output::HTML::ToolBar::Link',
            Name      => 'Escalation view',
            Priority  => '1010030',
        );

        $HelperObject->ConfigSettingChange(
            Key   => 'Frontend::ToolBarModule###130-Ticket::AgentTicketEscalation',
            Value => \%AgentTicketEscalationView,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::ToolBarModule###130-Ticket::AgentTicketEscalation',
            Value => \%AgentTicketEscalationView
        );

        # Create test user.
        my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        );

        $UserObject->SetPreferences(
            UserID => $TestUserID,
            Key    => 'UserToolBar',
            Value  => 1,
        );

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # click on tool bar AgentTicketEscalationView
        $Selenium->find_element("//a[contains(\@title, \'Escalation view:\' )]")->VerifiedClick();

        # verify that test is on the correct screen
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        my $ExpectedURL = "${ScriptAlias}index.pl?Action=AgentTicketEscalationView";

        $Self->True(
            index( $Selenium->get_current_url(), $ExpectedURL ) > -1,
            "ToolBar AgentTicketEscalationView shortcut - success",
        );
    }
);

1;
