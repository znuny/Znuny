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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::PostMaster::Read');

my ( $ExitCode, $Result );

{
    local *STDIN;
    open STDIN, '<:utf8', \'';    ## no critic
    $ExitCode = $CommandObject->Execute();
}

$Self->Is(
    $ExitCode,
    1,
    "Maint::PostMaster::Read exit code without email input",
);

{
    my $Email = "From: me\@home.com\nTo: you\@home.com\nSubject: Test\nUnit tests rock.\n";
    local *STDIN;
    open STDIN, '<:utf8', \$Email;    ## no critic
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute();
}

$Self->Is(
    $ExitCode,
    0,
    "Maint::PostMaster::Read exit code with email input",
);

# cleanup is done by RestoreDatabase

1;
