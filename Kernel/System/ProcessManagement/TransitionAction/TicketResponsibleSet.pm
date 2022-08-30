# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::TicketResponsibleSet;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::TicketResponsibleSet - A module to set a new ticket
responsible

=head1 DESCRIPTION

All TicketResponsibleSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketResponsibleSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketResponsibleSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction TicketResponsibleSet.

    my $Success = $TicketResponsibleSetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            Responsible => 'root@localhost',
            # or
            ResponsibleID => 1,
            UserID        => 123,               # optional, to override the UserID from the logged user
        }
    );

Returns:

    my $Success = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # define a common message to output in case of any error
    my $CommonMessage = "Process: $Param{ProcessEntityID} Activity: $Param{ActivityEntityID}"
        . " Transition: $Param{TransitionEntityID}"
        . " TransitionAction: $Param{TransitionActionEntityID} - ";

    # check for missing or wrong params
    my $Success = $Self->_CheckParams(
        %Param,
        CommonMessage => $CommonMessage,
    );
    return if !$Success;

    # override UserID if specified as a parameter in the TA config
    $Param{UserID} = $Self->_OverrideUserID(%Param);

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    if ( !$Param{Config}->{ResponsibleID} && !$Param{Config}->{Responsible} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No Responsible or ResponsibleID configured!",
        );
        return;
    }

    $Success = 0;

    if (
        defined $Param{Config}->{Responsible}
        && $Param{Config}->{Responsible} ne $Param{Ticket}->{Responsible}
        )
    {
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketResponsibleSet(
            TicketID => $Param{Ticket}->{TicketID},
            NewUser  => $Param{Config}->{Responsible},
            UserID   => $Param{UserID},
        );
    }
    elsif (
        defined $Param{Config}->{ResponsibleID}
        && $Param{Config}->{ResponsibleID} ne $Param{Ticket}->{ResponsibleID}
        )
    {
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketResponsibleSet(
            TicketID  => $Param{Ticket}->{TicketID},
            NewUserID => $Param{Config}->{ResponsibleID},
            UserID    => $Param{UserID},
        );
    }
    else {

        # data is the same as in ticket nothing to do
        $Success = 1;
    }

    if ( !$Success ) {
        my $CustomMessage;
        if ( defined $Param{Config}->{Responsible} ) {
            $CustomMessage = "Responsible: $Param{Config}->{Responsible},";
        }
        else {
            $CustomMessage = "ResponsibleID: $Param{Config}->{ResponsibleID},";
        }
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . 'Ticket responsible could not be updated to '
                . $CustomMessage
                . ' for Ticket: '
                . $Param{Ticket}->{TicketID} . '!',
        );
        return;
    }
    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
