# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Notification::SystemConfigurationIsDirtyCheck;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::JSON',
    'Kernel::System::SysConfig',
);

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Param{Type} eq 'Admin' ) {
        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
        my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');

        my $Group = $Param{Config}->{Group} || 'admin';

        my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => $Group,
            Type      => 'rw',
        );

        return '' if !$HasPermission;

        my $Result = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigurationIsDirtyCheck(
            UserID => $Self->{UserID},
        );

        if ($Result) {

            my $Data = $LayoutObject->{LanguageObject}->Translate('You have undeployed settings:');

            my $LinkURL = $LayoutObject->{Baselink}
                . 'Action=AdminSystemConfigurationDeployment;Subaction=Deployment';

            if ( !$LayoutObject->{SessionIDCookie} ) {
                $LinkURL .= ';' . $LayoutObject->{SessionName} . '=' . $LayoutObject->{SessionID};
            }

            my $Actions = [
                {
                    url     => $LinkURL,
                    text    => $LayoutObject->{LanguageObject}->Translate('Standard Deploy'),
                    type    => 'primary',
                    classes => 'CallForAction btn-main btn-primary',
                },
                {
                    url     => '#',
                    id      => 'QuickDeploy',
                    text    => $LayoutObject->{LanguageObject}->Translate('Quick Deploy'),
                    type    => 'ghost',
                    classes => 'CallForAction btn-main btn-primary-ghost',
                },
            ];

            return $LayoutObject->Notify(
                Priority        => 'Notice',
                Data            => $Data,
                Actions         => $Actions,
                ActionSeparator => $LayoutObject->{LanguageObject}->Translate('or'),
                ID              => 'QuickDeployNotification',
            );
        }
    }

    return '';
}

1;
