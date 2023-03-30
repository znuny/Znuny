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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

# Initialize test database based on fresh OTRS 6 schema.
my $Success = $HelperObject->ProvideTestDatabase(
    DatabaseXMLFiles => [
        "$Home/scripts/database/schema.xml",
        "$Home/scripts/database/initial_insert.xml",
    ],
);
if ( !$Success ) {
    $Self->False(
        0,
        'Test database could not be provided, skipping test',
    );
    return 1;
}
$Self->True(
    $Success,
    'ProvideTestDatabase - Load and execute OTRS 6 XML files',
);

my @List = $Kernel::OM->Get('Kernel::System::Package')->RepositoryList(
    Result => 'short',
);

if (@List) {
    $Self->True(
        0,
        'System should not contain any installed package',
    );
}

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::Package::UpgradeAll');

my ( $Result, $ExitCode );
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    $ExitCode = $CommandObject->Execute();
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeInput( \$Result );
}

$Self->False(
    $ExitCode,
    'Admin::Package::UpgradeAll executes without any issue',
);
$Self->IsNot(
    $Result || '',
    '',
    'Admin::Package::UpgradeAll result',
);

1;
