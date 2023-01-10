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

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

# Make sure to enable cloud services.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'CloudServices::Disabled',
    Value => 0,
);

my $RandomID = $HelperObject->GetRandomID();

# Override Request() from WebUserAgent to always return some test data without making any
#   actual web service calls. This should prevent instability in case cloud services are
#   unavailable at the exact moment of this test run.
my $CustomCode = <<"EOS";
sub Kernel::Config::Files::ZZZZUnitTestAdminPackageManager${RandomID}::Load {} # no-op, avoid warning logs
use Kernel::System::WebUserAgent;
package Kernel::System::WebUserAgent;
use strict;
use warnings;
{
    no warnings 'redefine';
    sub Request {
        return (
            Status  => '200 OK',
            Content => '{"Success":1,"Results":{"PackageManagement":[{"Operation":"PackageVerify","Data":{"Test":"not_verified","TestPackageIncompatible":"not_verified"},"Success":"1"}]},"ErrorMessage":""}',
        );
    }
}
1;
EOS
$HelperObject->CustomCodeActivate(
    Code       => $CustomCode,
    Identifier => 'Admin::Package::Upgrade' . $RandomID,
);

#
# Install package before upgrade.
#
my $Location             = $ConfigObject->Get('Home') . '/scripts/test/sample/PackageManager/TestPackage.opm';
my $InstallCommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::Package::Install');

my $ExitCode = $InstallCommandObject->Execute($Location);

$Self->Is(
    $ExitCode,
    0,
    "Admin::Package::Install exit code - package installed",
);

#
# Upgrade package
#
$Location = $ConfigObject->Get('Home') . '/scripts/test/sample/PackageManager/TestPackageUpgrade.opm';
my $UpgradeCommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::Package::Upgrade');

$ExitCode = $UpgradeCommandObject->Execute($Location);

$Self->Is(
    $ExitCode,
    0,
    "Admin::Package::Upgrade exit code - package upgraded.",
);

$ExitCode = $UpgradeCommandObject->Execute($Location);

$Self->Is(
    $ExitCode,
    1,
    "Admin::Package::Upgrade exit code without arguments - Can't upgrade, package 'Test-0.0.2' already installed!",
);

$HelperObject->CustomFileCleanup();

1;
