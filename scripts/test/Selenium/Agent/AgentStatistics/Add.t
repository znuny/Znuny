# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

        my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
        my $SLAObject     = $Kernel::OM->Get('Kernel::System::SLA');
        my $StatsObject   = $Kernel::OM->Get('Kernel::System::Stats');
        my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

        my $Success = $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 1,
        );

        my @ServiceIDs;
        my @SLAIDs;

        # Add test services and SLAs.
        for ( 1 .. 5 ) {
            my $ServiceID = $ServiceObject->ServiceAdd(
                Name    => "TestService - " . $HelperObject->GetRandomID(),
                ValidID => 1,
                UserID  => 1,
            );
            $Self->True(
                $ServiceID,
                "Service $ServiceID has been created.",
            );

            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => '<DEFAULT>',
                ServiceID         => $ServiceID,
                Active            => 1,
                UserID            => 1,
            );
            push @ServiceIDs, $ServiceID;

            my $SLAID = $SLAObject->SLAAdd(
                Name    => "TestSLA - " . $HelperObject->GetRandomID(),
                ValidID => 1,
                UserID  => 1,
            );
            $Self->True(
                $SLAID,
                "SLA $SLAID has been created.",
            );
            push @SLAIDs, $SLAID;

        }

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users', 'stats' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Check add statistics screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Add");

        for my $Statistics (qw(DynamicMatrix DynamicList Static)) {
            $Selenium->WaitFor(
                JavaScript =>
                    "return typeof(\$) === 'function' && \$('a[data-statistic-preselection=$Statistics]').length;"
            );
            $Self->True(
                $Selenium->execute_script("return \$('a[data-statistic-preselection=$Statistics]').length;"),
                "There is a link for adding '$Statistics' statistics",
            );
        }

        my @Tests = (
            {
                Title            => 'Statistic DynamicMatrix' . $HelperObject->GetRandomID(),
                Object           => 'Kernel::System::Stats::Dynamic::Ticket',
                Type             => 'DynamicMatrix',
                XAxis            => 'XAxisServiceIDs',
                YAxis            => 'YAxisSLAIDs',
                RestrictionID    => 'RestrictionsQueueIDs',
                Restrictionvalue => 3,
            },
            {
                Title             => 'Statistic DynamicMatrix' . $HelperObject->GetRandomID(),
                Object            => 'Kernel::System::Stats::Dynamic::Ticket',
                Type              => 'DynamicMatrix',
                XAxis             => 'XAxisCreateTime',
                YAxis             => 'YAxisSLAIDs',
                RestrictionID     => 'RestrictionsQueueIDs',
                Restrictionvalue  => 3,
                SelectedTimeField => 1,
            },
            {
                Title            => 'Statistic - TicketAccountedTime' . $HelperObject->GetRandomID(),
                Object           => 'Kernel::System::Stats::Dynamic::TicketAccountedTime',
                Type             => 'DynamicMatrix',
                XAxis            => 'XAxisKindsOfReporting',
                YAxis            => 'YAxisSLAIDs',
                RestrictionID    => 'RestrictionsServiceIDs',
                Restrictionvalue => $ServiceIDs[0],
            },
            {
                Title            => 'Statistic - TicketSolutionResponseTime' . $HelperObject->GetRandomID(),
                Object           => 'Kernel::System::Stats::Dynamic::TicketSolutionResponseTime',
                Type             => 'DynamicMatrix',
                XAxis            => 'XAxisKindsOfReporting',
                YAxis            => 'YAxisSLAIDs',
                RestrictionID    => 'RestrictionsServiceIDs',
                Restrictionvalue => $ServiceIDs[0],
            },
            {
                Title              => 'Statistic - TicketList' . $HelperObject->GetRandomID(),
                Object             => 'Kernel::System::Stats::Dynamic::TicketList',
                Type               => 'DynamicList',
                YAxis              => 'YAxisOrderBy',
                OrderBy            => 'TicketNumber',
                RestrictionID      => 'RestrictionsServiceIDs',
                Restrictionvalue   => $ServiceIDs[0],
                CheckInvalidFormat => 1,
            },
        );

        my @StatsFormatDynamicMatrix = (
            {
                Format         => 'Print',
                PreviewContent => 'PreviewContentPrint',
            },
            {
                Format         => 'D3::StackedAreaChart',
                PreviewContent => 'PreviewContentD3StackedAreaChart',

            },
            {
                Format         => 'D3::LineChart',
                PreviewContent => 'PreviewContentD3LineChart',
            },
            {
                Format         => 'D3::BarChart',
                PreviewContent => 'PreviewContentD3BarChart',
            },
        );

        my @StatsFormatDynamicList = (
            {
                Format         => 'Print',
                PreviewContent => 'PreviewContentPrint',
            },
        );

        # Add new statistics.
        for my $StatsData (@Tests) {

            # Go to add statistics screen.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Add");

            $Selenium->find_element("//a[contains(\@data-statistic-preselection, \'$StatsData->{Type}\' )]")->click();
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Title").length;' );

            # Check title of the page (see bug #13942)
            $Self->Is(
                $Selenium->get_title(),
                'Add New Statistic - Statistics - ' . $ConfigObject->Get('ProductName'),
                "Check title of the page",
            );

            # Set values for new statistics - General Specifications.
            $Selenium->find_element( "#Title", 'css' )->send_keys( $StatsData->{Title} );
            my $Description = 'Description ' . $StatsData->{Title};
            $Selenium->find_element( "#Description", 'css' )->send_keys($Description);
            $Selenium->InputFieldValueSet(
                Element => '#ObjectModule',
                Value   => $StatsData->{Object},
            );
            $Selenium->find_element("//button[\@value='Save'][\@type='submit']")->VerifiedClick();

            # Check X-axis configuration dialog.
            $Selenium->VerifiedRefresh();
            $Selenium->execute_script('$(".EditXAxis").click();');
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $(".Dialog.Modal").length && $("#DialogButton1").length;'
            );

            if ( $StatsData->{Object} ne 'Kernel::System::Stats::Dynamic::TicketList' ) {
                $Selenium->InputFieldValueSet(
                    Element => '#EditDialog select',
                    Value   => $StatsData->{XAxis},
                );

                # Set invalid date for CreateTime (31.06.).
                # See bug #13938 (https://bugs.otrs.org/show_bug.cgi?id=13938).
                if ( $StatsData->{XAxis} eq 'XAxisCreateTime' ) {
                    $Selenium->InputFieldValueSet(
                        Element => '#XAxisCreateTimeStopMonth',
                        Value   => 6,
                    );
                    $Selenium->InputFieldValueSet(
                        Element => '#XAxisCreateTimeStopDay',
                        Value   => 31,
                    );
                }
            }
            $Selenium->find_element( "#DialogButton1", 'css' )->click();
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Dialog.Modal").length;' );

            # Check error message if there is set wrong invalid date for x-axis
            if ( $StatsData->{XAxis} eq 'XAxisCreateTime' ) {
                $Self->Is(
                    $Selenium->execute_script("return \$('.Preview p.Error').text().trim();"),
                    "CreateTime: The selected date is not valid.",
                    "There is message for invalid date for CreateTime",
                );

                $Selenium->find_element( ".EditXAxis", 'css' )->click();
                $Selenium->WaitFor(
                    JavaScript =>
                        'return typeof($) === "function" && $(".Dialog.Modal").length && $("#DialogButton1").length;'
                );

                $Selenium->InputFieldValueSet(
                    Element => '#XAxisCreateTimeStopMonth',
                    Value   => 12,
                );
                $Selenium->InputFieldValueSet(
                    Element => '#XAxisCreateTimeStopDay',
                    Value   => 31,
                );

                $Selenium->find_element( "#DialogButton1", 'css' )->click();
                $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Dialog.Modal").length;' );
            }

            # Check Y-axis configuration dialog.
            $Selenium->VerifiedRefresh();
            $Selenium->execute_script('$(".EditYAxis").click();');

            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $(".Dialog.Modal").length;' );
            $Selenium->WaitFor( JavaScript => 'return $("#EditDialog select").length && $("#DialogButton1").length;' );

            $Selenium->InputFieldValueSet(
                Element => '#EditDialog select',
                Value   => $StatsData->{YAxis},
            );

            if ( $StatsData->{Object} eq 'Kernel::System::Stats::Dynamic::TicketList' ) {

                # Wait for load selected YAxis.
                $Selenium->WaitFor(
                    JavaScript => "return typeof(\$) === 'function' && \$('#$StatsData->{YAxis}').length;"
                );

                # Select order by option.
                $Selenium->InputFieldValueSet(
                    Element => "#EditDialog #$StatsData->{YAxis}",
                    Value   => $StatsData->{OrderBy},
                );
            }
            $Selenium->find_element( "#DialogButton1", 'css' )->click();
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Dialog.Modal").length;' );

            # Check Restrictions configuration dialog.
            $Selenium->VerifiedRefresh();
            $Selenium->execute_script('$(".EditRestrictions").click();');
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $(".Dialog.Modal").length && $("#EditDialog select").length;'
            );

            $Selenium->InputFieldValueSet(
                Element => '#EditDialog select',
                Value   => $StatsData->{RestrictionID},
            );

            # Wait for load selected Restriction.
            $Selenium->WaitFor(
                JavaScript => "return typeof(\$) === 'function' && \$('#$StatsData->{RestrictionID}').length;"
            );

            # Add restriction.
            $Selenium->InputFieldValueSet(
                Element => "#EditDialog #$StatsData->{RestrictionID}",
                Value   => $StatsData->{Restrictionvalue},
            );

            $Selenium->find_element( "#DialogButton1", 'css' )->click();
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Dialog.Modal").length;' );

            sleep 2;

            # Change preview format to Print.
            $Selenium->execute_script("\$('button[data-format=Print]').click();");
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#PreviewContentPrint").css("display") === "block";'
            );

            $Self->True(
                $Selenium->execute_script("return \$('#PreviewContentPrint').css('display');") eq 'block',
                "Print format is displayed",
            );

            my @StatsFormat = @StatsFormatDynamicMatrix;

            if ( $StatsData->{Type} eq 'DynamicList' ) {
                @StatsFormat = @StatsFormatDynamicList;
            }

            for my $StatsFormat (@StatsFormat) {

                # Change preview format.
                $Selenium->execute_script("\$('button[data-format=\"$StatsFormat->{Format}\"]').click();");
                $Selenium->WaitFor(
                    JavaScript =>
                        "return typeof(\$) === 'function' && \$('#$StatsFormat->{PreviewContent}').css('display') === 'block';"
                );

                $Self->True(
                    $Selenium->execute_script("return \$('#$StatsFormat->{PreviewContent}').css('display');") eq
                        'block',
                    "StackedArea format is displayed",
                );
            }

            # Check the options for the cache field in the general section.
            if ( $StatsData->{SelectedTimeField} ) {

                $Self->True(
                    $Selenium->execute_script(
                        "return \$('#Cache option[value=\"1\"]').val() == 1 && \$('#Cache option[value=\"1\"]')[0].innerHTML == 'Yes';"
                    ),
                    'Found element "Yes" in Cache the select field.',
                );
            }
            else {

                $Self->False(
                    $Selenium->execute_script("return \$('#Cache option[value=\"1\"]').val() == 1;"),
                    'Found no element "Yes" in the Cache select field.',
                );
            }

            # Save and finish test statistics.
            $Selenium->find_element( "#SaveAndFinish", 'css' )->VerifiedClick();

            sleep 2;

            # Sort decreasing by StatsID.
            $Selenium->VerifiedGet(
                "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Overview;Direction=DESC;OrderBy=ID;StartHit=1"
            );

            # Get stats IDs.
            my $StatsIDs = $StatsObject->GetStatsList(
                AccessRw => 1,
                UserID   => 1,
            );

            my $Count       = scalar @{$StatsIDs};
            my $StatsIDLast = $StatsIDs->[ $Count - 1 ];

            # Check for created stats on overview screen.
            $Self->True(
                index( $Selenium->get_page_source(), $StatsData->{Title} ) > -1,
                "Test statistic is created - $StatsData->{Title} "
            );

            # Check handling of invalid formats in the edit screen.
            if ( $StatsData->{CheckInvalidFormat} ) {
                my $Stat = $StatsObject->StatsGet(
                    StatID => $StatsIDLast,
                );

                # Prepare stat data for an update.
                my %Data = (
                    Title                 => $Stat->{Title},
                    Description           => $Stat->{Description},
                    Valid                 => $Stat->{Valid},
                    TimeZone              => $Stat->{TimeZone},
                    SumRow                => $Stat->{SumRow},
                    SumCol                => $Stat->{SumCol},
                    Cache                 => $Stat->{Cache},
                    ShowAsDashboardWidget => $Stat->{ShowAsDashboardWidget},
                    Permission            => $Stat->{Permission},
                    Format                => [

                        # Invalid format.
                        'D3::BarChart "><br />',
                    ],
                );

                my $Success = $StatsObject->StatsUpdate(
                    StatID => $StatsIDLast,
                    Hash   => \%Data,
                    UserID => 1,
                );
                $Self->True(
                    $Success // 0,
                    'StatsUpdate() - add invalid format'
                );

                # Go to the stat edit screen.
                $Selenium->VerifiedGet(
                    "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Edit;StatID=$StatsIDLast"
                );

                # Check if the button contains expected format attribute value.
                $Self->Is(
                    $Selenium->execute_script('return $("button.SwitchPreviewFormat").data("format")') // '',
                    'D3::BarChart "><br />',
                    'Preview button format attribute'
                );

                # Go back to the stats overview screen.
                $Selenium->VerifiedGet(
                    "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Overview;Direction=DESC;OrderBy=ID;StartHit=1"
                );
            }

            # Delete created test statistics.
            $Selenium->execute_script('window.Core.App.PageLoadComplete = false;');
            $Selenium->find_element(
                "//a[contains(\@href, \'Action=AgentStatistics;Subaction=DeleteAction;StatID=$StatsIDLast\' )]"
            )->click();

            $Selenium->WaitFor( AlertPresent => 1 );
            sleep 1;
            $Selenium->accept_alert();
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
            );

            $Self->True(
                $Selenium->execute_script(
                    "return !\$('a[href*=\"Action=AgentStatistics;Subaction=Edit;StatID=$StatsIDLast\"]').length;"
                ),
                "StatsData statistic is deleted - $StatsData->{Title} "
            ) || die;
        }

        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # Clean up test data.
        for my $SLAID (@SLAIDs) {
            my $Success = $DBObject->Do(
                SQL => "DELETE FROM service_sla WHERE sla_id = $SLAID",
            );
            $Self->True(
                $Success,
                "ServiceSla - $SLAID",
            );

            $Success = $DBObject->Do(
                SQL => "DELETE FROM sla WHERE id = $SLAID",
            );
            $Self->True(
                $Success,
                "SLADelete - $SLAID",
            );
        }

        for my $ServiceID (@ServiceIDs) {
            my $Success = $DBObject->Do(
                SQL => "DELETE FROM service_customer_user WHERE service_id = $ServiceID",
            );
            $Self->True(
                $Success,
                "ServiceCustomerUser deleted - $ServiceID",
            );

            $Success = $DBObject->Do(
                SQL => "DELETE FROM service WHERE id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Deleted Service - $ServiceID",
            );
        }

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure the cache is correct.
        for my $Cache (
            qw (Service SLA Stats)
            )
        {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
