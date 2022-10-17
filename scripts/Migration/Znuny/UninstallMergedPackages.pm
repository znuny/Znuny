# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny::UninstallMergedPackages;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::Package',
);

=head1 SYNOPSIS

Uninstalls code that was merged from packages into Znuny.

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

    # Note: Znuny and Znuny4OTRS in case one of the packages later will be built with the Znuny prefix
    my @PackageName = (
        qw(
            Znuny-SMIME
            )
    );

    PACKAGENAME:
    for my $PackageName (@PackageName) {
        my $Success = $PackageObject->_PackageUninstallMerged(
            Name => $PackageName,
        );
        next PACKAGENAME if $Success;

        print "\n    Error uninstalling package $PackageName\n\n";
        return;
    }

    return 1;
}

1;
