# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::Event::TicketPendingTimeReset;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
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
    for my $Needed (qw(Data Event Config)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    for my $Needed (qw(TicketID)) {
        if ( !$Param{Data}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # read pending state types from config
    my $PendingReminderStateType =
        $ConfigObject->Get('Ticket::PendingReminderStateType:') || 'pending reminder';

    my $PendingAutoStateType =
        $ConfigObject->Get('Ticket::PendingAutoStateType:') || 'pending auto';

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get ticket
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{Data}->{TicketID},
        UserID        => 1,
        DynamicFields => 0,
    );
    return if !%Ticket;

    # only set the pending time to 0 if it's actually set
    return 1 if !defined $Ticket{UntilTime};

    # only set the pending time to 0 if the new state is NOT a pending state
    return 1 if $Ticket{StateType} eq $PendingReminderStateType;
    return 1 if $Ticket{StateType} eq $PendingAutoStateType;

    # reset pending date/time
    return if !$TicketObject->TicketPendingTimeSet(
        TicketID => $Param{Data}->{TicketID},
        UserID   => $Param{UserID},
        String   => '0000-00-00 00:00:00',
    );

    return 1;
}

1;
