# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Database::CKEditorMigration;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::AutoResponse',
    'Kernel::System::DB',
    'Kernel::System::NotificationEvent',
    'Kernel::System::ProcessManagement::DB::ActivityDialog',
    'Kernel::System::Salutation',
    'Kernel::System::Signature',
    'Kernel::System::StandardTemplate',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Migrates CKEditor content from version 4 to 5.');
    $Self->AddArgument(
        Name        => 'print-only-errors',
        Description => 'Print only errors.',
        Required    => 0,
        ValueRegex  => qr/.*/smx,
    );
    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Running CKEditor migration from version 4 to 5...</yellow>\n");

    my $DBObject        = $Kernel::OM->Get('Kernel::System::DB');
    my $PrintOnlyErrors = $Self->GetArgument('print-only-errors');

    my $TableExists = $Self->TableExists(
        Table => 'ckeditor_migration_4_5',
    );
    if ( !$TableExists ) {
        $Self->PrintError(
            "Table 'ckeditor_migration_4_5' does not exist! Please make sure to execute migration script first\n" .
                "or create and populate this table with data to migrate!\n" .
                "Schema of the table can be found in module \"scripts::Migration::Znuny::MigrateCKEditorContent\"."
        );
        return $Self->ExitCodeError();
    }

    $Self->{EntitiesToMigrateMapping} = {
        ActivityDialog    => 'pm_activity_dialog',
        AutoResponse      => 'auto_response',
        NotificationEvent => 'notification_event',
        Salutation        => 'salutation',
        Signature         => 'signature',
        StandardTemplate  => 'standard_template',
    };

    my %Summary;
    my $PrintOutput = $PrintOnlyErrors ? 0 : 1;

    for my $Entity ( sort keys %{ $Self->{EntitiesToMigrateMapping} } ) {
        my @Data = $Self->DataToMigrateFetch(
            EntityName => $Self->{EntitiesToMigrateMapping}->{$Entity},
        );

        my $FunctionName = $Entity . 'Migrate';

        if ( !$Self->can($FunctionName) ) {
            $Self->PrintError("Function: $FunctionName not found!");
            return $Self->ExitCodeError();
        }

        my $Result = $Self->$FunctionName(
            Data => \@Data,
        );

        if ( !$Result->{Success} ) {
            push @{ $Summary{Failed} }, $Entity;
            $PrintOutput = 1;
        }
        elsif ( $Result->{Success} ) {
            push @{ $Summary{Success} }, {
                Entity      => $Entity,
                Migrated    => $Result->{Migrated} || [],
                NotMigrated => $Result->{NotMigrated} || [],
                Empty       => $Result->{Empty} || [],
            };

            if ( IsArrayRefWithData( $Result->{NotMigrated} ) ) {
                $PrintOutput = 1;
            }

            $Self->DataToMigrateDelete(
                Entity => $Entity,
                IDs    => $Result->{Migrated} || [],
            );
        }
    }

    $Self->Print("<yellow>Summary:</yellow>\n") if $PrintOutput;
    if ( IsArrayRefWithData( $Summary{Failed} ) ) {
        my $ErrorsOccuredStrg = join( ', ', @{ $Summary{Error} } ) || '';
        $Self->Print("<red>\nErrors occured when migrating entities: $ErrorsOccuredStrg.</red>\n");
    }
    if ( IsArrayRefWithData( $Summary{Success} ) ) {
        for my $MigrationResult ( @{ $Summary{Success} } ) {
            my $Entity       = $MigrationResult->{Entity};
            my $Migrated     = $MigrationResult->{Migrated};
            my $NotMigrated  = $MigrationResult->{NotMigrated};
            my $EmptyContent = $MigrationResult->{Empty};

            my $MigratedStrg     = join( ', ', @{$Migrated} )     || 'none';
            my $NotMigratedStrg  = join( ', ', @{$NotMigrated} )  || 'none';
            my $EmptyContentStrg = join( ', ', @{$EmptyContent} ) || 'none';

            if ( !$PrintOnlyErrors ) {
                $Self->Print(
                    "\n<yellow>Entity: $Entity\n</yellow>" .
                        "<green>Migrated objects: $MigratedStrg</green>\n" .
                        "<red>Errors occured while migrating objects: $NotMigratedStrg</red>\n" .
                        "<yellow>Objects with empty ckeditor content: $EmptyContentStrg</yellow>\n"
                );
            }
            elsif ($PrintOutput) {
                $Self->Print(
                    "\n<yellow>Entity: $Entity\n</yellow>" .
                        "<red>Errors occured while migrating objects: $NotMigratedStrg</red>\n"
                );
            }
        }
    }

    $Self->Print("<green>Done.</green>\n") if $PrintOutput;

    return $Self->ExitCodeOk();
}

