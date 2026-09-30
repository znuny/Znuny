# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Ticket::Unwatch;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::Ticket',
    'Kernel::System::User',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Removes closed tickets from the watched tickets list after a number of days.');
    $Self->AddOption(
        Name        => 'days',
        Description => 'Number of days a ticket has to be closed to be removed from the watch list (default: 7)',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^(?!0)\d+$/a,
        Multiple    => 0,
    );

    $Self->AddOption(
        Name        => 'no-invalid-users',
        Description => 'Ignore agents marked as invalid.',
        Required    => 0,
        HasValue    => 0,
        Multiple    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

    my $NoInvalidUser = $Self->GetOption('no-invalid-users');

    $Self->Print("<yellow>Unwatching closed tickets ...</yellow>\n");

    my %Users = $UserObject->UserList(
        Type          => 'Short',
        NoOutOfOffice => 1,
        Valid         => $NoInvalidUser ? 1 : 0,
    );

    my @TicketIDs = $Self->_GetClosedWatchedTicketIDs( [ keys %Users ] );

    for my $TicketID (@TicketIDs) {
        if ($NoInvalidUser) {

            # Make sure to only unsubscribe users in the valid users list
            my @Watchers = $TicketObject->TicketWatchGet(
                TicketID => $TicketID,
                Result   => 'ARRAY',
            );
            for my $Watcher ( grep { exists $Users{$_} } @Watchers ) {
                $TicketObject->TicketWatchUnsubscribe(
                    TicketID    => $TicketID,
                    WatchUserID => $Watcher,
                    UserID      => 1,
                );
            }
        }
        else {
            # Just unsubscribe everybody
            $TicketObject->TicketWatchUnsubscribe(
                TicketID => $TicketID,
                AllUsers => 1,
                UserID   => 1,
            );
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

# Return a list of ticket IDs for all tickets in the system that are closed
# and have anyone on @$UserIDs watching them
sub _GetClosedWatchedTicketIDs {
    my ( $Self, $UserIDs ) = @_;

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $TicketObject   = $Kernel::OM->Get('Kernel::System::Ticket');

    my $CutoffDays = $Self->GetOption('days') // 7;
    $DateTimeObject->Subtract( Days => $CutoffDays );
    my $CutoffDateTimeString = $DateTimeObject->Format( Format => '%F %T' );

    return $TicketObject->TicketSearch(
        UserID                       => 1,
        Result                       => 'ARRAY',
        StateType                    => 'Closed',
        TicketLastCloseTimeOlderDate => $CutoffDateTimeString,
        WatchUserIDs                 => $UserIDs,
    );
}

1;
