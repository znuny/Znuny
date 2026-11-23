# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::AuthenticationConfig;    ## no critic

use strict;
use warnings;

use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateAuthenticationConfigTable(%Param);

    return 1;
}

sub _CreateAuthenticationConfigTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="authentication_config">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
            <Column Name="dbcrud_uuid" Required="false" Size="36" Type="VARCHAR"/>
            <Column Name="name" Required="true" Size="250" Type="VARCHAR"/>
            <Column Name="type" Required="true" Size="50" Type="VARCHAR"/>
            <Column Name="context_type" Required="true" Size="20" Type="VARCHAR"/>
            <Column Name="slot" Required="true" Size="2" Type="VARCHAR"/>
            <Column Name="auth_config" Required="true" Size="100000" Type="VARCHAR"/>
            <Column Name="sync_enabled" Required="true" Default="0" Type="SMALLINT"/>
            <Column Name="sync_config" Required="false" Size="100000" Type="VARCHAR"/>
            <Column Name="valid_id" Required="true" Type="SMALLINT"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <Column Name="change_time" Required="true" Type="DATE"/>
            <Column Name="change_by" Required="true" Type="INTEGER"/>
            <Unique Name="authentication_config_uuid">
                <UniqueColumn Name="dbcrud_uuid"/>
            </Unique>
            <Unique Name="authentication_config_name">
                <UniqueColumn Name="name"/>
            </Unique>
            <Unique Name="authentication_config_context_slot">
                <UniqueColumn Name="context_type"/>
                <UniqueColumn Name="slot"/>
            </Unique>
            <ForeignKey ForeignTable="valid">
                <Reference Local="valid_id" Foreign="id"/>
            </ForeignKey>
            <ForeignKey ForeignTable="users">
                <Reference Local="create_by" Foreign="id"/>
                <Reference Local="change_by" Foreign="id"/>
            </ForeignKey>
        </Table>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
