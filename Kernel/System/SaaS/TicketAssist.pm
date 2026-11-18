# --
# Copyright (C) 2026 Teztarif
# --
package Kernel::System::SaaS::TicketAssist;

use strict;
use warnings;

# Intentionally deterministic and provider-free. This is a low-cost
# baseline for ticket triage, NOT a trained AI/ML model.
# The caller must enforce the authenticated tenant and ticket permissions
# before passing any text or authorized candidates to this helper.
sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Suggest {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Subject} && !defined $Param{Body};
    my $Text = join ' ', map { defined $_ ? $_ : '' } ( $Param{Subject}, $Param{Body} );
    $Text = lc substr( $Text, 0, 20000 );

    my %Patterns = (
        network  => qr/\b(?:internet|wifi|wi-fi|router|dns|network|vpn|connectivity)\b/i,
        hardware => qr/\b(?:printer|keyboard|mouse|monitor|laptop|desktop|hardware|scanner)\b/i,
        software => qr/\b(?:software|application|app|install|crash|update|login|password)\b/i,
        billing  => qr/\b(?:invoice|billing|payment|refund|amount|charged)\b/i,
    );

    my @Matches = sort grep { $Text =~ $Patterns{$_} } keys %Patterns;
    my $Category = @Matches == 1 ? $Matches[0] : 'manual-review';

    # Priority recommendations are not safe to infer from a keyword alone.
    # SLA, affected users, contractual impact and outage must be verified.
    return {
        Category            => $Category,
        NeedsHumanReview    => @Matches == 1 ? 0 : 1,
        SuggestedAction     => 'Review ticket category and search authorized knowledge base.',
        AIModelUsed         => 0,
        AutomaticAssignment => 0,
        AutomaticClosure    => 0,
    };
}

1;
