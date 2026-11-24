# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::Output::HTML::TicketZoom::Customer::MIMEBase;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
    'Kernel::Output::HTML::Layout' => {
        UserID    => 1,
        Lang      => 'en',
        SessionID => 123,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

$Kernel::OM->Get('Kernel::Output::HTML::Layout');

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::Frontend::ZoomRichTextForce',
    Value => 1,
);

my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
    ChannelName => 'Email',
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'CustomerTicketZoom plain body escape',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => 'customer',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $TicketID,
    'TicketCreate()',
);

my $ArticleRenderObject = Kernel::Output::HTML::TicketZoom::Customer::MIMEBase->new();

my $XSSPlainBody = "Hello <u id=\"cvdmarker\">cvdmarker</u>\nSecond line";

my $HTMLArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    IsVisibleForCustomer => 1,
    SenderType           => 'customer',
    From                 => 'Customer <customer@example.com>',
    To                   => 'Support <support@example.com>',
    Subject              => 'HTML article with markup in plain body',
    Body                 => $XSSPlainBody,
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'EmailCustomer',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
);
$Self->True(
    $HTMLArticleID,
    'ArticleCreate() with HTML part',
);

my $HTMLAttachmentWrite = $ArticleBackendObject->ArticleWriteAttachment(
    ArticleID   => $HTMLArticleID,
    Filename    => 'file-2',
    ContentType => 'text/html; charset="utf-8"',
    Content     => '<p>Ordinary html part</p>',
    Disposition => 'inline',
    UserID      => 1,
);
$Self->True(
    $HTMLAttachmentWrite,
    'ArticleWriteAttachment() HTML body',
);

my $HTMLRender = $ArticleRenderObject->ArticleRender(
    TicketID  => $TicketID,
    ArticleID => $HTMLArticleID,
    Class     => 'Visible',
);
$Self->True(
    $HTMLRender,
    'ArticleRender() with HTML part',
);

$Self->False(
    index( $HTMLRender, '<u id="cvdmarker">' ) > -1,
    'HTML article: live marker tag is not present',
);
$Self->True(
    index( $HTMLRender, '&lt;u id=&quot;cvdmarker&quot;&gt;' ) > -1,
    'HTML article: plain body marker is escaped',
);
$Self->True(
    index( $HTMLRender, 'iframe' ) > -1,
    'HTML article: sandboxed iframe is present',
);

my $PlainArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    IsVisibleForCustomer => 1,
    SenderType           => 'customer',
    From                 => 'Customer <customer@example.com>',
    To                   => 'Support <support@example.com>',
    Subject              => 'Plain-text only article',
    Body                 => "Plain line one\nPlain line two <u id=\"plainmarker\">x</u>",
    MimeType             => 'text/plain',
    Charset              => 'utf-8',
    HistoryType          => 'EmailCustomer',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
);
$Self->True(
    $PlainArticleID,
    'ArticleCreate() plain-text only',
);

my $PlainRender = $ArticleRenderObject->ArticleRender(
    TicketID  => $TicketID,
    ArticleID => $PlainArticleID,
    Class     => 'Visible',
);
$Self->True(
    $PlainRender,
    'ArticleRender() plain-text only',
);

$Self->False(
    index( $PlainRender, '<u id="plainmarker">' ) > -1,
    'Plain article: live marker tag is not present',
);
$Self->True(
    index( $PlainRender, '&lt;u id=&quot;plainmarker&quot;&gt;' ) > -1,
    'Plain article: body marker is escaped',
);
$Self->True(
    index( $PlainRender, '<br/>' ) > -1,
    'Plain article: Ascii2Html line breaks are present',
);

1;
