# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::TicketAttributeRelations::Import;

use strict;
use warnings;

use File::Spec;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::TicketAttributeRelations',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Imports ticket attribute relations from a CSV/Excel file.'
    );

    $Self->AddArgument(
        Name => 'filepath',
        Description =>
            'Path to CSV/Excel file. The filename will be used as identifier to update ticket attribute relations that were imported earlier.',
        Required   => 1,
        ValueRegex => qr/.+/,
    );

    $Self->AddOption(
        Name        => 'priority',
        Description => 'Priority for evaluation.',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );

    $Self->AddOption(
        Name        => 'dynamic-field-config-update',
        Description => "Update dynamic field configs to have selectable values according to data of imported file.",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                      = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject                     = $Kernel::OM->Get('Kernel::System::Main');
    my $TicketAttributeRelationsObject = $Kernel::OM->Get('Kernel::System::TicketAttributeRelations');

    my $UserID = 1;

    my $FilePath = $Self->GetArgument('filepath');

    $Self->Print("<yellow>Importing ticket attribute relations from file $FilePath...</yellow>\n\n");

    my $Priority                 = $Self->GetOption('priority') // 0;
    my $DynamicFieldConfigUpdate = $Self->GetOption('dynamic-field-config-update');

    # determine full path of file (needed for storing it in import record)
    $FilePath = File::Spec->rel2abs($FilePath);
    if ( !-f $FilePath ) {
        $Self->PrintError("File $FilePath could not be found/read.");
        return $Self->ExitCodeError();
    }

    # Copy file to import directory (it will be deleted after import)
    my $FileContentRef = $MainObject->FileRead(
        Location => $FilePath,
        Result   => 'SCALAR',
    );
    if ( !$FileContentRef ) {
        $Self->PrintError("File $FilePath could not be read.");
        return $Self->ExitCodeError();
    }

    # Get base filename of the csv file
    my ( $Volume, $Directories, $Filename ) = File::Spec->splitpath($FilePath);

    # check if there is an existing db entry for the filename
    my $ExistingTicketAttributeRelations = $TicketAttributeRelationsObject->GetTicketAttributeRelations(
        Filename => $Filename,
        UserID   => $UserID,
    );

    # create or update db entry
    my $ImportSuccess;
    if ( IsHashRefWithData($ExistingTicketAttributeRelations) ) {
        $ImportSuccess = $TicketAttributeRelationsObject->UpdateTicketAttributeRelations(
            ID                       => $ExistingTicketAttributeRelations->{ID},
            Filename                 => $Filename,
            Data                     => ${$FileContentRef},
            Priority                 => $Priority || $ExistingTicketAttributeRelations->{Priority},
            DynamicFieldConfigUpdate => $DynamicFieldConfigUpdate,
            UserID                   => $UserID,
        );
    }
    else {
        $ImportSuccess = $TicketAttributeRelationsObject->AddTicketAttributeRelations(
            Filename                 => $Filename,
            Data                     => ${$FileContentRef},
            Priority                 => $Priority || 9000,
            DynamicFieldConfigUpdate => $DynamicFieldConfigUpdate,
            UserID                   => $UserID,
        );
    }

    if ( !$ImportSuccess ) {
        $Self->PrintError( $LogObject->{error}->{Message} );
        return $Self->ExitCodeError();
    }

    $Self->Print("\n<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
