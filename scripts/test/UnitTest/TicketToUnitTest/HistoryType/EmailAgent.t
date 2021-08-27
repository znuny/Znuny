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

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $TicketToUnitTestHistoryTypeObject
    = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest::HistoryType::EmailAgent');

my $TicketID  = $HelperObject->TicketCreate();
my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my %Param = (
    TicketID    => $TicketID,
    ArticleID   => $ArticleID,
    HistoryType => 'EmailAgent',
);

my %Article = $ArticleObject->ArticleGet(
    TicketID  => $Param{TicketID},
    ArticleID => $Param{ArticleID}
);

my $Output = $TicketToUnitTestHistoryTypeObject->Run(
    %Param,
);

my $ExpectedOutout = <<OUTPUT;
\$TempValue = <<'BODY';
$Article{Body}
BODY

\$ArticleID = \$HelperObject->ArticleCreate(
    TicketID             => \$TicketID,
    Subject              => '$Article{Subject}',
    Body                 => \$TempValue,
    IsVisibleForCustomer => '$Article{IsVisibleForCustomer}',
    SenderType           => '$Article{SenderType}',
    From                 => '$Article{From}',
    To                   => '$Article{To}',
    Charset              => '$Article{Charset}',
    MimeType             => '$Article{MimeType}',
    HistoryType          => '$Param{HistoryType}',
    HistoryComment       => 'UnitTest',
    UserID               => \$UserID,
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
    'TicketToUnitTest::HistoryType::EmailAgent',
);

1;
