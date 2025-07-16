# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::ProcessPreferences;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::NotificationEvent',
);

=head1 SYNOPSIS

Adds new table for user process preferences support.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateProcessPreferencesTable(%Param);

    return 1;
}

sub _CreateProcessPreferencesTable {
    my ( $Self, %Param ) = @_;

    my $ProcessPreferencesTableExists = $Self->TableExists(
        Table => 'pm_process_preferences',
    );

    return 1 if $ProcessPreferencesTableExists;

    my @XMLStrings = (
        '<TableCreate Name="pm_process_preferences">
            <Column Name="process_entity_id" Required="true" Type="VARCHAR" Size="50"/>
            <Column Name="preferences_key" Required="true" Size="150" Type="VARCHAR"/>
            <Column Name="preferences_value" Required="false" Size="3000" Type="VARCHAR"/>
            <Index Name="pm_process_preferences_process_entity_id">
                <IndexColumn Name="process_entity_id"/>
            </Index>
            <ForeignKey ForeignTable="pm_process">
                <Reference Local="process_entity_id" Foreign="entity_id"/>
            </ForeignKey>
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
