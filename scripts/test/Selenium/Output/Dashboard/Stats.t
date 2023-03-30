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

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $CacheObject   = $Kernel::OM->Get('Kernel::System::Cache');
        my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Stats::Dashboard::Generate');
        my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
        my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
        my $StatsObject   = $Kernel::OM->Get('Kernel::System::Stats');
        my $UserObject    = $Kernel::OM->Get('Kernel::System::User');
        my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');

        # Disable all dashboard plugins.
        my $Config = $ConfigObject->Get('DashboardBackend');
        $HelperObject->ConfigSettingChange(
            Valid => 0,
            Key   => 'DashboardBackend',
            Value => \%$Config,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Stats::ExchangeAxis',
            Value => 1,
        );

        # Add at least one dashboard setting dashboard SysConfig so dashboard can be loaded.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0400-UserOnline',
            Value => {
                'Block'         => 'ContentSmall',
                'CacheTTLLocal' => '5',
                'Default'       => '1',
                'Description'   => '',
                'Filter'        => 'Agent',
                'Group'         => '',
                'IdleMinutes'   => '60',
                'Limit'         => '10',
                'Module'        => 'Kernel::Output::HTML::Dashboard::UserOnline',
                'ShowEmail'     => '0',
                'SortBy'        => 'UserFullname',
                'Title'         => 'Online'
            },
        );

        # Create test user.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users', 'stats' ],
        ) || die "Did not get test user";

        # Get test user ID.
        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        my $StatisticContent = $MainObject->FileRead(
            Location => $Selenium->{Home}
                . '/scripts/test/Selenium/Output/Dashboard/Stats.xml',
        );

        # Import test stats.
        my $TestStatID = $StatsObject->Import(
            Content => $StatisticContent,
            UserID  => $TestUserID,
        );
        $Self->True(
            $TestStatID,
            "Successfully imported StatID $TestStatID",
        );

        # Update test stats name and show as dashboard widget.
        my $TestStatsName = "SeleniumStats" . $HelperObject->GetRandomID();
        my $Update        = $StatsObject->StatsUpdate(
            StatID => $TestStatID,
            Hash   => {
                Title                 => $TestStatsName,
                ShowAsDashboardWidget => '1',
            },
            UserID => $TestUserID,
        );
        $Self->True(
            $Update,
            "Stats is updated - ID $TestStatID",
        );

        $TestStatID = sprintf( "%02d", $TestStatID );
        my $StatsWidgetID = "10$TestStatID-Stats";

        # Store invalid old-style time zone offset in user preferences for imported statistic.
        my $Success = $UserObject->SetPreferences(
            Key   => "UserDashboardStatsStatsConfiguration$StatsWidgetID",
            Value => $JSONObject->Encode(
                Data => {
                    TimeZone => '+2',    # old-style offset
                },
            ),
            UserID => $TestUserID,
        );

        # Login and go to dashboard.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # Enable stats widget on dashboard.
        my $StatsIDSelector = 100 . $TestStatID;
        my $StatsSelector   = 10 . $TestStatID . "-Stats";
        my $StatsInSettings = "Settings10" . $TestStatID . "-Stats";
        $Selenium->execute_script("\$('.SettingsWidget .Header a').click();");
        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('.SettingsWidget.Expanded').length;"
        );

        $Selenium->find_element( "#FilterAvailableWidgets", "css" )->send_keys($StatsIDSelector);
        sleep 1;

        $Selenium->find_element( "a[data-widget-name='$StatsSelector']", "css" )->click();

        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('li[data-widget-name=\"$StatsSelector\"]:visible').length;"
        );
        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('.SettingsWidget button:visible').length;"
        );

        $Selenium->execute_script("\$('.SettingsWidget button').trigger('click');");

        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('#Dashboard$StatsSelector-box:visible').length;"
        );

        my $ExitCode = $CommandObject->Execute();
        sleep 2;
        $Selenium->VerifiedRefresh();
        $Selenium->WaitFor(
            JavaScript => "return !\$('#Dashboard$TestStatID-Stats i').hasClass('fa-signal')",
        );
        $Selenium->WaitFor(
            JavaScript => "return \$('#GraphWidgetContainer10$TestStatID-Stats svg').length;",
        );

        $Self->Is(
            $Selenium->execute_script('return $(".nv-legend-text:contains(Misc)").length;'),
            1,
            "Legend entry for Misc queue found.",
        );

        # Expand stat widget settings.
        $Selenium->execute_script("\$('#Dashboard$StatsWidgetID-toggle').trigger('click');");

        # Verify time zone is set to system default.
        my $SelectedTimeZone = $Selenium->execute_script("return \$('#TimeZone').val();");
        $Self->Is(
            $SelectedTimeZone,
            $ConfigObject->Get('OTRSTimeZone'),
            'Default time zone'
        );

        # Exchange axis and check if it works.
        $Selenium->InputFieldValueSet(
            Element => '#ExchangeAxis',
            Value   => '1',
        );
        $Selenium->execute_script( "\$('#Dashboard$StatsWidgetID" . "_submit').trigger('click');" );
        sleep 1;

        $ExitCode = $CommandObject->Execute();
        sleep 2;
        $Selenium->VerifiedRefresh();
        $Selenium->WaitFor(
            JavaScript => "return !\$('#Dashboard$TestStatID-Stats i').hasClass('fa-signal')",
        );
        $Selenium->WaitFor(
            JavaScript => "return \$('#GraphWidgetContainer10$TestStatID-Stats svg').length;",
        );

        $Self->Is(
            $Selenium->execute_script('return $(".nv-legend-text:contains(open)").length;'),
            1,
            "Legend entry for open state found.",
        );

        # Change the language from the user to test the translations.
        $UserObject->SetPreferences(
            UserID => $TestUserID,
            Key    => 'UserLanguage',
            Value  => 'de',
        );
        sleep 1;

        $ExitCode = $CommandObject->Execute();
        sleep 2;
        $Selenium->VerifiedRefresh();
        $Selenium->WaitFor(
            JavaScript => "return !\$('#Dashboard$TestStatID-Stats i').hasClass('fa-signal');",
        );
        $Selenium->WaitFor(
            JavaScript => "return \$('#GraphWidgetContainer10$TestStatID-Stats svg').length;",
        );

        $Self->Is(
            $Selenium->execute_script('return $(".nv-legend-text:contains(offen)").length;'),
            1,
            "Legend entry for open state found.",
        );

        # Check if statistic PNG can be downloaded. See bug#14583.
        my $HashRef = $StatsObject->StatsGet(
            StatID             => $TestStatID,
            NoObjectAttributes => 1,
        );

        $Selenium->execute_script(
            "\$('#GraphWidgetLink10$TestStatID-Stats').closest('.ActionMenu').show();"
        );

        $Selenium->execute_script(
            "\$('#GraphWidgetLink10$TestStatID-Stats').find('.TriggerTooltip').click();"
        );

        $Selenium->find_element( "#GraphWidgetLink10$TestStatID-Stats a[download=\"$HashRef->{Title}\.png\"]", "css" )
            ->click();

        # TODO DENNY / JENS: add this code again but first check gui and forw. guys.
        #         # Check if href is created.
        #         $Self->Is(
        #             $Selenium->execute_script(
        #                 "return \$('#GraphWidgetLink10$TestStatID-Stats a[href*=\"data:image\/png\"]').length;"
        #             ),
        #             1,
        #             "Download link for png exists"
        #         );

        # Delete test stat.
        $Self->True(
            $StatsObject->StatsDelete(
                StatID => $TestStatID,
                UserID => $TestUserID,
            ),
            "Stats is deleted - ID $TestStatID",
        );

        # Make sure cache is correct.
        for my $Cache (qw( Stats Dashboard DashboardQueueOverview )) {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
