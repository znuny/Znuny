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

    $Self->Print("<yellow>Listing package repositories...</yellow>\n");

    my $Count = 0;
    my %List  = $PackageObject->ConfiguredRepositoryListGet();
    if ( !%List ) {
        $Self->PrintError("No package repositories configured.");
        return $Self->ExitCodeError();
    }

    for my $Source ( sort keys %List ) {
        $Count++;
        print "+----------------------------------------------------------------------------+\n";
        print "| $Count) Name: $Source\n";
        print "|    URL:  $List{$Source}->{URL}\n";
    }
    print "+----------------------------------------------------------------------------+\n";
    print "\n";

    $Self->Print("<yellow>Listing package repository content...</yellow>\n");

    for my $Source ( sort keys %List ) {
        print
            "+----------------------------------------------------------------------------+\n";
        print "| Package overview for repository $Source:\n";
        my @Packages = $Kernel::OM->Get('Kernel::System::Package')->RepositoryPackageListGet(
            Source => $Source,
            Lang   => $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage'),
        );
        my $PackageCount = 0;
        PACKAGE:
        for my $Package (@Packages) {

            # Just show if PackageIsVisible flag is enabled.
            if (
                defined $Package->{PackageIsVisible}
                && !$Package->{PackageIsVisible}->{Content}
                )
            {
                next PACKAGE;
            }
            $PackageCount++;
            print
                "+----------------------------------------------------------------------------+\n";
            print "| $PackageCount) Name:        $Package->{Name}\n";
            print "|    Version:     $Package->{Version}\n";
            print "|    Vendor:      $Package->{Vendor}\n";
            print "|    URL:         $Package->{URL}\n";
            print "|    License:     $Package->{License}\n";
            print "|    Description: $Package->{Description}\n";
            print "|    Install:     $Source:$Package->{File}\n";
        }
        print
            "+----------------------------------------------------------------------------+\n";
        print "\n";
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
