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

        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

        # enable tool bar AgentTicketStatus
        my %AgentTicketStatus = (
            AccessKey => 'S',
            Action    => 'AgentTicketStatusView',
            Block     => 'ToolBarOverviews',
            CssClass  => 'StatusView',
            Icon      => 'fa fa-list-ol',
            Link      => 'Action=AgentTicketStatusView',
            Module    => 'Kernel::Output::HTML::ToolBar::Link',
            Name      => 'Status view',
            Priority  => '1010020',
        );

        $HelperObject->ConfigSettingChange(
            Key   => 'Frontend::ToolBarModule###120-Ticket::AgentTicketStatus',
            Value => \%AgentTicketStatus,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::ToolBarModule###120-Ticket::AgentTicketStatus',
            Value => \%AgentTicketStatus
        );

        # create test user and login
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

        # click on tool bar AgentTicketStatus
        $Selenium->find_element("//a[contains(\@title, \'Status view:\' )]")->VerifiedClick();

        # verify that test is on the correct screen
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        my $ExpectedURL = "${ScriptAlias}index.pl?Action=AgentTicketStatusView";

        $Self->True(
            index( $Selenium->get_current_url(), $ExpectedURL ) > -1,
            "ToolBar AgentTicketStatus shortcut - success",
        );
    }
);

1;
