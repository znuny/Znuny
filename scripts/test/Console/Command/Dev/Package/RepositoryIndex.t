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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Package::RepositoryIndex');

my $ExitCode = $CommandObject->Execute();

$Self->Is(
    $ExitCode,
    1,
    "Dev::Package::RepositoryIndex exit code without arguments",
);

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

my $Result;
{
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute("$Home/Kernel/Config/Files");
}

$Self->Is(
    $ExitCode,
    0,
    "Dev::Package::RepositoryIndex exit code",
);

$Self->Is(
    $Result,
    '<?xml version="1.0" encoding="utf-8" ?>
<otrs_package_list version="1.0">
</otrs_package_list>
',
    "Dev::Package::RepositoryIndex result for empty directory",
);

1;
