# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::TicketStateSet;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::TicketStateSet - A module to set the ticket state

=head1 DESCRIPTION

All TicketStateSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketStateSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketStateSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction TicketStateSet.

    my $Success = $TicketStateSetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            State   => 'open',
            # or
            StateID => 3,

            PendingTime     => '2016-02-13 12:00',  # optional, set the pending time to a fixed value
            PendingTimeDiff => 123,                 # optional, used for pending states, difference in seconds from
                                                    # current time to desired pending time (e.g. a value of 3600 means
                                                    # that the pending time will be 1 hr after the Transition Action is
                                                    # executed)
            UserID  => 123,                         # optional, to override the UserID from the logged user
        }
    );

Returns:

    my $Success = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $StateObject  = $Kernel::OM->Get('Kernel::System::State');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

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

    if ( !$Param{Config}->{StateID} && !$Param{Config}->{State} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No State or StateID configured!",
        );
        return;
    }

    $Success = 0;
    my %StateData;

    if ( defined $Param{Config}->{StateID} ) {

        %StateData = $StateObject->StateGet(
            ID => $Param{Config}->{StateID},
        );

        if ( $Param{Config}->{StateID} ne $Param{Ticket}->{StateID} ) {

            $Success = $TicketObject->TicketStateSet(
                TicketID => $Param{Ticket}->{TicketID},
                StateID  => $Param{Config}->{StateID},
                UserID   => $Param{UserID},
            );

            if ( !$Success ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => $CommonMessage
                        . 'Ticket StateID '
                        . $Param{Config}->{StateID}
                        . ' could not be updated for Ticket: '
                        . $Param{Ticket}->{TicketID} . '!',
                );
            }
        }
        else {

            # Data is the same as in ticket nothing to do.
            $Success = 1;
        }

    }
    elsif ( $Param{Config}->{State} ) {

        %StateData = $StateObject->StateGet(
            Name => $Param{Config}->{State},
        );
        if ( $Param{Config}->{State} ne $Param{Ticket}->{State} ) {

            $Success = $TicketObject->TicketStateSet(
                TicketID => $Param{Ticket}->{TicketID},
                State    => $Param{Config}->{State},
                UserID   => $Param{UserID},
            );

            if ( !$Success ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => $CommonMessage
                        . 'Ticket State '
                        . $Param{Config}->{State}
                        . ' could not be updated for Ticket: '
                        . $Param{Ticket}->{TicketID} . '!',
                );
            }
        }
        else {

            # Data is the same as in ticket nothing to do.
            $Success = 1;
        }

    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . "Couldn't update Ticket State - can't find valid State parameter!",
        );
        return;
    }

    # set pending time
    if (
        %StateData
        && $StateData{TypeName} =~ m{\A pending}msxi
        && IsNumber( $Param{Config}->{PendingTimeDiff} )
        )
    {

        # get datetime object
        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
        $DateTimeObject->Add( Seconds => $Param{Config}->{PendingTimeDiff} );

        my $DateTimeString = $DateTimeObject->ToString();

        # set pending time
        $TicketObject->TicketPendingTimeSet(
            UserID   => $Param{UserID},
            TicketID => $Param{Ticket}->{TicketID},
            String   => $DateTimeString,
        );
    }

    return $Success if !$Success;
    return $Success if !%StateData;
    return $Success if $StateData{TypeName} !~ m{\A pending}msxi;
    return $Success if !IsStringWithData( $Param{Config}->{PendingTime} );

    # set pending time
    $TicketObject->TicketPendingTimeSet(
        UserID   => $Param{UserID},
        TicketID => $Param{Ticket}->{TicketID},
        String   => $Param{Config}->{PendingTime},
    );

    return $Success;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
