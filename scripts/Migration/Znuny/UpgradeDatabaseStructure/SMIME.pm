# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::SMIME;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

=head1 SYNOPSIS

Increases size of columns of database table smime_keys.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_IncreaseColumnsSize(%Param);

    return 1;
}

sub _IncreaseColumnsSize {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="smime_keys">
            <ColumnChange NameOld="email_address" NameNew="email_address" Required="false" Size="100000" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
