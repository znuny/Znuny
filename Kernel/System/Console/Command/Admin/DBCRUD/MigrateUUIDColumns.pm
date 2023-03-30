# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::DBCRUD::MigrateUUIDColumns;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Util',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Migrates UUID column for every database table of a DBCRUD module for Znuny 6.1 and up. Already migrated columns will not be touched again and reported as success.'
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $UtilObject = $Kernel::OM->Get('Kernel::System::Util');

    $Self->Print("<yellow>Checking/migrating UUID columns for DBCRUD tables...</yellow>\n\n");

    my $InstalledDBCRUDObjects = $UtilObject->GetInstalledDBCRUDObjects();
    if ( !IsArrayRefWithData($InstalledDBCRUDObjects) ) {
        $Self->Print("No installed DBCRUD modules found.\n");
        return $Self->ExitCodeOk();
    }

    DATABASEBACKENDOBJECT:
    for my $DBCRUDObject ( @{$InstalledDBCRUDObjects} ) {
        $Self->Print("$DBCRUDObject->{Name}... ");

        my $Success = $DBCRUDObject->MigrateUUIDDatabaseTableColumns();
        if ( !$Success ) {
            $Self->PrintError("Error\n");
            next DATABASEBACKENDOBJECT;
        }

        $Self->Print("<green>OK</green>\n");
    }

    $Self->Print("\n<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
