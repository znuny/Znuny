# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Enable TicketOverViewPageShown preference.
        for my $View (qw( Small Medium Preview )) {

            my %TicketOverViewPageShown = (
                Active          => "1",
                PreferenceGroup => "Miscellaneous",
                DataSelected    => "25",
                Key             => "Ticket limit per page for Ticket Overview \"$View\"",
                Label           => "Ticket Overview \"$View\" Limit",
                Module          => "Kernel::Output::HTML::Preferences::Generic",
                PrefKey         => "UserTicketOverview" . $View . "PageShown",
                Prio            => "8000",
                Data            => {
                    "10" => "10",
                    "15" => "15",
                    "20" => "20",
                    "25" => "25",
                    "30" => "30",
                    "35" => "35",
                },
            );

            my $Key = "PreferencesGroups###TicketOverview" . $View . "PageShown";
            $HelperObject->ConfigSettingChange(
                Key   => $Key,
                Value => \%TicketOverViewPageShown,
            );

            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => $Key,
                Value => \%TicketOverViewPageShown,
            );
        }

        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Go to agent preferences.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentPreferences;Subaction=Group;Group=Miscellaneous");

        # Create test params.
        my @Tests = (
            {
                Name  => 'Overview Refresh Time',
                ID    => 'UserRefreshTime',
                Value => '5',
            },
            {
                Name  => 'Ticket Overview "Small" Limit',
                ID    => 'UserTicketOverviewSmallPageShown',
                Value => '10',
            },
            {
                Name  => 'Ticket Overview "Medium" Limit',
                ID    => 'UserTicketOverviewMediumPageShown',
                Value => '10',
            },
            {
                Name  => 'Ticket Overview "Preview" Limit',
                ID    => 'UserTicketOverviewPreviewPageShown',
                Value => '10',
            },
            {
                Name  => 'Screen after new ticket',
                ID    => 'UserCreateNextMask',
                Value => 'AgentTicketZoom',
            },

        );

        # Update generic preferences.
        # Generic preference modules set NeedsReload, so a successful save reloads the page
        # before the success icon stays visible.
        for my $Test (@Tests) {

            $Selenium->InputFieldValueSet(
                Element => "#$Test->{ID}",
                Value   => $Test->{Value},
            );

            $Selenium->execute_script('window.Core.App.PageLoadComplete = false;');
            $Selenium->execute_script(
                "\$('#$Test->{ID}').closest('.WidgetSimple').find('.SettingUpdateBox').find('button').trigger('click');"
            );
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete',
            );

            $Self->Is(
                $Selenium->execute_script("return \$('#$Test->{ID}').val();"),
                $Test->{Value},
                "Preference $Test->{Name} saved.",
            );
        }
    }
);

1;
