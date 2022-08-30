# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Event::ObjectType::Article;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

=head1 NAME

Kernel::GenericInterface::Event::ObjectType::Article - GenericInterface event data handler

=head1 SYNOPSIS

This event handler gathers data from objects.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub DataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    for my $Needed (qw(Data)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my %IDs;
    $IDs{ArticleID} = $Param{Data}->{ArticleID};
    $IDs{TicketID}  = $Param{Data}->{TicketID};

    for my $Needed (qw(ArticleID TicketID)) {
        if ( !$IDs{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if (
        defined $Param{InvokerType}
        && $Param{InvokerType} eq 'Ticket::Generic'
        )
    {
        my %Ticket = $TicketObject->TicketDeepGet(
            %IDs,
            UserID => 1,
        );
        return %Ticket;
    }

    # Get ticket data to be able to filtering conditions at article event (see bug#13708).
    my %TicketData = $TicketObject->TicketGet(
        TicketID      => $Param{Data}->{TicketID},
        DynamicFields => 1,
        UserID        => 1,
    );

    my $ArticleBackendObject = $ArticleObject->BackendForArticle(%IDs);

    my %ObjectData = $ArticleBackendObject->ArticleGet(
        %IDs,
        DynamicFields => 1,
        RealNames     => 1,
        UserID        => 1,
    );

    return ( %TicketData, %ObjectData );

}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
