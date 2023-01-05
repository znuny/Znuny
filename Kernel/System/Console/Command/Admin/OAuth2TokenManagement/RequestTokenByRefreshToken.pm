# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::OAuth2TokenManagement::RequestTokenByRefreshToken;

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
        'Requests a token by using a refresh token. The refresh token must have already been retrieved and stored in the token record.'
    );

    $Self->AddArgument(
        Name        => 'token-config-name',
        Description => 'Name of token config to request the token for.',
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

    my %Token = $OAuth2TokenObject->RequestTokenByRefreshToken(
        TokenConfigID => $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} },
        UserID        => $UserID,
    );
    if ( !%Token ) {
        $Self->PrintError("Error requesting token by refresh token for token config '$TokenConfigName'");
        return $Self->ExitCodeError();
    }

    my $TokenErrorMessage = $OAuth2TokenObject->GetTokenErrorMessage(
        TokenConfigID => $TokenConfig{ $OAuth2TokenConfigObject->{Identifier} },
        UserID        => $UserID,
    );
    if ( defined $TokenErrorMessage && length $TokenErrorMessage ) {
        $Self->PrintError(
            "Error requesting token by refresh token for token config '$TokenConfigName': $TokenErrorMessage"
        );
        return $Self->ExitCodeError();
    }

    $Self->Print("Token for token config with name '$TokenConfigName' has been successfully retrieved/updated.\n");

    return $Self->ExitCodeOk();
}

1;
