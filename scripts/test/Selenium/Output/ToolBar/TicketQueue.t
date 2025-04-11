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

        # enable tool bar AgentTicketQueue
        my %AgentTicketQueue = (
            AccessKey => 'q',
            Action    => 'AgentTicketQueue',
            Block     => 'ToolBarOverviews',
            CssClass  => 'QueueView',
            Icon      => 'fa fa-folder',
            Link      => 'Action=AgentTicketQueue',
            Module    => 'Kernel::Output::HTML::ToolBar::Link',
            Name      => 'Queue view',
            Priority  => '1010010',
        );

        $HelperObject->ConfigSettingChange(
            Key   => 'Frontend::ToolBarModule###110-Ticket::AgentTicketQueue',
            Value => \%AgentTicketQueue,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::ToolBarModule###110-Ticket::AgentTicketQueue',
            Value => \%AgentTicketQueue
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

        # click on tool bar AgentTicketQueue
        $Selenium->find_element("//a[contains(\@title, \'Queue view:\' )]")->VerifiedClick();

        # verify that test is on the correct screen
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        my $ExpectedURL = "${ScriptAlias}index.pl?Action=AgentTicketQueue";

        $Self->True(
            index( $Selenium->get_current_url(), $ExpectedURL ) > -1,
            "ToolBar AgentTicketQueue shortcut - success",
        );
    }
);

1;
