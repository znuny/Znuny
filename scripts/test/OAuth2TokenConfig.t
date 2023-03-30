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
my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
my $MainObject              = $Kernel::OM->Get('Kernel::System::Main');
my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');
my $MailAccountObject       = $Kernel::OM->Get('Kernel::System::MailAccount');
my $WebserviceObject        = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

my $UserID = 1;

#
# Import example token configs.
#
my $HomePath                   = $ConfigObject->Get('Home');
my $ExampleTokenConfigFilePath = $HomePath . '/scripts/test/sample/Webservice/OAuth2TokenConfigs.yml';

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

#
# Test first token config with mail account
#
my %TokenConfig = $OAuth2TokenConfigObject->DataGet(
    Name   => 'Microsoft Outlook (example@outlook.com)',
    UserID => $UserID,
);
my $TokenConfigID = $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} };

my $MailAccountID = $MailAccountObject->MailAccountAdd(
    Login               => 'mail',
    Password            => 'OAuth2Token',
    Host                => 'pop3.example.com',
    Type                => 'POP3',
    ValidID             => 1,
    Trusted             => 0,
    AuthenticationType  => 'oauth2_token',
    OAuth2TokenConfigID => $TokenConfigID,
    DispatchingBy       => 'Queue',
    QueueID             => 1,
    UserID              => 1,
);

my $OAuth2TokenConfigIsInUse = $OAuth2TokenConfigObject->IsOAuth2TokenConfigInUse(
    ID => 999999,
);

$Self->False(
    scalar $OAuth2TokenConfigIsInUse,
    'IsOAuth2TokenConfigInUse() must report that token config with ID 999999 is not in use.',
);

$OAuth2TokenConfigIsInUse = $OAuth2TokenConfigObject->IsOAuth2TokenConfigInUse(
    ID => $TokenConfigID,
);

$Self->True(
    scalar $OAuth2TokenConfigIsInUse,
    "IsOAuth2TokenConfigInUse() must report that token config with ID $TokenConfigID is in use.",
);

#
# Test second token config with web service
#
%TokenConfig = $OAuth2TokenConfigObject->DataGet(
    Name   => 'Google Mail (example@gmail.com)',
    UserID => $UserID,
);
$TokenConfigID = $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} };

my %WebserviceConfig = (
    Debugger => {
        DebugThreshold => 'debug',
        TestMode       => 0,
    },
    Description => 'Unit test',
    Provider    => {
        Transport => {
            Type => '',
        },
    },
    RemoteSystem => '',
    Requester    => {
        Transport => {
            Config => {
                AdditionalHeaders => {
                    Authorization => 'Bearer <OTRS_OAUTH2_TOKEN>',
                },
                Authentication => {
                    AuthType            => 'OAuth2Token',
                    OAuth2TokenConfigID => $TokenConfigID,
                },
                ContentType               => '',
                DefaultCommand            => 'GET',
                Host                      => 'example.org',
                SSLNoHostnameVerification => 0,
                Timeout                   => 120,
            },
            Type => 'HTTP::REST',
        },
    },
);

my $WebserviceID = $WebserviceObject->WebserviceAdd(
    Name    => 'Unit test OAuth2 token usage',
    Config  => \%WebserviceConfig,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    scalar $WebserviceID,
    'Web service must have been created successfully.',
);

$OAuth2TokenConfigIsInUse = $OAuth2TokenConfigObject->IsOAuth2TokenConfigInUse(
    ID => $TokenConfigID,
);

$Self->True(
    scalar $OAuth2TokenConfigIsInUse,
    "IsOAuth2TokenConfigInUse() must report that token config with ID $TokenConfigID is in use.",
);

1;
