# --
# Copyright (C) 2026 Teztarif
# --
use strict;
use warnings;

use vars (qw($Self));

my $Recommendations = $Kernel::OM->Get('Kernel::System::SaaS::TicketRecommendations');

my $A = Kernel::System::SaaS::TicketRecommendations::_Words(
    'Printer network issue: printer offline'
);
my $B = Kernel::System::SaaS::TicketRecommendations::_Words(
    'Printer offline in office'
);
my $Similarity = Kernel::System::SaaS::TicketRecommendations::_Similarity($A, $B);
$Self->True( $Similarity > 0, 'Meaningful overlapping terms yield similarity' );
$Self->Is(
    Kernel::System::SaaS::TicketRecommendations::_Similarity({}, {}),
    0,
    'Empty titles are not a duplicate match',
);
$Self->Is(
    Kernel::System::SaaS::TicketRecommendations::_Similarity(
        Kernel::System::SaaS::TicketRecommendations::_Words('wifi router'),
        Kernel::System::SaaS::TicketRecommendations::_Words('salary invoice'),
    ),
    0,
    'Unrelated issues do not match',
);

$Self->False(
    $Recommendations->Recommend( TicketID => 123456, UserID => 1 ),
    'Without an authenticated tenant context, no recommendation is returned',
);

1;
