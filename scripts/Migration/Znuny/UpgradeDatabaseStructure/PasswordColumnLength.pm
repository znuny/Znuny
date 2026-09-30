# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::PasswordColumnLength;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
);

=head1 SYNOPSIS

Increase password column length for users, customer_user and mail_account.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="users">
            <ColumnChange NameOld="pw" NameNew="pw" Size="255" Type="VARCHAR"/>
        </TableAlter>',
        '<TableAlter Name="customer_user">
            <ColumnChange NameOld="pw" NameNew="pw" Size="255" Type="VARCHAR"/>
        </TableAlter>',
        '<TableAlter Name="mail_account">
            <ColumnChange NameOld="pw" NameNew="pw" Size="255" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