sub DataToMigrateDelete {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $IDs    = $Param{IDs};
    my $Entity = $Param{Entity};

    return if !IsArrayRefWithData($IDs);
    return if !$Self->{EntitiesToMigrateMapping}->{$Entity};

    for my $ID ( @{$IDs} ) {
        return if !$DBObject->Do(
            SQL => '
                DELETE FROM ckeditor_migration_4_5
                WHERE entity_name = ? AND entity_object_id = ?',
            Bind => [ \$Self->{EntitiesToMigrateMapping}->{$Entity}, \$ID ],
        );
    }

    return 1;
}

sub AutoResponseMigrate {
    my ( $Self, %Param ) = @_;

    my $AutoResponseObject = $Kernel::OM->Get('Kernel::System::AutoResponse');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    my %AutoResponseList = $AutoResponseObject->AutoResponseList(
        Valid => 0,
    );

    AUTORESPONSEID:
    for my $AutoResponseID ( @{$Data} ) {
        if ( !$AutoResponseList{$AutoResponseID} ) {
            push @{ $Result{NotMigrated} }, $AutoResponseID;
            next AUTORESPONSEID;
        }

        my %Data = $AutoResponseObject->AutoResponseGet(
            ID => $AutoResponseID,
        );

        my $CKEditorContent = $Data{Response};
        if ( !$CKEditorContent ) {
            push @{ $Result{Empty} }, $AutoResponseID;
            next AUTORESPONSEID;
        }

        my $ReplacedCKEditorContent = $Self->ContentReplace(
            Content => $CKEditorContent,
        ) // '';

        my $EntityUpdateSuccess = $AutoResponseObject->AutoResponseUpdate(
            %Data,
            Response    => $ReplacedCKEditorContent,
            ContentType => 'text/html',
            UserID      => 1,
        );

        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $AutoResponseID;
        }
        else {
            push @{ $Result{NotMigrated} }, $AutoResponseID;
        }
    }

    return \%Result;
}

sub ActivityDialogMigrate {
    my ( $Self, %Param ) = @_;

    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    ACTIVITYDIALOGID:
    for my $ActivityDialogID ( @{$Data} ) {

        my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
            EntityID => $ActivityDialogID,
            UserID   => 1,
        );

        if ( !$ActivityDialog ) {
            push @{ $Result{NotMigrated} }, $ActivityDialogID;
            next ACTIVITYDIALOGID;
        }

        my $CKEditorContent = $ActivityDialog->{Config}->{Fields}->{Article}->{Config}->{Body};

        if ( !$CKEditorContent ) {
            push @{ $Result{Empty} }, $ActivityDialogID;
            next ACTIVITYDIALOGID;
        }

        my $ReplacedCKEditorContent = $Self->ContentReplace(
            Content => $CKEditorContent,
        ) // '';

        my $Config = $ActivityDialog->{Config};
        $Config->{Fields}->{Article}->{Config}->{Body} = $ReplacedCKEditorContent;
        my $EntityUpdateSuccess = $ActivityDialogObject->ActivityDialogUpdate(
            %{$ActivityDialog},
            Config => $Config,
            UserID => 1
        );
        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $ActivityDialogID;
        }
        else {
            push @{ $Result{NotMigrated} }, $ActivityDialogID;
        }
    }

    return \%Result;
}

