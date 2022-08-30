# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# Copyright (C) 2021 maxence business consulting GmbH, http://www.maxence.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::WebService::List;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::GenericInterface::Webservice',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List all web services.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Listing all web services...</yellow>\n");

    my $List = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList( Valid => 0 );
    for my $ID ( sort keys %{$List} ) {
        print "  $List->{$ID} ($ID)\n";
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
