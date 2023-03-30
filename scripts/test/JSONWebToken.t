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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $JWTObject    = $Kernel::OM->Get('Kernel::System::JSONWebToken');

return 1 if !$JWTObject->IsSupported();

my $Home = $ConfigObject->Get('Home');

#
# Test with private key without password.
#

my $PrivateKeyFilePath = "$Home/scripts/test/sample/JSONWebToken/PrivateKeyWithoutPassword.pem";

my $PrivateKeyFileContent = ${
    $MainObject->FileRead(
        Location        => $PrivateKeyFilePath,
        Mode            => 'binmode',
        Type            => 'Local',
        Result          => 'SCALAR',
        DisableWarnings => 0,
    )
};

my $JWT = $JWTObject->Encode(
    Payload => {
        Key1 => 'This is a value with <OTRS_multiple> <OTRS_placeholders>.',
        Key2 => 'Another <OTRS_one> with a missing value for a <OTRS_missing_value>.',
    },
    Algorithm       => 'RS512',
    KeyFilePath     => $PrivateKeyFilePath,
    KeyPassword     => '',
    PlaceholderData => {
        OTRS_multiple     => 'multiple',
        OTRS_one          => 'one',
        OTRS_placeholders => 'placeholders',
    },
);

$Self->True(
    scalar $JWT,
    'Encode() must return a generated JSON web token.',
);

my $DecodedJWT = $JWTObject->Decode(
    Token       => $JWT,
    Key         => $PrivateKeyFileContent,
    KeyPassword => 'IRRELEVANT_WILL_BE_IGNORED',
);

my %ExpectedDecodedJWT = (
    Key1 => 'This is a value with multiple placeholders.',
    Key2 => 'Another one with a missing value for a .',
);

$Self->IsDeeply(
    $DecodedJWT,
    \%ExpectedDecodedJWT,
    'Decode() must return expected data.',
);

#
# Test with private key with password.
#

$PrivateKeyFilePath = "$Home/scripts/test/sample/JSONWebToken/PrivateKeyWithPassword.pem";
my $PrivateKeyPassword = 'test1234';

$PrivateKeyFileContent = ${
    $MainObject->FileRead(
        Location        => $PrivateKeyFilePath,
        Mode            => 'binmode',
        Type            => 'Local',
        Result          => 'SCALAR',
        DisableWarnings => 0,
    )
};

$JWT = $JWTObject->Encode(
    Payload => {
        Key1 => 'This is a value with <OTRS_multiple> <OTRS_placeholders>.',
        Key2 => 'Another <OTRS_one> with a missing value for a <OTRS_missing_value>.',
    },
    Algorithm       => 'RS512',
    Key             => $PrivateKeyFileContent,
    KeyPassword     => 'INVALID_PASSWORD',
    PlaceholderData => {
        OTRS_multiple     => 'multiple',
        OTRS_one          => 'one',
        OTRS_placeholders => 'placeholders',
    },
);

$Self->False(
    scalar $JWT,
    'Encode() must return no JSON web token for wrong password of key file.',
);

$JWT = $JWTObject->Encode(
    Payload => {
        Key1 => 'This is a value with <OTRS_multiple> <OTRS_placeholders>.',
        Key2 => 'Another <OTRS_one> with a missing value for a <OTRS_missing_value>.',
    },
    Algorithm       => 'RS512',
    Key             => $PrivateKeyFileContent,
    KeyPassword     => 'test1234',
    PlaceholderData => {
        OTRS_multiple     => 'multiple',
        OTRS_one          => 'one',
        OTRS_placeholders => 'placeholders',
    },
);

$Self->True(
    scalar $JWT,
    'Encode() must return a generated JSON web token for correct password of key file.',
);

$DecodedJWT = $JWTObject->Decode(
    Token       => $JWT,
    Key         => $PrivateKeyFileContent,
    KeyPassword => 'INVALID_PASSWORD',
);

$Self->False(
    scalar $DecodedJWT,
    'Decode() must not return data for wrong password of key file.',
);

$DecodedJWT = $JWTObject->Decode(
    Token       => $JWT,
    Key         => $PrivateKeyFileContent,
    KeyPassword => 'test1234',
);

%ExpectedDecodedJWT = (
    Key1 => 'This is a value with multiple placeholders.',
    Key2 => 'Another one with a missing value for a .',
);

$Self->IsDeeply(
    $DecodedJWT,
    \%ExpectedDecodedJWT,
    'Decode() must return expected data.',
);

1;
