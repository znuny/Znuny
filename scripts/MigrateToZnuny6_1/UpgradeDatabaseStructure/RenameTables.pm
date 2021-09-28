# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::UpgradeDatabaseStructure::RenameTables;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies;

=head1 SYNOPSIS

Rename database tables.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my @XML = (
        '<TableAlter NameOld="groups" NameNew="permission_groups"/>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XML,
    );

    return 1;
}

1;
