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

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

# Avoid network access from root repository resolution in this test.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Package::RepositoryRoot',
    Value => [],
);
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Package::RepositoryList',
    Value => [],
);

my $RepositoryXML = <<'EOF';
<?xml version="1.0" encoding="utf-8" ?>
<otrs_package_list version="1.0">
<Package>
<Name>TestPackage</Name>
<Version>1.0.0</Version>
<Vendor>Znuny</Vendor>
<Framework>7.0.x</Framework>
</Package>
</otrs_package_list>
EOF

my @Tests = (
    {
        Name         => 'packages.xml is missing',
        MockDownload => sub {
            my $RequestedURLs = shift;
            return sub {
                my ( $Self, %Param ) = @_;
                push @{$RequestedURLs}, $Param{URL};
                return;
            };
        },
        ExpectedURLs         => ['https://example.invalid/repository/packages.xml'],
        ExpectedPackageCount => 0,
        URLsDescription      => 'RepositoryPackageListGet() requests packages.xml only.',
        ListDescription      => 'RepositoryPackageListGet() returns no packages when packages.xml is missing.',
    },
    {
        Name         => 'packages.xml succeeds',
        MockDownload => sub {
            my $RequestedURLs = shift;
            return sub {
                my ( $Self, %Param ) = @_;
                push @{$RequestedURLs}, $Param{URL};
                return $RepositoryXML if $Param{URL} =~ m{/packages\.xml\z};
                return;
            };
        },
        ExpectedURLs         => ['https://example.invalid/repository/packages.xml'],
        ExpectedPackageCount => 1,
        URLsDescription      => 'RepositoryPackageListGet() requests packages.xml.',
        ListDescription      => 'RepositoryPackageListGet() returns package list from packages.xml.',
    },
);

no warnings 'redefine';    ## no critic

# RepositoryList() reads package_repository and would mark or drop packages by install state.
# This test only checks which index file is downloaded and the parsed list.
local *Kernel::System::Package::RepositoryList = sub {
    return;
};

# Index fixture declares Framework 7.0.x. Accept it so the package is not filtered out.
local *Kernel::System::Package::AnalyzePackageFrameworkRequirements = sub {
    return ( Success => 1 );
};

for my $Test (@Tests) {

    my @RequestedURL;

    local *Kernel::System::Package::_Download = $Test->{MockDownload}->( \@RequestedURL );

    my @List = $PackageObject->RepositoryPackageListGet(
        Source => 'https://example.invalid/repository',
        Lang   => 'en',
    );

    $Self->IsDeeply(
        \@RequestedURL,
        $Test->{ExpectedURLs},
        "$Test->{Name} - $Test->{URLsDescription}",
    );

    $Self->Is(
        scalar @List,
        $Test->{ExpectedPackageCount},
        "$Test->{Name} - $Test->{ListDescription}",
    );
}

1;
