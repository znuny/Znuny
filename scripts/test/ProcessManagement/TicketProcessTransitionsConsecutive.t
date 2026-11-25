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

use Kernel::System::VariableCheck qw(IsHashRefWithData);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $RandomID = $HelperObject->GetRandomID();

my ( $TestUserLogin, $UserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
);

my $Activity = sub {
    my ( $Name, %Param ) = @_;

    return {
        Name       => $Name,
        EntityID   => $Name,
        CreateTime => '2026-01-01 00:00:00',
        ChangeTime => '2026-01-01 00:00:00',
        Config     => {
            Scope         => 'Process',
            ScopeEntityID => $Param{ScopeEntityID} || 'Process-Consecutive',
        },
        ActivityDialogs => [],
    };
};

my $Transition = sub {
    my ( $Name, %Param ) = @_;

    return {
        Name       => $Name,
        EntityID   => $Name,
        CreateTime => '2026-01-01 00:00:00',
        ChangeTime => '2026-01-01 00:00:00',
        Config     => {
            Condition => {
                '1' => {
                    Fields => {
                        State => {
                            Match => 'open',
                            Type  => 'String',
                        },
                    },
                    Type => 'and',
                },
            },
            ConditionLinking => 'and',
            Scope            => 'Process',
            ScopeEntityID    => $Param{ScopeEntityID} || 'Process-Consecutive',
        },
    };
};

my $ProcessName = "Consecutive $RandomID";

my $ProcessData = {
    Activities => {
        'Activity-Start'  => $Activity->("Start $RandomID"),
        'Activity-Middle' => $Activity->("Middle $RandomID"),
        'Activity-End'    => $Activity->("End $RandomID"),
    },
    ActivityDialogs   => {},
    TransitionActions => {},
    Transitions       => {
        'Transition-One' => $Transition->("ToMiddle $RandomID"),
        'Transition-Two' => $Transition->("ToEnd $RandomID"),
    },
    Process => {
        Name              => $ProcessName,
        EntityID          => 'Process-Consecutive',
        State             => 'Active',
        StateEntityID     => 'S1',
        Activities        => [ 'Activity-Start', 'Activity-Middle', 'Activity-End' ],
        Transitions       => [ 'Transition-One', 'Transition-Two' ],
        TransitionActions => [],
        Layout            => {},
        Config            => {
            Description   => 'Consecutive transitions',
            StartActivity => 'Activity-Start',
            Path          => {
                'Activity-Start' => {
                    'Transition-One' => {
                        ActivityEntityID => 'Activity-Middle',
                        TransitionAction => [],
                    },
                },
                'Activity-Middle' => {
                    'Transition-Two' => {
                        ActivityEntityID => 'Activity-End',
                        TransitionAction => [],
                    },
                },
                'Activity-End' => {},
            },
        },
    },
};

my $DBProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

my $ProcessContent = $YAMLObject->Dump( Data => $ProcessData );

my %ProcessImport = $DBProcessObject->ProcessImport(
    Content => $ProcessContent,
    UserID  => $UserID,
);

$Self->True(
    $ProcessImport{Success},
    "ProcessImport() succeeded ($ProcessImport{Message})",
);

my $Dump = $DBProcessObject->ProcessDump(
    ResultType => 'HASH',
    UserID     => $UserID,
);

$Self->True(
    IsHashRefWithData($Dump),
    'ProcessDump() returned the deployed configuration',
);

my %ConfigKey = (
    Process          => 'Process',
    Activity         => 'Process::Activity',
    ActivityDialog   => 'Process::ActivityDialog',
    Transition       => 'Process::Transition',
    TransitionAction => 'Process::TransitionAction',
    State            => 'Process::State',
);

for my $DumpKey ( sort keys %ConfigKey ) {
    $HelperObject->ConfigSettingChange(
        Valid => 1,
        Key   => $ConfigKey{$DumpKey},
        Value => $Dump->{$DumpKey},
    );
}

