# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigrateCKEditorContent;    ## no critic

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::AutoResponse',
    'Kernel::System::NotificationEvent',
    'Kernel::System::ProcessManagement::ActivityDialog',
    'Kernel::System::ProcessManagement::DB::Activity',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::Salutation',
    'Kernel::System::Signature',
    'Kernel::System::StandardTemplate',
    'Kernel::System::Console::Command::Maint::Database::CKEditorMigration',
    'Kernel::System::Encode',
);

=head1 SYNOPSIS

Migrate data to upgrade CKEditor content from version 4 to 5.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # ignore task if it was already migrated
    return 1 if $Self->_CheckIfMigrationTableExists();
    return   if !$Self->_CreateMigrationTable();
    return   if !$Self->_PopulateMigrationTable();
    return   if !$Self->_ExecuteMigration();

    return 1;
}

sub _CheckIfMigrationTableExists {
    my ( $Self, %Param ) = @_;

    return 1 if $Self->TableExists(
        Table => 'ckeditor_migration_4_5',
    );
    return;
}

sub _CreateMigrationTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableCreate Name="ckeditor_migration_4_5">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
            <Column Name="entity_object_id" Required="true" Size="255" Type="VARCHAR"/>
            <Column Name="entity_name" Required="true" Size="200" Type="VARCHAR"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <ForeignKey ForeignTable="users">
                <Reference Local="create_by" Foreign="id"/>
            </ForeignKey>
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _PopulateMigrationTable {
    my ( $Self, %Param ) = @_;

    return if !$Self->_PopulateTableWithAutoResponses();
    return if !$Self->_PopulateTableWithSalutations();
    return if !$Self->_PopulateTableWithSignatures();
    return if !$Self->_PopulateTableWithStandardTemplates();
    return if !$Self->_PopulateTableWithNotifications();
    return if !$Self->_PopulateTableWithActivityDialogs();

    return 1;
}

sub _ExecuteMigration {
    my ( $Self, %Param ) = @_;

    my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Database::CKEditorMigration');

    my ( $Result, $ExitCode );
    {
        local *STDOUT;
        open STDOUT, '>:encoding(UTF-8)', \$Result;
        $ExitCode = $CommandObject->Execute('--print-only-errors');
        $Kernel::OM->Get('Kernel::System::Encode')->EncodeInput( \$Result );
    }

    print $Result;

    my $Success = $ExitCode ? 0 : 1;

    return $Success;
}

sub _PopulateMigrationTableGeneric {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$Param{EntityName} || !defined $Param{IDs};

    # no data to migrate found
    return 1 if !$Param{IDs}->[0];

    for my $ID ( @{ $Param{IDs} } ) {

        # insert into database
        return if !$DBObject->Do(
            SQL => '
                INSERT INTO ckeditor_migration_4_5
                    (entity_object_id, entity_name, create_time, create_by)
                VALUES
                    (?, ?, current_timestamp, ?)',
            Bind => [
                \$ID, \$Param{EntityName}, \1,
            ],
        );
    }

    return 1;
}

sub _PopulateTableWithAutoResponses {
    my ( $Self, %Param ) = @_;

    my $AutoResponseObject = $Kernel::OM->Get('Kernel::System::AutoResponse');

    my @IDs;
    my %List = $AutoResponseObject->AutoResponseList(
        Valid => 0,
    );

    ID:
    for my $ID ( sort keys %List ) {
        my %Data = $AutoResponseObject->AutoResponseGet(
            ID => $ID,
        );

        next ID if !$Data{ContentType} || $Data{ContentType} ne 'text/html';

        push @IDs, $ID;
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'auto_response',
        IDs        => \@IDs
    );

    return 1;
}

sub _PopulateTableWithSalutations {
    my ( $Self, %Param ) = @_;

    my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');

    my @IDs;
    my %List = $SalutationObject->SalutationList(
        Valid => 0,
    );

    ID:
    for my $ID ( sort keys %List ) {
        my %Data = $SalutationObject->SalutationGet(
            ID => $ID,
        );

        next ID if !$Data{ContentType} || $Data{ContentType} ne 'text/html';

        push @IDs, $ID;
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'salutation',
        IDs        => \@IDs
    );

    return 1;
}

sub _PopulateTableWithSignatures {
    my ( $Self, %Param ) = @_;

    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');

    my @IDs;
    my %List = $SignatureObject->SignatureList(
        Valid => 0,
    );

    ID:
    for my $ID ( sort keys %List ) {
        my %Data = $SignatureObject->SignatureGet(
            ID => $ID,
        );

        next ID if !$Data{ContentType} || $Data{ContentType} ne 'text/html';

        push @IDs, $ID;
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'signature',
        IDs        => \@IDs
    );

    return 1;
}

sub _PopulateTableWithStandardTemplates {
    my ( $Self, %Param ) = @_;

    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

    my @IDs;
    my %List = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );

    ID:
    for my $ID ( sort keys %List ) {
        my %Data = $StandardTemplateObject->StandardTemplateGet(
            ID => $ID,
        );

        next ID if !$Data{ContentType} || $Data{ContentType} ne 'text/html';

        push @IDs, $ID;
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'standard_template',
        IDs        => \@IDs
    );

    return 1;
}

sub _PopulateTableWithNotifications {
    my ( $Self, %Param ) = @_;

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');

    my @IDs;
    my %List = $NotificationEventObject->NotificationList(
        Details => 1,
        All     => 1,
    );

    ID:
    for my $ID ( sort keys %List ) {
        next ID if !IsHashRefWithData( $List{$ID}->{Message} );

        my $MigrateNotification;
        LANGUAGE:
        for my $Message ( values %{ $List{$ID}->{Message} } ) {
            if ( $Message->{ContentType} && $Message->{ContentType} eq 'text/html' ) {
                $MigrateNotification = 1;
                last LANGUAGE;
            }
        }

        push @IDs, $ID if $MigrateNotification;
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'notification_event',
        IDs        => \@IDs
    );

    return 1;
}

sub _PopulateTableWithActivityDialogs {
    my ( $Self, %Param ) = @_;

    my $ProcessObject        = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');

    my @IDs;
    my $List = $ProcessObject->ProcessListGet(
        UserID => 1,
    );

    PROCESS:
    for my $Process ( @{$List} ) {
        my $MigrateProcess;
        my $ActivityList = $Process->{Activities};
        next PROCESS if !IsArrayRefWithData($ActivityList);

        ACTIVITY:
        for my $EntityID ( @{$ActivityList} ) {
            my $ActivityData = $ActivityObject->ActivityGet(
                EntityID => $EntityID,
                UserID   => 1
            );

            my $ActivityDialogs = $ActivityData->{ActivityDialogs};
            next ACTIVITY if !IsArrayRefWithData($ActivityDialogs);

            DIALOG:
            for my $Dialog ( @{$ActivityDialogs} ) {
                my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
                    ActivityDialogEntityID => $Dialog,
                    Interface              => 'all',
                );

                if ( $ActivityDialog->{Fields}->{Article} && $ActivityDialog->{Fields}->{Article}->{Config}->{Body} ) {
                    push @IDs, $Dialog;
                }
            }
        }
    }

    return if !$Self->_PopulateMigrationTableGeneric(
        EntityName => 'pm_activity_dialog',
        IDs        => \@IDs,
    );

    return 1;
}

1;
