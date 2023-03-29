# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::PerlCritic)

use strict;
use warnings;
use utf8;

use Data::Dumper;
use vars (qw($Self));

use List::Util qw{shuffle};
use Storable;

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $MainObject                = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
my $ArticleObject             = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $ModuleName     = 'TicketCreate';
my $RandomID       = $HelperObject->GetRandomID();
my $MinimumSamples = 2;
my $UserID         = 1;

my %FileTypeMap = (
    bin => 'application/octet-stream',
    txt => 'text/plain',
    pdf => 'application/pdf',
);

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => '0',
);

my $TicketID = $HelperObject->TicketCreate(
    UserID => $UserID,
);

my $AttachmentsDynamicFieldName = $ConfigObject->Get('Process::DynamicFieldProcessManagementAttachment')
    // 'ProcessManagementAttachment';

my @DynamicFields = (
    {
        Name       => $AttachmentsDynamicFieldName,
        Label      => $AttachmentsDynamicFieldName,
        ObjectType => 'Ticket',
        FieldType  => 'TextArea',
        Config     => {
            DefaultValue => '',
        },
    },
);
$ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(@DynamicFields);

# Create a bunch of articles and attachments
for my $ChannelName (qw(Email Phone Internal)) {
    my $ArticleID = $ArticleObject->ArticleCreate(
        ChannelName          => $ChannelName,
        TicketID             => $TicketID,
        SenderType           => 'agent',
        IsVisibleForCustomer => 1,
        From                 => 'Some Agent <email@example.com>',
        To                   => 'Some Customer A <customer-a@example.com>',
        Cc                   => 'Some Customer B <customer-b@example.com>',
        Bcc                  => 'Some Customer C <customer-c@example.com>',
        Subject              => 'Origin article Subject',
        Body                 => 'Lorem ipsum',
        MessageID            => '<' . $RandomID . '@example.com>',
        Charset              => 'ISO-8859-15',
        MimeType             => 'text/plain',
        HistoryType          => 'AddNote',
        HistoryComment       => 'Some free text!',
        UserID               => 1,
        UnlockOnAway         => 1,
        FromRealname         => 'Some Agent',
        ToRealname           => 'Some Customer A',
        CcRealname           => 'Some Customer B',
    );
    $Self->True(
        $ArticleID,
        "ArticleCreate - Added article $ArticleID",
    );

    my @File = (
        qw(
            Ticket-Article-Test1.txt
            Ticket-Article-Test1.pdf
            Ticket-Article-Test-utf8-1.txt
            Ticket-Article-Test-utf8-1.bin
            Ticket-Article-Test-empty.txt
            )
    );

    for my $File (@File) {
        my $Location   = $ConfigObject->Get('Home') . "/scripts/test/sample/Ticket/$File";
        my $ContentRef = $MainObject->FileRead(
            Location => $Location,
            Mode     => 'binmode',
        );

        my @FileNames = ( '_Attachment1_', '_Attachment2_', '_Attachment3_' );
        for my $FileName (@FileNames) {
            my $Content         = ${$ContentRef};
            my $FileDisposition = $ChannelName . $FileName . $File;
            my $ContentType     = $File;

            $ContentType =~ m{.*\.(.*)\z};
            $ContentType = $FileTypeMap{$1};

            my $ArticleWroteAttachment = $ArticleObject->ArticleWriteAttachment(
                TicketID    => $TicketID,
                Content     => $Content,
                Filename    => $FileDisposition,
                ContentType => $ContentType,
                ArticleID   => $ArticleID,
                UserID      => 1,
            );
            $Self->True(
                scalar $ArticleWroteAttachment,
                "ArticleWriteAttachment() - $FileDisposition",
            );
        }
    }
}

my @OriginalArticles = $ArticleObject->ArticleList(
    TicketID => $TicketID,
);

