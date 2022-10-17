# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::SMIMEKeys;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

=head1 SYNOPSIS

Adds new database table 'smime_keys'

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $SMIMEKeysTableExists = $Self->TableExists(
        Table => 'smime_keys',
    );

    return 1 if $SMIMEKeysTableExists;

    my @XMLStrings = (
        '<TableCreate Name="smime_keys">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="key_hash" Required="true" Size="8" Type="VARCHAR" />
            <Column Name="key_type" Required="true" Size="255" Type="VARCHAR" />
            <Column Name="file_name" Required="true" Size="255" Type="VARCHAR" />
            <Column Name="email_address" Required="false" Size="255" Type="VARCHAR" />
            <Column Name="expiration_date" Required="false" Type="DATE" />
            <Column Name="fingerprint" Required="false" Size="59" Type="VARCHAR" />
            <Column Name="subject" Required="false" Size="255" Type="VARCHAR" />
            <Column Name="create_time" Required="false" Type="DATE" />
            <Column Name="change_time" Required="false" Type="DATE" />
            <Column Name="create_by" Required="false" Type="INTEGER" />
            <Column Name="change_by" Required="false" Type="INTEGER" />
            <Index Name="smime_keys_key_hash">
                <IndexColumn Name="key_hash" />
            </Index>
            <Index Name="smime_keys_key_type">
                <IndexColumn Name="key_type" />
            </Index>
            <Index Name="smime_keys_file_name">
                <IndexColumn Name="file_name" />
            </Index>
            <ForeignKey ForeignTable="users">
                <Reference Local="create_by" Foreign="id" />
                <Reference Local="change_by" Foreign="id" />
            </ForeignKey>
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
