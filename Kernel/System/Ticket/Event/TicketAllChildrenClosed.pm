# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::TicketAllChildrenClosed;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::LinkObject',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::System::Ticket::Event::TicketAllChildrenClosed - A module to trigger an event after all child tickets have been closed.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketAllChildrenClosedObject = $Kernel::OM->Get('Kernel::System::Ticket::Event::TicketAllChildrenClosed');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

    Run Data

    my $Success = $TicketAllChildTicketsClosedObject->Run(
        Data    => {
            TicketID => TicketID,
        },
        Event   => $EventName,
        Config  => $Config,
        UserID  => $UserID,
    )

    If all child tickets of a parent ticket are closed/merged/removed,
    the event 'TicketAllChildrenClosed' will be triggered.

    Returns:

    $Success = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');

    NEEDED:
    for my $Needed (qw( Data Event Config UserID )) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    NEEDED:
    for my $Needed (qw(TicketID)) {
        next NEEDED if $Param{Data}->{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in Data!"
        );
        return;
    }

    my %LinkedParentTickets = $LinkObject->LinkKeyList(
        Object1   => 'Ticket',
        Key1      => $Param{Data}->{TicketID},
        Object2   => 'Ticket',
        State     => 'Valid',
        Type      => 'ParentChild',
        Direction => 'Source',
        UserID    => $Param{UserID},
    );

    return 1 if !%LinkedParentTickets;

    PARENTTICKETID:
    for my $ParentTicketID ( sort keys %LinkedParentTickets ) {
        my %LinkedChildren = $LinkObject->LinkKeyList(
            Object1   => 'Ticket',
            Key1      => $ParentTicketID,
            Object2   => 'Ticket',
            State     => 'Valid',
            Type      => 'ParentChild',
            Direction => 'Target',
            UserID    => $Param{UserID},
        );

        my $AllChildTicketsClosed = 1;

        CHILDTICKETID:
        for my $ChildTicketID ( sort keys %LinkedChildren ) {
            my %ChildTicket = $TicketObject->TicketGet(
                TicketID => $ChildTicketID,
            );

            next CHILDTICKETID if !%ChildTicket;
            next CHILDTICKETID if $ChildTicket{StateType} =~ m{\A(closed|merged|removed)\z};

            $AllChildTicketsClosed = 0;
            last CHILDTICKETID;
        }

        next PARENTTICKETID if !$AllChildTicketsClosed;

        $TicketObject->EventHandler(
            Event => 'TicketAllChildrenClosed',
            Data  => {
                TicketID => $ParentTicketID,
            },
            UserID      => $Param{UserID},
            Transaction => 0,
        );
    }

    return 1;
}

1;
