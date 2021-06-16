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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomNumber1 = $HelperObject->GetRandomNumber();
my $RandomNumber2 = $HelperObject->GetRandomNumber();

my %StartConfig = $ZnunyHelperObject->_ProcessWidgetDynamicFieldGroupsGet();

$Self->True(
    \%StartConfig,
    "StartConfig",
);

my %ProcessWidgetDynamicFieldGroupsAdd = (
    "Group $RandomNumber1" => [
        'TestDynamicField1',
        'TestDynamicField2',
        'TestDynamicField3',
    ],
    "Group $RandomNumber2" => []
);

my $Success = $ZnunyHelperObject->_ProcessWidgetDynamicFieldGroupsAdd(%ProcessWidgetDynamicFieldGroupsAdd);

my %AfterAddConfig = $ZnunyHelperObject->_ProcessWidgetDynamicFieldGroupsGet();

my %ExpectedConfig = (
    %StartConfig,
    %ProcessWidgetDynamicFieldGroupsAdd,
);

$Self->IsDeeply(
    \%AfterAddConfig,
    \%ExpectedConfig,
    'ProcessWidgetDynamicFieldGroupsAdd was successful',
);

$Success = $ZnunyHelperObject->_ProcessWidgetDynamicFieldGroupsRemove(%ProcessWidgetDynamicFieldGroupsAdd);

my %AfterRemoveConfig = $ZnunyHelperObject->_ProcessWidgetDynamicFieldGroupsGet();

$Self->IsDeeply(
    \%AfterRemoveConfig,
    \%StartConfig,
    'ProcessWidgetDynamicFieldGroupsRemove was successful',
);

1;
