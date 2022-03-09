# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package scripts::DBUpdateTo6::UninstallMergedPackages;    ## no critic

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo6::Base);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::Package',
);

=head1 NAME

scripts::DBUpdateTo6::UninstallMergedPackages - Uninstalls code that was merged from packages into Znuny.

=head1 PUBLIC INTERFACE

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $CacheObject   = $Kernel::OM->Get('Kernel::System::Cache');
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Purge relevant caches before uninstalling to avoid errors because of inconsistent states.
    $CacheObject->CleanUp(
        Type => 'RepositoryList',
    );
    $CacheObject->CleanUp(
        Type => 'RepositoryGet',
    );
    $CacheObject->CleanUp(
        Type => 'XMLParse',
    );

    # Uninstall merged original OTRS packages.
    PACKAGENAME:
    for my $PackageName (
        qw(
        OTRSAppointmentCalendar
        OTRSTicketNumberCounterDatabase
        OTRSAdvancedTicketSplit
        OTRSGenericInterfaceInvokerEventFilter
        OTRSPostMasterKeepState
        )
        )
    {
        my $Success = $PackageObject->_PackageUninstallMerged(
            Name => $PackageName,
        );
        next PACKAGENAME if $Success;

        print "\n    Error uninstalling package $PackageName\n\n";
        return;
    }

    # Uninstall merged Znuny packages
    my @InstalledPackages = $PackageObject->RepositoryList(
        Result => 'short',
    );

    PACKAGENAME:
    for my $PackageName (
        qw(
        Znuny4OTRS-ZSA202106
        )
        )
    {
        my @InstalledPackage = grep { $_->{Name} eq $PackageName } @InstalledPackages;
        next PACKAGENAME if @InstalledPackage != 1;

        my $InstalledPackage = shift @InstalledPackage;

        my $Package = $PackageObject->RepositoryGet(
            Name    => $InstalledPackage->{Name},
            Version => $InstalledPackage->{Version},
        );
        if ( defined $Package && length $Package ) {
            my $Success = $PackageObject->PackageUninstall( String => $Package );
            next PACKAGENAME if $Success;
        }

        print "\n    Error uninstalling package $PackageName\n\n";
        return;
    }

    return 1;
}

1;
