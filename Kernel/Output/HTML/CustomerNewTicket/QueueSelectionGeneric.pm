# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw( UserID SystemAddress)) {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');

    # check if own selection is configured
    my %NewTos;
    if ( $ConfigObject->{CustomerPanelOwnSelection} ) {
        for my $Queue ( sort keys %{ $ConfigObject->{CustomerPanelOwnSelection} } ) {
            my $Value = $ConfigObject->{CustomerPanelOwnSelection}->{$Queue};
            if ( $Queue =~ /^\d+$/ ) {
                $NewTos{$Queue} = $Value;
            }
            else {
                if ( $QueueObject->QueueLookup( Queue => $Queue ) ) {
                    $NewTos{ $QueueObject->QueueLookup( Queue => $Queue ) } = $Value;
                }
                else {
                    $NewTos{$Queue} = $Value;
                }
            }
        }

        # check create permissions
        my %Queues = $TicketObject->MoveList(
            %{ $Param{ACLParams} },
            CustomerUserID => $Param{Env}->{UserID},
            Type           => 'create',
            Action         => $Param{Env}->{Action},
        );
        for my $QueueID ( sort keys %NewTos ) {
            if ( !$Queues{$QueueID} ) {
                delete $NewTos{$QueueID};
            }
        }
    }
    else {

        # SelectionType Queue or SystemAddress?
        my %Tos;
        if ( $ConfigObject->Get('CustomerPanelSelectionType') eq 'Queue' ) {
            %Tos = $TicketObject->MoveList(
                %{ $Param{ACLParams} },
                CustomerUserID => $Param{Env}->{UserID},
                Type           => 'create',
                Action         => $Param{Env}->{Action},
            );
        }
        else {
            my %Queues = $TicketObject->MoveList(
                %{ $Param{ACLParams} },
                CustomerUserID => $Param{Env}->{UserID},
                Type           => 'create',
                Action         => $Param{Env}->{Action},
            );
            my %SystemTos = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList();
            for my $QueueID ( sort keys %Queues ) {
                if ( $SystemTos{$QueueID} ) {
                    $Tos{$QueueID} = $Queues{$QueueID};
                }
            }
        }
        %NewTos = %Tos;

        # build selection string
        for my $QueueID ( sort keys %NewTos ) {
            my %QueueData = $QueueObject->QueueGet( ID => $QueueID );
            my $String    = $ConfigObject->Get('CustomerPanelSelectionString')
                || '<Realname> <<Email>> - Queue: <Queue>';
            $String =~ s/<Queue>/$QueueData{Name}/g;
            $String =~ s/<QueueComment>/$QueueData{Comment}/g;
            if ( $ConfigObject->Get('CustomerPanelSelectionType') ne 'Queue' ) {
                my %SystemAddressData = $Self->{SystemAddress}->SystemAddressGet( ID => $QueueData{SystemAddressID} );
                $String =~ s/<Realname>/$SystemAddressData{Realname}/g;
                $String =~ s/<Email>/$SystemAddressData{Name}/g;
            }
            $NewTos{$QueueID} = $String;
        }
    }
    return %NewTos;
}

1;
