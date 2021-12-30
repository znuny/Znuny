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

use vars (qw($Self));

my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

my $SeleniumTest = sub {
    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

    my %TestUser = $SeleniumObject->AgentLogin(
        Groups   => [ 'admin', 'users' ],
        Language => 'de'
    );

    for my $Position (qw(MenuBar ToolBar Avatar)) {
        my $ElementClass = '.LastView' . $Position;

        my %PreferencesCheck = (
            UserLastViewsPosition => $Position,
            UserLastViewsTypes =>
                '["Admin","Agent","FAQ","Calendar","Customer","CustomerUser","Statistics","Appointment","TicketCreate","TicketOverview","Ticket"]',
        );

        for my $Preference ( sort keys %PreferencesCheck ) {
            $UserObject->SetPreferences(
                Key    => $Preference,
                Value  => $PreferencesCheck{$Preference},
                UserID => $TestUser{UserID},
            );

            my %Preferences = $UserObject->GetPreferences(
                UserID => $TestUser{UserID},
            );

            $Self->Is(
                $Preferences{$Preference},
                $PreferencesCheck{$Preference},
                "Preference: $Preference",
            );
        }

        my $TicketID = $HelperObject->TicketCreate();

        my $ArticleID = $HelperObject->ArticleCreate(
            TicketID => $TicketID,
        );

        $SeleniumObject->AgentInterface(
            Action      => 'AgentTicketZoom',
            TicketID    => $TicketID,
            WaitForAJAX => 0,
        );

        $SeleniumObject->AgentInterface(
            Action      => 'AgentDashboard',
            WaitForAJAX => 0,
        );

        if ( $Position eq 'Avatar' ) {
            $SeleniumObject->find_element( 'li.UserAvatar', 'css' )->click();
        }
        $SeleniumObject->ElementExists(
            Selector     => $ElementClass,
            SelectorType => 'css',
        );

        $Self->True(
            $SeleniumObject->find_element( $ElementClass, 'css' )->is_displayed(),
            "Menu: $Position is visible.",
        );
    }
};

$SeleniumObject->RunTest($SeleniumTest);

1;
