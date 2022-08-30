# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Ticket::RestoreFromArchive;

use strict;
use warnings;

use Time::HiRes();

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Restore non-closed tickets from the ticket archive.');
    $Self->AddOption(
        Name        => 'micro-sleep',
        Description => "Specify microseconds to sleep after every ticket to reduce system load (e.g. 1000).",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Restoring tickets from ticket archive...</yellow>\n");

    # disable ticket events
    $Kernel::OM->Get('Kernel::Config')->{'Ticket::EventModulePost'} = {};

    # check if archive system is activated
    if ( !$Kernel::OM->Get('Kernel::Config')->Get('Ticket::ArchiveSystem') ) {
        $Self->Print("<green>No action required. The archive system is disabled at the moment.</green>\n");
        return $Self->ExitCodeOk();
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get all tickets with an archive flag and an open statetype
    my @TicketIDs = $TicketObject->TicketSearch(
        StateType    => [ 'new', 'open', 'pending reminder', 'pending auto' ],
        ArchiveFlags => ['y'],
        Result       => 'ARRAY',
        Limit        => 100_000_000,
        UserID       => 1,
        Permission   => 'ro',
    );

    my $TicketNumber = scalar @TicketIDs;
    my $Count        = 1;
    my $MicroSleep   = $Self->GetOption('micro-sleep');

    TICKETID:
    for my $TicketID (@TicketIDs) {

        # restore ticket from archive
        $TicketObject->TicketArchiveFlagSet(
            TicketID    => $TicketID,
            UserID      => 1,
            ArchiveFlag => 'n',
        );

        # output state
        if ( $Count % 2000 == 0 ) {
            my $Percent = int( $Count / ( $TicketNumber / 100 ) );
            $Self->Print(
                "<yellow>$Count</yellow> of <yellow>$#TicketIDs</yellow> processed (<yellow>$Percent %</yellow> done).\n"
            );
        }

        $Count++;

        Time::HiRes::usleep($MicroSleep) if $MicroSleep;
    }

    $Self->Print("<green>Done ($TicketNumber tickets restored).</green>\n");
    return $Self->ExitCodeOk();
}

1;
