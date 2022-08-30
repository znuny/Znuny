# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Ticket::Delete;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete one or more tickets.');
    $Self->AddOption(
        Name        => 'ticket-number',
        Description => "Specify one or more ticket numbers of tickets to be deleted.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
        Multiple    => 1,
    );
    $Self->AddOption(
        Name        => 'ticket-id',
        Description => "Specify one or more ticket ids of tickets to be deleted.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/\d+/smx,
        Multiple    => 1,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my @TicketIDs     = @{ $Self->GetOption('ticket-id')     // [] };
    my @TicketNumbers = @{ $Self->GetOption('ticket-number') // [] };

    if ( !@TicketIDs && !@TicketNumbers ) {
        die "Please provide option --ticket-id or --ticket-number.\n";
    }

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Deleting tickets...</yellow>\n");

    my @TicketIDs     = @{ $Self->GetOption('ticket-id')     // [] };
    my @TicketNumbers = @{ $Self->GetOption('ticket-number') // [] };

    my @DeleteTicketIDs;

    TICKETNUMBER:
    for my $TicketNumber (@TicketNumbers) {

        # lookup ticket id
        my $TicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketIDLookup(
            TicketNumber => $TicketNumber,
            UserID       => 1,
        );

        # error handling
        if ( !$TicketID ) {
            $Self->PrintError("Unable to find ticket number $TicketNumber.\n");
            next TICKETNUMBER;
        }

        push @DeleteTicketIDs, $TicketID;
    }

    TICKETID:
    for my $TicketID (@TicketIDs) {

        # lookup ticket number
        my $TicketNumber = $Kernel::OM->Get('Kernel::System::Ticket')->TicketNumberLookup(
            TicketID => $TicketID,
            UserID   => 1,
        );

        # error handling
        if ( !$TicketNumber ) {
            $Self->PrintError("Unable to find ticket id $TicketID.\n");
            next TICKETID;
        }

        push @DeleteTicketIDs, $TicketID;
    }

    my $DeletedTicketCount = 0;

    TICKETID:
    for my $TicketID (@DeleteTicketIDs) {

        # delete the ticket
        my $True = $Kernel::OM->Get('Kernel::System::Ticket')->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );

        # error handling
        if ( !$True ) {
            $Self->PrintError("Unable to delete ticket with id $TicketID\n");
            next TICKETID;
        }

        $Self->Print("  $TicketID\n");

        # increase the deleted ticket count
        $DeletedTicketCount++;
    }

    if ( !$DeletedTicketCount ) {
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>$DeletedTicketCount tickets have been deleted.</green>\n");
    return $Self->ExitCodeOk();
}

1;
