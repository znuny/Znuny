# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UtilObject   = $Kernel::OM->Get('Kernel::System::Util');

#
# IsITSMInstalled()
#

my $IsITSMInstalled = $UtilObject->IsITSMInstalled();

$Self->False(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being not installed.',
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Frontend::Module###AdminITSMCIPAllocate',
    Value => {
        'Group' => [
            'admin'
        ],
        'GroupRo'     => [],
        'Description' => 'Manage priority matrix.',
        'Title'       => 'Criticality ↔ Impact ↔ Priority',
        'NavBarName'  => 'Admin',
    },
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Util'],
);

$UtilObject      = $Kernel::OM->Get('Kernel::System::Util');
$IsITSMInstalled = $UtilObject->IsITSMInstalled();

$Self->True(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being installed.',
);

#
# IsFrontendContext()
#

my $IsFrontendContext = $UtilObject->IsFrontendContext();

$Self->False(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report no frontend context.',
);

# Fake frontend context.
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
$LayoutObject->{Action} = 'AgentTicketZoom';

$IsFrontendContext = $UtilObject->IsFrontendContext();

$Self->True(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report frontend context.',
);

1;
