# --
# Copyright (C) 2026 Teztarif
# --
use strict;
use warnings;

use vars (qw($Self));

my $Permission = $Kernel::OM->Get('Kernel::System::SaaS::Permission');

$Self->False(
    $Permission->Check(
        UserID => 1, Module => 'tickets', Action => 'view', Scope => 'company',
    ),
    'No authenticated tenant context denies access',
);
$Self->False(
    $Permission->Check(
        UserID => 1, Module => 'tickets', Action => 'invalid', Scope => 'company',
    ),
    'Unknown action fails closed',
);
$Self->False(
    $Permission->Check(
        UserID => 1, Module => 'tickets', Action => 'edit', Scope => 'global',
    ),
    'Unsupported cross-company scope fails closed',
);
my $Modules = $Permission->VisibleModules( UserID => 1 );
$Self->Is( scalar @{$Modules}, 0, 'No context yields an empty sidebar module list' );

1;
