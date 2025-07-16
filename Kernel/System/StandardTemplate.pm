# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::StandardTemplate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::System::Queue',
    'Kernel::Language',
    'Kernel::System::StdAttachment',
    'Kernel::System::SystemAddress',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::StandardTemplate - standard template lib

=head1 DESCRIPTION

All standard template functions. E. g. to add standard template or other functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 StandardTemplateAdd()

add new standard template

    my $ID = $StandardTemplateObject->StandardTemplateAdd(
        Name         => 'New Standard Template',
        Template     => 'Thank you for your email.',
        ContentType  => 'text/plain; charset=utf-8',
        TemplateType => 'Answer,Forward',
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub StandardTemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ValidID Template ContentType UserID TemplateType)) {
        if ( !defined( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if a standard template with this name already exists
    if ( $Self->NameExistsCheck( Name => $Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A standard template with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # sort TemplateType
    $Param{TemplateType} = join ',', sort split( /\s*,\s*/, $Param{TemplateType} );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO standard_template (name, valid_id, comments, text,
                content_type, create_time, create_by, change_time, change_by, template_type)
            VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?)',
        Bind => [
            \$Param{Name},        \$Param{ValidID}, \$Param{Comment}, \$Param{Template},
            \$Param{ContentType}, \$Param{UserID},  \$Param{UserID},  \$Param{TemplateType},
        ],
    );

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM standard_template WHERE name = ? AND change_by = ?',
        Bind => [ \$Param{Name}, \$Param{UserID}, ],
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return $ID;
}

=head2 StandardTemplateGet()

get standard template attributes

    my %StandardTemplate = $StandardTemplateObject->StandardTemplateGet(
        ID => 123,
    );

Returns:

    %StandardTemplate = (
        ID                  => '123',
        Name                => 'Simple remplate',
        Comment             => 'Some comment',
        Template            => 'Template content',
        ContentType         => 'text/plain',
        TemplateType        => 'Answer,Forward',
        ValidID             => '1',
        CreateTime          => '2010-04-07 15:41:15',
        CreateBy            => '321',
        ChangeTime          => '2010-04-07 15:59:45',
        ChangeBy            => '223',
    );

=cut

sub StandardTemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => '
            SELECT name, valid_id, comments, text, content_type, create_time, create_by,
                change_time, change_by, template_type
            FROM standard_template
            WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    my %Data;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Data = (
            ID           => $Param{ID},
            Name         => $Data[0],
            Comment      => $Data[2],
            Template     => $Data[3],
            ContentType  => $Data[4] || 'text/plain',
            ValidID      => $Data[1],
            CreateTime   => $Data[5],
            CreateBy     => $Data[6],
            ChangeTime   => $Data[7],
            ChangeBy     => $Data[8],
            TemplateType => $Data[9],
        );
    }

    return %Data;
}

=head2 StandardTemplateDelete()

delete a standard template

    $StandardTemplateObject->StandardTemplateDelete(
        ID => 123,
    );

=cut

sub StandardTemplateDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete queue<->std template relation
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM queue_standard_template WHERE standard_template_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # delete attachment<->std template relation
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM standard_template_attachment WHERE standard_template_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM standard_template WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return 1;
}

=head2 StandardTemplateUpdate()

update standard template attributes

    $StandardTemplateObject->StandardTemplateUpdate(
        ID           => 123,
        Name         => 'New Standard Template',
        Template     => 'Thank you for your email.',
        ContentType  => 'text/plain; charset=utf-8',
        TemplateType => 'Answer,Forward',
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub StandardTemplateUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name ValidID TemplateType ContentType UserID)) {
        if ( !defined( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if a standard template with this name already exists
    if (
        $Self->NameExistsCheck(
            Name => $Param{Name},
            ID   => $Param{ID}
        )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A standard template with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # sort TemplateType
    $Param{TemplateType} = join ',', sort split( /\s*,\s*/, $Param{TemplateType} );

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            UPDATE standard_template
            SET name = ?, text = ?, content_type = ?, comments = ?, valid_id = ?,
                change_time = current_timestamp, change_by = ? ,template_type = ?
            WHERE id = ?',
        Bind => [
            \$Param{Name},    \$Param{Template}, \$Param{ContentType},  \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID},   \$Param{TemplateType}, \$Param{ID},
        ],
    );

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return 1;
}

=head2 StandardTemplateLookup()

return the name or the standard template id

    my $StandardTemplateName = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplateID => 123,
    );

    or

    my $StandardTemplateID = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplate => 'Std Template Name',
    );