# Enriching each article in the OriginalArticle array with the attachment (meta information)
# and storing some selected attachment IDs in the TestDataArrayMatrix,
# which will also be included in each article, to be used in the later verification process.
for my $Article (@OriginalArticles) {
    my %FullArticle = $ArticleObject->ArticleGet(
        TicketID      => $TicketID,
        ArticleID     => $Article->{ArticleID},
        DynamicFields => 1,
    );

    my %Article = ( %{$Article}, %FullArticle );

    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $TicketID,
        ArticleID        => $Article->{ArticleID},
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
        ExcludeInline    => 0,
    );
    for my $AttachmentID ( sort keys %AttachmentIndex ) {
        my %Attachment = $ArticleObject->ArticleAttachment(
            TicketID  => $TicketID,
            ArticleID => $Article->{ArticleID},
            FileID    => $AttachmentID,
        );

        # Don't store/keep the raw content, instead this test stores just the MD5 sum in the
        # TestDataRecord - for later comparison, as described.
        $Attachment{Content} = $MainObject->MD5sum(
            String => $Attachment{Content},
        );
        $AttachmentIndex{$AttachmentID} = \%Attachment;
    }

    my $AttachmentCount = keys %AttachmentIndex;

    my $SampleCount = int( rand($AttachmentCount) );    ## no-critic
    $SampleCount = $MinimumSamples if $SampleCount < $MinimumSamples;

    my @RandomAttachmentIndex = shuffle keys %AttachmentIndex;
    @RandomAttachmentIndex = @RandomAttachmentIndex[ 0 .. $SampleCount - 1 ];

    # store/assign it to the Article Test Data
    $Article{RandomAttachmentIndex} = \@RandomAttachmentIndex;

    # store/assign it to the Article Test Data for later use
    $Article{AttachmentIndex} = \%AttachmentIndex;

    $Article = \%Article;
}

# create a stringified structure to use data as key in html selection
# we need this information to get the correct attachment from backend
#
# stringified structure
# $ValueString = 'ObjectType=Article;ObjectID=1;ID=5'
# $ValueString = 'ObjectType=Article;ObjectID=1;ID=5,ObjectType=Article;ObjectID=3;ID=2'
#
# parsed stringified structure
# Data = {
#     ObjectType => 'Article',
#     ObjectID   => '1',
#     ID         => '4',
# }
my $ValueString;
for my $Article (@OriginalArticles) {
    my @ArticleAttachmentArray
        = map {"ObjectType=Article;ObjectID=$Article->{ArticleID};ID=$_"} @{ $Article->{RandomAttachmentIndex} };
    $ValueString = join( ',', @ArticleAttachmentArray );
}

# prepare the attachments{Filename} hash for easy verification at a later stage, see below
# Example:
# 'Internal_Attachment3_Ticket-Article-Test-utf8-1.txt' => {
#     ContentType => 'text/plain',
#     Content     => 'md5sum....',
# },
my %ArticleAttachmentsToTest;
for my $Article (@OriginalArticles) {
    for my $AttachmentID ( @{ $Article->{RandomAttachmentIndex} } ) {
        my $Attachment = $Article->{AttachmentIndex}{$AttachmentID};

        $ArticleAttachmentsToTest{ $Attachment->{Filename} }->{ContentType} = $Attachment->{ContentType};
        $ArticleAttachmentsToTest{ $Attachment->{Filename} }->{Content}     = $Attachment->{Content};
        $ArticleAttachmentsToTest{ $Attachment->{Filename} }->{FilesizeRaw} = $Attachment->{FilesizeRaw};
        $ArticleAttachmentsToTest{ $Attachment->{Filename} }->{ArticleID}   = $Article->{ArticleID};
    }
}

my $NewCreatedSubTicketConfigData = {
    Title                => 'New Subticket',
    Subject              => 'New Subticket',
    StateID              => 1,
    Priority             => '3 normal',
    Lock                 => 'unlock',
    QueueID              => 1,
    IsVisibleForCustomer => 0,
    HistoryType          => 'AddNote',
    HistoryComment       => 'Subticket created',
    From                 => 'znuny',
    LinkAs               => 'Child',
    SenderType           => 'agent',
    CommunicationChannel => 'Internal',
    ContentType          => 'text/html; charset=UTF-8',
    OwnerID              => $UserID,
};

my $AttachmentsDynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $AttachmentsDynamicFieldName,
);
my $ValidConfig = IsHashRefWithData($AttachmentsDynamicFieldConfig);

$Self->True(
    IsHashRefWithData($AttachmentsDynamicFieldConfig),
    "Got dynamic field config for $AttachmentsDynamicFieldName.",
);

# Test config collection
my @Tests = (
    {
        Name   => 'Empty AttachmentsReuse',
        Config => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                AttachmentsReuse => '',
            },
        },
        ExpectedSuccess           => 1,
        ExpectedSuccessAttachment => 0,
    },
    {
        Name   => 'Empty AttachmentsReuse with 0',
        Config => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                AttachmentsReuse => '0',
            },
        },
        ExpectedSuccess           => 1,
        ExpectedSuccessAttachment => 0,
    },
    {
        Name   => 'AttachmentsReuse with 1',
        Config => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                AttachmentsReuse => '1',
            },
        },
        ExpectedSuccess           => 1,
        ExpectedSuccessAttachment => 1,
    },
    {
        Name   => 'AttachmentsReuse with y',
        Config => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                AttachmentsReuse => 'y',
            },
        },
        ExpectedSuccess           => 1,
        ExpectedSuccessAttachment => 1,
    },
    {
        Name   => 'AttachmentsReuse with yes',
        Config => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                AttachmentsReuse => 'yes',
            },
        },
        ExpectedSuccess           => 1,
        ExpectedSuccessAttachment => 1,
    },
);

