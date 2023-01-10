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

my $SchedulerObject = $Kernel::OM->Get('Kernel::System::Scheduler');

my %TaskData = (
    Type => 'AsynchronousExecutor',
    Name => 'UnitTestSchedulerObjectTest',
    Data => {
        Object   => 'Kernel::System::Ticket',
        Function => '_TicketCacheClear',
        Params   => {
            TicketID => 1,
        },
    },
);

$SchedulerObject->TaskAdd(%TaskData);

my $UnitTestSchedulerObject = $Kernel::OM->Get('Kernel::System::UnitTest::Scheduler');

$UnitTestSchedulerObject->CheckCount(
    UnitTestObject => $Self,
    Count          => '0',
);

$SchedulerObject->TaskAdd(%TaskData);
$SchedulerObject->TaskAdd(%TaskData);

$UnitTestSchedulerObject->CheckCount(
    UnitTestObject => $Self,
    Count          => '2',
);

$UnitTestSchedulerObject->Execute(
    Type => 'AsynchronousExecutor',
);

$UnitTestSchedulerObject->CheckCount(
    UnitTestObject => $Self,
    Count          => '0',
);

$SchedulerObject->TaskAdd(%TaskData);

$UnitTestSchedulerObject->CleanUp(
    Type => 'GenericInterface',
);

$UnitTestSchedulerObject->CheckCount(
    UnitTestObject => $Self,
    Count          => '1',
);

$UnitTestSchedulerObject->CleanUp(
    Type => 'AsynchronousExecutor',
);

$UnitTestSchedulerObject->CheckCount(
    UnitTestObject => $Self,
    Count          => '0',
);

1;
