# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::CustomerCompany::Event::TicketUpdate;

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
    for my $Needed (qw( Data Event Config UserID )) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    for my $Needed (qw( CustomerID OldCustomerID )) {
        if ( !$Param{Data}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    # only update if CustomerID has really changed
    return 1 if $Param{Data}->{CustomerID} eq $Param{Data}->{OldCustomerID};

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # create ticket object and perform search
    my @Tickets = $TicketObject->TicketSearch(
        Result        => 'ARRAY',
        Limit         => 100_000,
        CustomerIDRaw => $Param{Data}->{OldCustomerID},
        ArchiveFlags  => [ 'y', 'n' ],
        UserID        => 1,
    );

    # update the customer ID of tickets
    for my $TicketID (@Tickets) {
        $TicketObject->TicketCustomerSet(
            No       => $Param{Data}->{CustomerID},
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
    }

    return 1;
}

1;
