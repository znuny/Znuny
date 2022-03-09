# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @FrameworkVersionParts = split /\./, $Kernel::OM->Get('Kernel::Config')->Get('Version');
my $FrameworkVersion      = $FrameworkVersionParts[0];

my @Tests = (
    {
        Name           => 'No Repositories',
        ConfigSet      => {},
        Success        => 1,
        ExpectedResult => {},
    },
    {
        Name      => 'No ITSM Repositories',
        ConfigSet => {
            'http://znuny.org' => 'Test Repository',
        },
        Success        => 1,
        ExpectedResult => {
            'http://znuny.org' => 'Test Repository',
        },
    },
    {
        Name      => 'ITSM 33 Repository',
        ConfigSet => {
            'http://znuny.org'                                     => 'Test Repository',
            'https://download.znuny.org/releases/itsm/packages33/' => 'OTRS::ITSM 3.3 Master',
        },
        Success        => 1,
        ExpectedResult => {
            'http://znuny.org' => 'Test Repository',
            "https://download.znuny.org/releases/itsm/packages$FrameworkVersion/" =>
                "OTRS::ITSM $FrameworkVersion Master",
        },
    },
    {
        Name      => 'ITSM 33 and 4 Repository',
        ConfigSet => {
            'http://znuny.org'                                     => 'Test Repository',
            'https://download.znuny.org/releases/itsm/packages33/' => 'OTRS::ITSM 3.3 Master',
            'https://download.znuny.org/releases/itsm/packages4/'  => 'OTRS::ITSM 4 Master',
        },
        Success        => 1,
        ExpectedResult => {
            'http://znuny.org' => 'Test Repository',
            "https://download.znuny.org/releases/itsm/packages$FrameworkVersion/" =>
                "OTRS::ITSM $FrameworkVersion Master",
        },
    },
    {
        Name      => 'ITSM 33 4 and 5 Repository',
        ConfigSet => {
            'http://znuny.org'                                     => 'Test Repository',
            'https://download.znuny.org/releases/itsm/packages33/' => 'OTRS::ITSM 3.3 Master',
            'https://download.znuny.org/releases/itsm/packages4/'  => 'OTRS::ITSM 4 Master',
            'https://download.znuny.org/releases/itsm/packages5/'  => 'OTRS::ITSM 5 Master',
        },
        Success        => 1,
        ExpectedResult => {
            'http://znuny.org' => 'Test Repository',
            "https://download.znuny.org/releases/itsm/packages$FrameworkVersion/" =>
                "OTRS::ITSM $FrameworkVersion Master",
        },
    },
    {
        Name      => 'ITSM 6 Repository',
        ConfigSet => {
            'http://znuny.org'                                    => 'Test Repository',
            'https://download.znuny.org/releases/itsm/packages6/' => 'OTRS::ITSM 6 Master',
        },
        Success        => 1,
        ExpectedResult => {
            'http://znuny.org' => 'Test Repository',
            "https://download.znuny.org/releases/itsm/packages$FrameworkVersion/" =>
                "OTRS::ITSM $FrameworkVersion Master",
        },
    },
);

my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $ConfigKey       = 'Package::RepositoryList';
my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

for my $Test (@Tests) {
    if ( $Test->{ConfigSet} ) {
        my $Success = $ConfigObject->Set(
            Key   => $ConfigKey,
            Value => $Test->{ConfigSet},
        );
        $Self->True(
            $Success,
            "$Test->{Name} configuration set in run time",
        );

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            Name   => $ConfigKey,
            Force  => 1,
            UserID => 1,
        );

        my %Result = $SysConfigObject->SettingUpdate(
            Name              => $ConfigKey,
            IsValid           => 1,
            EffectiveValue    => $Test->{ConfigSet},
            ExclusiveLockGUID => $ExclusiveLockGUID,
            UserID            => 1,
        );
        $Self->True(
            $Result{Success},
            "$Test->{Name} configuration set in DB",
        );
    }

    my $UpgradeSuccess = $Kernel::OM->Create('scripts::DBUpdateTo6::MigratePackageRepositoryConfiguration')->Run(
        ContinueOnModified => 1,
    );
    $Self->Is(
        $UpgradeSuccess,
        $Test->{Success},
        "$Test->{Name} Upgrade Package Repository result",
    );

    my %Setting = $SysConfigObject->SettingGet(
        Name   => $ConfigKey,
        UserID => 1,
    );

    $Self->IsDeeply(
        $Setting{EffectiveValue},
        $Test->{ExpectedResult},
        "$Test->{Name} $ConfigKey value",
    );
}

1;
