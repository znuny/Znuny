# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;
use Data::Dumper;
use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Get the necessary bunch of Access-Objects
my $LinkObject         = $Kernel::OM->Get('Kernel::System::LinkObject');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $ArticleObject      = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');


# define variables
my $TestModule = 'Kernel::System::ProcessManagement::TransitionAction::TicketCreate';
my $ModuleName = 'TicketCreate';
my $RandomID = $Helper->GetRandomID();
my $MinimumSamples = 2;
my $UserID = 1;
my %SimpleFileTypeMap = (
    bin => 'application/octet-stream',
    txt => 'text/plain',
    pdf => 'application/pdf',
);
$Self->{FileTypeMap} = \%SimpleFileTypeMap;

$Self->Is(
    $Self->GetContentType(File => 'test.bin',),
    'application/octet-stream',
    'Initial function Test',
);


# Create customer for ticket creation
$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'CheckEmailAddresses',
    Value => '0',
);

my $CustomerUserFirstName = 'FirstName' . $RandomID;
my $CustomerUserID = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => $CustomerUserFirstName,
    UserLastname   => 'Doe',
    UserCustomerID => "Customer#$RandomID",
    UserLogin      => "CustomerLogin#$RandomID",
    UserEmail      => "customer$RandomID\@example.com",
    UserPassword   => 'some_pass',
    ValidID        => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserID,
    "CustomerUser $CustomerUserID created."
);

my $Epoch = $Kernel::OM->Create('Kernel::System::DateTime',)->ToEpoch();

#
# Create a test ticket
#
my $TicketID = $TicketObject->TicketCreate(
    Title         => 'test' . "_$Epoch",
    QueueID       => 1,
    Lock          => 'unlock',
    Priority      => '3 normal',
    StateID       => 1,
    TypeID        => 1,
    OwnerID       => 1,
    ResponsibleID => 1,
    CustomerUser  => $CustomerUserID,
    UserID        => $UserID,
);

# Check TicketID
$Self->True(
    $TicketID,
    "TicketCreate() - $TicketID",
);
die('Can not continue without Ticket.') if !$TicketID;


# Create the dynamic fields for testing
my $DFAttachmentsName = $ConfigObject->Get('Process::DynamicFieldProcessManagementAttachment');

$Self->True(
    $DFAttachmentsName,
    $ModuleName . " DynamicFieldProcessManagementAttachment configured properly",
);

# Has to be set properly to continue
die("Wrong SysConfigEntry: Process::DynamicFieldProcessManagementAttachment not configured properly " . Dumper($DFAttachmentsName)) if !IsStringWithData($DFAttachmentsName);

my $MessageID = '<' . $Helper->GetRandomID() . '@example.com>';
my %OriginArticleHash = (
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 1,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer A <customer-a@example.com>',
    Cc                   => 'Some Customer B <customer-b@example.com>',
    Bcc                  => 'Some Customer C <customer-c@example.com>',
    Subject              => 'Origin article Subject',
    Body                 => 'Lorem ipsum',
    MessageID            => $MessageID,
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

# Creates a bunch of origin articles and attachments
for my $ChannelName (qw(Email Phone Internal)) {
    my $ArticleBackendObject = $Kernel::OM->Get("Kernel::System::Ticket::Article::Backend::$ChannelName");
    $Self->True(
        $ArticleBackendObject,
        "Got '$ChannelName' article backend object"
    );

    # Creates a test article.
    my $ArticleID = $ArticleBackendObject->ArticleCreate(
        %OriginArticleHash,
    );
    $Self->True(
        $ArticleID,
        "ArticleCreate - Added article $ArticleID"
    );

    for my $File (
        qw(
            Ticket-Article-Test1.txt
            Ticket-Article-Test1.pdf
            Ticket-Article-Test-utf8-1.txt
            Ticket-Article-Test-utf8-1.bin
            Ticket-Article-Test-empty.txt
        )
    ) {
        my $Location = $ConfigObject->Get('Home') . "/scripts/test/sample/Ticket/$File";
        my $ContentRef = $MainObject->FileRead(
            Location => $Location,
            Mode     => 'binmode',
        );

        for my $FileName (
            '_Attachment1_',
            '_Attachment2_',
            '_Attachment3_',
        ) {
            my $Content = ${$ContentRef};
            my $FileDisposition = $ChannelName . $FileName . $File;

            ## TODO: because of the lack of the cpan  https://metacpan.org/pod/MIME::Types ...
            ## we just map simply the content type based on the file extension for these few filetypes
            ## (the otrs' default mimetype recognition is delegated to and comes from the browsers upload response)
            my $ContentType = $Self->GetContentType(Location => $Location, File => $File,);

            my $ArticleWroteAttachment = $ArticleBackendObject->ArticleWriteAttachment(
                Content     => $Content,
                Filename    => $FileDisposition,
                ContentType => $ContentType,
                ArticleID   => $ArticleID,
                UserID      => 1,
            );
            $Self->True(
                $ArticleWroteAttachment,
                "ArticleWriteAttachment() - $FileDisposition",
            );
        }
    }
}

# Now retrieve the Ticket with the dynamic Fields
my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    UserID        => $UserID,
    DynamicFields => 1,
);

