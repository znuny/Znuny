# --
# Copyright (C) 2026 Teztarif
# --
use strict;
use warnings;

use vars (qw($Self));

my $Navigation = $Kernel::OM->Get('Kernel::System::SaaS::Navigation');
$Self->Is(
    $Navigation->_ModuleForAction( Action => 'AgentTicketZoom' ),
    'tickets',
    'Ticket zoom is mapped to tickets license',
);
$Self->Is(
    $Navigation->_ModuleForAction( Action => 'AgentDashboard' ),
    'dashboard',
    'Dashboard is mapped to dashboard license',
);
$Self->False(
    $Navigation->_ModuleForAction( Action => 'AdminUser' ),
    'Unmapped admin actions are identified for further authorization work',
);
$Self->False(
    $Navigation->AllowedAction( Action => 'AgentTicketZoom' ),
    'No authenticated user is denied',
);

1;
