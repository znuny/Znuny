use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

our $Self;

my $SaaSObject = $Kernel::OM->Get('Kernel::System::TeztarifSaaS');

$Self->True(
    $SaaSObject->ModuleAllowed( Plan => 'basic', Module => 'tickets' ),
    'Basic plan permits tickets',
);
$Self->False(
    $SaaSObject->ModuleAllowed( Plan => 'basic', Module => 'reports' ),
    'Basic plan denies reports',
);
$Self->True(
    $SaaSObject->LimitCheck( Plan => 'basic', Resource => 'agents', Current => 4 ),
    'Agent count below limit',
);
$Self->False(
    $SaaSObject->LimitCheck( Plan => 'basic', Resource => 'agents', Current => 5 ),
    'Agent count at limit',
);
$Self->True(
    $SaaSObject->SubscriptionActive( Status => 'trial' ),
    'Trial subscription is active',
);
$Self->False(
    $SaaSObject->SubscriptionActive( Status => 'cancelled' ),
    'Cancelled subscription is inactive',
);

1;

