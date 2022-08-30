# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use vars (qw($Self));

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new();

$Kernel::OM->ObjectParamAdd(
    'Kernel::Config' => {
        Data => 'Test payload',
    },
);

$Self->IsDeeply(
    $Kernel::OM->{Param}->{'Kernel::Config'},
    {
        Data => 'Test payload',
    },
    'ObjectParamAdd set key',
);

$Kernel::OM->ObjectParamAdd(
    'Kernel::Config' => {
        Data2 => 'Test payload 2',
    },
);

$Self->IsDeeply(
    $Kernel::OM->{Param}->{'Kernel::Config'},
    {
        Data  => 'Test payload',
        Data2 => 'Test payload 2',
    },
    'ObjectParamAdd set key',
);

$Kernel::OM->ObjectParamAdd(
    'Kernel::Config' => {
        Data => undef,
    },
);

$Self->IsDeeply(
    $Kernel::OM->{Param}->{'Kernel::Config'},
    {
        Data2 => 'Test payload 2',
    },
    'ObjectParamAdd removed key',
);

$Kernel::OM->ObjectParamAdd(
    'Kernel::Config' => {
        Data2 => undef,
    },
);

$Self->IsDeeply(
    $Kernel::OM->{Param}->{'Kernel::Config'},
    {},
    'ObjectParamAdd removed key',
);

1;
