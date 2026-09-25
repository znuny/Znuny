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
    = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest::HistoryType::SendAgentNotification');

my $TicketID = $HelperObject->TicketCreate();

my %Param = (
    Name         => '%%Agent ticket notification%%root@localhost%%Email',
    Notification => {
        Name => 'Agent ticket notification',
    },
    Recipient => {
        UserLogin => 'root@localhost',
    },
    Transport => 'Email',
    TicketID  => $TicketID,
);

my $Output = $TicketToUnitTestHistoryTypeObject->Run(
    %Param,
);

my $ExpectedOutout = <<OUTPUT;
my \$NotificationEventObject = \$Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent');

\$Success = \$NotificationEventObject->_SendRecipientNotification(
    TicketID        => \$TicketID,
    Notification    => 'Agent ticket notification',
    Recipient       => 'root\@localhost',
    Event           => 'SendAgentNotification',
    Transport       => 'Email',
    TransportObject => \$TransportObject,   # please check this object
    UserID          => \$UserID,
);

\$Self->True(
    \$Success,
    '_SendRecipientNotification "Agent ticket notification" to "root\@localhost" was successful.',
);

OUTPUT

$Self->Is(
    $Output,
    $ExpectedOutout,
    'TicketToUnitTest::HistoryType::SendAgentNotification',
);

1;
