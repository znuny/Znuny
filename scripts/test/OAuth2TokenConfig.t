# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
my $MainObject              = $Kernel::OM->Get('Kernel::System::Main');
my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
my $MailAccountObject       = $Kernel::OM->Get('Kernel::System::MailAccount');
my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

my $UserID = 1;

#
# Import example token config.
#
my $HomePath                   = $ConfigObject->Get('Home');
my $ExampleTokenConfigFilePath = $HomePath . '/scripts/OAuth2TokenManagement/oauth2_token_config_example.yml';

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

my @UsedOAuth2TokenConfigListGet = $OAuth2TokenConfigObject->UsedOAuth2TokenConfigListGet();

$Self->Is(
    $UsedOAuth2TokenConfigListGet[-1]->{ID},
    $TokenConfigID,
    'UsedOAuth2TokenConfigListGet',
);

1;
