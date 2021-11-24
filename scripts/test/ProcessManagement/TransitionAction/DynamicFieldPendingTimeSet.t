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

my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TransitionActionObject
    = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldPendingTimeSet');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $TimeObject        = $Kernel::OM->Get('Kernel::System::Time');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

$HelperObject->FixedTimeSet();

my @DynamicFields = (
    {
        Name       => 'TestTransitionActionField',
        Label      => "Label",
        ObjectType => 'Ticket',
        FieldType  => 'DateTime',
        Config     => {
            DefaultValue  => "0",
            YearsPeriod   => "0",
            YearsInFuture => "5",
            YearsInPast   => "5",
            Link          => '',
        },
    },
);

my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    "Create test dynamic field 'TestTransitionActionField'.",
);

my $TicketID = $HelperObject->TicketCreate();

$Self->True(
    $TicketID,
    "Create test ticket '$TicketID'.",
);

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'TestTransitionActionField',
);

$Self->True(
    IsHashRefWithData($DynamicFieldConfig) ? 1 : 0,
    "Dynamic field config exists.",
);

my $SystemTime = $TimeObject->SystemTime();
my $TimeStamp  = $TimeObject->CurrentTimestamp();

$Success = $BackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $TimeStamp,
    UserID             => 1,
);

$Self->True(
    $Success,
    "Set dynamic field value of 'TestTransitionActionField' to '2016-06-27 11:09:00'.",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    %Ticket ? 1 : 0,
    "Get ticket data of ticket id '$TicketID'.",
);

$Success = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        DynamicField => 'TestTransitionActionField',
        State        => 'pending auto close+',
        Offset       => '1h 1m',
        UserID       => 1,
    }
);

$Self->True(
    $Success,
    "Run transition action module 'TransitionAction::DynamicFieldPendingTimeSet' on '$TicketID'.",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    %Ticket ? 1 : 0,
    "Get ticket data of ticket id '$TicketID'.",
);

my $RealTillTimeNotUsedTimeStamp = $TimeObject->SystemTime2TimeStamp(
    SystemTime => $Ticket{RealTillTimeNotUsed},
);

$Self->Is(
    $Ticket{RealTillTimeNotUsed},
    $SystemTime + ( 60 * 60 ) + 60,    # 1h 1m
    "Until time of ticket '$TicketID' is '1h 1m'",
);

#
# try without offset because its optional
#

$Success = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        DynamicField => 'TestTransitionActionField',
        State        => 'pending auto close-',
        UserID       => 1,
    }
);

$Self->True(
    $Success,
    "Run transition action module 'TransitionAction::DynamicFieldPendingTimeSet' on '$TicketID'.",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    %Ticket ? 1 : 0,
    "Get ticket data of ticket id '$TicketID'.",
);

$RealTillTimeNotUsedTimeStamp = $TimeObject->SystemTime2TimeStamp(
    SystemTime => $Ticket{RealTillTimeNotUsed},
);

$Self->Is(
    $Ticket{RealTillTimeNotUsed},
    $SystemTime,
    "Until time of ticket '$TicketID' is system time",
);

1;
