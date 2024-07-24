# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigrateUTF8MB4;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Migrate database and all tables to utf8mb4

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if !$Self->_IsAffectedDatabaseBackend(%Param);

    return if !$Self->_CheckInnoDB(%Param);
    return if !$Self->_SetNames(%Param);
    return if !$Self->_SetCollationConnection(%Param);
    return if !$Self->_SetCharacterSetDatabase(%Param);
    return if !$Self->_SetCharacterSetTables(%Param);
    return if !$Self->_RepairAndOptimizeTables(%Param);

    return 1;
}

sub _IsAffectedDatabaseBackend {
    my ( $Self, %Param ) = @_;

    # verify that backend is mysql or mariadb

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $VersionString = $DBObject->Version();

    if ( $VersionString !~ m{ \A (MySQL|MariaDB) \s+ ([0-9.]+) \z }xms ) {
        print "    Database backend is not MySQL or MariaDB. Skipping...\n";
        return;
    }

    return 1;
}

sub _CheckInnoDB {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $Verbose   = $Param{CommandlineOptions}->{Verbose} || 0;
    my %Variables = (
        'default_storage_engine' => 'InnoDB',
        'innodb_file_per_table'  => 'ON',
    );

    for my $Variable ( sort keys %Variables ) {
        my $Result = $DBObject->SelectAll(
            SQL  => 'SHOW VARIABLES like ?;',
            Bind => [ \$Variable ],
        );

        if ( $Result->[0][1] ne $Variables{$Variable} ) {
            print "\n    Error: Variable '"
                . $Variable
                . "' is '"
                . $Result->[0][1]
                . "' but should set to '"
                . $Variables{$Variable} . "'!\n";
            return;
        }

        if ($Verbose) {
            print "Variable '" . $Variable . "' is '" . $Result->[0][1] . "'.\n";
        }
    }

    return 1;
}

sub _SetNames {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'SET NAMES utf8mb4;',
    );

    return 1;
}

sub _SetCollationConnection {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'SET collation_connection = utf8mb4_unicode_ci;',
    );

    return 1;
}

sub _SetCharacterSetDatabase {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

    my $Verbose  = $Param{CommandlineOptions}->{Verbose} || 0;
    my $Database = $ConfigObject->Get('Database');

    # Do not quote database name in this statement!
    return if !$DBObject->Do(
        SQL => 'ALTER DATABASE ' . $Database . ' CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;',
    );

    if ($Verbose) {
        print "Character set of the database changed successfully to utf8mb4.\n";
    }

    return 1;
}

sub _SetCharacterSetTables {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;
    my @Tables  = $DBObject->ListTables();
    my @FailedTables;

    for my $Table ( sort @Tables ) {

        # Do not quote table name in this statement!
        my $Success = $DBObject->Do(
            SQL => 'ALTER TABLE ' . $Table . ' CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',
        );

        if ( !$Success ) {
            print "\n    Error: Could not change character set for table '" . $Table . "' to utf8mb4!\n";
            push @FailedTables, $Table;
        }
    }

    if (@FailedTables) {
        print
            "\n    Error: For the following tables was the change of the character set to utf8mb4 not successfully: '";
        print join( "', '", @FailedTables ) . "'.\n";
        return;
    }

    if ($Verbose) {
        print "Character set changed successfully to utf8mb4 for all tables.\n";
    }

    return 1;
}

sub _RepairAndOptimizeTables {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;
    my @Tables  = $DBObject->ListTables();

    TABLE:
    for my $Table ( sort @Tables ) {

        my $Repair = $DBObject->Do(
            SQL => 'REPAIR TABLE ' . $Table . ';',
        );
        if ( !$Repair ) {
            print "\n    Error: Could not repair table '" . $Table . "'!\n";
            next TABLE;
        }

        my $Optimize = $DBObject->Do(
            SQL => 'OPTIMIZE TABLE ' . $Table . ';',
        );
        if ( !$Optimize ) {
            print "\n    Error: Could not optimize table '" . $Table . "'!\n";
        }
    }

    if ($Verbose) {
        print "REPAIR TABLE and OPTIMIZE TABLE successfully for all tables.\n";
    }

    return 1;
}

1;
