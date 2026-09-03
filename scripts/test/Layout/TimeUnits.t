# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic(RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$Kernel::OM->ObjectParamAdd(
    'Kernel::Output::HTML::Layout' => {
        Lang => 'en',
    },
);
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

my $UnitTestParamObject = $Kernel::OM->Get('Kernel::System::UnitTest::Param');

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::Frontend::AccountTimeType',
    Value => 'Dropdown',
);

$UnitTestParamObject->ParamSet(
    Name  => 'TimeUnitsHours',
    Value => '3600',
);
$UnitTestParamObject->ParamSet(
    Name  => 'TimeUnitsMinutes',
    Value => '300',
);
$UnitTestParamObject->ParamSet(
    Name  => 'TimeUnits',
    Value => '3900',
);

my $HTML = $LayoutObject->TimeUnits(
    TimeUnits => '3900',
);

$Self->True(
    $HTML =~ m{ name="TimeUnitsHours" .*? value="3600" .*? selected }smx,
    'TimeUnits() restores Hours dropdown value from request params',
);

$Self->True(
    $HTML =~ m{ name="TimeUnitsMinutes" .*? value="300" .*? selected }smx,
    'TimeUnits() restores Minutes dropdown value from request params',
);

$Self->True(
    $HTML =~ m{ name="TimeUnits" .*? value="3900" }smx,
    'TimeUnits() keeps hidden TimeUnits value from request params',
);

1;
