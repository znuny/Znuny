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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Log::Clear');
my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

$LogObject->CleanUp();
$LogObject->Log(
    Priority => 'error',
    Message  => 'test',
);

$Self->True(
    length $LogObject->GetLog(),
    "Error log before resetting",
);

my ( $Result, $ExitCode );
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    $ExitCode = $CommandObject->Execute();
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeInput( \$Result );
}

$Self->Is(
    $ExitCode,
    0,
    "Exit code for log reset",
);

$Self->Is(
    $LogObject->GetLog(),
    '',
    "Error log after resetting",
);

1;
