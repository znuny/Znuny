# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::ForceResponsibleReset;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

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

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # reset responsible
    $TicketObject->TicketResponsibleSet(
        TicketID           => $Param{Data}->{TicketID},
        NewUserID          => 1,
        SendNoNotification => 1,
        UserID             => 1,
    );

    return 1;
}

1;
