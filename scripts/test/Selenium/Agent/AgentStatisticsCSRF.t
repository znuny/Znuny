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

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $StatsObject  = $Kernel::OM->Get('Kernel::System::Stats');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'SessionCSRFProtection',
            Value => 1,
        );

        my $StatisticContent = $MainObject->FileRead(
            Location => $ConfigObject->Get('Home') . '/var/stats/Stats.NewTickets.en.xml',
        );
        my $StatID = $StatsObject->Import(
            Content => ${$StatisticContent},
            UserID  => 1,
        );
        $Self->True(
            $StatID,
            "Imported statistic StatID $StatID",
        );

        my $OriginalStat = $StatsObject->StatsGet(
            StatID => $StatID,
            UserID => 1,
        );
        my $OriginalTitle = $OriginalStat->{Title};

        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users', 'stats' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        my $StatsBefore = $StatsObject->GetStatsList(
            OrderBy   => 'StatID',
            Direction => 'ASC',
            UserID    => 1,
        );
        my $CountBefore = scalar @{$StatsBefore};

        $Selenium->get(
            "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=AddAction;Title=CVD-CSRF;Description=CVD-CSRF;ObjectModule=Kernel::System::Stats::Dynamic::Ticket;StatType=dynamic;Valid=1;Permission=3;Format=CSV"
        );

        my $AddPageSource = $Selenium->get_page_source();
        $Self->True(
            index( $AddPageSource, 'Challenge Token' ) > -1
                || index( $AddPageSource, 'Fatal Error' ) > -1,
            'AddAction without ChallengeToken shows a fatal/challenge-token error page',
        );

        my $StatsAfter = $StatsObject->GetStatsList(
            OrderBy   => 'StatID',
            Direction => 'ASC',
            UserID    => 1,
        );
        $Self->Is(
            scalar @{$StatsAfter},
            $CountBefore,
            'AddAction without ChallengeToken did not create a statistic',
        );

        $Selenium->get(
            "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=EditAction;StatID=$StatID;Title=CVD-CSRF-Overwrite;Description=CVD-CSRF;Valid=1;Permission=3;Format=CSV;ReturnToStatisticOverview=1"
        );

        my $EditPageSource = $Selenium->get_page_source();
        $Self->True(
            index( $EditPageSource, 'Challenge Token' ) > -1
                || index( $EditPageSource, 'Fatal Error' ) > -1,
            'EditAction without ChallengeToken shows a fatal/challenge-token error page',
        );

        my $StatAfterEdit = $StatsObject->StatsGet(
            StatID => $StatID,
            UserID => 1,
        );
        $Self->Is(
            $StatAfterEdit->{Title},
            $OriginalTitle,
            'EditAction without ChallengeToken did not change the statistic title',
        );

        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Edit;StatID=$StatID");

        # General Specification starts collapsed; expand it so Title is usable.
        $Selenium->execute_script(
            "\$('.WidgetSimple.Collapsed .WidgetAction.Toggle a').first().trigger('click');"
        );
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && !\$('#Title').closest('.WidgetSimple').hasClass('Collapsed');"
        );

        my $NewTitle = 'CSRF-Safe-' . $HelperObject->GetRandomID();
        $Selenium->find_element( '#Title',         'css' )->clear();
        $Selenium->find_element( '#Title',         'css' )->send_keys($NewTitle);
        $Selenium->find_element( '#SaveAndFinish', 'css' )->VerifiedClick();

        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && document.readyState === 'complete';"
        );

        my $StatAfterSave = $StatsObject->StatsGet(
            StatID => $StatID,
            UserID => 1,
        );
        $Self->Is(
            $StatAfterSave->{Title},
            $NewTitle,
            'Edit form with ChallengeToken still saves the statistic',
        );

        my $Success = $StatsObject->StatsDelete(
            StatID => $StatID,
            UserID => 1,
        );
        $Self->True(
            $Success,
            "StatisticID $StatID is deleted.",
        );
    }
);

1;