$Self->True(
    IsHashRefWithData(\%Ticket),
    "TicketGet() - Get Ticket with ID $TicketID.",
);

my @OriginArticles = $ArticleObject->ArticleList(
    TicketID => $TicketID,
);

# Enriching each article in the OriginArticle array with the attachment (meta-information)
# and storing some selected attachment IDs in the TestDataArrayMatrix,
# which will also be included in each article, to be used in the later verification process
for my $ArticleRef (@OriginArticles) {
    my $ArticleBackendObject = $ArticleObject->BackendForArticle(
        TicketID  => $TicketID,
        ArticleID => $ArticleRef->{ArticleID},
    );

    my %FullArticle = $ArticleBackendObject->ArticleGet(
        TicketID      => $TicketID,
        ArticleID     => $ArticleRef->{ArticleID},
        DynamicFields => 1,
    );
    # Join Article Data
    my %Article = (%{$ArticleRef}, %FullArticle);

    my %AttachmentIndex = $ArticleBackendObject->ArticleAttachmentIndex(
        ArticleID        => $ArticleRef->{ArticleID},
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
        ExcludeInline    => 0,
    );
    for my $AttachmentID (keys %AttachmentIndex) {
        my %Attachment = $ArticleBackendObject->ArticleAttachment(
            ArticleID => $ArticleRef->{ArticleID},
            FileID    => $AttachmentID,
        );

        # Don't store/keep the raw content, instead this test stores just the MD5SUM in the
        # TestDataRecord - for later comparison, as described
        $Attachment{Content} = $MainObject->MD5sum(String => $Attachment{Content},);
        $AttachmentIndex{$AttachmentID} = \%Attachment;
    }


    my $AttachmentCount = scalar(keys %AttachmentIndex);
    my @RandomAttachmentIndexes; # Stores the random Attachment IDs of each Article

    my $SampleCount;
    # find a random sample count between the fix $MinimumSamples amount and the $AttachmentCount as maximum
    do {
        $SampleCount = int( rand( $AttachmentCount ) ); ## no critic
    } while ($SampleCount lt $MinimumSamples);

    # find random index numbers and create an array with size of sample count, filled with these random index numbers
    do {
        my $RandomAttachmentIndex = int( rand( $AttachmentCount ) ); ## no critic
        my $AlreadyContains = grep( /^$RandomAttachmentIndex$/, @RandomAttachmentIndexes ); ## no critic
        push @RandomAttachmentIndexes, $RandomAttachmentIndex if !$AlreadyContains && $RandomAttachmentIndex; # !=0
    } while ($SampleCount gt (scalar @RandomAttachmentIndexes));

    $Article{RandomAttachmentIndexes} = \@RandomAttachmentIndexes; # store/assign it to the Article Test Data
    $Article{AttachmentIndex} = \%AttachmentIndex; # store/assign it to the Article Test Data for later use

    $ArticleRef = \%Article; # push back the enriched Article in the Array
}

my @ArticleAttachmentIDsArray;

# build the specific "Dynamic Field  CSV", Key::Value Pair String,
# with the item from the Random Index Array of each Article
# which is a central used item in the
# TicketCreate TransitionAction
# these Operations can also be handled by tests
for my $Article (@OriginArticles) {
    my @ArticleAttachmentArray = map {"$_\:\:$Article->{ArticleID}"} @{$Article->{RandomAttachmentIndexes}};
    my $ArticleAttachmentMapString = join(',', @ArticleAttachmentArray);
    push @ArticleAttachmentIDsArray, $ArticleAttachmentMapString;
}

