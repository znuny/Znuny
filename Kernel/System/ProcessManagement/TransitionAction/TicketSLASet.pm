# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::TicketSLASet;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::SLA',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::TicketSLASet - A module to set the ticket SLA

=head1 DESCRIPTION

All TicketSLASet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketSLASetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketSLASet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction TicketSLASet.

    my $Success = $TicketSLASetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            SLA => 'MySLA',
            # or
            SLAID  => 123,
            UserID => 123,                      # optional, to override the UserID from the logged user
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

    if ( !$Param{Config}->{SLAID} && !$Param{Config}->{SLA} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No SLA or SLAID configured!",
        );
        return;
    }

    if ( !$Param{Ticket}->{ServiceID} && !$Param{Ticket}->{Service} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "To set a SLA the ticket requires a service!",
        );
        return;
    }

    $Success = 0;

    # If Ticket's SLAID is already the same as the Value we
    # should set it to, we got nothing to do and return success
    if (
        defined $Param{Config}->{SLAID}
        && defined $Param{Ticket}->{SLAID}
        && $Param{Config}->{SLAID} eq $Param{Ticket}->{SLAID}
        )
    {
        return 1;
    }

    # If Ticket's SLAID is not the same as the Value we
    # should set it to, set the SLAID
    elsif (
        (
            defined $Param{Config}->{SLAID}
            && defined $Param{Ticket}->{SLAID}
            && $Param{Config}->{SLAID} ne $Param{Ticket}->{SLAID}
        )
        || !defined $Param{Ticket}->{SLAID}
        )
    {

        # check if serivce is assigned to Service otherwise return
        $Success = $Self->_CheckSLA(
            ServiceID => $Param{Ticket}->{ServiceID},
            SLAID     => $Param{Config}->{SLAID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'SLAID '
                    . $Param{Config}->{SLAID}
                    . ' is not assigned to Service '
                    . $Param{Ticket}->{Service}
            );
            return;
        }

        # set ticket SLA
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLASet(
            TicketID => $Param{Ticket}->{TicketID},
            SLAID    => $Param{Config}->{SLAID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket SLAID '
                    . $Param{Config}->{SLAID}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }

    # If Ticket's SLA is already the same as the Value we
    # should set it to, we got nothing to do and return success
    elsif (
        defined $Param{Config}->{SLA}
        && defined $Param{Ticket}->{SLA}
        && $Param{Config}->{SLA} eq $Param{Ticket}->{SLA}
        )
    {
        return 1;
    }

    # If Ticket's SLA is not the same as the Value we
    # should set it to, set the SLA
    elsif (
        (
            defined $Param{Config}->{SLA}
            && defined $Param{Ticket}->{SLA}
            && $Param{Config}->{SLA} ne $Param{Ticket}->{SLA}
        )
        || !defined $Param{Ticket}->{SLA}
        )
    {

        my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLALookup(
            Name => $Param{Config}->{SLA},
        );

        if ( !$SLAID ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'SLA '
                    . $Param{Config}->{SLA}
                    . ' is invalid!'
            );
            return;
        }

        # check if SLA is assigned to Service, otherwise return
        $Success = $Self->_CheckSLA(
            ServiceID => $Param{Ticket}->{ServiceID},
            SLAID     => $SLAID,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'SLA '
                    . $Param{Config}->{SLA}
                    . ' is not assigned to Service '
                    . $Param{Ticket}->{Service}
            );
            return;
        }

        # set ticket SLA
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLASet(
            TicketID => $Param{Ticket}->{TicketID},
            SLA      => $Param{Config}->{SLA},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket SLA '
                    . $Param{Config}->{SLA}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . "Couldn't update Ticket SLA - can't find valid SLA parameter!",
        );
        return;
    }

    return $Success;
}

=begin Internal:

=head2 _CheckSLA()

checks if a SLA is assigned to a Service

    my $Success = _CheckSLA(
        ServiceID => 123,
        SLAID     => 123,
    );

    Returns:

    $Success = 1;       # or undef

=cut

sub _CheckSLA {
    my ( $Self, %Param ) = @_;

    # get a list of assigned SLAs to the Service
    my %SLAs = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
        ServiceID => $Param{ServiceID},
        UserID    => 1,
    );

    # return failure if there are no assigned SLAs for this Service
    return if !IsHashRefWithData( \%SLAs );

    # return failure if the the SLA is not assigned to the Service
    return if !$SLAs{ $Param{SLAID} };

    # otherwise return success
    return 1;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