sub NotificationEventMigrate {
    my ( $Self, %Param ) = @_;

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    my %NotificationList = $NotificationEventObject->NotificationList(
        Details => 1,
        All     => 1,
    );

    NOTIFICATIONID:
    for my $NotificationID ( @{$Data} ) {
        if ( !$NotificationList{$NotificationID} ) {
            push @{ $Result{NotMigrated} }, $NotificationID;
            next NOTIFICATIONID;
        }

        my %Data = $NotificationEventObject->NotificationGet(
            ID => $NotificationID,
        );

        my $IDMessage = $NotificationID;

        if ( !IsHashRefWithData( $Data{Message} ) ) {
            push @{ $Result{NotMigrated} }, $NotificationID;
            next NOTIFICATIONID;
        }

        my %UpdateData = %Data;

        LANGUAGE:
        for my $Language ( sort keys %{ $Data{Message} } ) {
            my $CKEditorContent = $Data{Message}->{$Language}->{Body};

            if ( !$CKEditorContent ) {
                my $InternalID = $IDMessage . '_' . $Language;
                push @{ $Result{Empty} }, $InternalID;
                next LANGUAGE if !$CKEditorContent;
            }

            my $ReplacedCKEditorContent = $Self->ContentReplace(
                Content => $CKEditorContent,
            ) // '';

            $UpdateData{Message}->{$Language}->{Body}        = $ReplacedCKEditorContent;
            $UpdateData{Message}->{$Language}->{ContentType} = 'text/html';
        }

        my $EntityUpdateSuccess = $NotificationEventObject->NotificationUpdate(
            %UpdateData,
            UserID => 1,
        );

        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $NotificationID;
        }
        else {
            push @{ $Result{NotMigrated} }, $NotificationID;
        }
    }

    return \%Result;
}

sub SalutationMigrate {
    my ( $Self, %Param ) = @_;

    my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    my %List = $SalutationObject->SalutationList(
        Valid => 0,
    );

    SALUTATIONID:
    for my $SalutationID ( @{$Data} ) {
        if ( !$List{$SalutationID} ) {
            push @{ $Result{NotMigrated} }, $SalutationID;
            next SALUTATIONID;
        }

        my %Data = $SalutationObject->SalutationGet(
            ID => $SalutationID,
        );

        my $CKEditorContent = $Data{Text};
        if ( !$CKEditorContent ) {
            push @{ $Result{Empty} }, $SalutationID;
            next SALUTATIONID;
        }

        my $ReplacedCKEditorContent = $Self->ContentReplace(
            Content => $CKEditorContent,
        ) // '';

        my $EntityUpdateSuccess = $SalutationObject->SalutationUpdate(
            %Data,
            Text        => $ReplacedCKEditorContent,
            ContentType => 'text/html',
            UserID      => 1,
        );

        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $SalutationID;
        }
        else {
            push @{ $Result{NotMigrated} }, $SalutationID;
        }
    }

    return \%Result;
}

sub SignatureMigrate {
    my ( $Self, %Param ) = @_;

    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    my %List = $SignatureObject->SignatureList(
        Valid => 0,
    );

    SIGNATUREID:
    for my $SignatureID ( @{$Data} ) {
        if ( !$List{$SignatureID} ) {
            push @{ $Result{NotMigrated} }, $SignatureID;
            next SIGNATUREID;
        }

        my %Data = $SignatureObject->SignatureGet(
            ID => $SignatureID,
        );

        my $CKEditorContent = $Data{Text};
        if ( !$CKEditorContent ) {
            push @{ $Result{Empty} }, $SignatureID;
            next SIGNATUREID;
        }

        my $ReplacedCKEditorContent = $Self->ContentReplace(
            Content => $CKEditorContent,
        ) // '';

        my $EntityUpdateSuccess = $SignatureObject->SignatureUpdate(
            %Data,
            Text        => $ReplacedCKEditorContent,
            ContentType => 'text/html',
            UserID      => 1,
        );

        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $SignatureID;
        }
        else {
            push @{ $Result{NotMigrated} }, $SignatureID;
        }
    }

    return \%Result;
}

