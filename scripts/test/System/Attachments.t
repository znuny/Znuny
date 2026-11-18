# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package main;
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Archive::Zip qw( :ERROR_CODES );

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
my $FileTempObject    = $Kernel::OM->Get('Kernel::System::FileTemp');
my $EncodeObject      = $Kernel::OM->Get('Kernel::System::Encode');
my $ArticleObject     = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $AttachmentsObject = $Kernel::OM->Get('Kernel::System::Attachments');

my $UserID = 1;

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Attachment###ShowDuplicateFiles',
    Value => 0,
);

#
# Assemble test attachment data.
#

my @Filenames = (
    '.test1',
    'test2.txt',
    'test3.äöüÄÖÜ€.test.txt',
    'test4',
    'test5.äöüÄÖÜ€.plain.txt',
    'test6.txt',
);

my @AttachmentData;

my $FileCounter = 0;
for my $Filename (@Filenames) {
    $FileCounter++;

    my $FileContent = "Test $FileCounter öäüÖÄÜß€";

    my %AttachmentData = (
        Content     => $FileContent,
        ContentType => 'text/plain',
        Filename    => $Filename,
    );

    push @AttachmentData, \%AttachmentData;
}

#
# Create test ticket with several articles and attachments.
#

my $TicketID = $HelperObject->TicketCreate();

my @ArticleAttachments = (
    [
        $AttachmentData[0],
        $AttachmentData[1],
    ],
    [
        $AttachmentData[2],
        $AttachmentData[3],
    ],
    [
        $AttachmentData[4],
    ],

    # Last article contains mix of already used files, resulting in duplicate filenames.
    [
        $AttachmentData[0],
        $AttachmentData[2],
        $AttachmentData[3],
        $AttachmentData[4],
        $AttachmentData[5],
    ],
);

my $ArticleID;
for my $ArticleAttachments (@ArticleAttachments) {
    $ArticleID = $HelperObject->ArticleCreate(
        TicketID   => $TicketID,
        Attachment => $ArticleAttachments,
    );

    return if !$ArticleID;
}

#
# Tests for ArticleAttachmentCount()
#
my $ArticleAttachmentCount = $AttachmentsObject->ArticleAttachmentCount(
    TicketID => $TicketID,
);

$Self->Is(
    $ArticleAttachmentCount,
    10,
    "ArticleAttachmentCount: $ArticleAttachmentCount",
);

# Tests for IsArticleCountReached()

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Attachment###DeactivateWidgetArticleCount',
    Value => 4,
);
my $IsArticleCountReached = $AttachmentsObject->IsArticleCountReached(
    TicketID => $TicketID,
);

$Self->True(
    $IsArticleCountReached,
    "IsArticleCountReached: $IsArticleCountReached",
);

# Tests for IsArticleAttachmentCountReached()
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Attachment###DeactivateWidgetAttachmentCount',
    Value => 10,
);
my $IsArticleAttachmentCountReached = $AttachmentsObject->IsArticleAttachmentCountReached(
    TicketID => $TicketID,
);

$Self->True(
    $IsArticleAttachmentCountReached,
    "IsArticleAttachmentCountReached: $IsArticleAttachmentCountReached",
);

#
# Tests for ArticleAttachmentListGet()
#

my $TicketAttachments = $AttachmentsObject->ArticleAttachmentListGet(
    TicketID => $TicketID,
);

my %TestAttachment = %{ $TicketAttachments->[0] };

my @ExpectedTicketAttachmentFilenames = (
    'test1',
    'test2.txt',
    'test3.äöüÄÖÜ€.test.txt',
    'test4',
    'test5.äöüÄÖÜ€.plain.txt',
    'test6.txt'
);

my $TicketAttachmentCounter = 0;
for my $TicketAttachment ( @{$TicketAttachments} ) {
    $Self->True(
        scalar( $TicketAttachment->{ArticleID} && $TicketAttachment->{FileID} && $TicketAttachment->{Filesize} ),
        'ArticleAttachmentListGet(): Ticket attachment must have article ID, file ID and filesize set.',
    );

    $Self->Is(
        $TicketAttachment->{Filename},
        $ExpectedTicketAttachmentFilenames[$TicketAttachmentCounter],
        'ArticleAttachmentListGet(): Ticket attachment filename must match expected one.',
    );

    $TicketAttachmentCounter++;
}

#
# Tests for ArticleAttachmentGet()
#

my %Attachment = $AttachmentsObject->ArticleAttachmentGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    FileID    => $TestAttachment{FileID},
    UserID    => 1,
);

my $IsDeeplyResult = $Self->IsDeeply(
    \%Attachment,
    {
        ContentID          => '',
        FilesizeRaw        => '24',
        Content            => 'Test 1 Ã¶Ã¤Ã¼ÃÃÃÃâ¬',
        Disposition        => 'attachment',
        ContentType        => 'text/plain',
        Filename           => 'test1',
        ContentAlternative => ''
    },
    'ArticleAttachmentGet',
);

