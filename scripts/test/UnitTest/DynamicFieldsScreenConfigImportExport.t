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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject      = $Kernel::OM->Get('Kernel::System::SysConfig');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Create dynamic fields to test export
my @DynamicFieldConfigs = (
    {
        Name       => 'DynField0' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 1',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => 'DynField1' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 2',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => 'DynField2' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 3',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => 'DynField3' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 4',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => 'DynField4' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 5',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => 'DynField5' . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 6',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
);

my $DynamicFieldsCreated = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFieldConfigs);

$Self->True(
    scalar $DynamicFieldsCreated,
    'Dynamic fields must have been created successfully.',
);

# Test export
my @Tests = (
    {
        Name       => 'Import and Export one DynamicField with one DynamicFieldScreens.',
        ImportData => {
            $DynamicFieldConfigs[0]->{Name} => {
                'Ticket::Frontend::AgentTicketZoom###DynamicField' => 1,
            },
        },
    },
    {
        Name       => 'Import and Export one DynamicField with one DefaultColumnsScreens.',
        ImportData => {
            $DynamicFieldConfigs[1]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 2,
                'DashboardBackend###0100-TicketPendingReminder'                            => 0,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'DashboardBackend###0120-TicketNew'                                        => 0,
            },
        },
    },
    {
        Name       => 'Import and Export one DynamicField with all possible configs.',
        ImportData => {
            $DynamicFieldConfigs[2]->{Name} => {
                'Ticket::Frontend::AgentTicketClose###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketCompose###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketEmail###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketEmailOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketForward###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketFreeText###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketMove###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketNote###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketOwner###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPending###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketPhone###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPhoneInbound###DynamicField'                 => 1,
                'Ticket::Frontend::AgentTicketPhoneOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketPrint###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPriority###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketResponsible###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketSearch###DynamicField'                       => 1,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 1,
                'Ticket::Frontend::CustomerTicketMessage###DynamicField'                   => 1,
                'Ticket::Frontend::CustomerTicketPrint###DynamicField'                     => 1,
                'Ticket::Frontend::CustomerTicketSearch###DynamicField'                    => 1,
                'Ticket::Frontend::CustomerTicketZoom###DynamicField'                      => 1,
                'Ticket::Frontend::OverviewMedium###DynamicField'                          => 1,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 1,
                'Ticket::Frontend::OverviewSmall###DynamicField'                           => 1,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField'            => 1,
                'Ticket::Frontend::AgentTicketStatusView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'                      => 1,
                'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns'            => 1,
                'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'                  => 1,
                'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns'             => 1,
                'Ticket::Frontend::AgentTicketSearch###DefaultColumns'                     => 1,
                'Ticket::Frontend::AgentTicketService###DefaultColumns'                    => 1,
                'DashboardBackend###0100-TicketPendingReminder'                            => 1,
                'DashboardBackend###0110-TicketEscalation'                                 => 1,
                'DashboardBackend###0120-TicketNew'                                        => 1,
                'DashboardBackend###0130-TicketOpen'                                       => 1,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 1,
                'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => 1,
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => 1,
            },
        },
    },
    {
        Name       => 'Import and Export multiple DynamicFields with multiple screens.',
        ImportData => {
            $DynamicFieldConfigs[3]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 1,
                'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => 1,
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => 1,
                'DashboardBackend###0100-TicketPendingReminder'                            => 1,
                'DashboardBackend###0110-TicketEscalation'                                 => 1,
                'DashboardBackend###0120-TicketNew'                                        => 1,
                'DashboardBackend###0130-TicketOpen'                                       => 1,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns'             => 1,
                'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'                      => 1,
                'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns'            => 1,
                'Ticket::Frontend::AgentTicketSearch###DefaultColumns'                     => 1,
                'Ticket::Frontend::AgentTicketService###DefaultColumns'                    => 1,
                'Ticket::Frontend::AgentTicketStatusView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'                  => 1,
                'Ticket::Frontend::AgentTicketClose###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketCompose###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketEmail###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketEmailOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketForward###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketFreeText###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketMove###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketNote###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketOwner###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPending###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketPhone###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPhoneInbound###DynamicField'                 => 1,
                'Ticket::Frontend::AgentTicketPhoneOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketPrint###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPriority###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketResponsible###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketSearch###DynamicField'                       => 1,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField'            => 1,
                'Ticket::Frontend::CustomerTicketMessage###DynamicField'                   => 1,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 1,
                'Ticket::Frontend::CustomerTicketPrint###DynamicField'                     => 1,
                'Ticket::Frontend::CustomerTicketSearch###DynamicField'                    => 1,
                'Ticket::Frontend::CustomerTicketZoom###DynamicField'                      => 1,
                'Ticket::Frontend::OverviewMedium###DynamicField'                          => 1,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 1,
                'Ticket::Frontend::OverviewSmall###DynamicField'                           => 1
            },
            $DynamicFieldConfigs[4]->{Name} => {
                'Ticket::Frontend::AgentTicketClose###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketCompose###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketEmail###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketEmailOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketForward###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketFreeText###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketMove###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketNote###DynamicField'                         => 1,
                'Ticket::Frontend::AgentTicketOwner###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPending###DynamicField'                      => 1,
                'Ticket::Frontend::AgentTicketPhone###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPhoneInbound###DynamicField'                 => 1,
                'Ticket::Frontend::AgentTicketPhoneOutbound###DynamicField'                => 1,
                'Ticket::Frontend::AgentTicketPrint###DynamicField'                        => 1,
                'Ticket::Frontend::AgentTicketPriority###DynamicField'                     => 1,
                'Ticket::Frontend::AgentTicketResponsible###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketSearch###DynamicField'                       => 1,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 1,
                'Ticket::Frontend::CustomerTicketMessage###DynamicField'                   => 1,
                'Ticket::Frontend::CustomerTicketPrint###DynamicField'                     => 1,
                'Ticket::Frontend::CustomerTicketSearch###DynamicField'                    => 1,
                'Ticket::Frontend::CustomerTicketZoom###DynamicField'                      => 1,
                'Ticket::Frontend::OverviewMedium###DynamicField'                          => 1,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 1,
                'Ticket::Frontend::OverviewSmall###DynamicField'                           => 1,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField'            => 1,
                'Ticket::Frontend::AgentTicketStatusView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'                      => 1,
                'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns'            => 1,
                'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'                  => 1,
                'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns'             => 1,
                'Ticket::Frontend::AgentTicketSearch###DefaultColumns'                     => 1,
                'Ticket::Frontend::AgentTicketService###DefaultColumns'                    => 1,
                'DashboardBackend###0100-TicketPendingReminder'                            => 1,
                'DashboardBackend###0110-TicketEscalation'                                 => 1,
                'DashboardBackend###0120-TicketNew'                                        => 1,
                'DashboardBackend###0130-TicketOpen'                                       => 1,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 1,
                'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => 1,
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => 1,
            },
            $DynamicFieldConfigs[5]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 2,
                'DashboardBackend###0100-TicketPendingReminder'                            => 0,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'DashboardBackend###0120-TicketNew'                                        => 0,
                'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'                      => 2,
                'Ticket::Frontend::AgentTicketPhone###DynamicField'                        => 0,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 1,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 2,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 0,
            },
        },
    },
);

