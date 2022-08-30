# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::TicketLockSet;

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

Kernel::System::ProcessManagement::TransitionAction::TicketLockSet - A module to unlock a ticket

=head1 DESCRIPTION

All TicketLockSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketLockSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketLockSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction TicketLockSet.

    my $Success = $TicketLockSetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            Lock  => 'lock',
            # or
            LockID => 1,
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

    if ( !$Param{Config}->{LockID} && !$Param{Config}->{Lock} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No Lock or LockID configured!",
        );
        return;
    }

    $Success = 0;

    # If Ticket's LockID is already the same as the Value we
    # should set it to, we got nothing to do and return success
    if (
        defined $Param{Config}->{LockID}
        && $Param{Config}->{LockID} eq $Param{Ticket}->{LockID}
        )
    {
        return 1;
    }

    # If Ticket's LockID is not the same as the Value we
    # should set it to, set the LockID
    elsif (
        defined $Param{Config}->{LockID}
        && $Param{Config}->{LockID} ne $Param{Ticket}->{LockID}
        )
    {

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        $Success = $TicketObject->TicketLockSet(
            TicketID => $Param{Ticket}->{TicketID},
            LockID   => $Param{Config}->{LockID},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket LockID '
                    . $Param{Config}->{LockID}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }

    # If Ticket's Lock is already the same as the Value we
    # should set it to, we got nothing to do and return success
    elsif (
        defined $Param{Config}->{Lock}
        && $Param{Config}->{Lock} eq $Param{Ticket}->{Lock}
        )
    {
        return 1;
    }

    # If Ticket's Lock is not the same as the Value we
    # should set it to, set the Lock
    elsif (
        defined $Param{Config}->{Lock}
        && $Param{Config}->{Lock} ne $Param{Ticket}->{Lock}
        )
    {
        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        $Success = $TicketObject->TicketLockSet(
            TicketID => $Param{Ticket}->{TicketID},
            Lock     => $Param{Config}->{Lock},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket Lock '
                    . $Param{Config}->{Lock}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . "Couldn't update Ticket Lock - can't find valid Lock parameter!",
        );
        return;
    }

    return $Success;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
