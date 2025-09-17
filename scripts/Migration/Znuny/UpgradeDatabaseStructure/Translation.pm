# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::Translation;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Alter old translations tables to new translation table.
Or create new translation table if it does not exist.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @Tables = $DBObject->ListTables();
    my %Tables = map { $_ => 1 } @Tables;

    if ( $Tables{znuny4otrs_translations} ) {
        return $Self->_AlterZnuny4OTRSTranslationTable(%Param);
    }
    elsif ( $Tables{znuny_translations} ) {
        return $Self->_AlterZnunyTranslationTable(%Param);
    }

    return $Self->_CreateTranslationTable(%Param);
}

sub _AlterZnuny4OTRSTranslationTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter NameOld="znuny4otrs_translations" NameNew="translation"/>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _AlterZnunyTranslationTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter NameOld="znuny_translations" NameNew="translation"/>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _CreateTranslationTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="translation">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
            <Column Name="dbcrud_uuid" Required="false" Size="36" Type="VARCHAR"/>
            <Column Name="language_id" Required="true" Size="5" Type="VARCHAR"/>
            <Column Name="source_string" Required="true" Size="1000" Type="VARCHAR"/>
            <Column Name="destination_string" Required="true" Size="1000" Type="VARCHAR"/>
            <Column Name="valid_id" Default="1" Required="true" Type="SMALLINT"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <Column Name="change_time" Required="true" Type="DATE"/>
            <Column Name="change_by" Required="true" Type="INTEGER"/>
            <Column Name="deployment_state" Default="0" Required="true" Type="SMALLINT"/>
            <Unique Name="translation_uuid">
                <UniqueColumn Name="dbcrud_uuid"/>
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
