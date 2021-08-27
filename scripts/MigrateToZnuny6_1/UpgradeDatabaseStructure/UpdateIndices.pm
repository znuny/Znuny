# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::UpgradeDatabaseStructure::UpdateIndices;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies;

=head1 NAME

Update indices.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my @XML = (
        '<TableAlter Name="time_accounting">
            <IndexCreate Name="time_accounting_article_id">
                <IndexColumn Name="article_id"/>
            </IndexCreate>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XML,
    );

    return 1;
}

1;