my ($ProcessEntityID) = grep { $Dump->{Process}->{$_}->{Name} eq $ProcessName } keys %{ $Dump->{Process} };
my $ProcessConfig = $Dump->{Process}->{$ProcessEntityID};

$Self->True(
    IsHashRefWithData($ProcessConfig),
    'Imported process is part of the dumped configuration',
);

my $ActivityStart   = $ProcessConfig->{StartActivity};
my ($TransitionOne) = keys %{ $ProcessConfig->{Path}->{$ActivityStart} };
my $ActivityMiddle  = $ProcessConfig->{Path}->{$ActivityStart}->{$TransitionOne}->{ActivityEntityID};
my ($TransitionTwo) = keys %{ $ProcessConfig->{Path}->{$ActivityMiddle} };
my $ActivityEnd     = $ProcessConfig->{Path}->{$ActivityMiddle}->{$TransitionTwo}->{ActivityEntityID};

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::EventModulePost###9800-TicketProcessTransitions',
    Value => {
        Event       => '',
        Module      => 'Kernel::System::Ticket::Event::TicketProcessTransitions',
        Transaction => 0,
    },
);

# The transition limit notice is only written if transition debugging is enabled.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'ProcessManagement::Transition::Debug::Enabled',
    Value => 1,
);

my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $ProcessIDDynamicField = $DynamicFieldObject->DynamicFieldGet(
    Name => $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID'),
);
my $ActivityIDDynamicField = $DynamicFieldObject->DynamicFieldGet(
    Name => $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID'),
);

my $ActivityFieldName = $ActivityIDDynamicField->{Name};

my $ActivityHistoryCount = sub {
    my ($TicketID) = @_;

    my @History = $TicketObject->HistoryGet(
        TicketID => $TicketID,
        UserID   => $UserID,
    );

    return scalar grep {
        ( $_->{HistoryType} // '' ) eq 'TicketDynamicFieldUpdate'
            && ( $_->{Name} // '' ) =~ m{%%FieldName%%\Q$ActivityFieldName\E%%}
    } @History;
};

my $ActivityForMaxTransitionsPerRequest = sub {
    my (%Param) = @_;

    my $EnrolledProcessEntityID  = $Param{ProcessEntityID}  || $ProcessEntityID;
    my $EnrolledActivityEntityID = $Param{ActivityEntityID} || $ActivityStart;

    $HelperObject->ConfigSettingChange(
        Valid => 1,
        Key   => 'Process::Transition::MaxTransitionsPerRequest',
        Value => $Param{MaxTransitionsPerRequest},
    );

    my $TicketID = $TicketObject->TicketCreate(
        Title        => "Consecutive $RandomID $Param{MaxTransitionsPerRequest}",
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => '123465',
        CustomerUser => 'customer@example.com',
        OwnerID      => $UserID,
        UserID       => $UserID,
    );

    $Self->True(
        $TicketID,
        "TicketCreate() for MaxTransitionsPerRequest $Param{MaxTransitionsPerRequest}",
    );

    my $ProcessSet = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $ProcessIDDynamicField,
        ObjectID           => $TicketID,
        Value              => $EnrolledProcessEntityID,
        UserID             => $UserID,
    );
    my $ActivitySet = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $ActivityIDDynamicField,
        ObjectID           => $TicketID,
        Value              => $EnrolledActivityEntityID,
        UserID             => $UserID,
    );

    $Self->True(
        $ProcessSet && $ActivitySet,
        "Process enrollment for MaxTransitionsPerRequest $Param{MaxTransitionsPerRequest}",
    );

    # Enrollment already ran the transition handler once. Drop the ticket object so the loop
    # guard does not block the state change that should advance the process.
    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Ticket'] );
    $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $HistoryBefore = $ActivityHistoryCount->($TicketID);

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # Default minimum log level is error (16) and drops notices (8). Lower it on this object
    # only. Discarding the log object would also discard the database handle and roll back
    # the test transaction.
    local $LogObject->{MinimumLevelNum} = 8;
    $LogObject->CleanUp();

    # Setting the state matches the transitions. Further steps run only while the limit allows
    # them and the condition stays true.
    my $StateSet = $TicketObject->TicketStateSet(
        State    => 'open',
        TicketID => $TicketID,
        UserID   => $UserID,
    );

    $Self->True(
        $StateSet,
        "TicketStateSet() for MaxTransitionsPerRequest $Param{MaxTransitionsPerRequest}",
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
    );

    my $Log = $LogObject->GetLog() // '';

    return {
        ActivityEntityID => $Ticket{"DynamicField_$ActivityFieldName"},
        Log              => $Log,
        TicketID         => $TicketID,
        TransitionCount  => $ActivityHistoryCount->($TicketID) - $HistoryBefore,
    };
};

