# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $YAMLObject          = $Kernel::OM->Get('Kernel::System::YAML');
my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');
my $MainObject          = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');

# get StandardTemplate object
my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();

# create default salutation
my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');
my $NewSalutationID  = $SalutationObject->SalutationAdd(
    Name        => 'New Salutation',
    Text        => "--\nSome Salutation Infos",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

# create default signature
my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
my $NewSignatureID  = $SignatureObject->SignatureAdd(
    Name        => 'New Signature',
    Text        => "--\nSome Signature Infos",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

# create some new queues
my @NewQueuesIDs;

my %NewQueueParams = (
    ValidID             => 1,
    GroupID             => 1,
    FirstResponseTime   => 0,
    FirstResponseNotify => 0,
    UpdateTime          => 0,
    UpdateNotify        => 0,
    SolutionTime        => 0,
    SolutionNotify      => 0,
    SystemAddressID     => 1,
    SignatureID         => $NewSignatureID,
    SalutationID        => $NewSalutationID,
    Comment             => 'Some Comment',
    UserID              => 1,
);

for my $Counter ( 1 .. 5 ) {

    # set queue name
    my $QueueName = 'Some::Queue' . $RandomID . " - $Counter";

    my $QueueID = $QueueObject->QueueAdd(
        %NewQueueParams,
        Name => $QueueName,
    );

    $Self->True(
        $QueueID,
        "QueueAdd() - $QueueName, $QueueID",
    );

    push @NewQueuesIDs, $QueueID if $QueueID;
}

# create some new standard attachments
my @NewStdAttachmentsIDs;

my $Home     = $ConfigObject->Get('Home');
my $Location = $Home . "/scripts/test/sample/StdAttachment/StdAttachment-Test1.txt";

my $ContentRef = $MainObject->FileRead(
    Location => $Location,
    Mode     => 'binmode',
);

my $Content = ${$ContentRef};

my %NewAttachmentParams = (
    ValidID     => 1,
    Content     => $Content,
    ContentType => 'text/xml',
    Filename    => 'StdAttachment.txt',
    Comment     => 'Some Comment',
    UserID      => 1,
);

for my $Counter ( 1 .. 5 ) {

    # set attachment name
    my $AttachmentName = 'Some::Attachment' . $RandomID . " - $Counter";

    my $AttachmentID = $StdAttachmentObject->StdAttachmentAdd(
        %NewAttachmentParams,
        Name => $AttachmentName,
    );

    $Self->True(
        $AttachmentID,
        "StdAttachmentAdd() - $AttachmentName, $AttachmentID",
    );

    push @NewStdAttachmentsIDs, $AttachmentID if $AttachmentID;
}

# tests
my @Tests = (
    {
        Name => 'text',
        Add  => {
            Name         => 'text' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text',
            ContentType  => 'text/plain; charset=iso-8859-1',
            TemplateType => 'Answer',
            Comment      => 'some comment',
            UserID       => 1,
        },
        AddSecond => {
            Name         => 'text_second_' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text',
            ContentType  => 'text/plain; charset=iso-8859-1',
            TemplateType => 'Answer',
            Comment      => 'some comment',
            UserID       => 1,
        },
        AddTwoTypes => {
            Name         => 'two_types_tmpl' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text',
            ContentType  => 'text/plain; charset=iso-8859-1',
            TemplateType => 'PhoneCall,Email',
            Comment      => 'some comment',
            UserID       => 1,
        },
        AddGet => {
            Name         => 'text' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text',
            ContentType  => 'text/plain; charset=iso-8859-1',
            TemplateType => 'Answer',
            Comment      => 'some comment',
        },
        Update => {
            Name         => 'text2' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text\'2',
            ContentType  => 'text/plain; charset=utf-8',
            TemplateType => 'Forward',
            Comment      => 'some comment2',
            UserID       => 1,
        },
        UpdateGet => {
            Name         => 'text2' . $RandomID,
            ValidID      => 1,
            Template     => 'Template text\'2',
            ContentType  => 'text/plain; charset=utf-8',
            TemplateType => 'Forward',
            Comment      => 'some comment2',
        },
    },
);
my @IDs;

for my $Test (@Tests) {

    # add
    my $ID = $StandardTemplateObject->StandardTemplateAdd(
        %{ $Test->{Add} },
    );
    $Self->True(
        $ID,
        "StandardTemplateAdd() - $ID",
    );

    push( @IDs, $ID );

    # add with existing name
    my $IDWrong = $StandardTemplateObject->StandardTemplateAdd(
        %{ $Test->{Add} },
    );
    $Self->False(
        $IDWrong,
        "StandardTemplateAdd() - Try to add the standard template with existing name",
    );

    my %Data = $StandardTemplateObject->StandardTemplateGet(
        ID => $ID,
    );
    for my $Key ( sort keys %{ $Test->{AddGet} } ) {
        $Self->Is(
            $Test->{AddGet}->{$Key},
            $Data{$Key},
            "StandardTemplateGet() - $Key",
        );
    }

    # lookup by ID
    my $Name = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplateID => $ID
    );
    $Self->Is(
        $Name,
        $Test->{Add}->{Name},
        "StandardTemplateLookup()",
    );

    # lookup by Name
    my $LookupID = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplate => $Test->{Add}->{Name},
    );
    $Self->Is(
        $ID,
        $LookupID,
        "StandardTemplateLookup()",
    );

    # update
    my $Update = $StandardTemplateObject->StandardTemplateUpdate(
        ID => $ID,
        %{ $Test->{Update} },
    );
    $Self->True(
        $ID,
        "StandardTemplateUpdate()",
    );

    %Data = $StandardTemplateObject->StandardTemplateGet(
        ID => $ID,
    );
    for my $Key ( sort keys %{ $Test->{UpdateGet} } ) {
        $Self->Is(
            $Test->{UpdateGet}->{$Key},
            $Data{$Key},
            "StandardTemplateGet() - $Key",
        );
    }

    # add another standard template
    my $IDSecond = $StandardTemplateObject->StandardTemplateAdd(
        %{ $Test->{AddSecond} },
    );

    push( @IDs, $IDSecond );

    $Self->True(
        $IDSecond,
        "StandardTemplateAdd() - $IDSecond",
    );

    # update with existing name
    my $UpdateWrong = $StandardTemplateObject->StandardTemplateUpdate(
        ID => $IDSecond,
        %{ $Test->{Update} },
    );
    $Self->False(
        $UpdateWrong,
        "StandardTemplateUpdate() - Try to update the standard template with existing name",
    );

    # check function NameExistsCheck()
    # check does it exist a standard template with certain Name or
    # check is it possible to set Name for standard template with certain ID
    my $Exist = $StandardTemplateObject->NameExistsCheck(
        Name => $Test->{AddSecond}->{Name},
    );

    $Self->True(
        $Exist,
        "NameExistsCheck() - A standard template with \'$Test->{AddSecond}->{Name}\' already exists!",
    );

    # there is a standard template with certain name, now check if there is another one
    $Exist = $StandardTemplateObject->NameExistsCheck(
        Name => "$Test->{AddSecond}->{Name}",
        ID   => $IDSecond,
    );

    $Self->False(
        $Exist,
        "NameExistsCheck() - Another standard template \'$Test->{AddSecond}->{Name}\' for ID=$IDSecond does not exist!",
    );

    $Exist = $StandardTemplateObject->NameExistsCheck(
        Name => $Test->{AddSecond}->{Name},
        ID   => $ID,
    );

    $Self->True(
        $Exist,
        "NameExistsCheck() - Another standard template \'$Test->{AddSecond}->{Name}\' for ID=$ID already exists!",
    );

    # check is there a standard template whose name has been updated in the meantime
    $Exist = $StandardTemplateObject->NameExistsCheck(
        Name => "$Test->{Add}->{Name}",
    );

    $Self->False(
        $Exist,
        "NameExistsCheck() - A standard template with \'$Test->{Add}->{Name}\' does not exist!",
    );

    $Exist = $StandardTemplateObject->NameExistsCheck(
        Name => "$Test->{Add}->{Name}",
        ID   => $ID,
    );

    $Self->False(
        $Exist,
        "NameExistsCheck() - Another standard template \'$Test->{Add}->{Name}\' for ID=$ID does not exist!",
    );

    # test StandardTemplateList()
    my %StandardTemplates              = $StandardTemplateObject->StandardTemplateList();
    my %AnswerStandardTemplates        = $StandardTemplateObject->StandardTemplateList( Type => 'Answer' );
    my %ForwardStandardTemplates       = $StandardTemplateObject->StandardTemplateList( Type => 'Forward' );
    my %CombinedAnswerForwardSingeList = ( %AnswerStandardTemplates, %ForwardStandardTemplates );

    my %AnswerForwardList         = $StandardTemplateObject->StandardTemplateList( Type => 'Answer,Forward' );
    my %CombinedAnswerForwardList = ( %{ $AnswerForwardList{Answer} }, %{ $AnswerForwardList{Forward} } );

    $Self->IsDeeply(
        \%CombinedAnswerForwardList,
        \%CombinedAnswerForwardSingeList,
        'StandardTemplateList() - Single requested type lists vs combined type lists should be the same',
    );

    $Self->IsNotDeeply(
        \%StandardTemplates,
        \%AnswerStandardTemplates,
        'StandardTemplateList() - Full vs just Answer type should be different',
    );
    $Self->IsNotDeeply(
        \%StandardTemplates,
        \%ForwardStandardTemplates,
        'StandardTemplateList() - Full vs just Forward type should be different',
    );
    $Self->IsNotDeeply(
        \%AnswerStandardTemplates,
        \%ForwardStandardTemplates,
        'StandardTemplateList() - Answer vs Forward type should be different',
    );

    # test with not only valid templates
    my %AllStandardTemplates = $StandardTemplateObject->StandardTemplateList( Valid => 0 );
    $Self->IsNotDeeply(
        \%AllStandardTemplates,
        {},
        'StandardTemplateList() - All templates is not an empty hash',
    );
    my %AllAnswerStandardTemplatess = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
        Type  => 'Answer',
    );
    $Self->IsNotDeeply(
        \%AllAnswerStandardTemplatess,
        {},
        'StandardTemplateList() - All Answer is not an empty hash',
    );

    # some tests with multiple template types
    my $IDTwoTypes = $StandardTemplateObject->StandardTemplateAdd(
        %{ $Test->{AddTwoTypes} },
    );
    push( @IDs, $IDTwoTypes );

    $Self->True(
        $IDTwoTypes,
        "StandardTemplateAdd() - $IDTwoTypes",
    );

    %Data = $StandardTemplateObject->StandardTemplateGet(
        ID => $IDTwoTypes,
    );

    $Self->Is(
        $Data{TemplateType},
        'Email,PhoneCall',
        "StandardTemplateGet() - Both TemplateTypes correctly returned",
    );

    # test linking between queues and standard templates
    my %QueuesListAfterLink1;
    for my $QueueID (@NewQueuesIDs) {
        my $Queue = $QueueObject->QueueLookup( QueueID => $QueueID );
        $QueuesListAfterLink1{$QueueID} = $Queue;
    }

    my %QueuesListAfterLink2;
    my @PartOfNewQueuesIDs = @NewQueuesIDs[ 0 .. 2 ];
    for my $QueueID (@PartOfNewQueuesIDs) {
        my $Queue = $QueueObject->QueueLookup( QueueID => $QueueID );
        $QueuesListAfterLink2{$QueueID} = $Queue;
    }

    my @QueuesLinkTests = (
        {
            Name             => '- 1',
            QueuesToLink     => \@NewQueuesIDs,
            StandardTemplate => {
                ID => $ID,
            },
            QueuesListBeforeLink => {
                ExpectedData => {}
            },
            QueuesListAfterLink => {
                ExpectedData => \%QueuesListAfterLink1,
            },
        },
        {
            Name             => '- 2',
            QueuesToLink     => \@PartOfNewQueuesIDs,
            StandardTemplate => {
                ID => $ID,
            },
            QueuesListBeforeLink => {
                ExpectedData => \%QueuesListAfterLink1,
            },
            QueuesListAfterLink => {
                ExpectedData => \%QueuesListAfterLink2,
            },
        },
        {
            Name             => '- 3',
            QueuesToLink     => [],
            StandardTemplate => {
                ID => $ID,
            },
            QueuesListBeforeLink => {
                ExpectedData => \%QueuesListAfterLink2,
            },
            QueuesListAfterLink => {
                ExpectedData => {},
            },
        },
        {
            Name             => '- 4',
            QueuesToLink     => \@PartOfNewQueuesIDs,
            StandardTemplate => {
                ID => $ID,
            },
            QueuesListBeforeLink => {
                ExpectedData => {},
            },
            QueuesListAfterLink => {
                ExpectedData => \%QueuesListAfterLink2,
            },
        },
    );

    for my $QueuesTest (@QueuesLinkTests) {
        my $StdTemplateID = $QueuesTest->{StandardTemplate}->{ID};

        my %StandardTemplateQueues = $StandardTemplateObject->StandardTemplateQueuesList(
            ID => $StdTemplateID,
        );

        $Self->IsDeeply(
            \%StandardTemplateQueues,
            $QueuesTest->{QueuesListBeforeLink}->{ExpectedData},
            "StandardTemplateQueuesList() - test response before linking queues data $QueuesTest->{Name}",
        );

        my $StdTemplateQueueLinkSuccess = $StandardTemplateObject->StandardTemplateQueueLinkByTemplate(
            QueueIDs => $QueuesTest->{QueuesToLink},
            ID       => $StdTemplateID,
            UserID   => 1,
        );

        $Self->True(
            $StdTemplateQueueLinkSuccess,
            "StandardTemplateQueueLinkByTemplate() - test response after linking queues data $QueuesTest->{Name}",
        );

        # check queues link data after linking them
        %StandardTemplateQueues = $StandardTemplateObject->StandardTemplateQueuesList(
            ID => $StdTemplateID,
        );

        $Self->IsDeeply(
            \%StandardTemplateQueues,
            $QueuesTest->{QueuesListAfterLink}->{ExpectedData},
            "StandardTemplateQueuesList() - test response when standard template was linked to new queues $QueuesTest->{Name}",
        );
    }

    # test linking between attachments and standard templates
    my %AttachmentsListAfterLink1;
    for my $AttachmentID (@NewStdAttachmentsIDs) {
        my $Attachment = $StdAttachmentObject->StdAttachmentLookup( StdAttachmentID => $AttachmentID );
        $AttachmentsListAfterLink1{$AttachmentID} = $Attachment;
    }

    my %AttachmentsListAfterLink2;
    my @PartOfNewStdAttachmentIDs = @NewStdAttachmentsIDs[ 0 .. 2 ];
    for my $AttachmentID (@PartOfNewStdAttachmentIDs) {
        my $Attachment = $StdAttachmentObject->StdAttachmentLookup( StdAttachmentID => $AttachmentID );
        $AttachmentsListAfterLink2{$AttachmentID} = $Attachment;
    }

    my @AttachmentsLinkTests = (
        {
            Name              => '- 1',
            AttachmentsToLink => \@NewStdAttachmentsIDs,
            StandardTemplate  => {
                ID => $ID,
            },
            AttachmentsListBeforeLink => {
                ExpectedData => {}
            },
            AttachmentsListAfterLink => {
                ExpectedData => \%AttachmentsListAfterLink1,
            },
        },
        {
            Name              => '- 2',
            AttachmentsToLink => \@PartOfNewStdAttachmentIDs,
            StandardTemplate  => {
                ID => $ID,
            },
            AttachmentsListBeforeLink => {
                ExpectedData => \%AttachmentsListAfterLink1,
            },
            AttachmentsListAfterLink => {
                ExpectedData => \%AttachmentsListAfterLink2,
            },
        },
        {
            Name              => '- 3',
            AttachmentsToLink => [],
            StandardTemplate  => {
                ID => $ID,
            },
            AttachmentsListBeforeLink => {
                ExpectedData => \%AttachmentsListAfterLink2,
            },
            AttachmentsListAfterLink => {
                ExpectedData => {},
            },
        },
        {
            Name              => '- 4',
            AttachmentsToLink => \@PartOfNewStdAttachmentIDs,
            StandardTemplate  => {
                ID => $ID,
            },
            AttachmentsListBeforeLink => {
                ExpectedData => {},
            },
            AttachmentsListAfterLink => {
                ExpectedData => \%AttachmentsListAfterLink2,
            },
        },
    );

    for my $AttachmentsTest (@AttachmentsLinkTests) {
        my $StdTemplateID = $AttachmentsTest->{StandardTemplate}->{ID};

        my %StandardTemplateAttachments = $StandardTemplateObject->StandardTemplateAttachmentsList(
            ID => $StdTemplateID,
        );

        $Self->IsDeeply(
            \%StandardTemplateAttachments,
            $AttachmentsTest->{AttachmentsListBeforeLink}->{ExpectedData},
            "StandardTemplateAttachmentsList() - test response before linking attachment data $AttachmentsTest->{Name}",
        );

        my $StdTemplateAttachmentLinkSuccess = $StandardTemplateObject->StandardTemplateAttachmentLinkByTemplate(
            AttachmentIDs => $AttachmentsTest->{AttachmentsToLink},
            ID            => $StdTemplateID,
            UserID        => 1,
        );

        $Self->True(
            $StdTemplateAttachmentLinkSuccess,
            "StandardTemplateAttachmentLinkByTemplate() - test response after linking attachment data $AttachmentsTest->{Name}",
        );

        # check attachments link data after linking them
        %StandardTemplateAttachments = $StandardTemplateObject->StandardTemplateAttachmentsList(
            ID => $StdTemplateID,
        );

        $Self->IsDeeply(
            \%StandardTemplateAttachments,
            $AttachmentsTest->{AttachmentsListAfterLink}->{ExpectedData},
            "StandardTemplateAttachmentsList() - test response when standard template was linked to new attachments $AttachmentsTest->{Name}",
        );
    }

    # context: at this point standard template $ID should be linked
    # with attachments: @PartOfNewStdAttachmentIDs and queues: @PartOfNewQueuesIDs

    # StandardTemplateCopy
    my $NewStandardTemplateID = $StandardTemplateObject->StandardTemplateCopy(
        ID     => $ID,
        UserID => 1,
    );

    $Self->True(
        $NewStandardTemplateID,
        'StandardTemplateCopy() - test copy of auto response'
    );

    my $OriginalStandardTemplateName = $Test->{UpdateGet}->{Name};
    my $CopiedStandardTemplateName
        = $LayoutObject->{LanguageObject}->Translate( '%s (copy)', $OriginalStandardTemplateName );

    # StandardTemplateExport
    my @ExportTests = (
        {
            Name =>
                "StandardTemplateExport() - test export of copied standard template (Standard template name: $CopiedStandardTemplateName)",
            Params => {
                ID => $NewStandardTemplateID,
            },
            ExpectedData => [
                {
                    ID => $NewStandardTemplateID,
                    %{ $Test->{UpdateGet} },
                    Name        => $CopiedStandardTemplateName,
                    Queues      => {},
                    Attachments => {},
                }
            ],
            Import => {
                OverwriteCase => {
                    ExpectedData => {
                        Added            => '',
                        Errors           => '',
                        Success          => 1,
                        Updated          => $CopiedStandardTemplateName,
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                }
            }
        },
        {
            Name =>
                "StandardTemplateExport() - test export of original standard template (Standard template name: $OriginalStandardTemplateName)",
            Params => {
                ID => $ID,
            },
            ExpectedData => [
                {
                    ID => $ID,
                    %{ $Test->{UpdateGet} },
                    Queues      => \%QueuesListAfterLink2,
                    Attachments => \%AttachmentsListAfterLink2,
                }
            ],
            Import => {
                OverwriteCase => {
                    ExpectedData => {
                        Added            => '',
                        Errors           => '',
                        Success          => 1,
                        Updated          => $OriginalStandardTemplateName,
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                }
            }
        },
    );

    # perform export & check it
    for my $ExportTest (@ExportTests) {

        my $Data = $StandardTemplateObject->StandardTemplateExport(
            %{ $ExportTest->{Params} }
        );

        $Self->True(
            IsArrayRefWithData($Data),
            $ExportTest->{Name} . ' - 1',
        );

        my $ExportContentDump = $YAMLObject->Dump(
            Data => $Data,
        );

        for my $Row ( @{$Data} ) {
            delete $Row->{CreateBy};
            delete $Row->{CreateTime};
            delete $Row->{ChangeTime};
            delete $Row->{ChangeBy};
        }

        my $IsDeeply = $Self->IsDeeply(
            $Data,
            $ExportTest->{ExpectedData},
            $ExportTest->{Name} . ' - 2',
        );

        $ExportTest->{ImportParams} = {
            Content => $ExportContentDump,
        } if $IsDeeply;
    }

    # context: export data contains linked attachments and queues - reset them
    my @StdTemplateIDs = ( $ID, $NewStandardTemplateID );

    for my $TemplateID (@StdTemplateIDs) {
        my $StdTemplateQueueLinkClearSuccess = $StandardTemplateObject->StandardTemplateQueueLinkByTemplate(
            QueueIDs => [],
            ID       => $TemplateID,
            UserID   => 1,
        );

        $Self->True(
            $StdTemplateQueueLinkClearSuccess,
            "StandardTemplateQueueLinkByTemplate() - Standard template id: $TemplateID, queues: []",
        );

        my $StdTemplateAttachmentLinkClearSuccess = $StandardTemplateObject->StandardTemplateAttachmentLinkByTemplate(
            AttachmentIDs => [],
            ID            => $TemplateID,
            UserID        => 1,
        );

        $Self->True(
            $StdTemplateAttachmentLinkClearSuccess,
            "StandardTemplateAttachmentLinkByTemplate() - Standard template id: $TemplateID, attachments: []",
        );
    }

    # StandardTemplateImport
    # if export was succesfull, we define import tests based on this
    my @ImportTests = grep { IsHashRefWithData( $_->{ImportParams} ) } @ExportTests;
    for my $ImportTest (@ImportTests) {

        # test import result when trying to overwrite, but no overwriting is possible
        my $ImportResult = $StandardTemplateObject->StandardTemplateImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingTemplates => 0,
            UserID                     => 1,
        );

        my $ExpectedData = {
            Added            => '',
            Errors           => '',
            Success          => 1,
            Updated          => '',
            NotUpdated       => $ImportTest->{ExpectedData}->[0]->{Name},
            AdditionalErrors => [],
        };

        $Self->IsDeeply(
            $ImportResult,
            $ExpectedData,
            'StandardTemplateImport() - test response when trying to overwrite without overwrite existing auto responses parameter'
        );

        # test import result when trying to overwrite and overwriting is possible
        $ImportResult = $StandardTemplateObject->StandardTemplateImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingTemplates => 1,
            UserID                     => 1,
        );

        $Self->IsDeeply(
            $ImportResult,
            $ImportTest->{Import}->{OverwriteCase}->{ExpectedData},
            'StandardTemplateImport() - test response when trying to overwrite with overwrite permission parameter'
        );
    }

    # show linked data after importing standard templates
    my %AfterImportTests = (
        StandardTemplateQueuesList => [
            {
                Name => 'StandardTemplateQueuesList() - test original auto response linked data check after import',
                StandardTemplateID => $ID,
                ExpectedData       => \%QueuesListAfterLink2,
            },
            {
                Name => 'StandardTemplateQueuesList() - test copied auto response linked data check after import',
                StandardTemplateID => $NewStandardTemplateID,
                ExpectedData       => {},
            },
        ],
        StandardTemplateAttachmentsList => [
            {
                Name =>
                    'StandardTemplateAttachmentsList() - test original auto response linked data check after import',
                StandardTemplateID => $ID,
                ExpectedData       => \%AttachmentsListAfterLink2,
            },
            {
                Name => 'StandardTemplateAttachmentsList() - test copied auto response linked data check after import',
                StandardTemplateID => $NewStandardTemplateID,
                ExpectedData       => {},
            },
        ],

    );

    for my $Test ( @{ $AfterImportTests{StandardTemplateQueuesList} } ) {

        my %StandardTemplateQueuesAfterImport = $StandardTemplateObject->StandardTemplateQueuesList(
            ID => $Test->{StandardTemplateID},
        );

        $Self->IsDeeply(
            \%StandardTemplateQueuesAfterImport,
            $Test->{ExpectedData},
            $Test->{Name},
        );
    }

    for my $Test ( @{ $AfterImportTests{StandardTemplateAttachmentsList} } ) {

        my %StandardTemplateAttachmentsAfterImport = $StandardTemplateObject->StandardTemplateAttachmentsList(
            ID => $Test->{StandardTemplateID},
        );

        $Self->IsDeeply(
            \%StandardTemplateAttachmentsAfterImport,
            $Test->{ExpectedData},
            $Test->{Name},
        );
    }

    # test case where content parameters are missing
    my $ImportMissingNameTest = <<"EOF";
---
- some-property: some-value
EOF
    @ImportTests = (
        {
            ImportParams => {
                Content => $ImportMissingNameTest,
            },
            ExpectedData => {
                Errors           => '',
                AdditionalErrors => ['One or more standard templates "Name" parameter is missing!'],
                Added            => '',
                Success          => 1,
                Updated          => '',
                NotUpdated       => '',
            },
            Name => 'StandardTemplateImport() - test response when missing Name parameter.'
        }
    );

    for my $ImportTest (@ImportTests) {

        my $ImportResult = $StandardTemplateObject->StandardTemplateImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingTemplates => 1,
            UserID                     => 1,
        );

        $Self->IsDeeply(
            $ImportResult,
            $ImportTest->{ExpectedData},
            $ImportTest->{Name},
        );
    }

    # delete created standard template
    for my $ID (@IDs) {
        my $Delete = $StandardTemplateObject->StandardTemplateDelete(
            ID => $ID,
        );
        $Self->True(
            $Delete,
            "StandardTemplateDelete() -  $ID ",
        );
    }
}

# cleanup is done by RestoreDatabase

1;
