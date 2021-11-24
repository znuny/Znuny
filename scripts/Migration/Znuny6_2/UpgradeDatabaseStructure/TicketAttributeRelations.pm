# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny6_2::UpgradeDatabaseStructure::TicketAttributeRelations;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies;

sub Run {
    my ( $Self, %Param ) = @_;

    my $NewTableExists = $Self->TableExists( Table => 'acl_ticket_attribute_relations' );
    return 1 if $NewTableExists;

    my @XML;

    my $OldTableExists = $Self->TableExists( Table => 'acl_ticket_relations' );
    if ($OldTableExists) {

        # Migrate existing table.
        @XML = (
            '<TableAlter NameOld="acl_ticket_relations" NameNew="acl_ticket_attribute_relations">
                <ColumnChange NameOld="name" NameNew="filename" Required="true" Size="255" Type="VARCHAR"/>
                <UniqueCreate Name="acl_tar_filename">
                    <UniqueColumn Name="filename"/>
                </UniqueCreate>
                <ForeignKeyCreate ForeignTable="users">
                    <Reference Local="create_by" Foreign="id"/>
                    <Reference Local="change_by" Foreign="id"/>
                </ForeignKeyCreate>
            </TableAlter>',
        );
    }
    else {

        # Create new table
        @XML = (
            '<Table Name="acl_ticket_attribute_relations">
                <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
                <Column Name="filename" Required="true" Size="255" Type="VARCHAR"/>
                <Column Name="attribute_1" Required="true" Size="200" Type="VARCHAR"/>
                <Column Name="attribute_2" Required="true" Size="200" Type="VARCHAR"/>
                <Column Name="acl_data" Required="true" Size="1800000" Type="VARCHAR"/>
                <Column Name="priority" Required="true" Type="BIGINT"/>
                <Column Name="create_time" Required="true" Type="DATE"/>
                <Column Name="create_by" Required="true" Type="INTEGER"/>
                <Column Name="change_time" Required="true" Type="DATE"/>
                <Column Name="change_by" Required="true" Type="INTEGER"/>
                <Unique Name="acl_tar_filename">
                    <UniqueColumn Name="filename"/>
                </Unique>
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
