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

my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketPrioritySet');

my $TicketID = $HelperObject->TicketCreate();
my %Ticket   = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Priority => '5 very high',
        UserID   => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    'TransitionActionObject->Run() - Priority',
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{Priority},
    '5 very high',
    'Priority',
);

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        PriorityID => 1,
        UserID     => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    'TransitionActionObject->Run() - PriorityID',
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{PriorityID},
    '1',
    'Priority',
);
1;