=cut

sub StandardTemplateLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{StandardTemplate} && !$Param{StandardTemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no StandardTemplate or StandardTemplateID!'
        );
        return;
    }

    # check if we ask the same request?
    if ( $Param{StandardTemplateID} && $Self->{"StandardTemplateLookup$Param{StandardTemplateID}"} )
    {
        return $Self->{"StandardTemplateLookup$Param{StandardTemplateID}"};
    }
    if ( $Param{StandardTemplate} && $Self->{"StandardTemplateLookup$Param{StandardTemplate}"} ) {
        return $Self->{"StandardTemplateLookup$Param{StandardTemplate}"};
    }

    # get data
    my $SQL;
    my $Suffix;
    my @Bind;
    if ( $Param{StandardTemplate} ) {
        $Suffix = 'StandardTemplateID';
        $SQL    = 'SELECT id FROM standard_template WHERE name = ?';
        @Bind   = ( \$Param{StandardTemplate} );
    }
    else {
        $Suffix = 'StandardTemplate';
        $SQL    = 'SELECT name FROM standard_template WHERE id = ?';
        @Bind   = ( \$Param{StandardTemplateID} );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        # store result
        $Self->{"StandardTemplate$Suffix"} = $Row[0];
    }

    # check if data exists
    if ( !exists $Self->{"StandardTemplate$Suffix"} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Found no \$$Suffix!"
        );
        return;
    }

    return $Self->{"StandardTemplate$Suffix"};
}

=head2 StandardTemplateExport()

export a standard template

    my $ExportData = $StandardTemplateObject->StandardTemplateExport(
        # required either ID or ExportAll
        ID                       => $StandardTemplateID,
        ExportAll                => 0,               # possible: 0, 1

        UserID                   => 1,               # required
    }

returns Standard Template hashes in an array with data:

    my $ExportData =
    [
        {
            'ValidID' => 1,
            'Template' => '<p>some-content</p>',
            'CreateBy' => 1,
            'Name' => 'create1',
            'TemplateType' => 'Create',
            'Comment' => '',
            'Queues' => {},
            'ChangeBy' => 1,
            'ID' => '24',
            'Attachments' => {
                '1' => 'attachment1',
                '2' => 'attachment2'
            },
            'CreateTime' => '2024-07-24 09:47:28',
            'ContentType' => 'text/html',
            'ChangeTime' => '2024-07-24 09:53:25'
        },
    ];


=cut

sub StandardTemplateExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $StandardTemplateData;

    if ( $Param{ExportAll} ) {
        my %StandardTemplateList = $Self->StandardTemplateList(
            Valid => 0,
        );

        my @Data;
        for my $ItemID ( sort keys %StandardTemplateList ) {
            my %StandardTemplateSingleData = $Self->StandardTemplateExportDataGet(
                ID => $ItemID,
            );

            push @Data, \%StandardTemplateSingleData if %StandardTemplateSingleData;
        }
        $StandardTemplateData = \@Data;
    }
    elsif ( $Param{ID} ) {
        my %StandardTemplateSingleData = $Self->StandardTemplateExportDataGet(
            ID => $Param{ID},
        );

        return if !%StandardTemplateSingleData;

        $StandardTemplateData = [ \%StandardTemplateSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" parameter!',
        );
        return;
    }

    return $StandardTemplateData;
}

=head2 StandardTemplateImport()

import a standard template via YAML content

    my $ImportResult = $StandardTemplateObject->StandardTemplateImport(
        Content                    => $YAMLContent, # mandatory, YAML format
        OverwriteExistingTemplates => 0,            # optional, possible: 0, 1
        UserID                     => 1,            # mandatory
    );

