# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::Event::TicketProcessTransitions;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::ProcessManagement::Process',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Data Event Config UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # listen to all kinds of events
    if ( !$Param{Data}->{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID in Data!",
        );
        return;
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get ticket data in silent mode, it could be that the ticket was deleted
    #   in the meantime.
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{Data}->{TicketID},
        DynamicFields => 1,
        Silent        => 1,
    );

    return if !%Ticket;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ProcessIDField  = $ConfigObject->Get("Process::DynamicFieldProcessManagementProcessID");
    my $ProcessEntityID = $Ticket{"DynamicField_$ProcessIDField"};

    my $ActivityIDField  = $ConfigObject->Get("Process::DynamicFieldProcessManagementActivityID");
    my $ActivityEntityID = $Ticket{"DynamicField_$ActivityIDField"};

    # ticket can be ignored if it is no process ticket. Don't set the cache key in this case as
    #   later events might make a transition check neccessary.
    return if ( !$ProcessEntityID || !$ActivityEntityID );

    # Ticket can be ignored if it does not belong to an active or fadeaway process.
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
    my $ProcessList   = $ProcessObject->ProcessList(
        ProcessState => [ 'Active', 'FadeAway' ],
        Interface    => 'all',
        Silent       => 1,
    );
    return if !$ProcessList->{$ProcessEntityID};

    # ok, now we know that we need to call the sequence flow logic for this ticket.

    # Loop protection: track visited activities per ticket, not just "was processed".
    # This allows chained transitions (A→B→C) while preventing loops (A→B→A).
    # See bug#9748 for original loop protection rationale.
    my $CacheKey = '_TicketProcessTransitions::VisitedActivities';
    $TicketObject->{$CacheKey}->{ $Param{Data}->{TicketID} } //= {};

    # If we already visited this activity in this request, stop (actual loop detected).
    return if $TicketObject->{$CacheKey}->{ $Param{Data}->{TicketID} }->{$ActivityEntityID};

    # Mark current activity as visited before processing to prevent recursion.
    $TicketObject->{$CacheKey}->{ $Param{Data}->{TicketID} }->{$ActivityEntityID} = 1;

    my $TransitionApplied = $ProcessObject->ProcessTransition(
        ProcessEntityID  => $ProcessEntityID,
        ActivityEntityID => $ActivityEntityID,
        TicketID         => $Param{Data}->{TicketID},
        UserID           => $Param{UserID},
    );

    if ( $Self->{Debug} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  =>
                "Transition for to TicketID: $Param{Data}->{TicketID}"
                . "  ProcessEntityID: $ProcessEntityID OldActivityEntityID: $ActivityEntityID "
                . ( $TransitionApplied ? "was applied." : "was not applied." ),
        );
    }

    return 1;
}

1;