#
# Tests for CreateTicketAttachmentZipArchive()
#

my $ZipArchiveContentRef = $AttachmentsObject->CreateTicketAttachmentZipArchive(
    TicketID    => $TicketID,
    Attachments => $TicketAttachments,
    UserID      => $UserID,
);

$Self->True(
    $ZipArchiveContentRef,
    'CreateTicketAttachmentZipArchive(): Zip archive must have been created successfully.',
);

my ( $ZipArchiveFH, $ZipArchiveFilename ) = $FileTempObject->TempFile();
close $ZipArchiveFH;

my $FileLocation = $MainObject->FileWrite(
    Location => $ZipArchiveFilename,
    Content  => $ZipArchiveContentRef,
);

my $ZipArchive     = Archive::Zip->new();
my $ZipArchiveRead = $ZipArchive->read($ZipArchiveFilename);

$Self->Is(
    $ZipArchiveRead,
    AZ_OK,
    'CreateTicketAttachmentZipArchive(): Zip archive must have been read successfully.',
);

my @ZipArchiveFilenames = $ZipArchive->memberNames();
@ZipArchiveFilenames = sort { $a cmp $b } @ZipArchiveFilenames;

my @DecodedZipArchiveFilenames;
for my $Filename (@ZipArchiveFilenames) {
    $EncodeObject->EncodeInput( \$Filename );
    push @DecodedZipArchiveFilenames, $Filename;
}

$Self->IsDeeply(
    \@DecodedZipArchiveFilenames,
    \@ExpectedTicketAttachmentFilenames,
    'CreateTicketAttachmentZipArchive(): Zip archive must contain expected files.',
);

#
# ZIP member name sanitization
#

my @ZipMemberNameTests = (
    {
        Name     => 'ASCII relative path',
        Filename => '../foo.txt',
        Expected => 'foo.txt',
    },
    {
        Name     => 'ASCII absolute path',
        Filename => '/etc/passwd',
        Expected => 'passwd',
    },
    {
        Name     => 'backslash relative path',
        Filename => '..\\..\\foo.txt',
        Expected => 'foo.txt',
    },
    {
        Name     => 'fullwidth solidus traversal',
        Filename => "..\x{FF0F}evil.txt",
        Expected => 'evil.txt',
    },
    {
        Name     => 'division slash traversal',
        Filename => "..\x{2215}evil.txt",
        Expected => 'evil.txt',
    },
    {
        Name     => 'fraction slash nested path',
        Filename => "foo\x{2044}bar\x{2044}..\x{2044}evil.txt",
        Expected => 'evil.txt',
    },
    {
        Name     => 'bare parent directory',
        Filename => '..',
        Expected => 'attachment',
    },
    {
        Name     => 'bare current directory',
        Filename => '.',
        Expected => 'attachment',
    },
    {
        Name     => 'Windows drive and ADS colon',
        Filename => 'C:\\Windows\\foo:stream.txt',
        Expected => 'foo stream.txt',
    },
    {
        Name     => 'NUL-separated traversal',
        Filename => "foo\x00../../bar.txt",
        Expected => 'bar.txt',
    },
);

for my $Test (@ZipMemberNameTests) {
    $Self->Is(
        $AttachmentsObject->_SanitizeZipMemberName( $Test->{Filename} ),
        $Test->{Expected},
        "_SanitizeZipMemberName(): $Test->{Name}",
    );
}

# Caller-supplied Filename must be sanitized before it becomes a ZIP member.
my $HostileZipContentRef = $AttachmentsObject->CreateTicketAttachmentZipArchive(
    TicketID    => $TicketID,
    Attachments => [
        {
            ArticleID => $TicketAttachments->[0]->{ArticleID},
            FileID    => $TicketAttachments->[0]->{FileID},
            Filename  => "..\x{FF0F}evil.txt",
        },
    ],
    UserID => $UserID,
);

$Self->True(
    $HostileZipContentRef,
    'CreateTicketAttachmentZipArchive(): zip with hostile caller Filename must still be created.',
);

my ( $HostileZipFH, $HostileZipFilename ) = $FileTempObject->TempFile();
close $HostileZipFH;
$MainObject->FileWrite(
    Location => $HostileZipFilename,
    Content  => $HostileZipContentRef,
);

my $HostileZip = Archive::Zip->new();
$Self->Is(
    $HostileZip->read($HostileZipFilename),
    AZ_OK,
    'CreateTicketAttachmentZipArchive(): hostile-name zip must be readable.',
);

my @HostileMemberNames = $HostileZip->memberNames();
$EncodeObject->EncodeInput( \$_ ) for @HostileMemberNames;

$Self->IsDeeply(
    \@HostileMemberNames,
    ['evil.txt'],
    'CreateTicketAttachmentZipArchive(): Unicode slash traversal must not survive as ZIP member name.',
);

