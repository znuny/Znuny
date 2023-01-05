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

use URI::Escape;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject            = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyHelperObject       = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
my $OAuth2TokenObject       = $Kernel::OM->Get('Kernel::System::OAuth2Token');
my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');
my $MainObject              = $Kernel::OM->Get('Kernel::System::Main');
my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');

my $UserID = 1;

#
# Import example token config.
#
my $HomePath                   = $ConfigObject->Get('Home');
my $ExampleTokenConfigFilePath = $HomePath
    . '/scripts/OAuth2TokenManagement/oauth2_token_config_example.yml';

my $ExampleTokenConfigFileContent = $MainObject->FileRead(
    Location => $ExampleTokenConfigFilePath,
    Result   => 'SCALAR',
);

my %ValidIDs       = $ValidObject->ValidList();
my %ValidIDsByName = reverse %ValidIDs;

$OAuth2TokenConfigObject->DataImport(
    Content   => ${$ExampleTokenConfigFileContent},
    Format    => 'yml',
    Overwrite => 1,
    Data      => {
        ValidID  => $ValidIDsByName{valid},
        CreateBy => $UserID,
        ChangeBy => $UserID,
    },
    UserID => $UserID,
);

my %TokenConfig = $OAuth2TokenConfigObject->DataGet(
    Name   => 'Microsoft Outlook (example@outlook.com)',
    UserID => $UserID,
);
my $TokenConfigID = $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} };