# Store the 'Sample' data in the Ticket Test Data just for later easy use/access
# Example: $Ticket{Samples} = '2::197,5::197';
$Ticket{Samples} = join(',', @ArticleAttachmentIDsArray);

$Self->True(
    $Ticket{Samples},
    "Ticket - $TicketID has {Samples} ",
);

my $ValueString = $Ticket{Samples};

# prepare the  Attachments{Filename}-Hash for easy verification at a later stage, see below
# Example: { 'Internal_Attachment3_Ticket-Article-Test-utf8-1.txt' => {
#                                   ContentType => 'text/plain',
#                                   Content => 'md5sum....',
#                                   },
my %ArticleAttachmentsToTest;
for my $Article (@OriginArticles) {
    for my $AttachmentID (@{$Article->{RandomAttachmentIndexes}}) {
        my $AttachmentRef = $Article->{AttachmentIndex}{$AttachmentID};
        $ArticleAttachmentsToTest{$AttachmentRef->{Filename}}->{ContentType} = $AttachmentRef->{ContentType};
        $ArticleAttachmentsToTest{$AttachmentRef->{Filename}}->{Content} = $AttachmentRef->{Content};
        $ArticleAttachmentsToTest{$AttachmentRef->{Filename}}->{FilesizeRaw} = $AttachmentRef->{FilesizeRaw};
        $ArticleAttachmentsToTest{$AttachmentRef->{Filename}}->{ArticleID} = $Article->{ArticleID};
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
    From                 => 'otrs',
    LinkAs               => 'Child',
    SenderType           => 'agent',
    CommunicationChannel => 'Internal',
    ContentType          => 'text/html; charset=UTF-8',
    OwnerID              => $UserID,
};

my $AttachmentsDFConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $DFAttachmentsName,
);
my $ValidConfig = IsHashRefWithData( $AttachmentsDFConfig );

$Self->True(
    $ValidConfig,
    "Got DynamicField -  " . ($ValidConfig ? ' with ' . $AttachmentsDFConfig->{Name} : "''"),
);
# Can't continue without DF
die ("Couldn't get no Dynamic Field named: '$DFAttachmentsName'") if ! IsHashRefWithData( $AttachmentsDFConfig );

# Test config collection
my @Tests = (
    {
        Name            => 'EmptyAttachments',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => '',           
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 0,
    },
    {
        Name            => 'EmptyAttachmentsWith0',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => '0',           
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 0,
    },
    {
        Name            => 'WrongValueAttachments',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => 'VALUE',           
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 0,
    },
    {
        Name            => 'AttachmentsWith1',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => '1',
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 1,
    },
    {
        Name            => 'AttachmentsWithy',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => 'y',
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 1,
    },
    {
        Name            => 'AttachmentsWithyes',
        Config          => {
            UserID => $UserID,
            Config => {
                %{$NewCreatedSubTicketConfigData},
                Attachments => 'yes',
            },
        },
        ExpectedSuccess => 1,
        ExpectedSuccessAttachment => 1,
    },
);

