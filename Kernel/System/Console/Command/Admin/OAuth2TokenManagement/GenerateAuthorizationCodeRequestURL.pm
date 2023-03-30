# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::OAuth2TokenManagement::GenerateAuthorizationCodeRequestURL;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::OAuth2Token',
    'Kernel::System::OAuth2TokenConfig',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Generates a URL to request an authorization code for an OAuth 2 token. URL can then be called with a browser.'
    );

    $Self->AddArgument(
        Name        => 'token-config-name',
        Description => 'Name of token config to generate the authorization code request URL for.',
        Required    => 1,
        ValueRegex  => qr{.+},
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');
    my $OAuth2TokenObject       = $Kernel::OM->Get('Kernel::System::OAuth2Token');

    my $UserID          = 1;
    my $TokenConfigName = $Self->GetArgument('token-config-name');

    my %TokenConfig = $OAuth2TokenConfigObject->DataGet(
        Name   => $TokenConfigName,
        UserID => $UserID,
    );
    if ( !%TokenConfig ) {
        $Self->PrintError("Token config with name '$TokenConfigName' not found.");
        return $Self->ExitCodeError();
    }

    my $URL = $OAuth2TokenObject->GenerateAuthorizationCodeRequestURL(
        TokenConfigID => $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} },
        UserID        => $UserID,
    );

    $Self->Print("$URL\n");

    return $Self->ExitCodeOk();
}

1;
