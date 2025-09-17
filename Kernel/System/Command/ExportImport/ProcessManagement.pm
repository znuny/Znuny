# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Command::ExportImport::ProcessManagement;

use strict;
use warnings;
use utf8;

use parent qw (Kernel::System::Command::ExportImport::Base);

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::YAML',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::Command::ExportImport::ProcessManagement

=head1 DESCRIPTION

ProcessManagement related functions to handle import/export command behavior.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CommandExportImportProcessManagementObject = $Kernel::OM->Get('Kernel::System::Command::ExportImport::Base');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # define handler options/arguments priority
    # it defines theirs order when displaying
    # them in command's help output
    $Self->{ConfigurePriority} = 100;

    return $Self;
}

=head2 ExportPreCheck()

performs pre check for exporting

    my $Success = $CommandExportImportProcessManagementObject->ExportPreCheck( %Params );

=cut

sub ExportPreCheck {
    my ( $Self, %Param ) = @_;

    my %CommandParams = (
        Format          => $Self->{CommandObject}->GetOption('format'),
        Type            => $Self->{CommandObject}->GetOption('type'),
        ExportID        => $Self->{CommandObject}->GetOption('export-id'),
        TargetDirectory => $Self->{CommandObject}->GetOption('target-directory'),
        ExportAll       => $Self->{CommandObject}->GetOption('export-all'),
    );

    my $Format          = $CommandParams{Format};
    my $TargetDirectory = $CommandParams{TargetDirectory};
    my $ExportAll       = $CommandParams{ExportAll};
    my $ExportID        = $CommandParams{ExportID};

    if ( $TargetDirectory && !-d $TargetDirectory ) {
        return {
            ErrorMessage => "Directory $TargetDirectory does not exist!",
        };
    }

    if ( $ExportAll && $ExportID ) {
        return {
            ErrorMessage => 'Option "export-all" and "export-id" specified simultanously, use only one!',
        };
    }
    if ( !$ExportAll && !$ExportID ) {
        return {
            ErrorMessage => 'Option "export-all" or "export-id" needs to be specified!',
        };
    }

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ExportHandle()

perform command export operation

    my $Result = $CommandExportImportProcessManagementObject->ExportHandle( %Params );

=cut

sub ExportHandle {
    my ( $Self, %Param ) = @_;

    my $YAMLObject    = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $ExportData;
    my @ProcessIDs;

    $Self->{CommandObject}->Print("<yellow>Exporting data...</yellow>\n");

    my $Params = $Self->{CommandObject}->{Params};
    my $Type   = $Params->{Type};

    my $Format          = $Params->{Format};
    my $TargetDirectory = $Params->{TargetDirectory};
    my $ExportAll       = $Params->{ExportAll};
    my $ExportID        = $Params->{ExportID};

    my $ExportSingleEntityName;
    if ($ExportAll) {
        my $ProcessList = $ProcessObject->ProcessList(
            UseEntities => 0,
            UserID      => 1,
        );

        @ProcessIDs = keys %{$ProcessList};
    }
    else {
        @ProcessIDs = @{$ExportID};
    }

    if (@ProcessIDs) {
        my @Data;

        for my $ProcessID (@ProcessIDs) {
            my $SingleExportData = $ProcessObject->ProcessExport(
                ID     => $ProcessID,
                UserID => 1,
            );

            push @Data, $SingleExportData if IsHashRefWithData($SingleExportData);
        }

        if ( scalar @Data > 1 ) {
            $ExportData = \@Data;
        }
        elsif ( scalar @Data == 1 ) {
            $ExportData             = $Data[0];
            $ExportSingleEntityName = $Data[0]->{Process}->{Name};
        }
    }

    if ( !IsArrayRefWithData($ExportData) && !IsHashRefWithData($ExportData) ) {
        $Self->{CommandObject}->PrintError('No data to export found!');
        return $Self->{CommandObject}->ExitCodeError();
    }

    my $ExportDump;
    if ( $Format =~ /yml|yaml/i ) {
        $ExportDump = $YAMLObject->Dump( Data => $ExportData );
    }
    else {
        $ExportDump = $MainObject->Dump($ExportData);
    }

    if ($TargetDirectory) {
        my $FilenameFunction = 'ProcessExportFilenameGet';
        my $Filename;
        if ( $ProcessObject->can($FilenameFunction) ) {
            $Filename = $ProcessObject->$FilenameFunction(
                Format => $Format,
                Name   => $ExportSingleEntityName,
            );
        }
        else {
            $Filename = "Export_${Type}.yml";
        }

        my $Location = $TargetDirectory . "/$Filename";

        my $FileLocation = $MainObject->FileWrite(
            Location => $Location,
            Content  => \$ExportDump,
        );

        if ( !$FileLocation ) {
            $Self->{CommandObject}->PrintError("Could not save exported data in path: $Location");
            return $Self->{CommandObject}->ExitCodeError();
        }
        $Self->{CommandObject}->Print("<green>File created: $Location</green>\n");
        $Self->{CommandObject}->Print("<green>Done.</green>\n");
    }
    else {
        $Self->{CommandObject}->Print("$ExportDump\n");
    }

    return $Self->{CommandObject}->ExitCodeOk();
}

=head2 ImportPreCheck()

performs pre check for importing

    my $Success = $CommandExportImportProcessManagementObject->ImportPreCheck( %Params );

=cut

sub ImportPreCheck {
    my ( $Self, %Param ) = @_;

    my %CommandParams = (
        SourceFilePath    => $Self->{CommandObject}->GetOption('source-path'),
        OverwriteExisting => $Self->{CommandObject}->GetOption('overwrite-existing'),
        Type              => $Self->{CommandObject}->GetOption('type'),
    );

    my $SourceFilePath = $CommandParams{SourceFilePath};

    if ( !-f $SourceFilePath ) {
        die "File path $SourceFilePath does not exist.\n";    ## no critic
    }

    my $ObjectConfig = $Param{ObjectConfig};

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ImportHandle()

perform command import operation

    my $Result = $CommandExportImportProcessManagementObject->ImportHandle( %Params );

=cut

sub ImportHandle {
    my ( $Self, %Param ) = @_;

    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $YAMLObject    = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');

    my $Params = $Self->{CommandObject}->{Params};

    my $SourceFilePath    = $Params->{SourceFilePath};
    my $OverwriteExisting = $Params->{OverwriteExisting};

    $Self->{CommandObject}->Print("<yellow>Importing data...</yellow>\n");

    my $YAMLImportContent = $MainObject->FileRead(
        Location => $SourceFilePath,
    );

    if ( !$YAMLImportContent ) {
        $Self->{CommandObject}->PrintError("Can't read specified source file!");
        return $Self->{CommandObject}->ExitCodeError();
    }

    my $ImportContent = $YAMLObject->Load(
        Data => ${$YAMLImportContent},
    );

    if ( !$ImportContent ) {
        $Self->{CommandObject}->PrintError("Invalid file content!");
        return $Self->{CommandObject}->ExitCodeError();
    }

    my @YAMLImportContentArray;

    if ( IsArrayRefWithData($ImportContent) ) {
        for my $Content ( @{$ImportContent} ) {
            my $YAMLString = $YAMLObject->Dump(
                Data => $Content,
            );

            push @YAMLImportContentArray, $YAMLString;
        }
    }
    else {
        my $YAMLString = $YAMLObject->Dump(
            Data => $ImportContent,
        );

        push @YAMLImportContentArray, $YAMLString;
    }

    my @Summary;

    for my $YAMLContent (@YAMLImportContentArray) {
        my %ImportResult = $ProcessObject->ProcessImport(
            Content                   => $YAMLContent,
            OverwriteExistingEntities => $OverwriteExisting,
            UserID                    => 1,
        );

        push @Summary, \%ImportResult;
    }

    $Self->{CommandObject}->Print("<yellow>Summary:</yellow>\n");

    for my $ImportResult (@Summary) {
        my $Color   = $ImportResult->{Success} ? 'green' : 'red';
        my $Message = $ImportResult->{Message};
        my $Comment = $ImportResult->{Comment};

        my $OutputMessage = $Message;
        $OutputMessage .= ' Comment:' . $Comment if $Comment;

        $Self->{CommandObject}->Print("<$Color>$Message</$Color>\n");
    }

    $Self->{CommandObject}->Print("\n<green>Done.</green>\n");

    return $Self->{CommandObject}->ExitCodeOk();
}

1;