for my $Test (@Tests) {

    # make a deep copy to avoid changing the definition
    my $OrigTest = Storable::dclone($Test);
    my $ValueWasSet = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $AttachmentsDFConfig,
        ObjectID           => $TicketID,
        Value              => $ValueString,
        UserID             => 1,
    );
    
    # Check if value was set
    $Self->True(
        $ValueWasSet,
        "DynamicField ValueSet() - $TicketID $AttachmentsDFConfig->{Name} "
    );

    %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        UserID        => $UserID,
        DynamicFields => 1,
    );
    # Preset a ticketnumber to work with
    my $TicketNumber = $TicketObject->TicketCreateNumber();
    $Test->{Config}->{Ticket} = \%Ticket;
    $Test->{Config}->{Config}->{TN} = $TicketNumber;
    my $Success = $Kernel::OM->Get($TestModule)->Run(
        %{$Test->{Config}},
        ProcessEntityID          => 'PEID1',
        ActivityEntityID         => 'AEID1',
        TransitionEntityID       => 'TEID1',
        TransitionActionEntityID => 'TAEID1',
    );

    if (!$Test->{ExpectedSuccess}) {
        $Self->False(
            $Success,
            "$ModuleName Run() - Test:'$Test->{Name}' expected '$Test->{ExpectedSuccess}' | returned  " . Dumper($Success)
        );
    }
    else {
        $Self->True(
            $Success,
            "$ModuleName Run() - Test:'$Test->{Name}' | expected '$Test->{ExpectedSuccess}' (executed with True) returned with '$Success'"
        );
    }

    my $ChildTicketID = $TicketObject->TicketIDLookup(
        TicketNumber => $TicketNumber,
    );

    # Retrieve the ChildTicket
    my %ChildTicket = $TicketObject->TicketGet(
        TicketID => $ChildTicketID,
    );

    # test ChildTicket-Structure
    $Self->True(
        IsHashRefWithData(\%ChildTicket),
        "$ModuleName Run() - Test: '$Test->{Name}' | got expected 'ChildTicket' Hash:"
    );

    # retrieve the Articles of the ChildTicket
    my @ChildArticles = $ArticleObject->ArticleList(
        TicketID  => $ChildTicketID,
        OnlyFirst => 1,
    );

    # there should be only one first Article so take index[0]
    my $FirstChildArticleID = $ChildArticles[0]->{ArticleID};
    # take the Backend of the Article
    my $ArticleBackendObject = $ArticleObject->BackendForArticle(
        TicketID  => $ChildTicketID,
        ArticleID => $FirstChildArticleID,
    );

    my %Article = $ArticleBackendObject->ArticleGet(
        TicketID      => $ChildTicketID,
        ArticleID     => $FirstChildArticleID,
    );

    # pull the Attachments of the Article
    my %AttachmentIndex = $ArticleBackendObject->ArticleAttachmentIndex(
        ArticleID        => $FirstChildArticleID,
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1, 
        ExcludeInline    => 0,
    );
    my $AttachmentIsHashWithData = IsHashRefWithData(\%AttachmentIndex);
    
    if ( $Test->{ExpectedSuccessAttachment} ) {
        $Self->True(
            $AttachmentIsHashWithData,
            "$ModuleName Run() - Test: '$Test->{Name}' | got expected ChildTicket Article Attachments",
        );
    }
    else {
        $Self->False(
            $AttachmentIsHashWithData,
            "$ModuleName Run() - Test: '$Test->{Name}' | got no ChildTicket Article Attachments",
        );
    }

    for my $AttachmentID (keys %AttachmentIndex) {
        my %Attachment = $ArticleBackendObject->ArticleAttachment(
            ArticleID => $FirstChildArticleID,
            FileID    => $AttachmentID,
        );
        
        # raw content should NOT match the MD5 sum from the origin Attachment,
        # which is stored in the AttachmentsToTest Hash
        $Self->IsNot(
            $Attachment{Content},
            $ArticleAttachmentsToTest{$Attachment{Filename}}->{Content},
            "$ModuleName Run() - Test:'$Test->{Name} $Attachment{Filename} Content MD5 false positive Verification ",
        );
        $Self->Is(
            $MainObject->MD5sum(String => $Attachment{Content},),
            $ArticleAttachmentsToTest{$Attachment{Filename}}->{Content},
            "$ModuleName Run() - Test:'$Test->{Name} $Attachment{Filename} Content MD5 Verification ",
        );
        $Self->Is(
            $Attachment{FilesizeRaw},
            $ArticleAttachmentsToTest{$Attachment{Filename}}->{FilesizeRaw},
            "$ModuleName Run() - Test:'$Test->{Name} $Attachment{Filename} Content Size Verification ",
        );
        $Self->Is(
            $Attachment{ContentType},
            $ArticleAttachmentsToTest{$Attachment{Filename}}->{ContentType},
            "$ModuleName Run() - Test:'$Test->{Name} $Attachment{Filename} ContentType Verification ",
        );

    }
}

=head2 GetContentType($Self, %Param)

  Gets the MimeType / ContentType for a limited amount of Filetypes
  only based on the file extension!

  my $ContentType = $Self->GetContentType( Location => $Location, File => $File, );
=cut
sub GetContentType {
    my ( $Self, %Param ) = @_;
    my $File = $Param{File};
    $File =~ m/\.(.*)$/;
    return $Self->{FileTypeMap}{$1};
}

1;