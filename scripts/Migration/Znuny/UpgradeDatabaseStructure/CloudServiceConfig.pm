# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::CloudServiceConfig;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

=head1 SYNOPSIS

Drops table 'cloud_service_config'.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_RemoveTable(%Param);

    return 1;
}

sub _RemoveTable {
    my ( $Self, %Param ) = @_;

    my $TableName = 'cloud_service_config';

    my $TableExists = $Self->TableExists(
        Table => $TableName,
    );

    return 1 if !$TableExists;

    my @XMLStrings = (
        '<TableDrop Name="' . $TableName . '" />',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
