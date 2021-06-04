# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Tools::Migrate::ConfigXMLStructure');

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

my ( $Result, $ExitCode );
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    $ExitCode = $CommandObject->Execute( "--source-directory", "$Home/Kernel/Config/Files/NotExisting/" );
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeInput( \$Result );
}
$Self->Is(
    $ExitCode,
    1,
    "Dev::Tools::Migrate::ConfigXMLStructure exit code not existing directory",
);

1;
