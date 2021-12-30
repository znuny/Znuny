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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

use Kernel::System::VariableCheck qw(:all);

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject   = $Kernel::OM->Get('Kernel::System::SysConfig');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @Tests = (
    {
        Name      => 'Missing Module parameter',
        Parameter => {
            Group   => ['user'],
            GroupRo => ['some_other_group'],
        },
        ExpectedResult        => 0,
        ExpectedAddGroup      => [],
        ExpectedAddGroupRo    => [],
        ExpectedRemoveGroup   => [],
        ExpectedRemoveGroupRo => [],
    },
    {
        Name      => 'Add groups without Frontend parameter',
        Parameter => {
            Module  => 'Admin',
            Group   => ['user'],
            GroupRo => ['some_other_group'],
        },
        ExpectedResult        => 1,
        ExpectedAddGroup      => [ 'admin', 'user' ],
        ExpectedAddGroupRo    => ['some_other_group'],
        ExpectedRemoveGroup   => ['admin'],
        ExpectedRemoveGroupRo => [],
    },
    {
        Name      => 'Add groups with Frontend parameter',
        Parameter => {
            Module   => 'PublicDefault',
            Frontend => 'PublicFrontend::Module',
            Group    => ['user'],
            GroupRo  => ['some_other_group'],
        },
        ExpectedResult        => 1,
        ExpectedAddGroup      => ['user'],
        ExpectedAddGroupRo    => ['some_other_group'],
        ExpectedRemoveGroup   => [],
        ExpectedRemoveGroupRo => [],
    },

);

TEST:
for my $Test (@Tests) {

    my %OldData;
    my $Frontend = $Test->{Parameter}->{Frontend} || 'Frontend::Module';
    my $Module   = $Test->{Parameter}->{Module};
    if (
        $Module
        && IsHashRefWithData( $ConfigObject->Get($Frontend)->{$Module} )
        )
    {
        %OldData = %{ $ConfigObject->Get($Frontend)->{$Module} };
    }

    #
    # Add
    #

    my $AddResult = $ZnunyHelperObject->_ModuleGroupAdd(
        %{ $Test->{Parameter} },
    );
    $AddResult = $AddResult ? 1 : 0;

    $Self->Is(
        $AddResult,
        $Test->{ExpectedResult},
        $Test->{Name} . ': Result of _ModuleGroupAdd() must match expected one.',
    );

    next TEST if $AddResult != $Test->{ExpectedResult};

    next TEST if !$Test->{ExpectedResult};

    my %SettingGet = $SysConfigObject->SettingGet(
        Name => $Frontend . '###' . $Module,
    );

    my %NewData = %{ $SettingGet{EffectiveValue} };

    for my $GroupType (qw(Group GroupRo)) {

        $Self->IsDeeply(
            $NewData{$GroupType},
            $Test->{ 'ExpectedAdd' . $GroupType },
            $Test->{Name} . ": $GroupType Add must match expected one.",
        );
    }

    #
    # Remove
    #

    my $RemoveResult = $ZnunyHelperObject->_ModuleGroupRemove(
        %{ $Test->{Parameter} },
    );
    $RemoveResult = $RemoveResult ? 1 : 0;

    $Self->Is(
        $RemoveResult,
        $Test->{ExpectedResult},
        $Test->{Name} . ': Result of _ModuleGroupRemove() must match expected one.',
    );

    next TEST if $RemoveResult != $Test->{ExpectedResult};

    # refetch config object because it was discarded by _PackageSetupInit
    $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    %SettingGet = $SysConfigObject->SettingGet(
        Name => $Frontend . '###' . $Module,
    );

    %NewData = %{ $SettingGet{EffectiveValue} };

    for my $GroupType (qw(Group GroupRo)) {

        $Self->IsDeeply(
            $NewData{$GroupType},
            $Test->{ 'ExpectedRemove' . $GroupType },
            $Test->{Name} . ": $GroupType Remove must match expected one.",
        );
    }
}

1;