for my $Test (@Tests) {

    # make a deep copy to avoid changing the definition
    my $OrigTest    = Storable::dclone($Test);
    my $ValueWasSet = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $AttachmentsDynamicFieldConfig,
        ObjectID           => $TicketID,
        Value              => $ValueString,
        UserID             => 1,
    );

    # Check if value was set
    $Self->True(
        scalar $ValueWasSet,
        "Dynamic field ValueSet() - $TicketID $AttachmentsDynamicFieldConfig->{Name}"
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        UserID        => $UserID,
        DynamicFields => 1,
    );

    # Pre-set a ticket number to work with
    my $TicketNumber = $TicketObject->TicketCreateNumber();

    $Test->{Config}->{Ticket} = \%Ticket;
    $Test->{Config}->{Config}->{TN} = $TicketNumber;

    my $TransitionActionObject = $Kernel::OM->Get(
        'Kernel::System::ProcessManagement::TransitionAction::TicketCreate'
    );
    my $Success = $TransitionActionObject->Run(
        %{ $Test->{Config} },
        ProcessEntityID          => 'PEID1',
        ActivityEntityID         => 'AEID1',
        TransitionEntityID       => 'TEID1',
        TransitionActionEntityID => 'TAEID1',
    );

    if ( !$Test->{ExpectedSuccess} ) {
        $Self->False(
            scalar $Success,
            "$ModuleName Run(): '$Test->{Name}' must fail.",
        );
    }
    else {
        $Self->True(
            scalar $Success,
            "$ModuleName Run(): '$Test->{Name}' must succeed.",
        );
    }

    my $ChildTicketID = $TicketObject->TicketIDLookup(
        TicketNumber => $TicketNumber,
    );

    my %ChildTicket = $TicketObject->TicketGet(
        TicketID => $ChildTicketID,
    );

    $Self->True(
        IsHashRefWithData( \%ChildTicket ),
        "$ModuleName Run(): '$Test->{Name}' Child ticket must exist."
    );

    my @ChildArticles = $ArticleObject->ArticleList(
        TicketID  => $ChildTicketID,
        OnlyFirst => 1,
    );

    my $FirstChildArticleID = $ChildArticles[0]->{ArticleID};

    my %Article = $ArticleObject->ArticleGet(
        TicketID  => $ChildTicketID,
        ArticleID => $FirstChildArticleID,
    );

    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $ChildTicketID,
        ArticleID        => $FirstChildArticleID,
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
        ExcludeInline    => 0,
    );

    if ( $Test->{ExpectedSuccessAttachment} ) {
        $Self->True(
            scalar %AttachmentIndex,
            "$ModuleName Run(): '$Test->{Name}' Child ticket article must have attachments.",
        );
    }
    else {
        $Self->False(
            scalar %AttachmentIndex,
            "$ModuleName Run(): '$Test->{Name}' Child ticket article must not have attachments.",
        );
    }

    for my $AttachmentID ( sort keys %AttachmentIndex ) {
        my %Attachment = $ArticleObject->ArticleAttachment(
            TicketID  => $ChildTicketID,
            ArticleID => $FirstChildArticleID,
            FileID    => $AttachmentID,
        );

        # raw content should NOT match the MD5 sum from the origin Attachment,
        # which is stored in the AttachmentsToTest hash
        $Self->IsNot(
            $Attachment{Content},
            $ArticleAttachmentsToTest{ $Attachment{Filename} }->{Content},
            "$ModuleName Run(): '$Test->{Name} $Attachment{Filename} content MD5 sum must not match.",
        );
        $Self->Is(
            $MainObject->MD5sum(
                String => $Attachment{Content},
            ),
            $ArticleAttachmentsToTest{ $Attachment{Filename} }->{Content},
            "$ModuleName Run(): '$Test->{Name} $Attachment{Filename} content MD5 sum must match.",
        );
        $Self->Is(
            $Attachment{FilesizeRaw},
            $ArticleAttachmentsToTest{ $Attachment{Filename} }->{FilesizeRaw},
            "$ModuleName Run(): '$Test->{Name} $Attachment{Filename} content size must match.",
        );
        $Self->Is(
            $Attachment{ContentType},
            $ArticleAttachmentsToTest{ $Attachment{Filename} }->{ContentType},
            "$ModuleName Run(): '$Test->{Name} $Attachment{Filename} content type must match.",
        );
    }
}

1;
