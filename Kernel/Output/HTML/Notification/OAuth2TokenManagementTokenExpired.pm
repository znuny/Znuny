# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::OAuth2TokenManagementTokenExpired;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Language',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::OAuth2Token',
    'Kernel::System::OAuth2TokenConfig',
    'Kernel::System::Valid',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LanguageObject          = $Kernel::OM->Get('Kernel::Language');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $GroupObject             = $Kernel::OM->Get('Kernel::System::Group');
    my $OAuth2TokenObject       = $Kernel::OM->Get('Kernel::System::OAuth2Token');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

    my $UserID = $LayoutObject->{UserID};
    return '' if !$UserID;

    my $UserHasPermission = $GroupObject->PermissionCheck(
        UserID    => $UserID,
        GroupName => 'admin',
        Type      => 'rw',
    );
    return '' if !$UserHasPermission;

    my @ValidIDs = $ValidObject->ValidIDsGet();
    return '' if !@ValidIDs;

    my $ValidID = shift @ValidIDs;

    my @TokenConfigs = $OAuth2TokenConfigObject->DataListGet(
        ValidID => $ValidID,
        UserID  => $UserID,
    );
    return '' if !@TokenConfigs;

    my @TranslatedNotifications;

    TOKENCONFIG:
    for my $TokenConfig (@TokenConfigs) {
        my $TokenConfigID = $TokenConfig->{ $OAuth2TokenConfigObject->{Identifier} };

        if ( $TokenConfig->{Config}->{Notifications}->{NotifyOnExpiredToken} ) {
            my $TokenHasExpired = $OAuth2TokenObject->HasTokenExpired(
                TokenConfigID => $TokenConfigID,
                UserID        => $UserID,
            );
            if ($TokenHasExpired) {
                my $TranslatedNotification = $LayoutObject->{LanguageObject}->Translate(
                    'OAuth2 token for "%s" has expired.',
                    $TokenConfig->{Name},
                );
                push @TranslatedNotifications, $TranslatedNotification;
            }
        }

        if (
            $TokenConfig->{Config}->{Notifications}->{NotifyOnExpiredRefreshToken}
            && IsHashRefWithData( $TokenConfig->{Config}->{Requests}->{TokenByRefreshToken} )
            )
        {
            my $RefreshTokenHasExpired = $OAuth2TokenObject->HasRefreshTokenExpired(
                TokenConfigID => $TokenConfigID,
                UserID        => $UserID,
            );
            if ($RefreshTokenHasExpired) {
                my $TranslatedNotification = $LayoutObject->{LanguageObject}->Translate(
                    'OAuth2 refresh token for "%s" has expired.',
                    $TokenConfig->{Name},
                );
                push @TranslatedNotifications, $TranslatedNotification;
            }
        }
    }

    return '' if !@TranslatedNotifications;

    my $Output;
    for my $TranslatedNotification (@TranslatedNotifications) {
        my $NotificationLink    = $LayoutObject->{Baselink} . 'Action=AdminOAuth2TokenManagement';
        my $NotificationContent = '<a href="' . $NotificationLink . '">' . $TranslatedNotification . '</a>';

        $Output .= $LayoutObject->Notify(
            Priority => 'Warning',
            Data     => $NotificationContent,
        );
    }

    return $Output;
}

1;
