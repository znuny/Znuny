# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateOAuth2TokenDatabaseTables;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

sub Run {
    my ( $Self, %Param ) = @_;

    #
    # OAuth2 tokens and configs
    # Only use oauth2_token to check if both tables exist.
    #
    my $NewTableExists = $Self->TableExists( Table => 'oauth2_token' );
    return 1 if $NewTableExists;

    my @XML;

    my $OldTableExists = $Self->TableExists( Table => 'z4o_oauth2_token' );
    if ($OldTableExists) {

        # Migrate existing tables.
        @XML = (
            '<TableAlter NameOld="z4o_oauth2_token" NameNew="oauth2_token">
                <ColumnChange NameOld="authorization_code" NameNew="authorization_code" Required="false" Size="2000" Type="VARCHAR" />

                <ForeignKeyDrop ForeignTable="z4o_oauth2_token_config">
                    <Reference Local="token_config_id" Foreign="id"/>
                </ForeignKeyDrop>

                <UniqueCreate Name="oauth2_token_config_id">
                    <UniqueColumn Name="token_config_id"/>
                </UniqueCreate>
                <UniqueDrop Name="z4o_oauth2_token_config_id" />
            </TableAlter>',

            '<TableAlter NameOld="z4o_oauth2_token_config" NameNew="oauth2_token_config">
                <UniqueDrop Name="z4o_oauth2_token_config_name" />
                <UniqueCreate Name="oauth2_token_config_name">
                    <UniqueColumn Name="name"/>
                </UniqueCreate>
            </TableAlter>',

            '<TableAlter NameOld="oauth2_token" NameNew="oauth2_token">
                <ForeignKeyCreate ForeignTable="oauth2_token_config">
                    <Reference Local="token_config_id" Foreign="id"/>
                </ForeignKeyCreate>
            </TableAlter>',
        );
    }
    else {

        # Create new tables.
        @XML = (
            '<Table Name="oauth2_token_config">
                <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
                <Column Name="name" Required="true" Size="250" Type="VARCHAR"/>
                <Column Name="config" Required="true" Size="5000" Type="VARCHAR"/>
                <Column Name="valid_id" Required="true" Type="SMALLINT"/>
                <Column Name="create_time" Required="true" Type="DATE"/>
                <Column Name="create_by" Required="true" Type="INTEGER"/>
                <Column Name="change_time" Required="true" Type="DATE"/>
                <Column Name="change_by" Required="true" Type="INTEGER"/>
                <Unique Name="oauth2_token_config_name">
                    <UniqueColumn Name="name"/>
                </Unique>
                <ForeignKey ForeignTable="valid">
                    <Reference Local="valid_id" Foreign="id"/>
                </ForeignKey>
                <ForeignKey ForeignTable="users">
                    <Reference Local="create_by" Foreign="id"/>
                    <Reference Local="change_by" Foreign="id"/>
                </ForeignKey>
            </Table>',

            '<Table Name="oauth2_token">
                <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
                <Column Name="token_config_id" Required="true" Type="INTEGER"/>
                <Column Name="authorization_code" Required="false" Size="2000" Type="VARCHAR"/>
                <Column Name="token" Required="false" Size="2000" Type="VARCHAR"/>
                <Column Name="token_expiration_date" Required="false" Type="DATE"/>
                <Column Name="refresh_token" Required="false" Size="2000" Type="VARCHAR"/>
                <Column Name="refresh_token_expiration_date" Required="false" Type="DATE"/>
                <Column Name="error_message" Required="false" Size="2000" Type="VARCHAR"/>
                <Column Name="error_description" Required="false" Size="2000" Type="VARCHAR"/>
                <Column Name="error_code" Required="false" Size="250" Type="VARCHAR"/>
                <Column Name="create_time" Required="true" Type="DATE"/>
                <Column Name="create_by" Required="true" Type="INTEGER"/>
                <Column Name="change_time" Required="true" Type="DATE"/>
                <Column Name="change_by" Required="true" Type="INTEGER"/>
                <Unique Name="oauth2_token_config_id">
                    <UniqueColumn Name="token_config_id"/>
                </Unique>
                <ForeignKey ForeignTable="oauth2_token_config">
                    <Reference Local="token_config_id" Foreign="id"/>
                </ForeignKey>
                <ForeignKey ForeignTable="users">
                    <Reference Local="create_by" Foreign="id"/>
                    <Reference Local="change_by" Foreign="id"/>
                </ForeignKey>
            </Table>',
        );
    }

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XML,
    );

    return 1;
}

1;
