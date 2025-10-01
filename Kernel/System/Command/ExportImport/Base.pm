# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Command::ExportImport::Base;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::Command::ExportImport::Base

=head1 DESCRIPTION

Base functions to handle import/export command behavior.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CommandExportImportBaseObject = $Kernel::OM->Get('Kernel::System::Command::ExportImport::Base');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # define handler options/arguments priority
    # it defines theirs order when displaying
    # them in command's help output
    $Self->{ConfigurePriority} = 1;

    return $Self;
}

=head2 ExportCommandInit()

initialize command object into handler module

    my $Success = $CommandExportImportBaseObject->ExportCommandInit( %Params );

=cut

sub ExportCommandInit {
    my ( $Self, %Param ) = @_;

    $Self->{CommandObject} = $Param{CommandObject};
    return 1;
}

=head2 ExportConfigure()

add options/arguments to the command

    my $Success = $CommandExportImportBaseObject->ExportConfigure( %Params );

=cut

sub ExportConfigure {
    my ( $Self, %Param ) = @_;

    return (
        'target-directory' => {
            Description =>
                "Path of the export directory. Use it to export data to the file, otherwise data will be printed.",
            Required   => 0,
            HasValue   => 1,
            ValueRegex => qr/.*/smx,
            Priority   => $Self->{ConfigurePriority}++,
            IsOption   => 1,
        },
        'format' => {
            Description => 'Format of the export: YAML or Perl.',
            Required    => 1,
            HasValue    => 1,
            ValueRegex  => qr/\A(ya?ml|perl)\z/i,
            Priority    => $Self->{ConfigurePriority}++,
            IsOption    => 1,
        },
        'export-id' => {
            Description => 'ID of object to export. Can specify multiple IDs.',
            Required    => 0,
            HasValue    => 1,
            Multiple    => 1,
            ValueRegex  => qr/\A\d+\z/i,
            Priority    => $Self->{ConfigurePriority}++,
            IsOption    => 1,
        },
        'export-all' => {
            Description => 'Export all objects.',
            Required    => 0,
            HasValue    => 0,
            Priority    => $Self->{ConfigurePriority}++,
            IsOption    => 1,
        },
    );
}

=head2 ExportPreCheck()

performs pre check for exporting

    my $Success = $CommandExportImportBaseObject->ExportPreCheck( %Params );

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

    my $ObjectConfig = $Param{ObjectConfig};

    my $ExportModule = $Self->ExportModuleGet(
        Module       => $ObjectConfig->{Config}->{ExportModule},
        FunctionName => $ObjectConfig->{Config}->{ExportFunctionName},
    );

    return $ExportModule if $ExportModule->{ErrorMessage};

    $ObjectConfig->{ExportModule} = $ExportModule;

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ExportModuleGet()

get export module object

    my $Result = $CommandExportImportBaseObject->ExportModuleGet(
        ExportModule => 'Kernel::System::AutoResponse',
        ExportFunctionName => 'AutoResponseExport',
    );

=cut

sub ExportModuleGet {
    my ( $Self, %Param ) = @_;

    return $Self->BaseModuleGet(
        Action => 'Export',
        %Param,
    );
}

=head2 ExportHandle()

perform command export operation

    my $Result = $CommandExportImportBaseObject->ExportHandle( %Params );

=cut