Returns:

    $Result = {
        Success          => 1,                                      # 1 if success or undef if operation could not
                                                                    # be performed
        Message          => 'The Message to show.',                 # error message
        Added            => 'StandardTemplate1, StandardTemplate2', # string of StandardTemplates correctly added
        Updated          => 'StandardTemplate3, StandardTemplate4', # string of StandardTemplates correctly updated
        NotUpdated       => 'StandardTemplate5, StandardTemplate6', # string of StandardTemplates not updated due to existing entity
                                                                    # with the same name
        Errors           => 'StandardTemplate5',                    # string of StandardTemplates that could not be added or updated
        AdditionalErrors => ['Some error occured!', 'Error2!'],     # list of additional error not necessarily related to specified StandardTemplate
    };

=cut

sub StandardTemplateImport {
    my ( $Self, %Param ) = @_;

    my $YAMLObject          = $Kernel::OM->Get('Kernel::System::YAML');
    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
    my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');

    for my $Needed (qw(Content UserID)) {

        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return {
                Success => 0,
                Message => "$Needed is missing, can not continue.",
            };
        }
    }

    my $StandardTemplateData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $StandardTemplateData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read standard template configuration file. Please make sure the file is valid."),
        };
    }

    my @UpdatedStandardTemplates;
    my @NotUpdatedStandardTemplates;
    my @AddedStandardTemplates;
    my @StandardTemplateErrors;

    my %CurrentStandardTemplates = $Self->StandardTemplateList(
        %Param,
    );
    my %ReverseCurrentStandardTemplates = reverse %CurrentStandardTemplates;
    my %AdditionalErrors;

    STANDARD_TEMPLATE:
    for my $StandardTemplate ( @{$StandardTemplateData} ) {

        next STANDARD_TEMPLATE if !$StandardTemplate;
        next STANDARD_TEMPLATE if ref $StandardTemplate ne 'HASH';

        if ( !$StandardTemplate->{Name} ) {
            my $StandardMessage = "One or more standard templates \"Name\" parameter is missing!";
            $AdditionalErrors{DataMissing} = $StandardMessage
                if !$AdditionalErrors{DataMissing};

            $LogObject->Log(
                Priority => 'error',
                Message  => $StandardMessage,
            );

            next STANDARD_TEMPLATE;
        }

        # link queues by name
        my $Queues = delete $StandardTemplate->{Queues};
        my @QueuesToLink;

        my $QueueContainsError;
        my $QueueErrorMessage;

        my $ShowQueues;

        # check if queues specified in the content exists in the db
        if ( IsHashRefWithData($Queues) ) {
            for my $QueueName ( values %{$Queues} ) {
                my $QueueID;

                $QueueID = $QueueObject->QueueLookup( Queue => $QueueName ) if $QueueName;

                if ($QueueID) {
                    push @QueuesToLink, $QueueID if $QueueID;
                }
                else {
                    if ( !$QueueContainsError ) {
                        $QueueContainsError = 1;

                        if ( !$QueueName ) {
                            $QueueErrorMessage
                                = "Standard template $StandardTemplate->{Name} import data contains linked queues that do not have a name.";
                        }
                        else {
                            $ShowQueues = 1;
                            $QueueErrorMessage
                                = "Standard template $StandardTemplate->{Name} import data contains linked queues that do not exist.";
                        }

                        $QueueErrorMessage .= " Invalid queues: $QueueName" if $ShowQueues;
                    }
                    else {
                        $QueueErrorMessage .= ", $QueueName" if $ShowQueues;
                    }
                }
            }

            if ($QueueErrorMessage) {
                $LogObject->Log(
                    Priority => 'error',
                    Message =>
                        $QueueErrorMessage . '.',
                );
                push @StandardTemplateErrors, $StandardTemplate->{Name};
                next STANDARD_TEMPLATE;
            }
        }

        # link attachments by name
        my $Attachments = delete $StandardTemplate->{Attachments};
        my @AttachmentsToLink;

        my $AttachmentContainsError;
        my $AttachmentErrorMessage;

        my $ShowAttachments;

        # check if attachments specified in the content exists in the db
        if ( IsHashRefWithData($Attachments) ) {
            for my $AttachmentName ( values %{$Attachments} ) {
                my $AttachmentID;

                $AttachmentID = $StdAttachmentObject->StdAttachmentLookup( StdAttachment => $AttachmentName )
                    if $AttachmentName;

                if ($AttachmentID) {
                    push @AttachmentsToLink, $AttachmentID if $AttachmentID;
                }
                else {
                    if ( !$AttachmentContainsError ) {
                        $AttachmentContainsError = 1;

                        if ( !$AttachmentName ) {
                            $AttachmentErrorMessage
                                = "Standard template $StandardTemplate->{Name} import data contains linked attachments that do not have a name.";
                        }
                        else {
                            $ShowAttachments = 1;
                            $AttachmentErrorMessage
                                = "Standard template $StandardTemplate->{Name} import data contains linked attachments that do not exist.";
                        }

                        $AttachmentErrorMessage .= " Invalid attachments: $AttachmentName" if $ShowAttachments;
                    }
                    else {
                        $AttachmentErrorMessage .= ", $AttachmentName" if $ShowAttachments;
                    }
                }
            }

            if ($AttachmentErrorMessage) {
                $LogObject->Log(
                    Priority => 'error',
                    Message =>
                        $AttachmentErrorMessage . '.',
                );
                push @StandardTemplateErrors, $StandardTemplate->{Name};
                next STANDARD_TEMPLATE;
            }
        }

        my $Success;
        my $LinkedDataSuccess      = 1;
        my $StandardTemplateExists = $ReverseCurrentStandardTemplates{ $StandardTemplate->{Name} };

        if ( $Param{OverwriteExistingTemplates} && $StandardTemplateExists ) {
            my $StandardTemplateID = $ReverseCurrentStandardTemplates{ $StandardTemplate->{Name} };
            $Success = $Self->StandardTemplateUpdate(
                %{$StandardTemplate},
                ID     => $StandardTemplateID,
                UserID => $Param{UserID},
            );

            if ($Success) {
                my $QueueLinkedDataSuccess = $Self->StandardTemplateQueueLinkByTemplate(
                    QueueIDs => \@QueuesToLink,
                    ID       => $StandardTemplateID,
                    UserID   => 1,
                );

                my $AttachmentLinkedDataSuccess = $Self->StandardTemplateAttachmentLinkByTemplate(
                    AttachmentIDs => \@AttachmentsToLink,
                    ID            => $StandardTemplateID,
                    UserID        => 1,
                );

                $LinkedDataSuccess = $QueueLinkedDataSuccess && $AttachmentLinkedDataSuccess;

                push @UpdatedStandardTemplates, $StandardTemplate->{Name};
            }
        }
        else {
            if ($StandardTemplateExists) {
                push @NotUpdatedStandardTemplates, $StandardTemplate->{Name};
                next STANDARD_TEMPLATE;
            }

            # now add the StandardTemplate
            my $StandardTemplateID = $Self->StandardTemplateAdd(
                %{$StandardTemplate},
                UserID => $Param{UserID},
            );

            $Success = $StandardTemplateID;

            if ($StandardTemplateID) {
                my $QueueLinkedDataSuccess = $Self->StandardTemplateQueueLinkByTemplate(
                    QueueIDs => \@QueuesToLink,
                    ID       => $StandardTemplateID,
                    UserID   => 1,
                );

                my $AttachmentLinkedDataSuccess = $Self->StandardTemplateAttachmentLinkByTemplate(
                    AttachmentIDs => \@AttachmentsToLink,
                    ID            => $StandardTemplateID,
                    UserID        => 1,
                );

                my $LinkedDataSuccess = $QueueLinkedDataSuccess && $AttachmentLinkedDataSuccess;

                push @AddedStandardTemplates, $StandardTemplate->{Name};
            }
        }

        # indicate error when entity wasn't imported at all or there are some
        # issues with linked data from the import file or for some
        # other reason data can't be linked correctly
        if ( !$Success || $QueueContainsError || $AttachmentContainsError || !$LinkedDataSuccess ) {
            push @StandardTemplateErrors, $StandardTemplate->{Name};
        }
    }

    my @StandardTemplateAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @StandardTemplateAdditionalErrors, $ErrorMessage;
    }

    return {
        Success          => 1,
        Added            => join( ', ', @AddedStandardTemplates ) || '',
        Updated          => join( ', ', @UpdatedStandardTemplates ) || '',
        NotUpdated       => join( ', ', @NotUpdatedStandardTemplates ) || '',
        Errors           => join( ', ', @StandardTemplateErrors ) || '',
        AdditionalErrors => \@StandardTemplateAdditionalErrors,
    };
}

