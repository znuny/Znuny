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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Secret::Encrypt');
my $SecretObject  = $Kernel::OM->Get('Kernel::System::Crypt::Secret');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $EncodeObject  = $Kernel::OM->Get('Kernel::System::Encode');

$ConfigObject->Set(
    Key   => 'ConfigSecretKeyFile',
    Value => undef,
);

my ( $Result, $ExitCode );

# Without key
{
    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = undef;
    local *STDOUT;
    local *STDERR;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    open STDERR, '>:encoding(UTF-8)', \my $ErrorResult;
    $ExitCode = $CommandObject->Execute('some-pass');
}

$Self->Is(
    $ExitCode,
    1,
    'Maint::Secret::Encrypt exit code without configured key',
);

# Without argument
{
    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key';
    local *STDOUT;
    local *STDERR;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    open STDERR, '>:encoding(UTF-8)', \my $ErrorResult;
    $ExitCode = $CommandObject->Execute();
}

$Self->Is(
    $ExitCode,
    1,
    'Maint::Secret::Encrypt exit code without value argument',
);

# With key
local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key';

$Result = undef;
{
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$Result;
    $ExitCode = $CommandObject->Execute('some-pass');
    $EncodeObject->EncodeInput( \$Result );
}

$Self->Is(
    $ExitCode,
    0,
    'Maint::Secret::Encrypt exit code with configured key',
);

my ($CipherText) = ( $Result // '' ) =~ m/ ^ ( \{AES256: [^:]+ : [^}]+ \} ) $ /xms;
$Self->True(
    $CipherText ? 1 : 0,
    'Maint::Secret::Encrypt prints a {AES256:...} value',
);
$Self->Is(
    $SecretObject->Decrypt( Value => $CipherText ),
    'some-pass',
    'Printed value decrypts to the original value',
);

1;
