# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Command::ExportImport::PostMasterFilter;

use strict;
use warnings;
use utf8;

use parent qw (Kernel::System::Command::ExportImport::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::PostMaster::Filter',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::Command::ExportImport::PostMasterFilter

=head1 DESCRIPTION

PostMasterFilter functions to handle import/export command behavior.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CommandExportImportPostMasterFilterObject = $Kernel::OM->Get('Kernel::System::Command::ExportImport::PostMasterFilter');

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

=head2 ExportConfigure()

add options/arguments to the command

    my $Success = $CommandExportImportPostMasterFilterObject->ExportConfigure( %Params );

=cut

sub ExportConfigure {
    my ( $Self, %Param ) = @_;

    return (
        'target-directory' => {
            Description =>
                "Path of the export directory. Use it to export data to a file, otherwise data will be printed.",
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
        'export-name' => {
            Description => 'Name of object to export. Can specify multiple names.',
            Required    => 0,
            HasValue    => 1,
            Multiple    => 1,
            ValueRegex  => qr/\A[^\r\n]+\z/,
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

    my $Success = $CommandExportImportPostMasterFilterObject->ExportPreCheck( %Params );

=cut

sub ExportPreCheck {
    my ( $Self, %Param ) = @_;

    my %CommandParams = (
        Format          => $Self->{CommandObject}->GetOption('format'),
        Type            => $Self->{CommandObject}->GetOption('type'),
        ExportName      => $Self->{CommandObject}->GetOption('export-name'),
        TargetDirectory => $Self->{CommandObject}->GetOption('target-directory'),
        ExportAll       => $Self->{CommandObject}->GetOption('export-all'),
    );

    my $Format          = $CommandParams{Format};
    my $TargetDirectory = $CommandParams{TargetDirectory};
    my $ExportAll       = $CommandParams{ExportAll};
    my $ExportName      = $CommandParams{ExportName};

    if ( $TargetDirectory && !-d $TargetDirectory ) {
        return {
            ErrorMessage => "Directory $TargetDirectory does not exist!",
        };
    }

    if ( $ExportAll && $ExportName ) {
        return {
            ErrorMessage => 'Option "export-all" and "export-name" specified simultanously, use only one!',
        };
    }
    if ( !$ExportAll && !$ExportName ) {
        return {
            ErrorMessage => 'Option "export-all" or "export-name" needs to be specified!',
        };
    }

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ExportHandle()

perform command export operation

    my $Result = $CommandExportImportPostMasterFilterObject->ExportHandle( %Params );

=cut

sub ExportHandle {
    my ( $Self, %Param ) = @_;

    my $YAMLObject             = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject             = $Kernel::OM->Get('Kernel::System::Main');
    my $PostMasterFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');
    my $ExportData;

    $Self->{CommandObject}->Print("<yellow>Exporting data...</yellow>\n");

    my $Params     = $Self->{CommandObject}->{Params};
    my $Type       = $Params->{Type};
    my $ConfigData = $Self->{CommandObject}->{ExportableObjects}->{$Type};

    my $Format          = $Params->{Format};
    my $TargetDirectory = $Params->{TargetDirectory};
    my $ExportAll       = $Params->{ExportAll};
    my $ExportName      = $Params->{ExportName};

    my $ExportSingleEntityName;
    if ($ExportAll) {
        $ExportData = $PostMasterFilterObject->FilterExport(
            ExportAll => 1,
        ) || [];
    }
    else {
        for my $Name ( @{$ExportName} ) {
            my $SingleExportData = $PostMasterFilterObject->FilterExport(
                Name => $Name,
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
        my $FilenameFunction = 'FilterExportFilenameGet';
        my $Filename;
        if ( $PostMasterFilterObject->can($FilenameFunction) ) {
            $Filename = $PostMasterFilterObject->$FilenameFunction(
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

1;
