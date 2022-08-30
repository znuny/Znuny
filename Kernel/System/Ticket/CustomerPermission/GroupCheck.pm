# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::CustomerPermission::GroupCheck;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CustomerGroup',
    'Kernel::System::Log',
    'Kernel::System::Queue',
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
    for my $Needed (qw(TicketID UserID Type)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get ticket data
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
    );

    return if !%Ticket;
    return if !$Ticket{QueueID};

    # get ticket group
    my $GroupID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID(
        QueueID => $Ticket{QueueID},
    );

    # get user groups
    my %GroupIDs = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupMemberList(
        UserID => $Param{UserID},
        Type   => $Param{Type},
        Result => 'HASH',
    );

    # return access if customer is in group
    return 1 if $GroupIDs{$GroupID};

    # return no access
    return;
}

1;
