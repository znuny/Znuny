# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Translation::Import;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::Translation',
);

=head1 NAME

Kernel::System::Console::Command::Admin::Translation::Import

=cut

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Import');

    $Self->AddArgument(
        Name        => 'source-path',
        Description => "Specify the source location of the import file.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'overwrite',
        Description => "Overwrite existing entities.",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'deploy',
        Description => "Deploy existing translations.",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    $Self->Print("<yellow>Import...</yellow>\n");

    $Param{SourcePath} = $Self->GetArgument('source-path');
    $Param{Overwrite}  = $Self->GetOption('overwrite');
    $Param{Deploy}     = $Self->GetOption('deploy');

    if ( !$Param{Format} ) {
        $Param{Format} = $Self->_GetFileFormat( $Param{SourcePath} ) || '';
    }

    my $Content = $MainObject->FileRead(
        Location        => $Param{SourcePath},
        Result          => 'SCALAR',
        DisableWarnings => 1,
    );

    my $Success = $TranslationObject->DataImport(
        Content   => ${$Content},
        Format    => $Param{Format},
        Overwrite => $Param{Overwrite},
        Data      => {
            DeploymentState => 0,
            ValidID         => 1,
        },
    );

    if ($Success) {
        $Self->Print("\n<green>Successful.</green>\n");
        if ( $Param{Deploy} ) {
            $TranslationObject->DataDeployment(
                UserID => 1,
            );
        }
    }
    else {
        $Self->Print("\n<red>Error.</red>\n");
    }

    $Self->Print("\n<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

sub _GetFileFormat {
    my ( $Self, $Filename ) = @_;

    my $Format;
    if ( $Filename =~ m{\.csv\z}xmsi ) {
        $Format = 'csv';
    }
    elsif ( $Filename =~ m{\.xlsx\z}xmsi ) {
        $Format = 'excel';
    }
    elsif ( $Filename =~ m{\.yml\z}xmsi ) {
        $Format = 'yml';
    }
    else {
        $Filename =~ m{\.(.+)\z}xmsi;
        $Format = $1;
    }

    return $Format;
}

1;
