# --
# Copyright (C) 2026 Teztarif
# --
use strict;
use warnings;

use vars (qw($Self));

my $Assist = $Kernel::OM->Get('Kernel::System::SaaS::TicketAssist');

my $Network = $Assist->Suggest( Subject => 'Office internet down' );
$Self->Is( $Network->{Category}, 'network', 'Single topic is classified' );
$Self->False( $Network->{AIModelUsed}, 'No paid model call for simple triage' );
$Self->False( $Network->{AutomaticClosure}, 'No automatic closure' );

my $Ambiguous = $Assist->Suggest( Subject => 'Invoice and printer issue' );
$Self->Is( $Ambiguous->{Category}, 'manual-review', 'Ambiguous topics require human triage' );
$Self->True( $Ambiguous->{NeedsHumanReview}, 'Human review flagged' );

my $Unknown = $Assist->Suggest( Subject => 'Please help immediately' );
$Self->Is( $Unknown->{Category}, 'manual-review', 'Unrecognized tickets are not guessed' );

1;
