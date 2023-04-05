# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
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
my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

# Make sure repository root setting is set to default for duration of the test.
my %Setting = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingGet(
    Name    => 'Package::RepositoryRoot',
    Default => 1,
);
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Package::RepositoryRoot',
    Value => $Setting{DefaultValue},
);

my @Tests = (
    {
        Name           => 'Only default root repository',
        RepositoryList => [],
        ExpectedResult => {
            'Freebie Features' => {
                'URL' => 'https://download.znuny.org/releases/packages',
            },
            'Znuny Open Source Add-ons' => {
                'URL' => 'https://addons.znuny.com/public',
            },
        },
    },
    {
        Name           => 'No ITSM Repositories',
        RepositoryList => [
            {
                Name            => 'Test repository',
                URL             => 'https://download.znuny.org',
                AuthHeaderKey   => 'Authorization',
                AuthHeaderValue => 'Token token=MyToken',
            },
            {
                Name => 'Test repository 2',
                URL  => 'https://download2.znuny.org',
            },
        ],
        ExpectedResult => {
            'Freebie Features' => {
                'URL' => 'https://download.znuny.org/releases/packages',
            },
            'Znuny Open Source Add-ons' => {
                'URL' => 'https://addons.znuny.com/public',
            },
            'Test repository' => {
                URL             => 'https://download.znuny.org',
                AuthHeaderKey   => 'Authorization',
                AuthHeaderValue => 'Token token=MyToken',
            },
            'Test repository 2' => {
                URL => 'https://download2.znuny.org',
            },
        },
    },
);

for my $Test (@Tests) {
    $HelperObject->ConfigSettingChange(
        Valid => 1,
        Key   => 'Package::RepositoryList',
        Value => $Test->{RepositoryList},
    );

    my %RepositoryList = $PackageObject->ConfiguredRepositoryListGet();

    $Self->IsDeeply(
        \%RepositoryList,
        $Test->{ExpectedResult},
        "$Test->{Name} ConfiguredRepositoryListGet() must return expected data.",
    );
}

1;
