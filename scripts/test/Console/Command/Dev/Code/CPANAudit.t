# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $CommandObject     = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Code::CPANAudit');
my $EnvironmentObject = $Kernel::OM->Get('Kernel::System::Environment');
my $EncodeObject      = $Kernel::OM->Get('Kernel::System::Encode');

my $Version = $EnvironmentObject->ModuleVersionGet( Module => 'CPAN::Audit' );
return 1 if !$Version;

my $ExitCode = $CommandObject->Execute();

my $Output;
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Output;
    $ExitCode = $CommandObject->Execute();
    $EncodeObject->EncodeInput( \$Output );
}

$Self->Is(
    $ExitCode,
    0,
    "Dev::Tools::CPANAudit exit code is 0",
);

1;
