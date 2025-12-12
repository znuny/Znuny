# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
package Kernel::System::Console::Command::Admin::Package::RepositoryList;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Lists all known package repositories.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

    $Self->Print("<yellow>Listing package repositories...</yellow>\n");

    my $Count = 0;
    my %List  = $PackageObject->ConfiguredRepositoryListGet();
    if ( !%List ) {
        $Self->PrintError("No package repositories configured.");
        return $Self->ExitCodeError();
    }

    for my $Source ( sort keys %List ) {
        $Count++;
        $Self->Print("+----------------------------------------------------------------------------+\n");
        $Self->Print("| $Count) Name: $Source\n");
        $Self->Print("|    URL:  $List{$Source}->{URL}\n");
    }
    $Self->Print("+----------------------------------------------------------------------------+\n");
    $Self->Print("\n");

    $Self->Print("<yellow>Listing package repository content...</yellow>\n");

    my $DefaultLanguage   = $ConfigObject->Get('DefaultLanguage');
    my @InstalledPackages = $PackageObject->RepositoryList(
        Result => 'Short',
    );

    my %InstalledPackagesLookup;
    INSTALLEDPACKAGE:
    for my $InstalledPackage (@InstalledPackages) {

        next INSTALLEDPACKAGE if !$InstalledPackage->{Name};
        next INSTALLEDPACKAGE if !$InstalledPackage->{Status};
        next INSTALLEDPACKAGE if $InstalledPackage->{Status} ne 'installed';

        $InstalledPackagesLookup{ $InstalledPackage->{Name} } = 1;
    }

    for my $Source ( sort keys %List ) {
        $Self->Print(
            "+----------------------------------------------------------------------------+\n"
        );
        $Self->Print("| Package overview for repository $Source:\n");

        my @Packages = $PackageObject->RepositoryPackageListGet(
            Source             => $Source,
            Lang               => $DefaultLanguage,
            IncludeSameVersion => 1,
        );

        my $PackageCount = 0;
        PACKAGE:
        for my $Package (@Packages) {
            my $InstalledStatus = $InstalledPackagesLookup{ $Package->{Name} } ? 'Yes' : 'No';

            # Just show if PackageIsVisible flag is enabled.
            if (
                defined $Package->{PackageIsVisible}
                && !$Package->{PackageIsVisible}->{Content}
                )
            {
                next PACKAGE;
            }
            $PackageCount++;

            $Self->Print(
                "+----------------------------------------------------------------------------+\n"
            );
            $Self->Print( "|" . sprintf( "%3d", $PackageCount ) . ") Name:        $Package->{Name}\n" );
            $Self->Print("|     Version:     $Package->{Version}\n");
            $Self->Print("|     Vendor:      $Package->{Vendor}\n");
            $Self->Print("|     URL:         $Package->{URL}\n");
            $Self->Print("|     License:     $Package->{License}\n");
            $Self->Print("|     Description: $Package->{Description}\n");
            $Self->Print("|     Installed:   $InstalledStatus\n");
            $Self->Print("|     Install:     $Source:$Package->{File}\n");
        }
        $Self->Print(
            "+----------------------------------------------------------------------------+\n"
        );
        $Self->Print("\n");
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
