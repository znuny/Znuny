# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Notification::DaemonCheck;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Cache',
    'Kernel::System::Group',
);

sub Run {
    my ( $Self, %Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get the NodeID from the SysConfig settings, this is used on High Availability systems.
    my $NodeID = $ConfigObject->Get('NodeID') || 1;

    # get running daemon cache
    my $Running = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => 'DaemonRunning',
        Key  => $NodeID,
    );

    return '' if $Running;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %NotificationDetails = (
        Priority => 'Error',
        Data     => $LayoutObject->{LanguageObject}->Translate("OTRS Daemon is not running."),
    );

    # check if user needs to be notified
    # get current user groups
    my %Groups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
        UserID => $Self->{UserID},
        Type   => 'move_into',
    );

    # reverse groups hash for easy look up
    %Groups = reverse %Groups;

    # check if the user is in the Admin group
    # if that is the case, extend the error with a link
    if ( $Groups{admin} ) {
        $NotificationDetails{Link}      = $LayoutObject->{Baselink} . '#';
        $NotificationDetails{LinkClass} = 'DaemonInfo';
    }

    # if user is not admin, add 'Please contact the administrator.' to error message
    else {
        $NotificationDetails{Data}
            .= ' ' . $LayoutObject->{LanguageObject}->Translate("Please contact the administrator.");
    }

    # show error notification
    return $LayoutObject->Notify(
        %NotificationDetails,
    );
}

1;
