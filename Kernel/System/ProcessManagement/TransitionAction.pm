# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction - action lib

=head1 DESCRIPTION

All Process Management Transition Action functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 TransitionActionGet()

    Get transition action info

    my $TransitionAction = $TransitionActionObject->TransitionActionGet(
        TransitionActionEntityID => 'TA1',
    );

    Returns:

    $TransitionAction = {
          'Name'       => 'TransitionAction 1'
          'CreateBy'   => '2',
          'CreateTime' => '07-02-2012 13:37:00',
          'ChangeBy'   => '3',
          'ChangeTime' => '08-02-2012 13:37:00',
          'Module'     => 'Kernel::System::ProcessManagement::TransitionAction::QueueMove',
          'Config'     => {
            # Config hash including all parameters
            # that can submitted to that module
          },
    };

=cut

sub TransitionActionGet {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(TransitionActionEntityID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $TransitionAction = $Kernel::OM->Get('Kernel::Config')->Get('Process::TransitionAction');

    if ( !IsHashRefWithData($TransitionAction) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TransitionAction config!',
        );
        return;
    }

    if ( !IsHashRefWithData( $TransitionAction->{ $Param{TransitionActionEntityID} } ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No Data for TransitionAction '$Param{TransitionActionEntityID}' found!",
        );
        return;
    }

    if (
        !$TransitionAction->{ $Param{TransitionActionEntityID} }->{Module}
        || !$Kernel::OM->Get('Kernel::System::Main')->Require(
            $TransitionAction->{ $Param{TransitionActionEntityID} }->{Module}
        )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Module for TransitionAction: $Param{TransitionActionEntityID} missing or"
                . " not found!",
        );
        return;
    }

    return $TransitionAction->{ $Param{TransitionActionEntityID} };
}

=head2 TransitionActionList()

    Get action config for dedicated TransitionActionEntityIDs

    my $TransitionActionList = $TransitionActionObject->TransitionActionList(
        TransitionActionEntityID => ['TA1', 'TA2', 'TA3',],
    );

    Returns:

    $TransitionActions = [
        {
          'TransitionActionEntityID' => 'TA1',
          'Name'                     => 'TransitionAction1'
          'CreateBy'                 => '2',
          'ChangeBy'                 => '3',
          'CreateTime'               => '25-04-2012 13:37:00',
          'ChangeTime'               => '24-04-2012 13:37:00',
          'Module'                   => 'Kernel::System::ProcessManagement::TransitionAction::QueueMove',
          'Config'                   => {
                                            # Config hash including all parameters
                                            # that can submitted to that module
           },
        },
        {
          'TransitionActionEntityID' => 'TA2',
          'Name'                     => 'TransitionAction2'
          'CreateBy'                 => '2',
          'ChangeBy'                 => '3',
          'CreateTime'               => '25-04-2012 13:37:00',
          'ChangeTime'               => '24-04-2012 13:37:00',
          'Module'                   => 'Kernel::System::ProcessManagement::TransitionAction::StatusUpdate',
          'Config'                   => {
                                            # Config hash including all parameters
                                            # that can submitted to that module
          },
        },
        {
          'TransitionActionEntityID' => 'TA3',
          'Name'                     => 'TransitionAction3'
          'CreateBy'                 => '2',
          'ChangeBy'                 => '3',
          'CreateTime'               => '25-04-2012 13:37:00',
          'ChangeTime'               => '24-04-2012 13:37:00',
          'Module'                   => 'Kernel::System::ProcessManagement::TransitionAction::NotifyOwner',
          'Config'                   => {
                                            # Config hash including all parameters
                                            # that can submitted to that module
          },
        },
    ];

=cut

sub TransitionActionList {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(TransitionActionEntityID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !IsArrayRefWithData( $Param{TransitionActionEntityID} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No TransitionActionEntityID Array submitted calling TransitionActionList!',
        );
        return;
    }

    my $TransitionAction = $Kernel::OM->Get('Kernel::Config')->Get('Process::TransitionAction');

    my $TransitionActionConfigs;
    for my $TransitionActionEntityID ( @{ $Param{TransitionActionEntityID} } ) {
        if ( !IsHashRefWithData( $TransitionAction->{$TransitionActionEntityID} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No Data for TransitionAction '$TransitionActionEntityID'"
                    . " found!",
            );
            return;
        }

        if (
            !$TransitionAction->{$TransitionActionEntityID}->{Module}
            || !$Kernel::OM->Get('Kernel::System::Main')->Require(
                $TransitionAction->{$TransitionActionEntityID}->{Module}
            )
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Module for TransitionAction: $TransitionActionEntityID"
                    . " missing or not found!",
            );
            return;
        }

        push @{$TransitionActionConfigs}, {
            TransitionActionEntityID => $TransitionActionEntityID,
            %{ $TransitionAction->{$TransitionActionEntityID} },
        };
    }

    return $TransitionActionConfigs;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
