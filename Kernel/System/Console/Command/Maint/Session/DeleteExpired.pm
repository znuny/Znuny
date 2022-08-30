# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Session::DeleteExpired;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::AuthSession',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete expired sessions.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my @Expired = $Kernel::OM->Get('Kernel::System::AuthSession')->GetExpiredSessionIDs();

    $Self->Print("<yellow>Deleting expired sessions...</yellow>\n");

    for my $SessionID ( @{ $Expired[0] } ) {
        my $Success = $Kernel::OM->Get('Kernel::System::AuthSession')->RemoveSessionID(
            SessionID => $SessionID,
        );

        if ( !$Success ) {
            $Self->PrintError("Session $SessionID could not be deleted.");
            return $Self->ExitCodeError();
        }

        $Self->Print("  $SessionID\n");
    }

    $Self->Print("<yellow>Deleting idle sessions...</yellow>\n");

    for my $SessionID ( @{ $Expired[1] } ) {
        my $Success = $Kernel::OM->Get('Kernel::System::AuthSession')->RemoveSessionID(
            SessionID => $SessionID,
        );

        if ( !$Success ) {
            $Self->PrintError("Session $SessionID could not be deleted.");
            return $Self->ExitCodeError();
        }

        $Self->Print("  $SessionID\n");
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
