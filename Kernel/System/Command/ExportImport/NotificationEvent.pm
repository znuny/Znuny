# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Command::ExportImport::NotificationEvent;

use strict;
use warnings;
use utf8;

use parent qw (Kernel::System::Command::ExportImport::Base);

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Command::ExportImport::Base',
    'Kernel::System::Main',
    'Kernel::System::NotificationEvent',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::Command::ExportImport::NotificationEvent

=head1 DESCRIPTION

NotificationEvent related functions to import/export command behavior.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CommandExportImportNotificationEventObject = $Kernel::OM->Get('Kernel::System::Command::ExportImport::Base');

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

=head2 ExportConfigure()

add options/arguments to the command

    my %OptionsConfig = $CommandExportImportNotificationEventObject->ExportConfigure( %Params );

=cut

sub ExportConfigure {
    my ( $Self, %Param ) = @_;

    my $CommandExportImportNotificationEventObject = $Kernel::OM->Get('Kernel::System::Command::ExportImport::Base');

    my %ExportConfigureBase = $Self->SUPER::ExportConfigure();

    return (
        %ExportConfigureBase,
        'notification-type' => {
            Description =>
                'Type of notification to export. Use only with export-all parameter (possible: Ticket or Appointment).',
            Required   => 0,
            HasValue   => 1,
            Multiple   => 0,
            ValueRegex => qr/(Ticket|Appointment)/i,
            Priority   => $CommandExportImportNotificationEventObject->{ConfigurePriority}++,
            IsOption   => 1,
        },
    );
}

=head2 ExportPreCheck()

performs pre check for exporting

    my $Success = $CommandExportImportNotificationEventObject->ExportPreCheck( %Params );

=cut

sub ExportPreCheck {
    my ( $Self, %Param ) = @_;

    my %CommandParams = (
        Format           => $Self->{CommandObject}->GetOption('format'),
        Type             => $Self->{CommandObject}->GetOption('type'),
        ExportID         => $Self->{CommandObject}->GetOption('export-id'),
        TargetDirectory  => $Self->{CommandObject}->GetOption('target-directory'),
        ExportAll        => $Self->{CommandObject}->GetOption('export-all'),
        NotificationType => $Self->{CommandObject}->GetOption('notification-type'),
    );

    my $Format           = $CommandParams{Format};
    my $TargetDirectory  = $CommandParams{TargetDirectory};
    my $ExportAll        = $CommandParams{ExportAll};
    my $ExportID         = $CommandParams{ExportID};
    my $NotificationType = $CommandParams{NotificationType};

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
    if ( !( $ExportAll && !$NotificationType ) ) {
        if ( $NotificationType && !$ExportAll ) {
            return {
                ErrorMessage =>
                    'Option "notification-type" specified, but no "export-all" - those should be used together!',
            };
        }
    }

    for my $Param ( sort keys %CommandParams ) {
        $Self->{CommandObject}->{Params}->{$Param} = $CommandParams{$Param};
    }

    return { Success => 1 };
}

=head2 ExportHandle()

perform command export operation

    my $Result = $CommandExportImportNotificationEventObject->ExportHandle( %Params );

=cut

sub ExportHandle {
    my ( $Self, %Param ) = @_;

    my $YAMLObject              = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject              = $Kernel::OM->Get('Kernel::System::Main');
    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');
    my $ExportData;

    $Self->{CommandObject}->Print("<yellow>Exporting data...</yellow>\n");

    my $Params     = $Self->{CommandObject}->{Params};
    my $Type       = $Params->{Type};
    my $ConfigData = $Self->{CommandObject}->{ExportableObjects}->{$Type};

    my $Format           = $Params->{Format};
    my $TargetDirectory  = $Params->{TargetDirectory};
    my $ExportAll        = $Params->{ExportAll};
    my $ExportID         = $Params->{ExportID};
    my $NotificationType = $Params->{NotificationType};

    my $AllTypes = !$NotificationType;

    my $ExportSingleEntityName;
    if ($ExportAll) {
        $ExportData = $NotificationEventObject->NotificationExport(
            ExportAll => 1,
            Type      => $NotificationType,
            All       => $AllTypes,
        );
    }
    else {
        for my $ID ( @{$ExportID} ) {
            my $SingleExportData = $NotificationEventObject->NotificationExport(
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

    if ($TargetDirectory) {
        my $FilenameFunction = 'NotificationExportFilenameGet';
        my $Filename;
        if ( $NotificationEventObject->can($FilenameFunction) ) {
            my $NotificationTypeParam;
            if ($ExportAll) {
                $NotificationTypeParam = $NotificationType ? $NotificationType : 'All';
            }

            $Filename = $NotificationEventObject->$FilenameFunction(
                Format => $Format,
                Name   => $ExportSingleEntityName,
                Type   => $NotificationTypeParam,
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

1;
