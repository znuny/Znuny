# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::Event::TriggerEscalationStopEvents;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Event UserID Config)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    for my $Needed (qw(OldTicketData TicketID)) {
        if ( !$Param{Data}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get the current escalation status
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{Data}->{TicketID},
        UserID        => $Param{UserID},
        DynamicFields => 0,
    );

    # compare old and the current escalation status
    my %Attr2Event = (
        FirstResponseTimeEscalation => 'EscalationResponseTimeStop',
        UpdateTimeEscalation        => 'EscalationUpdateTimeStop',
        SolutionTimeEscalation      => 'EscalationSolutionTimeStop',
    );

    while ( my ( $Attr, $Event ) = each %Attr2Event ) {

        if ( $Param{Data}->{OldTicketData}->{$Attr} && !$Ticket{$Attr} ) {

            # trigger the event
            $TicketObject->EventHandler(
                Event  => $Event,
                UserID => $Param{UserID},
                Data   => {
                    TicketID      => $Param{Data}->{TicketID},
                    OldTicketData => $Param{Data}->{OldTicketData},
                },
            );

            # log the triggered event in the history
            $TicketObject->HistoryAdd(
                TicketID     => $Param{Data}->{TicketID},
                HistoryType  => $Event,
                Name         => "%%$Event%%triggered",
                CreateUserID => $Param{UserID},
            );
        }
    }

    return 1;
}

1;