sub StandardTemplateMigrate {
    my ( $Self, %Param ) = @_;

    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

    my $Data   = $Param{Data};
    my %Result = (
        Migrated    => [],
        NotMigrated => [],
        Success     => 0,
    );

    return \%Result if ref $Data ne 'ARRAY';
    $Result{Success} = 1;
    return \%Result if !$Data->[0];

    my %List = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );

    STANDARDTEMPLATEID:
    for my $StandardTemplateID ( @{$Data} ) {
        if ( !$List{$StandardTemplateID} ) {
            push @{ $Result{NotMigrated} }, $StandardTemplateID;
            next STANDARDTEMPLATEID;
        }

        my %Data = $StandardTemplateObject->StandardTemplateGet(
            ID => $StandardTemplateID,
        );

        my $CKEditorContent = $Data{Template};
        if ( !$CKEditorContent ) {
            push @{ $Result{Empty} }, $StandardTemplateID;
            next STANDARDTEMPLATEID;
        }

        my $ReplacedCKEditorContent = $Self->ContentReplace(
            Content => $CKEditorContent,
        ) // '';

        my $EntityUpdateSuccess = $StandardTemplateObject->StandardTemplateUpdate(
            %Data,
            Template    => $ReplacedCKEditorContent,
            ContentType => 'text/html',
            UserID      => 1,
        );

        if ($EntityUpdateSuccess) {
            push @{ $Result{Migrated} }, $StandardTemplateID;
        }
        else {
            push @{ $Result{NotMigrated} }, $StandardTemplateID;
        }
    }

    return \%Result;
}

sub DataToMigrateFetch {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @Data;
    return if !$DBObject->Prepare(
        SQL => '
            SELECT entity_object_id
            FROM ckeditor_migration_4_5 WHERE entity_name = ?',
        Bind => [ \$Param{EntityName} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Data, $Row[0];
    }

    return @Data;
}

sub ContentReplace {
    my ( $Self, %Param ) = @_;

    my $Content = $Param{Content};
    return if !$Content;

    my $NewContent;
    my @ContentArray = split "[\r\n]", $Content;

    my $PreviousContains = {
        Counter => 0,
        What    => '',
    };

    my $Counter = 0;

    LINE:
    for my $Line (@ContentArray) {
        $Counter++;

        # identify break line
        my $ContainsBr = $Line =~ m/<br \/>/;

        # identify hr line
        my $IsHRLine = $Line =~ m/<hr \/>/;

        if ( $PreviousContains->{Counter} ) {
            my $ContainsWhat = $PreviousContains->{What};
            my $EndsWhat     = $Line =~ m/<\/$ContainsWhat>/;
            my $StartsWhat   = $Line =~ m/<$ContainsWhat>/;

            $PreviousContains->{Counter}++ if $StartsWhat;

            if ( !$EndsWhat ) {
                next LINE;
            }
            else {
                $PreviousContains->{Counter}--;
                next LINE;
            }
        }
        $Line =~ m/()/;
        $Line =~ m/<(table|ol|li|div|h1|h2|h3|h4|h5|h6|pre|p|figure).*/;
        my $StartsWithValidTag = $1;
        my $EndsWithValidTag   = '';

        if ($StartsWithValidTag) {
            $EndsWithValidTag = $Line =~ m/.*?<\/$StartsWithValidTag>/;
        }

        if ( $StartsWithValidTag && !$EndsWithValidTag ) {
            $PreviousContains = {
                Counter => 1,
                What    => $StartsWithValidTag,
            };
            next LINE;
        }

        if ($ContainsBr) {

            # hr line does not need to be within paragraph, it can be present right after hr
            if ($IsHRLine) {
                $Line =~ s/(.*?)<br \/>/$1<p><\/p>/;
            }
            else {
                $Line =~ s/(.*?)<br \/>/<p>$1<\/p>/;
            }
        }
    }

    $NewContent = join "\n", @ContentArray;

    #  replace paragraph with br with multiple paragraphs
    $NewContent =~ s{
        <p>(.*?)<\/p>
    }{
        my $Content = $1;

        if ($Content =~ /<br\s*\/?>/i) {
            my @Lines = split /<br\s*\/?>/i, $Content;

            join("\n", map {
                my $Line = $_;
                $Line =~ s/^\s+|\s+$//g;
                "<p>$Line</p>";
            } @Lines);
        } else {
            $Content =~ s/^\s+|\s+$//g;
            "<p>$Content</p>";
        }
    }gexsi if $NewContent;

    return $NewContent;
}

1;
