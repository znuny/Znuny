# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $StatsObject = $Kernel::OM->Get('Kernel::System::Stats');

my $Stats = $StatsObject->StatsListGet(
    UserID => 1,
);

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$Self->True(
    scalar keys %{$Stats},
    ( scalar keys %{$Stats} ) . " Stats found",
);

STATID:
for my $StatID ( sort { int $a <=> int $b } keys %{$Stats} ) {
    my $Stat   = $StatsObject->StatsGet( StatID => $StatID );
    my $Object = $Stat->{Object} // '';

    next STATID if ( $Stat->{StatType} eq 'static' );

    my $ResultLive = $StatsObject->StatsRun(
        StatID   => $StatID,
        GetParam => $Stat,
        UserID   => 1,
    );

    $Self->True(
        ref $ResultLive eq 'ARRAY',
        "StatsRun live mode (StatID $StatID)",
    );

    my $ResultPreview = $StatsObject->StatsRun(
        StatID   => $StatID,
        GetParam => $Stat,
        Preview  => 1,
        UserID   => 1,
    );

    $Self->True(
        ref $ResultPreview eq 'ARRAY',
        "StatsRun preview mode (StatID $StatID) $Object",
    ) || next STATID;

    $Self->True(
        ref $ResultPreview->[1] eq 'ARRAY',
        "StatsRun preview mode headline (StatID $StatID) $Object",
    ) || next STATID;

    $Self->Is(
        scalar @{ $ResultPreview->[1] },
        scalar @{ $ResultLive->[1] },
        "StatsRun preview result has same number of columns in Row 1 as live result (StatID $StatID) $Object",
    );

    # TicketList stats make a ticket search and that could return identical results in preview and live
    #   if there are not enough tickets in the system (for example just one).
    # Stats without data rows return the same empty structure in both modes on a fresh database.
    if ( $Object ne 'TicketList' && ref $ResultLive eq 'ARRAY' && @{$ResultLive} > 2 ) {
        $Self->IsNotDeeply(
            $ResultLive,
            $ResultPreview,
            "StatsRun differs between live and preview (StatID $StatID)",
        );
    }
}

# cleanup is done by RestoreDatabase.

1;
