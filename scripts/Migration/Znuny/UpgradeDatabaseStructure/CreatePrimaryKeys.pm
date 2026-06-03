# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::CreatePrimaryKeys;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Main',
    'Kernel::System::XML',
);

=head1 SYNOPSIS

Creates missing primary keys in tables.

=head1 PUBLIC INTERFACE

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $XMLObject    = $Kernel::OM->Get('Kernel::System::XML');

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;
    my @Tables  = qw(
        pm_process_preferences
    );

    TABLE:
    for my $Table ( sort @Tables ) {
        my $TableExists = $Self->TableExists(
            Table => $Table,
        );
        next TABLE if !$TableExists;

        my $ColumnExists = $Self->ColumnExists(
            Table  => $Table,
            Column => 'id',
        );
        next TABLE if $ColumnExists;

        if ( $DBObject->{'DB::Type'} eq 'mysql' ) {

            # Add the 'id' column.
            my $IDColumnAdded = $Self->_AddColumn(
                Table => $Table,
            );

            if ( !$IDColumnAdded ) {
                print "           Could not add primary key columnd 'id' to table $Table!\n" if $Verbose;
                next TABLE;
            }
        }

        # For postgresql and oracle is it needed to re-create the table with
        # the correct column order.
        #
        # For mysql these steps are not needed because it supports creating a new column
        # at the first position of the table.
        if ( $DBObject->{'DB::Type'} eq 'postgresql' || $DBObject->{'DB::Type'} eq 'oracle' ) {

            # Get all column names.
            $DBObject->Prepare(
                SQL   => "SELECT * FROM $Table",
                Limit => 1,
            );

            my @ColumnNames = $DBObject->GetColumnNames();
            my $ColumnOrder;

            for my $Column (@ColumnNames) {
                if ( !$ColumnOrder ) {
                    $ColumnOrder = $Column;
                }
                else {
                    $ColumnOrder .= ', ' . $Column;
                }
            }

            # Create a temporary table with new column order.
            # CREATE TABLE acl_sync_tmp AS SELECT acl_id, sync_state, create_time, change_time FROM acl_sync;
            my $SQL       = 'CREATE TABLE ' . $Table . '_tmp AS SELECT ' . $ColumnOrder . ' FROM ' . $Table;
            my $Temporary = $DBObject->Do( SQL => $SQL );
            if ( !$Temporary ) {
                print "           Could not create temporary table $Table with new column order!\n" if $Verbose;
                next TABLE;
            }

            # Drop the original table.
            my $TableDropped = $Self->_DropTable(
                Table => $Table,
            );

            if ( !$TableDropped ) {
                print "           Could not drop table $Table!\n" if $Verbose;
                next TABLE;
            }

            # Create the main table again with correct column order and all relations.
            my $TableCreated = $Self->_CreateTable(
                Table => $Table,
            );

            if ( !$TableCreated ) {
                print "           Could not create table $Table!\n" if $Verbose;
                next TABLE;
            }

            # Insert data from tmp in main table.
            #
            # INSERT INTO acl_sync
            #     ( acl_id, sync_state, create_time, change_time )
            #     SELECT acl_id, sync_state, create_time, change_time
            #         FROM acl_sync_tmp
            my $InsertSQL = 'INSERT INTO '
                . $Table . ' ( '
                . $ColumnOrder
                . ' ) SELECT '
                . $ColumnOrder
                . ' FROM '
                . $Table . '_tmp';
            my $DataInserted = $DBObject->Do( SQL => $InsertSQL );

            if ( !$DataInserted ) {
                print "           Could not insert data into table $Table!\n" if $Verbose;
                next TABLE;
            }

            # Drop the temporary table again.
            my $TemporaryTableDropped = $Self->_DropTable(
                Table => $Table . '_tmp',
            );

            if ( !$TemporaryTableDropped ) {
                print "           Could not drop temporary table $Table!\n" if $Verbose;
                next TABLE;
            }
        }
    }

    return 1;
}

sub _AddColumn {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    return if !$Param{Table};

    my $Table = $Param{Table};
    my $XML   = '
        <TableAlter Name="' . $Table . '">
            <ColumnAdd Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
        </TableAlter>
    ';

    my @XML = $XMLObject->XMLParse( String => $XML );
    return if !@XML;

    my @SQL = $DBObject->SQLProcessor( Database => \@XML );
    return if !@SQL;

    my @SQLPost = $DBObject->SQLProcessorPost();
    push @SQL, @SQLPost;

    for my $SQL (@SQL) {
        return if !$DBObject->Do( SQL => $SQL );
    }

    return 1;
}

sub _DropTable {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    return if !$Param{Table};

    my $Table = $Param{Table};
    my $XML   = '
        <TableDrop Name="' . $Param{Table} . '"/>
    ';

    my @XML = $XMLObject->XMLParse( String => $XML );
    return if !@XML;

    my @SQL = $DBObject->SQLProcessor( Database => \@XML );
    return if !@SQL;

    my @SQLPost = $DBObject->SQLProcessorPost();
    push @SQL, @SQLPost;

    for my $SQL (@SQL) {
        return if !$DBObject->Do( SQL => $SQL );
    }

    return 1;
}

sub _CreateTable {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    return if !$Param{Table};

    my $Table = $Param{Table};
    my $XML   = $Self->_GetTableSchema(
        Table => $Table,
    );
    return if !$XML;

    my @XML = $XMLObject->XMLParse( String => $XML );
    return if !@XML;

    my @SQL = $DBObject->SQLProcessor( Database => \@XML );
    return if !@SQL;

    my @SQLPost = $DBObject->SQLProcessorPost();
    push @SQL, @SQLPost;

    for my $SQL (@SQL) {
        return if !$DBObject->Do( SQL => $SQL );
    }

    return 1;
}

sub _GetTableSchema {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    return if !$Param{Table};

    # This hash is based on scripts/database/schema.xml
    my %Schema = (
        pm_process_preferences => '
            <Table Name="pm_process_preferences">
                <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
                <Column Name="process_entity_id" Required="true" Type="VARCHAR" Size="50"/>
                <Column Name="preferences_key" Required="true" Size="150" Type="VARCHAR"/>
                <Column Name="preferences_value" Required="false" Size="3000" Type="VARCHAR"/>
                <Index Name="pm_process_preferences_process_entity_id">
                    <IndexColumn Name="process_entity_id"/>
                </Index>
                <ForeignKey ForeignTable="pm_process">
                    <Reference Local="process_entity_id" Foreign="entity_id"/>
                </ForeignKey>
            </Table>',
    );

    return $Schema{ $Param{Table} } || undef;
}

1;