sub ExportHandle {
    my ( $Self, %Param ) = @_;

    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
    my $ExportData;

    $Self->{CommandObject}->Print("<yellow>Exporting data...</yellow>\n");

    my $Params     = $Self->{CommandObject}->{Params};
    my $Type       = $Params->{Type};
    my $ConfigData = $Self->{CommandObject}->{ExportableObjects}->{$Type};

    my $ExportModule       = $ConfigData->{Config}->{ExportModule};
    my $ExportFunctionName = $ConfigData->{Config}->{ExportFunctionName};

    my $ExportModuleObject = $ConfigData->{ExportModule};

    my $Format          = $Params->{Format};
    my $TargetDirectory = $Params->{TargetDirectory};
    my $ExportAll       = $Params->{ExportAll};
    my $ExportID        = $Params->{ExportID};

    my $ExportSingleEntityName;
    if ($ExportAll) {
        $ExportData = $ExportModuleObject->$ExportFunctionName(
            ExportAll => 1,
        ) || [];
    }
    else {
        for my $ID ( @{$ExportID} ) {
            my $SingleExportData = $ExportModuleObject->$ExportFunctionName(
                ID => $ID,
            );

            push @{$ExportData}, $SingleExportData->[0] if IsArrayRefWithData($SingleExportData);
        }

        $ExportData ||= [];

        $ExportSingleEntityName = $ExportData->[0]->{Name} if ( scalar @{$ExportData} == 1 );
    }

    if ( !IsArrayRefWithData $ExportData ) {
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

    # export data needs to be saved to file
    if ($TargetDirectory) {
        my $FilenameFunction = $Type . 'ExportFilenameGet';
        my $Filename;
        if ( $ExportModuleObject->can($FilenameFunction) ) {
            $Filename = $ExportModuleObject->$FilenameFunction(
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

    # show export data in console
    else {
        $Self->{CommandObject}->Print("$ExportDump\n");
    }

    return $Self->{CommandObject}->ExitCodeOk();
}

=head2 ImportCommandInit()

initialize command object into handler module

    my $Success = $CommandExportImportBaseObject->ImportCommandInit( %Params );

=cut

sub ImportCommandInit {
    my ( $Self, %Param ) = @_;

    $Self->{CommandObject} = $Param{CommandObject};
    return 1;
}

=head2 ImportConfigure()

add options/arguments to the command

    my $Success = $CommandExportImportBaseObject->ImportConfigure( %Params );

=cut

sub ImportConfigure {
    my ( $Self, %Param ) = @_;

    return (
        'source-path' => {
            Description =>
                "Path of the YAML import file.",
            Required   => 1,
            HasValue   => 1,
            ValueRegex => qr/.*/smx,
            Priority   => $Self->{ConfigurePriority}++,
            IsOption   => 1,
        },
        'overwrite-existing' => {
            Description => "Overwrite existing standard templates.",
            Required    => 0,
            HasValue    => 0,
            Priority    => $Self->{ConfigurePriority}++,
            IsOption    => 1,
        },
    );
}

=head2 ImportPreCheck()

performs pre check for importing

    my $Success = $CommandExportImportBaseObject->ImportPreCheck( %Params );

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

    my $ImportModule = $Self->ImportModuleGet(
        Module       => $ObjectConfig->{Config}->{ImportModule},
        FunctionName => $ObjectConfig->{Config}->{ImportFunctionName},
    );

    return $ImportModule if $ImportModule->{ErrorMessage};

    $ObjectConfig->{ImportModule} = $ImportModule;

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ImportModuleGet()

get import module object

    my $Result = $CommandExportImportBaseObject->ImportModuleGet(
        ImportModule => 'Kernel::System::AutoResponse',
        ImportFunctionName => 'AutoResponseImport',
    );

=cut

sub ImportModuleGet {
    my ( $Self, %Param ) = @_;

    return $Self->BaseModuleGet(
        Action => 'Import',
        %Param,
    );
}

=head2 ImportHandle()

perform command import operation

    my $Result = $CommandExportImportBaseObject->ImportHandle( %Params );

=cut

sub ImportHandle {
    my ( $Self, %Param ) = @_;

    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $Params     = $Self->{CommandObject}->{Params};
    my $Type       = $Params->{Type};
    my $ConfigData = $Self->{CommandObject}->{ImportableObjects}->{$Type};

    my $ImportModule             = $ConfigData->{Config}->{ImportModule};
    my $ImportFunctionName       = $ConfigData->{Config}->{ImportFunctionName};
    my $ImportOverwriteParameter = $ConfigData->{Config}->{ImportOverwriteParameter};

    my $ImportModuleObject = $ConfigData->{ImportModule};

    my $SourceFilePath    = $Params->{SourceFilePath};
    my $OverwriteExisting = $Params->{OverwriteExisting};

    my %OverwriteExistingParameter;

    # check if the parameter starts with specified string to make sure it's safe
    if ($ImportOverwriteParameter) {
        if ( $ImportOverwriteParameter =~ m/^OverwriteExisting.*$/ ) {
            %OverwriteExistingParameter = (
                $ImportOverwriteParameter => $OverwriteExisting,
            ) if $OverwriteExisting;
        }
        else {
            $Self->{CommandObject}->PrintError(
                'Command should contain "ImportOverwriteParameter" in system configuration ' .
                    'Admin::Object::Import::Command###ImportableObjects that starts ' .
                    'with "OverwriteExisting" as a pattern!'
            );
            return $Self->{CommandObject}->ExitCodeError();
        }
    }

    my $ImportFunctionParams = $Param{ImportFunctionParams} // {
        %OverwriteExistingParameter,
        UserID  => 1,
        ValidID => 0,
    };

    $Self->{CommandObject}->Print("<yellow>Importing data...</yellow>\n");

    my $YAMLImportContent = $MainObject->FileRead(
        Location => $SourceFilePath,
    );

    if ( !$YAMLImportContent ) {
        $Self->{CommandObject}->PrintError("Can't read specified source file!");
        return $Self->{CommandObject}->ExitCodeError();
    }

    my $ImportData = $ImportModuleObject->$ImportFunctionName(
        Content => ${$YAMLImportContent},
        %{$ImportFunctionParams},
    );

    if ( !$ImportData->{Success} ) {
        $Self->{CommandObject}->PrintError('Error occurred while importing data!');
        return $Self->{CommandObject}->ExitCodeError();
    }

    $Self->{CommandObject}->Print("<yellow>Summary:</yellow>\n");

    my $AddedStrg           = $ImportData->{Added};
    my $UpdatedStrg         = $ImportData->{Updated};
    my $NotUpdatedStrg      = $ImportData->{NotUpdated};
    my $ErrorStrg           = $ImportData->{Errors};
    my $ErrorAdditional     = $ImportData->{AdditionalErrors} // [];
    my $ErrorAdditionalStrg = join( "\n", @{$ErrorAdditional} ) || '';

    $Self->{CommandObject}->Print("<green>Added: $AddedStrg.</green>\n")              if $AddedStrg;
    $Self->{CommandObject}->Print("<green>Updated: $UpdatedStrg.</green>\n")          if $UpdatedStrg;
    $Self->{CommandObject}->Print("<yellow>Not updated: $NotUpdatedStrg.</yellow>\n") if $NotUpdatedStrg;
    $Self->{CommandObject}->Print("<red>Errors occured for: $ErrorStrg.</red>\n")     if $ErrorStrg;
    $Self->{CommandObject}->Print("<red>Error: $ErrorAdditionalStrg</red>\n")         if $ErrorAdditionalStrg;

    $Self->{CommandObject}->Print("\n<green>Done.</green>\n");

    return $Self->{CommandObject}->ExitCodeOk();
}

=head2 BaseModuleGet()

get export module object

    my $Result = $CommandExportImportBaseObject->BaseModuleGet(
        Action => 'Export',
        Module => 'Kernel::System::AutoResponse',
        FunctionName => 'AutoResponseExport',
    );

=cut

sub BaseModuleGet {
    my ( $Self, %Param ) = @_;

    my $Module       = $Param{Module};
    my $FunctionName = $Param{FunctionName};
    return {
        ErrorMessage => "No $Param{Action}Module or $Param{Action}FunctionName defined in system configuration!"
    } if !$Module || !$FunctionName;

    my $ModuleObject;
    my $ActionLc = lc $Param{Action};
    eval {
        $ModuleObject = $Kernel::OM->Get($Module);
    };
    if ($@) {
        return {
            ErrorMessage => "Error occured when creating object $Module: $@"
        };
    }
    elsif ( !$ModuleObject->can($FunctionName) ) {
        return {
            ErrorMessage => "Object: $Module configured module does not provide a possibility to $ActionLc data!",
        };
    }

    return $ModuleObject;
}

1;