my $ActivityMiddleName = $Dump->{Activity}->{$ActivityMiddle}->{Name};

# SysConfig default is 1: only the first matching transition runs.
my $DefaultLimit = $ActivityForMaxTransitionsPerRequest->( MaxTransitionsPerRequest => 1 );

$Self->Is(
    $DefaultLimit->{ActivityEntityID},
    $ActivityMiddle,
    'Default of 1 stops after the first matching transition',
);
$Self->Is(
    $DefaultLimit->{TransitionCount},
    1,
    'Default of 1 applies one transition',
);

my $LimitNotice = "Process transition limit of 1 reached for TicketID $DefaultLimit->{TicketID} "
    . "(Process: $ProcessName, Activity: $ActivityMiddleName). "
    . 'A cyclic process keeps applying transitions up to this limit on every ticket update.';

$Self->True(
    index( $DefaultLimit->{Log}, $LimitNotice ) != -1,
    'Stopping on the last allowed step writes a transition-limit notice',
);

# A limit above the matching transitions finishes the path and writes no notice.
my $WithinLimit = $ActivityForMaxTransitionsPerRequest->( MaxTransitionsPerRequest => 3 );

$Self->Is(
    $WithinLimit->{ActivityEntityID},
    $ActivityEnd,
    'A limit above the matching transitions advances across both',
);
$Self->Is(
    $WithinLimit->{TransitionCount},
    2,
    'A limit above the matching transitions applies both',
);
$Self->True(
    index( $WithinLimit->{Log}, 'Process transition limit of' ) == -1,
    'Finishing inside the limit writes no transition-limit notice',
);

my $CycleProcessName = "Cycle $RandomID";
my $CycleScope       = 'Process-Cycle';

my $CycleProcessData = {
    Activities => {
        'Activity-A' => $Activity->( "CycleA $RandomID", ScopeEntityID => $CycleScope ),
        'Activity-B' => $Activity->( "CycleB $RandomID", ScopeEntityID => $CycleScope ),
    },
    ActivityDialogs   => {},
    TransitionActions => {},
    Transitions       => {
        'Transition-AB' => $Transition->( "ToB $RandomID", ScopeEntityID => $CycleScope ),
        'Transition-BA' => $Transition->( "ToA $RandomID", ScopeEntityID => $CycleScope ),
    },
    Process => {
        Name              => $CycleProcessName,
        EntityID          => $CycleScope,
        State             => 'Active',
        StateEntityID     => 'S1',
        Activities        => [ 'Activity-A',    'Activity-B' ],
        Transitions       => [ 'Transition-AB', 'Transition-BA' ],
        TransitionActions => [],
        Layout            => {},
        Config            => {
            Description   => 'Cyclic transitions',
            StartActivity => 'Activity-A',
            Path          => {
                'Activity-A' => {
                    'Transition-AB' => {
                        ActivityEntityID => 'Activity-B',
                        TransitionAction => [],
                    },
                },
                'Activity-B' => {
                    'Transition-BA' => {
                        ActivityEntityID => 'Activity-A',
                        TransitionAction => [],
                    },
                },
            },
        },
    },
};

