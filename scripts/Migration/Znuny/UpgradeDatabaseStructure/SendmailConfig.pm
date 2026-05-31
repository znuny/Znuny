# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::SendmailConfig;    ## no critic

use strict;
use warnings;

use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateSendmailConfigTable(%Param);

    return 1;
}

sub _CreateSendmailConfigTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="sendmail_config">
            <Column Name="id" Required="true" Type="INTEGER" AutoIncrement="true" PrimaryKey="true"/>
            <Column Name="sendmail_module" Required="true" Type="VARCHAR" Size="255"/>
            <Column Name="cmd" Required="false" Type="VARCHAR" Size="2000"/>
            <Column Name="host" Required="false" Type="VARCHAR" Size="255"/>
            <Column Name="port" Required="false" Type="SMALLINT"/>
            <Column Name="timeout" Required="false" Type="SMALLINT"/>
            <Column Name="skip_ssl_verification" Required="false" Default="0" Type="SMALLINT"/>
            <Column Name="is_fallback_config" Required="false" Default="0" Type="SMALLINT"/>
            <Column Name="authentication_type" Required="false" Size="100" Type="VARCHAR"/>
            <Column Name="auth_user" Required="false" Type="VARCHAR" Size="255"/>
            <Column Name="auth_password" Required="false" Type="VARCHAR" Size="255"/>
            <Column Name="oauth2_token_config_id" Required="false" Type="INTEGER"/>
            <Column Name="email_addresses" Required="false" Type="VARCHAR" Size="2000" />
            <Column Name="comments" Required="false" Type="VARCHAR" Size="255"/>
            <Column Name="valid_id" Required="true" Type="SMALLINT"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <Column Name="change_time" Required="true" Type="DATE"/>
            <Column Name="change_by" Required="true" Type="INTEGER"/>
            <ForeignKey ForeignTable="oauth2_token_config">
                <Reference Local="oauth2_token_config_id" Foreign="id"/>
            </ForeignKey>
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
