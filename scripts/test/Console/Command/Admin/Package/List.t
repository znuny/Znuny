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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::Package::List');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $PackageLocation   = $ConfigObject->Get('Home') . '/scripts/test/sample/PackageManager/TestPackage.opm';
my $PackageContentRef = $MainObject->FileRead(
    Location => $PackageLocation,
    Mode     => 'utf8',
    Result   => 'SCALAR',
);

$Self->True(
    $PackageContentRef,
    "Admin::Package::List test package content loaded",
);

my $PackageContent = $PackageContentRef ? ${$PackageContentRef} : '';
my $RandomNumber   = $HelperObject->GetRandomNumber();
my $PackageName    = "Test$RandomNumber";
my $PackageVersion = '0.0.1';
my $PackageFile    = "Test$RandomNumber";
my $PackageTable   = "test_package_$RandomNumber";

$Self->True(
    $PackageContent,
    "Admin::Package::List test package content is not empty",
);

$PackageContent =~ s{<Name>Test</Name>}{<Name>$PackageName</Name>}ms;
$PackageContent =~ s{Location="var/tmp/Test"}{Location="var/tmp/$PackageFile"}gms;
$PackageContent =~ s{Location="var/Test"}{Location="var/$PackageFile"}gms;
$PackageContent =~ s{test_package}{$PackageTable}gms;

my $PackageInstall = $PackageObject->PackageInstall( String => $PackageContent );
$Self->True(
    $PackageInstall,
    "Admin::Package::List test package installed",
);

my $Result = '';
my $ExitCode;
{
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute();
}

$Self->Is(
    $ExitCode,
    0,
    "Admin::Package::List exit code without options",
);

$Self->True(
    scalar( $Result =~ m{Name:\s+\Q$PackageName\E}ms ),
    "Package list contains test package",
);

$Self->True(
    scalar( $Result =~ m{Version:\s+\Q$PackageVersion\E}ms ),
    "Package list contains installed test package version",
);

$Self->True(
    scalar( $Result =~ m{(?:Installation Status|Deployment):\s+(?:OK)}ms ),
    "Package list contains installation/deployment information",
);

$Result = '';
{
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute( '--package-name', lc "$PackageName-$PackageVersion" );
}

$Self->Is(
    $ExitCode,
    0,
    "Admin::Package::List exit code with --package-name",
);

$Self->True(
    scalar( $Result =~ m{Name:\s+\Q$PackageName\E}ms ),
    "Package list contains test package when filtered by package name",
);

$Result = '';
{
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute( '--package-name', 'DefinitelyNotInstalled-9.9.9' );
}

$Self->Is(
    $ExitCode,
    0,
    "Admin::Package::List exit code with unmatched --package-name",
);

$Self->False(
    scalar( $Result =~ m{Name:\s+\Q$PackageName\E}ms ),
    "Package list does not contain test package with unmatched package-name filter",
);

my $PackageUninstall = $PackageObject->PackageUninstall( String => $PackageContent );
$Self->True(
    $PackageUninstall,
    "Admin::Package::List test package uninstalled",
);

# cleanup cache is done by RestoreDatabase

1;