my $CycleProcessContent = $YAMLObject->Dump( Data => $CycleProcessData );

my %CycleProcessImport = $DBProcessObject->ProcessImport(
    Content => $CycleProcessContent,
    UserID  => $UserID,
);

$Self->True(
    $CycleProcessImport{Success},
    "ProcessImport() of the cycle succeeded ($CycleProcessImport{Message})",
);

$Dump = $DBProcessObject->ProcessDump(
    ResultType => 'HASH',
    UserID     => $UserID,
);

for my $DumpKey ( sort keys %ConfigKey ) {
    $HelperObject->ConfigSettingChange(
        Valid => 1,
        Key   => $ConfigKey{$DumpKey},
        Value => $Dump->{$DumpKey},
    );
}

my ($CycleProcessEntityID) = grep { $Dump->{Process}->{$_}->{Name} eq $CycleProcessName } keys %{ $Dump->{Process} };
my $CycleProcessConfig = $Dump->{Process}->{$CycleProcessEntityID};

$Self->True(
    IsHashRefWithData($CycleProcessConfig),
    'Imported cycle is part of the dumped configuration',
);

my $CycleActivityA      = $CycleProcessConfig->{StartActivity};
my ($CycleTransitionAB) = keys %{ $CycleProcessConfig->{Path}->{$CycleActivityA} };
my $CycleActivityB      = $CycleProcessConfig->{Path}->{$CycleActivityA}->{$CycleTransitionAB}->{ActivityEntityID};
my $CycleActivityAName  = $Dump->{Activity}->{$CycleActivityA}->{Name};
my $CycleActivityBName  = $Dump->{Activity}->{$CycleActivityB}->{Name};

my $CycleAtLimit = $ActivityForMaxTransitionsPerRequest->(
    MaxTransitionsPerRequest => 2,
    ProcessEntityID          => $CycleProcessEntityID,
    ActivityEntityID         => $CycleActivityA,
);

$Self->Is(
    $CycleAtLimit->{ActivityEntityID},
    $CycleActivityA,
    'Two allowed steps on a cycle return to the start activity',
);
$Self->Is(
    $CycleAtLimit->{TransitionCount},
    2,
    'Two allowed steps on a cycle apply two transitions',
);

my $CycleNotice = "Process transition limit of 2 reached for TicketID $CycleAtLimit->{TicketID} "
    . "(Process: $CycleProcessName, Activity: $CycleActivityAName). "
    . 'A cyclic process keeps applying transitions up to this limit on every ticket update.';

$Self->True(
    index( $CycleAtLimit->{Log}, $CycleNotice ) != -1,
    'A cycle that is still moving on the last step writes a transition-limit notice',
);

# A stored value above the SysConfig maximum (99) falls back to the default of 1.
my $CycleAboveMax = $ActivityForMaxTransitionsPerRequest->(
    MaxTransitionsPerRequest => 1000,
    ProcessEntityID          => $CycleProcessEntityID,
    ActivityEntityID         => $CycleActivityA,
);

$Self->Is(
    $CycleAboveMax->{TransitionCount},
    1,
    'A stored limit of 1000 falls back to the default of 1 transition',
);
$Self->Is(
    $CycleAboveMax->{ActivityEntityID},
    $CycleActivityB,
    'The fallback limit of 1 stops on the other activity of the cycle',
);

my $FallbackNotice = "Process transition limit of 1 reached for TicketID $CycleAboveMax->{TicketID} "
    . "(Process: $CycleProcessName, Activity: $CycleActivityBName). "
    . 'A cyclic process keeps applying transitions up to this limit on every ticket update.';

$Self->True(
    index( $CycleAboveMax->{Log}, $FallbackNotice ) != -1,
    'The fallback limit of 1 is the value written to the notice',
);

1;
