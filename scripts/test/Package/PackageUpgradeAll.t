# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
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
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $Cleanup = $Kernel::OM->Get('Kernel::System::DB')->Do(
    SQL => 'DELETE from package_repository',
);

$Self->True(
    $Cleanup,
    "Removed possibly pre-existing packages from the database (transaction)."
);

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$ConfigObject->Set(
    Key   => 'Package::RepositoryList',
    Value => [
        {
            Name => 'local',
            URL  => 'local',
        },
    ],
);
$ConfigObject->Set(
    Key   => 'Package::RepositoryRoot',
    Value => [],
);
$ConfigObject->Set(
    Key   => 'Version',
    Value => '6.2.2',
);

my @OrigPackageInstalledList
    = $Kernel::OM->Get('Kernel::System::Package')->RepositoryList(    # do not create object instance
    Result => 'short',
    );
my %OrigInstalledList = map { $_->{Name} => $_->{Version} } @OrigPackageInstalledList;

my $Home     = $ConfigObject->Get('Home');
my $TestPath = "$Home/scripts/test/sample/PackageManager/PackageUpgradeAll";

my @Tests = (
    {
        Name            => 'ITSM 6.2.1 to 6.2.20',
        InstallPackages => [
            'TestGeneralCatalog-6.2.1.opm',
            'TestImportExport-6.2.1.opm',
            'TestITSMCore-6.2.1.opm',
            'TestITSMChangeManagement-6.2.1.opm',
            'TestITSMConfigurationManagement-6.2.1.opm',
            'TestITSMIncidentProblemManagement-6.2.1.opm',
            'TestITSMServiceLevelManagement-6.2.1.opm',
        ],
        RepositoryListBefore => {
            TestGeneralCatalog                => '6.2.1',
            TestImportExport                  => '6.2.1',
            TestITSMCore                      => '6.2.1',
            TestITSMIncidentProblemManagement => '6.2.1',
            TestITSMConfigurationManagement   => '6.2.1',
            TestITSMChangeManagement          => '6.2.1',
            TestITSMServiceLevelManagement    => '6.2.1',
        },
        RepositoryPackageList => 'PackageOnlineListITSM6220.asc',
        ExpectedResult        => {
            Success        => 1,
            AlreadyUpdated => {},
            Failed         => {},
            Installed      => {},
            Undeployed     => {},
            Updated        => {
                TestGeneralCatalog                => 1,
                TestImportExport                  => 1,
                TestITSMCore                      => 1,
                TestITSMIncidentProblemManagement => 1,
                TestITSMConfigurationManagement   => 1,
                TestITSMChangeManagement          => 1,
                TestITSMServiceLevelManagement    => 1,
            },
        },
        RepositoryListAfter => {
            TestGeneralCatalog                => '6.2.20',
            TestImportExport                  => '6.2.20',
            TestITSMCore                      => '6.2.20',
            TestITSMIncidentProblemManagement => '6.2.20',
            TestITSMConfigurationManagement   => '6.2.20',
            TestITSMChangeManagement          => '6.2.20',
            TestITSMServiceLevelManagement    => '6.2.20',
        },
    },
    {
        Name            => 'ITSM 6.2.1 to 6.2.20 (New dependencies)',
        InstallPackages => [
            'TestImportExport-6.2.1.opm',
            'TestITSMChangeManagement-NoDep-6.2.1.opm',
            'TestITSMConfigurationManagement-NoDep-6.2.1.opm',
            'TestITSMIncidentProblemManagement-NoDep-6.2.1.opm',
            'TestITSMServiceLevelManagement-NoDep-6.2.1.opm',
        ],
        RepositoryListBefore => {
            TestImportExport                  => '6.2.1',
            TestITSMIncidentProblemManagement => '6.2.1',
            TestITSMConfigurationManagement   => '6.2.1',
            TestITSMChangeManagement          => '6.2.1',
            TestITSMServiceLevelManagement    => '6.2.1',
        },
        RepositoryPackageList => 'PackageOnlineListITSM6220.asc',
        ExpectedResult        => {
            Success        => 1,
            AlreadyUpdated => {},
            Failed         => {},
            Installed      => {
                TestGeneralCatalog => 1,
                TestITSMCore       => 1,
            },
            Undeployed => {},
            Updated    => {
                TestImportExport                  => 1,
                TestITSMIncidentProblemManagement => 1,
                TestITSMConfigurationManagement   => 1,
                TestITSMChangeManagement          => 1,
                TestITSMServiceLevelManagement    => 1,
            },
        },
        RepositoryListAfter => {
            TestGeneralCatalog                => '6.2.20',
            TestImportExport                  => '6.2.20',
            TestITSMCore                      => '6.2.20',
            TestITSMIncidentProblemManagement => '6.2.20',
            TestITSMConfigurationManagement   => '6.2.20',
            TestITSMChangeManagement          => '6.2.20',
            TestITSMServiceLevelManagement    => '6.2.20',
        },
    },
    {
        Name            => 'ITSM 6.2.1 to 6.2.20 (Missing dependencies)',
        InstallPackages => [
            'TestGeneralCatalog-6.2.1.opm',
            'TestImportExport-6.2.1.opm',
            'TestITSMCore-6.2.1.opm',
            'TestITSMChangeManagement-6.2.1.opm',
            'TestITSMConfigurationManagement-6.2.1.opm',
            'TestITSMIncidentProblemManagement-6.2.1.opm',
            'TestITSMServiceLevelManagement-6.2.1.opm',
        ],
        RepositoryListBefore => {
            TestGeneralCatalog                => '6.2.1',
            TestImportExport                  => '6.2.1',
            TestITSMCore                      => '6.2.1',
            TestITSMIncidentProblemManagement => '6.2.1',
            TestITSMConfigurationManagement   => '6.2.1',
            TestITSMChangeManagement          => '6.2.1',
            TestITSMServiceLevelManagement    => '6.2.1',
        },
        RepositoryPackageList => 'PackageOnlineListITSM6220MissingITSMCore.asc',
        ExpectedResult        => {
            Success        => 0,
            AlreadyUpdated => {},
            Failed         => {
                NotFound => {
                    TestITSMCore => 1,
                },
                DependencyFail => {
                    TestITSMChangeManagement          => 1,
                    TestITSMConfigurationManagement   => 1,
                    TestITSMIncidentProblemManagement => 1,
                    TestITSMServiceLevelManagement    => 1,
                },
            },
            Installed  => {},
            Undeployed => {},
            Updated    => {
                TestGeneralCatalog => 1,
                TestImportExport   => 1,
            },
        },
        RepositoryListAfter => {
            TestGeneralCatalog                => '6.2.20',
            TestImportExport                  => '6.2.20',
            TestITSMCore                      => '6.2.1',
            TestITSMIncidentProblemManagement => '6.2.1',
            TestITSMConfigurationManagement   => '6.2.1',
            TestITSMChangeManagement          => '6.2.1',
            TestITSMServiceLevelManagement    => '6.2.1',
        },
    },
);