#
# GenerateAuthorizationCodeRequestURL()
#
my $URL = $OAuth2TokenObject->GenerateAuthorizationCodeRequestURL(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

my $HttpType    = $ConfigObject->Get('HttpType')                                    // '';
my $Hostname    = URI::Escape::uri_escape_utf8( $ConfigObject->Get('FQDN') )        // '';
my $ScriptAlias = URI::Escape::uri_escape_utf8( $ConfigObject->Get('ScriptAlias') ) // '';

my $ExpectedURL
    = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?client_id=1111&redirect_uri=${HttpType}%3A%2F%2F${Hostname}%2F${ScriptAlias}get-oauth2-token-by-authorization-code.pl&response_mode=query&response_type=code&scope=https%3A%2F%2Foutlook.office.com%2FIMAP.AccessAsUser.All%20https%3A%2F%2Foutlook.office.com%2FPOP.AccessAsUser.All%20https%3A%2F%2Foutlook.office.com%2FSMTP.Send%20offline_access&state=TokenConfigID${TokenConfigID}";

$Self->Is(
    $URL,
    $ExpectedURL,
    'GenerateAuthorizationCodeRequestURL(): Authorization code request URL must match expected one.',
);

#
# GetAuthorizationCodeParameters()
#

# Fake web request parameters.
$ParamObject->{Query}->param(
    -name  => 'state',
    -value => "TokenConfigID$TokenConfigID",
);
$ParamObject->{Query}->param(
    -name  => 'code',
    -value => 'UnitTestAuthorizationCode',
);

my %AuthorizationCodeParameters = $OAuth2TokenObject->GetAuthorizationCodeParameters(
    ParamObject => $ParamObject,
    UserID      => $UserID,
);

my %ExpectedAuthorizationCodeParameters = (
    TokenConfigID     => $TokenConfigID,
    AuthorizationCode => 'UnitTestAuthorizationCode',
);

$Self->IsDeeply(
    \%AuthorizationCodeParameters,
    \%ExpectedAuthorizationCodeParameters,
    'GetAuthorizationCodeParameters(): Authorization code parameters must match expected ones.',
);

#
# Check if token exists for token config.
#
my %Token = $OAuth2TokenObject->DataGet(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->True(
    scalar %Token,
    "Token for token config with ID $TokenConfigID must exist.",
);

my $TokenID = $Token{ $OAuth2TokenObject->{Identifier} };

my $Token        = 'UnitTestToken';
my $RefreshToken = 'UnitTestRefreshToken';

#
# HasTokenExpired()
#
my $TokenHasExpired = $OAuth2TokenObject->HasTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->True(
    scalar $TokenHasExpired,
    'HasTokenExpired() must report token as expired.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    Token                            => $Token,
    UserID                           => $UserID,
);

$TokenHasExpired = $OAuth2TokenObject->HasTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->False(
    scalar $TokenHasExpired,
    'HasTokenExpired() must report token as not expired as no expiration date is set.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    TokenExpirationDate              => '1999-01-01 13:00:00',
    UserID                           => $UserID,
);

$TokenHasExpired = $OAuth2TokenObject->HasTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->True(
    scalar $TokenHasExpired,
    'HasTokenExpired() must report token as expired.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    TokenExpirationDate              => '2060-01-01 13:00:00',
    UserID                           => $UserID,
);

$TokenHasExpired = $OAuth2TokenObject->HasTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->False(
    scalar $TokenHasExpired,
    'HasTokenExpired() must report token as not expired.',
);

#
# HasRefreshTokenExpired()
#
my $RefreshTokenHasExpired = $OAuth2TokenObject->HasRefreshTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->True(
    scalar $RefreshTokenHasExpired,
    'HasRefreshTokenExpired() must report refresh token as expired.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    RefreshToken                     => $RefreshToken,
    UserID                           => $UserID,
);

$RefreshTokenHasExpired = $OAuth2TokenObject->HasRefreshTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->False(
    scalar $RefreshTokenHasExpired,
    'HasRefreshTokenExpired() must report refresh token as not expired as no expiration date is set.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    RefreshTokenExpirationDate       => '1999-01-01 13:00:00',
    UserID                           => $UserID,
);

$RefreshTokenHasExpired = $OAuth2TokenObject->HasRefreshTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->True(
    scalar $RefreshTokenHasExpired,
    'HasRefreshTokenExpired() must report refresh token as expired.',
);

$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    RefreshTokenExpirationDate       => '2060-01-01 13:00:00',
    UserID                           => $UserID,
);

$RefreshTokenHasExpired = $OAuth2TokenObject->HasRefreshTokenExpired(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->False(
    scalar $RefreshTokenHasExpired,
    'HasRefreshTokenExpired() must report refresh token as not expired.',
);

#
# GetToken()
# Attention: Test must not be executed with expired token because then
# a web request would be made.
#
my $RetrievedToken = $OAuth2TokenObject->GetToken(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->Is(
    $RetrievedToken,
    $Token,
    'GetToken() must return expected token.',
);

#
# GetTokenErrorMessage()
#
my $TokenErrorMessage = $OAuth2TokenObject->GetTokenErrorMessage(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->False(
    scalar $TokenErrorMessage,
    'GetTokenErrorMessage() must not report an error message.',
);

# Manually set errors in token.
$OAuth2TokenObject->DataUpdate(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    ErrorMessage                     => 'Unit test error message',
    ErrorDescription                 => 'Unit test error description',
    ErrorCode                        => '249827',
    UserID                           => $UserID,
);

$TokenErrorMessage = $OAuth2TokenObject->GetTokenErrorMessage(
    TokenConfigID => $TokenConfigID,
    UserID        => $UserID,
);

$Self->Is(
    $TokenErrorMessage,
    'Unit test error message (error code 249827): Unit test error description',
    'GetTokenErrorMessage() must report expected error message.',
);

#
# AssembleSASLAuthString()
#
my $SASLAuthString = $OAuth2TokenObject->AssembleSASLAuthString(
    Username    => 'unit-test-user',
    OAuth2Token => 'unit-test-token',
);

$Self->Is(
    $SASLAuthString,
    'dXNlcj11bml0LXRlc3QtdXNlcgFhdXRoPUJlYXJlciB1bml0LXRlc3QtdG9rZW4BAQ==',
    'AssembleSASLAuthString() must return expected string.',
);

# delete OAuth2Token manual
$OAuth2TokenObject->DataDelete(
    $OAuth2TokenObject->{Identifier} => $TokenID,
    UserID                           => $UserID,
);

1;
