# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Config::UnlockAll;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::SysConfig',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Unlock all settings.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Unlocking all settings...</yellow>\n");

    my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingUnlock(
        UnlockAll => 1,
    );

    return $Self->ExitCodeError(1) if !$Success;

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
