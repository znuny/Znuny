# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# prepare the environment
my $Success = $Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'DaemonModules###UnitTest1',
    Value => '1',
);
$Self->True(
    $Success,
    "Added UnitTest1 daemon to the config",
);
$Success = $Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'DaemonModules###UnitTest2',
    Value => {
        AnyKey => 1,
    },
);
$Self->True(
    $Success,
    "Added UnitTest2 daemon to the config",
);
$Success = $Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'DaemonModules###UnitTest3',
    Value => {
        Module => 'Kernel::System::Daemon::DaemonModules::NotExistent',
    },
);
$Self->True(
    $Success,
    "Added UnitTest3 daemon to the config",
);

my @Tests = (
    {
        Name     => 'No hash setting daemon module',
        Params   => ['UnitTest1'],
        ExitCode => 1,
    },
    {
        Name     => 'Wrong module setting daemon module',
        Params   => ['UnitTest2'],
        ExitCode => 1,
    },
    {
        Name     => 'Not existing module setting daemon module',
        Params   => ['UnitTest3'],
        ExitCode => 1,
    },
    {
        Name     => 'Not existing daemon module',
        Params   => ['UnitTestNotExisiting'],
        ExitCode => 1,
    },
    {
        Name     => 'SchedulerTaskWorker daemon module',
        Params   => ['SchedulerTaskWorker'],
        ExitCode => 0,
    },
    {
        Name     => 'All daemon modules',
        Params   => [],
        ExitCode => 0,
    },
);

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Daemon::Summary');

for my $Test (@Tests) {

    my $ExitCode = $CommandObject->Execute( @{ $Test->{Params} } );

    $Self->Is(
        $ExitCode,
        $Test->{ExitCode},
        "$Test->{Name} Command exit code",
    );
}

# cleanup cache is done by RestoreDatabase

1;
