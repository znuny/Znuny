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
    = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest::HistoryType::OwnerUpdate');

my %Param = (
    Owner => 'root@localhost',
);

my $Output = $TicketToUnitTestHistoryTypeObject->Run(
    %Param,
);

my $ExpectedOutout = <<OUTPUT;
\$Success = \$TicketObject->TicketOwnerSet(
    NewUser  => 'root\@localhost',
    TicketID => \$TicketID,
    UserID   => \$UserID,
);

\$Self->True(
    \$Success,
    'TicketOwnerSet to "$Param{Owner}" was successful.',
);

OUTPUT

$Self->Is(
    $Output,
    $ExpectedOutout,
    'TicketToUnitTest::HistoryType::OwnerUpdate',
);

1;