=head2 StandardTemplateCopy()

copy a standard template without linking it to any queue/attachment

    my $NewStandardTemplateID = $StandardTemplateObject->StandardTemplateCopy(
        ID     => 1, # mandatory
        UserID => 1, # mandatory
    );

=cut

sub StandardTemplateCopy {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    NEEDED:
    for my $Needed (qw(ID UserID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %StandardTemplateData = $Self->StandardTemplateGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );
    return if !IsHashRefWithData( \%StandardTemplateData );

    # create new standard template name
    my $StandardTemplateName = $LanguageObject->Translate( '%s (copy)', $StandardTemplateData{Name} );

    my $NewStandardTemplateID = $Self->StandardTemplateAdd(
        %StandardTemplateData,
        Name   => $StandardTemplateName,
        UserID => $Param{UserID},
    );

    return $NewStandardTemplateID;
}

=head2 StandardTemplateExportDataGet()

get data to export standard template

    my %StandardTemplateData = $StandardTemplateObject->StandardTemplateExportDataGet(
        ID => 1, # mandatory
    );

Returns:

    my %StandardTemplateData = (
        {
           'ValidID' => 1,
           'CreateBy' => 1,
           'Template' => '<p>some-content</p>',
           'Name' => 'create1',
           'TemplateType' => 'Create',
           'Queues' => {},
           'ChangeBy' => 1,
           'ID' => '24',
           'Comment' => '',
           'Attachments' => {
                '1' => 'attachment1',
                '2' => 'attachment2'
            },
            'CreateTime' => '2024-07-24 09:47:28',
            'ChangeTime' => '2024-07-24 09:53:25',
            'ContentType' => 'text/html'
        };
    );

=cut

sub StandardTemplateExportDataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

    NEEDED:
    for my $Needed (qw(ID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %StandardTemplate = $Self->StandardTemplateGet(
        ID => $Param{ID},
    );

    return if !%StandardTemplate;

    my %StandardTemplateQueuesList = $Self->StandardTemplateQueuesList(
        ID => $Param{ID},
    );

    my %StandardTemplateAttachmentsList = $Self->StandardTemplateAttachmentsList(
        ID => $Param{ID},
    );

    my %ExportData = (
        %StandardTemplate,
        Queues      => \%StandardTemplateQueuesList,
        Attachments => \%StandardTemplateAttachmentsList
    );

    return %ExportData;
}

=head2 StandardTemplateExportFilenameGet()

get export file name based on standard template name

    my $Filename = $StandardTemplateObject->StandardTemplateExportFilenameGet(
        Name => 'StandardTemplate_1',
        Format => 'YAML',
    );

=cut

sub StandardTemplateExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }
    return "Export_StandardTemplate$Extension" if !$Param{Name};

    my $DisplayName = 'Export_StandardTemplate_' . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

=head2 StandardTemplateQueuesList()

get a list of the queues that have been linked to standard template

    my %StandardTemplateQueues = $StandardTemplateObject->StandardTemplateQueuesList(
        ID => 1, # mandatory
    );

Returns:

    my %StandardTemplateQueues = (
        1 => 'queue1',
        2 => 'queue2',
    )

=cut

sub StandardTemplateQueuesList {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    return if !$DBObject->Prepare(
        SQL =>
            'SELECT qst.queue_id, q.name
             FROM queue_standard_template qst, queue q
             WHERE qst.queue_id = q.id AND qst.standard_template_id = ?
             ',
        Bind => [ \$Param{ID} ],
    );

    my %Queues;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Queues{ $Row[0] } = $Row[1];
    }

    return %Queues;
}