my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

TEST:
for my $Test (@Tests) {

    my $StartSystemTime = $TimeObject->SystemTime();
    my $CurrentSystemTime;
    my $TimeDiff;

    $Self->True(
        $Test->{Name},
        "$Test->{Name}",
    );

    my @DynamicFields = sort keys %{ $Test->{ImportData} };

    $Self->True(
        $Test->{Name},
        "Start - _DynamicFieldsScreenConfigExport",
    );

    my %Export = $ZnunyHelperObject->_DynamicFieldsScreenConfigExport(
        DynamicFields => \@DynamicFields,
    );

    for my $DynamicField ( sort keys %{ $Test->{ImportData} } ) {

        $Self->False(
            $Export{$DynamicField},
            "ScreenConfig for '$DynamicField' is not defined.",
        );
    }

    $CurrentSystemTime = $TimeObject->SystemTime();
    $TimeDiff          = $CurrentSystemTime - $StartSystemTime;

    $Self->True(
        $Test->{Name},
        "End - _DynamicFieldsScreenConfigExport - $TimeDiff",
    );

    $StartSystemTime = $TimeObject->SystemTime();

    $Self->True(
        $Test->{Name},
        "Start - _DynamicFieldsScreenConfigImport",
    );

    my $Import = $ZnunyHelperObject->_DynamicFieldsScreenConfigImport(
        Config => $Test->{ImportData},
    );

    $CurrentSystemTime = $TimeObject->SystemTime();
    $TimeDiff          = $CurrentSystemTime - $StartSystemTime;

    $Self->True(
        $Test->{Name},
        "End - _DynamicFieldsScreenConfigImport - $TimeDiff",
    );

    %Export = $ZnunyHelperObject->_DynamicFieldsScreenConfigExport(
        DynamicFields => \@DynamicFields,
    );

    DYNAMICFIELD:
    for my $DynamicField ( sort keys %{ $Test->{ImportData} } ) {

        $Self->True(
            $Export{$DynamicField},
            "ScreenConfig for '$DynamicField' is defined.",
        );

        next DYNAMICFIELD if !$Export{$DynamicField};

        $Self->IsDeeply(
            $Export{$DynamicField},
            $Test->{ImportData}->{$DynamicField},
            "Import and export for '$DynamicField' was successful .",
        );
    }
}

1;
