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

my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::LinkAdd');
my $ZnunyHelperObject      = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $LinkObject             = $Kernel::OM->Get('Kernel::System::LinkObject');

my $TicketID  = $HelperObject->TicketCreate();
my $TicketID2 = $HelperObject->TicketCreate();

my %Ticket = $TicketObject->TicketGet(
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
        SourceObject => 'Ticket',
        SourceKey    => $TicketID,
        TargetObject => 'Ticket',
        TargetKey    => $TicketID2,
        Type         => 'ParentChild',
        State        => 'Valid',
        UserID       => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    'TransitionActionObject->Run()',
);

my %LinkKeyList = $LinkObject->LinkKeyList(
    Object1 => 'Ticket',
    Key1    => $TicketID,
    Object2 => 'Ticket',
    State   => 'Valid',
    UserID  => 1,
);

$Self->True(
    $LinkKeyList{$TicketID2},
    'LinkKeyList()',
);

1;