=head2 StandardTemplateAttachmentsList()

get a list of attachments that have been linked to standard template

    my %StandardTemplateAttachments = $StandardTemplateObject->StandardTemplateAttachmentsList(
        ID => 1, # mandatory
    );

Returns:

    my %StandardTemplateAttachments = (
        1 => 'attachment1',
        2 => 'attachment2',
    )

=cut

sub StandardTemplateAttachmentsList {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    return if !$DBObject->Prepare(
        SQL =>
            'SELECT sta.standard_attachment_id, sa.name
             FROM standard_template_attachment sta, standard_attachment sa
             WHERE sta.standard_attachment_id = sa.id AND sta.standard_template_id = ?
             ',
        Bind => [ \$Param{ID} ],
    );

    my %Attachments;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Attachments{ $Row[0] } = $Row[1];
    }

    return %Attachments;
}

=head2 StandardTemplateQueueLinkByTemplate()

assign a list of queues to a template

    my $Success = $StandardTemplateObject->StandardTemplateQueueLinkByTemplate(
        QueueIDs => [1,2,3],
        ID       => 1,
        UserID   => 1,
    );

=cut

sub StandardTemplateQueueLinkByTemplate {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    for my $Argument (qw(QueueIDs ID UserID)) {
        if ( !$Param{$Argument} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my %StandardTemplateData = $Self->StandardTemplateGet(
        ID => $Param{ID},
    );

    # return failed status if template does not exists
    return if !$StandardTemplateData{ID};

    # delete all previous relations between standard template and it's queues
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM queue_standard_template WHERE standard_template_id = ?',
        Bind => [ \$Param{ID} ],
    );

    $CacheObject->CleanUp(
        Type => $QueueObject->{CacheType},
    );

    # return success if there are no queues to assign
    return 1 if !IsArrayRefWithData( $Param{QueueIDs} );

    my @Queues = @{ $Param{QueueIDs} };
    for ( my $i = 0; $i < scalar @Queues; $i++ ) {
        my $QueueID = $Queues[$i];
        my $Queue   = $QueueObject->QueueLookup( QueueID => $QueueID );

        delete $Queues[$i] if !$Queue;
    }

    # filter out deleted/not existing queues
    @Queues = grep {$_} @Queues;

    # no valid queues to link
    return if !scalar @Queues;

    for my $QueueID (@Queues) {
        my %Queue = $QueueObject->QueueGet(
            ID => $QueueID,
        );

        my $Success = $QueueObject->QueueStandardTemplateMemberAdd(
            QueueID            => $QueueID,
            StandardTemplateID => $Param{ID},
            Active             => 1,
            UserID             => $Param{UserID},
        );

        # this error is not perfect as it will show in the logs,
        # but result of the function will still be counted as successful
        # otherwise we might add some linked data and break at linking error
        # which is worse case to handle
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error occurred while linking queue with ID $QueueID to standard template with ID $Param{ID}.",
        ) if !$Success;
    }

    return 1;
}

