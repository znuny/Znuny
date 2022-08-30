# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Config::Dump;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Dump configuration settings.');
    $Self->AddArgument(
        Name        => 'name',
        Description => "Specify which config setting should be dumped.",
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Key = $Self->GetArgument('name');
    chomp $Key;
    my $Value = $Kernel::OM->Get('Kernel::Config')->Get($Key);

    if ( !defined $Value ) {
        $Self->PrintError("The config setting $Key could not be found.");
        return $Self->ExitCodeError();
    }

    my $Output;

    if ( ref($Value) eq 'ARRAY' ) {
        for my $String ( @{$Value} ) {
            $Output .= "$String;";
        }
        $Output .= "\n";
    }
    elsif ( ref($Value) eq 'HASH' ) {
        for my $SubKey ( sort keys %{$Value} ) {
            $Output .= "$SubKey=$Value->{$SubKey};";
        }
        $Output .= "\n";
    }
    else {
        $Output .= $Value . "\n";
    }
    print $Output;

    return $Self->ExitCodeOk();
}

1;
