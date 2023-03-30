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
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject
    = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldIncrement');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

my @DynamicFields = (
    {
        Name       => 'UnitTestTestDynamicField',
        Label      => "UnitTestTestDynamicField",
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
);

my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    "_DynamicFieldsCreate()",
);

my $TicketID = $HelperObject->TicketCreate();

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'UnitTestTestDynamicField',
);

my $ValueSet = $BackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => 0,
    UserID             => 1,
);

$Self->True(
    $ValueSet,
    "ValueSet()",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $DynamicFieldSetResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        UnitTestTestDynamicField => 1,
        UserID                   => 1,
    },
);

$Self->True(
    $DynamicFieldSetResult,
    "TransitionActionObject->Run()",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_UnitTestTestDynamicField},
    1,
    'value in ticket got set',
);

$DynamicFieldSetResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Value                    => 9,
        UnitTestTestDynamicField => 1,
        UserID                   => 1,
    },
);

$Self->True(
    $DynamicFieldSetResult,
    "TransitionActionObject->Run()",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_UnitTestTestDynamicField},
    10,
    'value in ticket got set',
);

$DynamicFieldSetResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Value                    => -10,
        UnitTestTestDynamicField => 1,
        UserID                   => 1,
    },
);

$Self->True(
    $DynamicFieldSetResult,
    "TransitionActionObject->Run()",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_UnitTestTestDynamicField},
    0,
    'value in ticket got set',
);

1;
