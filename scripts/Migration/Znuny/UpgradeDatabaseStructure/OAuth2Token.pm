# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::OAuth2Token;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::NotificationEvent',
);

=head1 SYNOPSIS

Increases size of columns of database tables oauth2_token_config and oauth2_token.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_IncreaseColumnsSize(%Param);

    return 1;
}

sub _IncreaseColumnsSize {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="oauth2_token_config">
            <ColumnChange NameOld="config" NameNew="config" Required="true" Size="100000" Type="VARCHAR"/>
        </TableAlter>',
        '<TableAlter Name="oauth2_token">
            <ColumnChange NameOld="authorization_code" NameNew="authorization_code" Required="false" Size="100000" Type="VARCHAR"/>
            <ColumnChange NameOld="token" NameNew="token" Required="false" Size="100000" Type="VARCHAR"/>
            <ColumnChange NameOld="refresh_token" NameNew="refresh_token" Required="false" Size="100000" Type="VARCHAR"/>
            <ColumnChange NameOld="error_message" NameNew="error_message" Required="false" Size="100000" Type="VARCHAR"/>
            <ColumnChange NameOld="error_description" NameNew="error_description" Required="false" Size="100000" Type="VARCHAR"/>
            <ColumnChange NameOld="error_code" NameNew="error_code" Required="false" Size="1000" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
