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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketToUnitTestHistoryTypeObject
    = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest::HistoryType::NewTicket');

my %Param = (
    Queue         => 'QueueTest',
    Priority      => 'PriorityTest',
    State         => 'StateTest',
    Type          => 'TypeTest',
    OwnerID       => 'OwnerIDTest',
    ResponsibleID => 'ResponsibleIDTest',
    CustomerUser  => 'CustomerUserTest',
    CustomerID    => 'CustomerIDTest',
    Service       => 'ServiceTest',
    SLA           => 'SLATest',
);

my $Output = $TicketToUnitTestHistoryTypeObject->Run(
    %Param,
);

my $ExpectedOutout = <<OUTPUT;
my \$TicketID = \$HelperObject->TicketCreate(
    Queue         => 'QueueTest',
    Priority      => "PriorityTest",
    State         => 'StateTest',
    Type          => 'TypeTest',
    OwnerID       => 'OwnerIDTest',
    ResponsibleID => 'ResponsibleIDTest',
    CustomerUser  => 'CustomerUserTest',
    CustomerID    => 'CustomerIDTest',
    Service       => 'ServiceTest',
    SLA           => 'SLATest',
);

# trigger transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

$Self->Is(
    $Output,
    $ExpectedOutout,
    'TicketToUnitTest::HistoryType::NewTicket',
);

1;
