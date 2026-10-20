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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Secret::KeyGenerate');
my $EncodeObject  = $Kernel::OM->Get('Kernel::System::Encode');

my ( $Result, $ExitCode );
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    $ExitCode = $CommandObject->Execute();
    $EncodeObject->EncodeInput( \$Result );
}

$Self->Is(
    $ExitCode,
    0,
    'Maint::Secret::KeyGenerate exit code',
);

my ($Key) = ( $Result // '' ) =~ m{ ^ ( [0-9a-f]{64} ) $ }xms;
$Self->True(
    $Key ? 1 : 0,
    'Maint::Secret::KeyGenerate prints a 256 bit (64 hex char) key',
);
$Self->True(
    index( $Result // '', "ZNUNY_CONFIG_SECRET_KEY='$Key'" ) > -1 ? 1 : 0,
    'Maint::Secret::KeyGenerate prints usage hint with the generated key',
);

1;
