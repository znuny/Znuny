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

use Cwd qw();

my $CommandObject     = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Code::CPANAudit');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $EnvironmentObject = $Kernel::OM->Get('Kernel::System::Environment');
my $EncodeObject      = $Kernel::OM->Get('Kernel::System::Encode');

my $Home = $ConfigObject->Get('Home');
$Home = Cwd::realpath($Home) || $Home;
$Home =~ s{/\z}{};

my $CpanLib = Cwd::realpath("$Home/Kernel/cpan-lib") || "$Home/Kernel/cpan-lib";
$CpanLib =~ s{/\z}{};

my $SystemPath = '/usr/lib/perl5';

my @PathsToScan = $CommandObject->_PathsToScanGet(
    $Home,
    "$Home/var/article",
    "$Home/Custom",
    "$Home/Kernel/cpan-lib",
    $SystemPath,
    '.',
);

my %PathsToScan = map { $_ => 1 } @PathsToScan;

$Self->False(
    $PathsToScan{$Home},
    'Home is excluded from scan paths',
);
$Self->False(
    $PathsToScan{"$Home/var/article"},
    'var/article is excluded from scan paths',
);
$Self->False(
    $PathsToScan{"$Home/Custom"},
    'Custom is excluded from scan paths',
);
$Self->False(
    $PathsToScan{'.'},
    'Current folder is excluded from scan paths',
);
$Self->True(
    $PathsToScan{$CpanLib},
    'Kernel/cpan-lib is included in scan paths',
);
$Self->True(
    $PathsToScan{ Cwd::realpath($SystemPath) || $SystemPath },
    'System Perl path is included in scan paths',
);

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
