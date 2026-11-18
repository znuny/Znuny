# --
# Copyright (C) 2026 Teztarif
# --
package Kernel::System::SaaS::TicketRecommendations;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::SaaS::Tenant',
    'Kernel::System::Ticket',
    'Kernel::System::SaaS::TicketAssist',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

# Tenant context and agent ro permission are mandatory. Never pass candidate
# tickets supplied by the browser; discover them through permission-filtered
# TicketSearch. Suggestions do not mutate ticket or user assignments.
sub Recommend {
    my ( $Self, %Param ) = @_;

    return if !$Param{TicketID} || !$Param{UserID};
    my $Tenant = $Kernel::OM->Get('Kernel::System::SaaS::Tenant');
    my $Context = $Tenant->ContextGet();
    return if !$Context || $Context->{UserID} != $Param{UserID};
    return if !$Tenant->ModuleEnabled( Module => 'ticket_ai' );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    return if !$TicketObject->TicketPermission(
        Type => 'ro', TicketID => $Param{TicketID}, UserID => $Param{UserID},
    );

    my %Ticket = $TicketObject->TicketGet( TicketID => $Param{TicketID}, UserID => $Param{UserID} );
    return if !%Ticket;
    my $Title = $Ticket{Title} // '';
    my $Triage = $Kernel::OM->Get('Kernel::System::SaaS::TicketAssist')->Suggest(
        Subject => $Title,
    );

    my @Candidates = $TicketObject->TicketSearch(
        Result => 'ARRAY', UserID => $Param{UserID}, Permission => 'ro',
        Limit => 120, SortBy => 'Changed', OrderBy => 'Down',
        CacheTTL => 60,
    );

    my @Similar;
    my %OwnerScore;
    my $Words = _Words($Title);
    for my $ID (@Candidates) {
        next if $ID == $Param{TicketID};
        next if !$Tenant->ObjectAccessCheck( ObjectType => 'Ticket', ObjectID => $ID );
        next if !$TicketObject->TicketPermission( Type => 'ro', TicketID => $ID, UserID => $Param{UserID} );

        my %Candidate = $TicketObject->TicketGet( TicketID => $ID, UserID => $Param{UserID} );
        next if !%Candidate;
        my $Score = _Similarity( $Words, _Words( $Candidate{Title} // '' ) );
        next if $Score < 0.35;
        my $IsClosed = ($Candidate{StateType} // '') eq 'closed' ? 1 : 0;
        push @Similar, {
            TicketID => $ID,
            Title    => substr( $Candidate{Title} // '', 0, 180 ),
            Score    => sprintf( '%.2f', $Score ),
            Closed   => $IsClosed,
        };

        # Past owner is only evidence of experience; availability, queue
        # membership and workload must be confirmed before assigning.
        if ( $IsClosed && $Candidate{OwnerID} && $Candidate{OwnerID} > 1 ) {
            $OwnerScore{ $Candidate{OwnerID} } += $Score;
        }
    }
    @Similar = sort { $b->{Score} <=> $a->{Score} } @Similar;
    splice @Similar, 5 if @Similar > 5;

    my ($SuggestedOwnerID) = sort {
        $OwnerScore{$b} <=> $OwnerScore{$a}
    } keys %OwnerScore;

    return {
        Category          => $Triage->{Category},
        SimilarTickets    => \@Similar,
        SuggestedOwnerID  => $SuggestedOwnerID || 0,
        SolutionHint      => (grep { $_->{Closed} } @Similar)
            ? 'Review the linked resolved ticket and verify the fix before applying it.'
            : 'No verified resolved match found. Follow the support runbook.',
        AutoAssigned      => 0,
        AutoClosed        => 0,
        RecommendationType => 'permission-filtered lexical similarity',
    };
}

sub _Words {
    my ($Text) = @_;
    my %Stop = map { $_ => 1 } qw(the and for with this that from not are you your have ticket issue please help);
    my %Words;
    for my $Word ( split /[^[:alnum:]]+/, lc( $Text // '' ) ) {
        next if length($Word) < 3 || $Stop{$Word};
        $Words{$Word} = 1;
    }
    return \%Words;
}

sub _Similarity {
    my ( $A, $B ) = @_;
    my $Total = scalar keys %{$A};
    my $Intersection = 0;
    for my $Word ( keys %{$B} ) {
        $Total++ if !$A->{$Word};
        $Intersection++ if $A->{$Word};
    }
    return $Total ? $Intersection / $Total : 0;
}

1;
