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

        # enable tool bar AgentTicketPhone
        my %AgentTicketPhone = (
            AccessKey => "",
            Action    => "AgentTicketPhone",
            Block     => "ToolBarActions",
            CssClass  => "PhoneTicket",
            Icon      => "fa fa-phone",
            Link      => "Action=AgentTicketPhone",
            Module    => "Kernel::Output::HTML::ToolBar::Link",
            Name      => "New phone ticket",
            Priority  => "1020010",
        );

        $HelperObject->ConfigSettingChange(
            Key   => 'Frontend::ToolBarModule###140-Ticket::AgentTicketPhone',
            Value => \%AgentTicketPhone,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::ToolBarModule###140-Ticket::AgentTicketPhone',
            Value => \%AgentTicketPhone
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

        # click on tool bar AgentTicketPhone
        $Selenium->find_element("//a[contains(\@title, \'New phone ticket:\' )]")->VerifiedClick();

        # verify that test is on the correct screen
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        my $ExpectedURL = "${ScriptAlias}index.pl?Action=AgentTicketPhone";

        $Self->True(
            index( $Selenium->get_current_url(), $ExpectedURL ) > -1,
            "ToolBar AgentTicketPhone shortcut - success",
        );
    }
);

1;
