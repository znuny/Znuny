# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::SpellCheck)

package scripts::Migration::Znuny6_3::MigrateDatabaseBackends;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Util',
);

use Kernel::System::VariableCheck qw(:all);

=head1 SYNOPSIS

Migrates name of UUID column of database backend (now: DBCRUD) tables and also adds missing UUID columns.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $UtilObject = $Kernel::OM->Get('Kernel::System::Util');

    my $InstalledDBCRUDObjects = $UtilObject->GetInstalledDBCRUDObjects();
    return 1 if !IsArrayRefWithData($InstalledDBCRUDObjects);

    for my $DBCRUDObject ( @{$InstalledDBCRUDObjects} ) {

        # Migrate DBCRUD UUID columns that still have the 'z4o_' prefix.
        my $Success = $DBCRUDObject->MigrateUUIDDatabaseTableColumns();
        if ( !$Success ) {
            print
                "        Error migrating UUID column for table $DBCRUDObject->{DatabaseTable} of DBCRUD module $DBCRUDObject->{Name}.\n";
            return;
        }

        # Create missing DBCRUD UUID columns.
        $Success = $DBCRUDObject->CreateMissingUUIDDatabaseTableColumns();
        if ( !$Success ) {
            print
                "        Error creating missing UUID column for table $DBCRUDObject->{DatabaseTable} of DBCRUD module $DBCRUDObject->{Name}.\n";
            return;
        }
    }

    return 1;
}

1;