=head2 StandardTemplateAttachmentLinkByTemplate()

assign a list of attachments to a template

    my $Success = $StandardTemplateObject->StandardTemplateAttachmentLinkByTemplate(
        AttachmentIDs => [1,2,3],
        ID            => 1,
        UserID        => 1,
    );

=cut

sub StandardTemplateAttachmentLinkByTemplate {
    my ( $Self, %Param ) = @_;

    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject            = $Kernel::OM->Get('Kernel::System::DB');
    my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');
    my $CacheObject         = $Kernel::OM->Get('Kernel::System::Cache');

    for my $Argument (qw(AttachmentIDs ID UserID)) {
        if ( !$Param{$Argument} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my %StandardTemplateData = $Self->StandardTemplateGet(
        ID => $Param{ID},
    );

    # return failed status if template does not exists
    return if !$StandardTemplateData{ID};

    # delete all previous relations between standard templates and it's attachments
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM standard_template_attachment WHERE standard_template_id = ?',
        Bind => [ \$Param{ID} ],
    );

    $CacheObject->CleanUp(
        Type => $StdAttachmentObject->{CacheType},
    );

    # return success if there are no queues to assign
    return 1 if !IsArrayRefWithData( $Param{AttachmentIDs} );

    my @Attachments = @{ $Param{AttachmentIDs} };
    for ( my $i = 0; $i < scalar @Attachments; $i++ ) {
        my $AttachmentID = $Attachments[$i];
        my $Attachment   = $StdAttachmentObject->StdAttachmentLookup( StdAttachmentID => $AttachmentID );

        delete $Attachments[$i] if !$Attachment;
    }

    # filter out deleted/not existing attachments
    @Attachments = grep {$_} @Attachments;

    # no valid attachments to link
    return if !scalar @Attachments;

    for my $AttachmentID (@Attachments) {
        my %Attachment = $StdAttachmentObject->StdAttachmentGet(
            ID => $AttachmentID,
        );

        my $Success = $StdAttachmentObject->StdAttachmentStandardTemplateMemberAdd(
            AttachmentID       => $AttachmentID,
            StandardTemplateID => $Param{ID},
            Active             => 1,
            UserID             => $Param{UserID},
        );

        # this error is not perfect as it will show in the logs,
        # but result of the function will still be counted as successful
        # otherwise we might add some linked data and break at linking error
        # which is worse case to handle
        $LogObject->Log(
            Priority => 'error',
            Message =>
                "Error occurred while linking attachment with ID $AttachmentID to standard template with ID $Param{ID}.",
        ) if !$Success;
    }

    return 1;
}

=head2 StandardTemplateList()

get all valid standard templates

    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList();

Returns:

    %StandardTemplates = (
        1 => 'Some Name',
        2 => 'Some Name2',
        3 => 'Some Name3',
    );

get all standard templates

    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );

