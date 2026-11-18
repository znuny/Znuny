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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
$HelperObject->FixedTimeSet();

$HelperObject->ConfigSettingChange(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

$HelperObject->ConfigSettingChange(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::Test',
);

my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject   = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $InternalBackend = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal');
my $EmailBackend    = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Email');
my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
my $MailQueueObject = $Kernel::OM->Get('Kernel::System::MailQueue');

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Attachment reuse',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $TicketID,
    'TicketCreate()',
);

my $SourceContent  = 'reused-attachment-content';
my $SourceFilename = 'reuse-source.txt';

my $SourceArticleID = $InternalBackend->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    Subject              => 'source article',
    Body                 => 'source body',
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => '%%',
    UserID               => 1,
    Attachment           => [
        {
            Content     => $SourceContent,
            ContentType => 'text/plain',
            Filename    => $SourceFilename,
        },
    ],
);
$Self->True(
    $SourceArticleID,
    'ArticleCreate() source article',
);

my %SourceIndex = $ArticleObject->ArticleAttachmentIndex(
    TicketID         => $TicketID,
    ArticleID        => $SourceArticleID,
    ExcludePlainText => 1,
    ExcludeHTMLBody  => 1,
    ExcludeInline    => 1,
);
my ($SourceFileID) = keys %SourceIndex;
$Self->True(
    $SourceFileID,
    'Source article has an attachment FileID',
);

my $TargetArticleID = $InternalBackend->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    Subject              => 'target article',
    Body                 => 'target body',
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => '%%',
    UserID               => 1,
    Attachment           => [
        {
            Content     => 'new-upload',
            ContentType => 'text/plain',
            Filename    => 'new-upload.txt',
        },
        {
            ArticleID => $SourceArticleID,
            FileID    => $SourceFileID,
        },
    ],
);
$Self->True(
    $TargetArticleID,
    'ArticleCreate() with reused Attachment reference',
);

my %TargetIndex = $ArticleObject->ArticleAttachmentIndex(
    TicketID         => $TicketID,
    ArticleID        => $TargetArticleID,
    ExcludePlainText => 1,
    ExcludeHTMLBody  => 1,
    ExcludeInline    => 1,
);

my %TargetFilenames = map { $TargetIndex{$_}->{Filename} => $_ } keys %TargetIndex;
$Self->True(
    $TargetFilenames{'new-upload.txt'},
    'Target article contains uploaded file',
);
$Self->True(
    $TargetFilenames{$SourceFilename},
    'Target article contains reused file',
);

my %ReusedAttachment = $ArticleObject->ArticleAttachment(
    TicketID  => $TicketID,
    ArticleID => $TargetArticleID,
    FileID    => $TargetFilenames{$SourceFilename},
    UserID    => 1,
);
$Self->Is(
    $ReusedAttachment{Content},
    $SourceContent,
    'Reused attachment content matches source',
);

my $OtherTicketID = $TicketObject->TicketCreate(
    Title        => 'Other ticket',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

my $CrossTicketArticleID = $InternalBackend->ArticleCreate(
    TicketID             => $OtherTicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    Subject              => 'cross ticket reuse',
    Body                 => 'must not copy foreign attachment',
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => '%%',
    UserID               => 1,
    Attachment           => [

        # An own upload alongside the foreign reference, so that the assertions below can
        # tell a rejected reference apart from attachment handling not running at all.
        {
            Content     => 'local-upload',
            ContentType => 'text/plain',
            Filename    => 'local-upload.txt',
        },
        {
            ArticleID => $SourceArticleID,
            FileID    => $SourceFileID,
        },
    ],
);
$Self->True(
    $CrossTicketArticleID,
    'ArticleCreate() with foreign-ticket Attachment reference still creates the article',
);

my %CrossIndex = $ArticleObject->ArticleAttachmentIndex(
    TicketID         => $OtherTicketID,
    ArticleID        => $CrossTicketArticleID,
    ExcludePlainText => 1,
    ExcludeHTMLBody  => 1,
    ExcludeInline    => 1,
);
my %CrossFilenames = map { $CrossIndex{$_}->{Filename} => 1 } keys %CrossIndex;
$Self->True(
    $CrossFilenames{'local-upload.txt'},
    "Foreign-ticket reference does not prevent the article's own uploads from being stored",
);
$Self->False(
    $CrossFilenames{$SourceFilename},
    'Cross-ticket attachment reuse is rejected',
);

$TestEmailObject->CleanUp();

my $SentArticleID = $EmailBackend->ArticleSend(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 1,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'customer@example.com',
    Subject              => 'reuse via ArticleSend',
    Body                 => 'please see attachment',
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'EmailAgent',
    HistoryComment       => '%%',
    UserID               => 1,
    Attachment           => [
        {
            ArticleID => $SourceArticleID,
            FileID    => $SourceFileID,
        },
    ],
);
$Self->True(
    $SentArticleID,
    'ArticleSend() with reused Attachment reference',
);

my %SentIndex = $ArticleObject->ArticleAttachmentIndex(
    TicketID         => $TicketID,
    ArticleID        => $SentArticleID,
    ExcludePlainText => 1,
    ExcludeHTMLBody  => 1,
    ExcludeInline    => 1,
);
my %SentFilenames = map { $SentIndex{$_}->{Filename} => 1 } keys %SentIndex;
$Self->True(
    $SentFilenames{$SourceFilename},
    'Sent article contains reused file',
);

my $QueueItem = $MailQueueObject->Get( ArticleID => $SentArticleID );
$Self->True(
    $QueueItem,
    'Mail queue item exists for sent article',
);
$MailQueueObject->Send( %{$QueueItem} );

my $Emails = $TestEmailObject->EmailsGet();
$Self->Is(
    scalar @{$Emails},
    1,
    'ArticleSend() queued and sent one email',
);

my $SentBody = $Emails->[0] ? ${ $Emails->[0]->{Body} // '' } : '';
$Self->True(
    scalar $SentBody =~ m{\Q$SourceFilename\E},
    'Sent email contains the reused attachment',
);

# Cleanup is done by RestoreDatabase.

1;