for my $Test (@Tests) {

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Install base packages.
    PACKAGENAME:
    for my $PackageName ( @{ $Test->{InstallPackages} } ) {

        my $Location = "$TestPath/$PackageName";

        my $FileString;

        my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $Location,
            Mode     => 'utf8',
            Result   => 'SCALAR',
        );
        if ($ContentRef) {
            $FileString = ${$ContentRef};
        }
        $Self->True(
            $FileString,
            "FileRead() - for package $PackageName",
        );

        my $Success = $PackageObject->PackageInstall(
            String => $FileString,
            Force  => 1,
        );
        $Self->True(
            $Success,
            "PackageInstall() - for package $PackageName",
        );
    }

    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::Package'],
    );

    # Redefine key features to prevent real network communications and use local results for this test.
    no warnings qw( once redefine );    ## no critic
    local *Kernel::System::Package::RepositoryPackageListGet = sub {
        return do "$TestPath/$Test->{RepositoryPackageList}";
    };
    local *Kernel::System::Package::PackageOnlineGet = sub {
        my ( $Self, %Param ) = @_;

        my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => "$TestPath/$Param{File}",
            Mode     => 'utf8',
            Result   => 'SCALAR',
        );
        return ${$ContentRef};
    };
    use warnings;

    # Recreate objects with the redefined functions.
    $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Check current installed packages
    my @PackageInstalledList = $PackageObject->RepositoryList(
        Result => 'short',
    );
    my %InstalledList
        = map { $_->{Name} => $_->{Version} } grep { !defined $OrigInstalledList{ $_->{Name} } } @PackageInstalledList;
    $Self->IsDeeply(
        \%InstalledList,
        $Test->{RepositoryListBefore},
        'RepositoryList() - before upgrade',
    );

    my %Result = $PackageObject->PackageUpgradeAll();
    $Self->IsDeeply(
        \%Result,
        $Test->{ExpectedResult},
        'PackageUpgradeAll() - result',
    );

    # Check installed packages after upgrade
    @PackageInstalledList = $PackageObject->RepositoryList(
        Result => 'short',
    );
    %InstalledList
        = map { $_->{Name} => $_->{Version} } grep { !defined $OrigInstalledList{ $_->{Name} } } @PackageInstalledList;
    $Self->IsDeeply(
        \%InstalledList,
        $Test->{RepositoryListAfter},
        'RepositoryList() - after upgrade',
    );

    # Here dependencies doesn't matter as we will remove all added packages
    for my $PackageName ( sort keys %{ $Test->{RepositoryListAfter} } ) {
        my $PackageVersion = $Test->{RepositoryListAfter}->{$PackageName};
        my $Success        = $PackageObject->RepositoryRemove(
            Name    => $PackageName,
            Version => $PackageVersion,
        );
        $Self->True(
            $Success,
            "RepositoryRemove() - $PackageName $PackageVersion",
        );
    }

}
continue {
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::Package'],
    );
}

1;