Returns:

    %StandardTemplates = (
        1 => 'Some Name',
        2 => 'Some Name2',
    );

get standard templates of a single type

    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
        Type  => 'Answer',
    );

Returns:

    %StandardTemplates = (
        1 => 'Some Name',
    );

get standard templates for multiple types

    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
        Type  => 'Answer,Forward',
    );

Returns:

    %StandardTemplates = (
        'Answer' => {
            '1' => 'Some Name',
            '4' => 'AW FWD',
        },
        'Forward' => {
            '3' => 'Some Name3',
            '4' => 'AW FWD',
        }
    );

=cut

sub StandardTemplateList {
    my ( $Self, %Param ) = @_;

    my $Valid = 1;
    if ( defined $Param{Valid} && $Param{Valid} eq '0' ) {
        $Valid = 0;
    }

    my $SQL = '
        SELECT id, name, template_type
        FROM standard_template';

    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . join ', ',
            $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet() . ')';
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my %TemplateTypes;
    my %Data;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        my @DBTypes = split( /\s*,\s*/, $Row[2] );
        if ( scalar @DBTypes > 1 ) {
            for my $Type (@DBTypes) {
                $TemplateTypes{$Type}->{ $Row[0] } = $Row[1];
            }
        }
        else {
            $TemplateTypes{ $Row[2] }->{ $Row[0] } = $Row[1];
        }
    }

    if ( defined $Param{Type} && $Param{Type} ne '' ) {
        my @ParamTypes = split( /\s*,\s*/, $Param{Type} );

        if ( scalar @ParamTypes > 1 ) {

            # Multiple types. Data should contain a hash of types with template names.
            for my $ParamType (@ParamTypes) {
                $Data{$ParamType} = $TemplateTypes{$ParamType};
            }
        }
        else {
            # Single type. Data should contain only the template names of specified type.
            %Data = %{ $TemplateTypes{ $Param{Type} } } if $TemplateTypes{ $Param{Type} };
        }
    }
    else {
        # No type specified. Data should contain all template names of all types.
        for my $Type ( sort keys %TemplateTypes ) {
            %Data = (
                %Data,
                %{ $TemplateTypes{$Type} }
            );
        }
    }

    return %Data;
}

=head2 NameExistsCheck()

    return 1 if another standard template with this name already exists

        $Exist = $StandardTemplateObject->NameExistsCheck(
            Name => 'Some::Template',
            ID   => 1,                  # optional
        );

=cut

sub NameExistsCheck {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM standard_template WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }
    if ($Flag) {
        return 1;
    }
    return 0;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
