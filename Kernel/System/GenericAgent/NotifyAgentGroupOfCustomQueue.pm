# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::GenericAgent::NotifyAgentGroupOfCustomQueue;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # get used calendar
    my $Calendar = $TicketObject->TicketCalendarGet(
        %Ticket,
    );

    # get time object
    my $StopDateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # check if it is during business hours, then send escalation info
    my $StartDateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            Epoch => $StopDateTimeObject->ToEpoch() - ( 10 * 60 ),
        }
    );

    my $CountedTime = StartDateTimeObject->Delta(
        DateTimeObject => $StopDateTimeObject,
        ForWorkingTime => 1,
        Calendar       => $Calendar,
    );
    if ( !$CountedTime ) {
        if ( $Self->{Debug} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'debug',
                Message =>
                    "Send no escalation for Ticket $Ticket{TicketNumber}/$Ticket{TicketID} because currently no working hours!",
            );
        }
        return 1;
    }

    # check if it's a escalation of escalation notification
    # check escalation times
    my $EscalationType = '';
    TYPE:
    for my $Type (
        qw(FirstResponseTimeEscalation UpdateTimeEscalation SolutionTimeEscalation
        FirstResponseTimeNotification UpdateTimeNotification SolutionTimeNotification)
        )
    {
        if ( defined $Ticket{$Type} ) {
            if ( $Type =~ /TimeEscalation$/ ) {
                $EscalationType = 'Escalation';
                last TYPE;
            }
            elsif ( $Type =~ /TimeNotification$/ ) {
                $EscalationType = 'EscalationNotifyBefore';
                last TYPE;
            }
        }
    }

    # check
    if ( !$EscalationType ) {
        if ( $Self->{Debug} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'debug',
                Message =>
                    "Can't send escalation for Ticket $Ticket{TicketNumber}/$Ticket{TicketID} because ticket is not escalated!",
            );
        }
        return;
    }

    # trigger notification event
    $TicketObject->EventHandler(
        Event => 'Notification' . $EscalationType,
        Data  => {
            TicketID              => $Param{TicketID},
            CustomerMessageParams => \%Param,
        },
        UserID => 1,
    );

    return 1;
}

1;