#
# Tests for AddAttachmentsToArticle()
#

# Add attachments of second and third article to last one.
my @ArticleIDs = $ArticleObject->ArticleIndex(
    TicketID => $TicketID,
);

my $SecondArticleID = $ArticleIDs[1];
my $ThirdArticleID  = $ArticleIDs[2];
my $LastArticleID   = $ArticleIDs[-1];

my %ArticleFileIDsToAdd;
for my $ArticleID ( $SecondArticleID, $ThirdArticleID ) {
    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $TicketID,
        ArticleID        => $ArticleID,
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
        ExcludeInline    => 1,
    );

    $ArticleFileIDsToAdd{$ArticleID} = [ keys %AttachmentIndex ];
}

my $AttachmentsAdded = $AttachmentsObject->AddAttachmentsToArticle(
    TicketID            => $TicketID,
    ArticleID           => $LastArticleID,
    ArticleFileIDsToAdd => \%ArticleFileIDsToAdd,
    UserID              => $UserID,
);

$Self->True(
    scalar $AttachmentsAdded,
    'AddAttachmentsToArticle(): Attachments of second and third article must have been added to the last article.',
);

# Check attachments of last article.
my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
    TicketID         => $TicketID,
    ArticleID        => $LastArticleID,
    ExcludePlainText => 1,
    ExcludeHTMLBody  => 1,
    ExcludeInline    => 1,
);

my @ExpectedArticleAttachmentFilenames = (
    'test1',
    'test3.äöüÄÖÜ€.test.txt',
    'test3_2.äöüÄÖÜ€.test.txt',
    'test4',
    'test4_2',
    'test5.äöüÄÖÜ€.plain.txt',
    'test5_2.äöüÄÖÜ€.plain.txt',
    'test6.txt',
);

my @ArticleAttachmentFilenames = sort { $a cmp $b }
    map { $AttachmentIndex{$_}->{Filename} }
    keys %AttachmentIndex;

$Self->IsDeeply(
    \@ArticleAttachmentFilenames,
    \@ExpectedArticleAttachmentFilenames,
    'AddAttachmentsToArticle(): Last article must contain expected files.',
);

#
# Tests for ArticleAndAttachmentListGet()
#

my @TestAttachments = (
    {
        Content     => 'asdf',
        ContentType => 'text/plain',
        Filename    => 'lala.txt',
    },
    {
        Content     => 'bcdrt',
        ContentType => 'text/plain',
        Filename    => 'test2.txt',
    },
    {
        Content     => 'bcdrt',
        ContentType => 'text/plain',
        Filename    => 'test3.txt',
        Disposition => 'inline',
    },
);

$TicketID = $HelperObject->TicketCreate();

$ArticleID = $HelperObject->ArticleCreate(
    TicketID             => $TicketID,
    IsVisibleForCustomer => 1,
    ChannelName          => 'Phone',
    SenderType           => 'customer',
    Attachment           => \@TestAttachments,
);

my @Attachments = $AttachmentsObject->ArticleAndAttachmentListGet(
    TicketID => $TicketID,
    UserID   => 1,
);

for my $Attachment (@Attachments) {

    my ($TestAttachment) = grep { $_->{Filename} eq $Attachment->{Filename} } @TestAttachments;

    $Self->True(
        IsHashRefWithData($TestAttachment) ? 1 : 0,
        "Found test attachment in ArticleAndAttachmentListGet with filename '$Attachment->{Filename}'",
    );

    if ( $TestAttachment->{Disposition} && $TestAttachment->{Disposition} eq 'inline' ) {
        $Self->True(
            $Attachment->{InlineElement},
            "Test attachment in ArticleAndAttachmentListGet with filename '$Attachment->{Filename}' is correctly marked as inline element",
        );
    }

    $Self->Is(
        $Attachment->{FileArticleTypeCSS},
        'fa-long-arrow-left',
        "Test attachment in ArticleAndAttachmentListGet with filename '$Attachment->{Filename}' has correct article type css",
    );

    $Self->Is(
        $Attachment->{FileTypeCSS},
        'fa-file-o',
        "Test attachment in ArticleAndAttachmentListGet with filename '$Attachment->{Filename}' has correct file type css",
    );
}

#
# Tests for AttachmentIconClassGet()
#

my $IconClass = $AttachmentsObject->AttachmentIconClassGet(
    ContentType => 'application/pdf',
);

$Self->Is(
    $IconClass,
    'fa-file-pdf-o',
    "AttachmentIconClassGet()",
);

#
# Tests for AttachmentDirectionIconClassGet()
#

my $DirectionIconClass = $AttachmentsObject->AttachmentDirectionIconClassGet(
    IsVisibleForCustomer => 1,
    SenderType           => 'customer',
);

$Self->Is(
    $DirectionIconClass,
    'fa-long-arrow-left',
    "AttachmentDirectionIconClassGet()",
);

1;
