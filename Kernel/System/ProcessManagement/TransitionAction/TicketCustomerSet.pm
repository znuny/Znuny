# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet;

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

Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet - A module to set a new ticket customer

=head1 DESCRIPTION

All TicketCustomerSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketCustomerSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction TicketCustomerSet.

    my $Success = $TicketCustomerSetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            CustomerID     => 'client123',
            # or
            CustomerUserID => 'client-user-123',

            #OR (Framework wording)
            No             => 'client123',
            # or
            User           => 'client-user-123',

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

    if (
        !$Param{Config}->{CustomerID}
        && !$Param{Config}->{No}
        && !$Param{Config}->{CustomerUserID}
        && !$Param{Config}->{User}
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No CustomerID/No or CustomerUserID/User configured!",
        );
        return;
    }

    if ( !$Param{Config}->{CustomerID} && $Param{Config}->{No} ) {
        $Param{Config}->{CustomerID} = $Param{Config}->{No};
    }
    if ( !$Param{Config}->{CustomerUserID} && $Param{Config}->{User} ) {
        $Param{Config}->{CustomerUserID} = $Param{Config}->{User};
    }

    if (
        defined $Param{Config}->{CustomerID}
        &&
        (
            !defined $Param{Ticket}->{CustomerID}
            || $Param{Config}->{CustomerID} ne $Param{Ticket}->{CustomerID}
        )
        )
    {
        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        my $Success = $TicketObject->TicketCustomerSet(
            TicketID => $Param{Ticket}->{TicketID},
            No       => $Param{Config}->{CustomerID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket CustomerID: '
                    . $Param{Config}->{CustomerID}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
            return;
        }
    }

    if (
        defined $Param{Config}->{CustomerUserID}
        &&
        (
            !defined $Param{Ticket}->{CustomerUserID}
            || $Param{Config}->{CustomerUserID} ne $Param{Ticket}->{CustomerUserID}
        )
        )
    {
        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        my $Success = $TicketObject->TicketCustomerSet(
            TicketID => $Param{Ticket}->{TicketID},
            User     => $Param{Config}->{CustomerUserID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket CustomerUserID: '
                    . $Param{Config}->{CustomerUserID}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
            return;
        }
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
