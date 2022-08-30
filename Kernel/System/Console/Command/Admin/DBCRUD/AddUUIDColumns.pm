# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::DBCRUD::AddUUIDColumns;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Util',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Adds a column for a UUID to every database table of a DBCRUD module.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $UtilObject = $Kernel::OM->Get('Kernel::System::Util');

    $Self->Print("<yellow>Checking/creating UUID columns for DBCRUD tables...</yellow>\n\n");

    my $InstalledDBCRUDObjects = $UtilObject->GetInstalledDBCRUDObjects();
    if ( !IsArrayRefWithData($InstalledDBCRUDObjects) ) {
        $Self->Print("No installed DBCRUD modules found.\n");
        return $Self->ExitCodeOk();
    }

    DATABASEBACKENDOBJECT:
    for my $DBCRUDObject ( @{$InstalledDBCRUDObjects} ) {
        $Self->Print(
            "$DBCRUDObject->{Name}: Column $DBCRUDObject->{UUIDDatabaseTableColumnName} "
                . "in table $DBCRUDObject->{DatabaseTable}..."
                . "\n"
        );

        my $UUIDColumnPresent = $DBCRUDObject->IsUUIDDatabaseTableColumnPresent();
        if ($UUIDColumnPresent) {
            $Self->Print("\tColumn already exists.\n");
        }
        else {
            my $UUIDColumnCreated = $DBCRUDObject->CreateUUIDDatabaseTableColumn();
            if ( !$UUIDColumnCreated ) {
                $Self->PrintError("\tColumn could not be created.\n");
                next DATABASEBACKENDOBJECT;
            }

            $Self->Print("\t<green>Column successfully created.</green>\n");
        }

        # Check/create history table UUID column.
        next DATABASEBACKENDOBJECT if !$DBCRUDObject->can('IsUUIDHistoryDatabaseTableColumnPresent');

        my $UUIDHistoryColumnPresent = $DBCRUDObject->IsUUIDHistoryDatabaseTableColumnPresent();
        if ($UUIDHistoryColumnPresent) {
            $Self->Print("\tHistory table UUID column already exists.\n");
            next DATABASEBACKENDOBJECT;
        }

        my $UUIDHistoryColumnCreated = $DBCRUDObject->CreateUUIDHistoryDatabaseTableColumn();
        if ( !$UUIDHistoryColumnCreated ) {
            $Self->PrintError("\tHistory table UUID column could not be created.\n");
            next DATABASEBACKENDOBJECT;
        }

        $Self->Print("\t<green>History table UUID column successfully created.</green>\n");
    }

    $Self->Print("\n<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
