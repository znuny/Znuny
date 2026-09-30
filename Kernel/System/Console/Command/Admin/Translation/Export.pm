# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Translation::Export;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::Translation',
    'Kernel::System::Time',
);

=head1 NAME

Kernel::System::Console::Command::Admin::Translation::Export

=cut

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Export');

    $Self->AddOption(
        Name        => 'format',
        Description => "Specify the format of the export: yml | csv | xlsx.'",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/\A(yml|csv|xlsx)\z/smxi,
    );

    $Self->AddOption(
        Name        => 'target-path',
        Description => "Specify the target location of the export file. If not set, prints via STDOUT.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'target-name',
        Description => "Specify the target name of the export file.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'filter',
        Description => "Specify filter for translations. e.g. --filter LanguageID=de --filter Source=Tickets",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $TimeObject        = $Kernel::OM->Get('Kernel::System::Time');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');

    my $TimeStamp = $TimeObject->CurrentTimestamp();

    $Param{Format}     = $Self->GetOption('format') || 'yml';
    $Param{TargetPath} = $Self->GetOption('target-path');
    $Param{TargetName} = $Self->GetOption('target-name') || "Export_Translations_$TimeStamp.$Param{Format}";
    $Param{Filter}     = $Self->GetOption('filter');

    my %Filter;
    for my $Filter ( @{ $Param{Filter} } ) {
        my ( $Key, $Value ) = split( /=/, $Filter );
        $Filter{$Key} = $Value;
    }

    my $Export = $TranslationObject->DataExport(
        Format => $Param{Format},
        Cache  => 0,
        %Filter,
    );

    if ( $Param{TargetPath} ) {
        $Self->Print("<yellow>Export...</yellow>\n\n");
        my $FileLocation = $MainObject->FileWrite(
            Directory => $Param{TargetPath},
            Filename  => $Param{TargetName} . ".$Param{Format}",
            Content   => \$Export,
        );
        $Self->Print("<yellow>File stored: $FileLocation</yellow>\n");
        $Self->Print("<green>Done.</green>\n");
    }
    else {
        $Self->Print("$Export\n");
    }

    return $Self->ExitCodeOk();
}

1;
