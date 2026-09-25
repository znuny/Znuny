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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $TicketToUnitTestHistoryTypeObject
    = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest::HistoryType::AddNote');

my $TicketID  = $HelperObject->TicketCreate();
my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my %Param = (
    TicketID    => $TicketID,
    ArticleID   => $ArticleID,
    HistoryType => 'AddNote',
);

my %Article = $ArticleObject->ArticleGet(
    TicketID  => $Param{TicketID},
    ArticleID => $Param{ArticleID}
);

my $Output = $TicketToUnitTestHistoryTypeObject->Run(
    %Param,
);

my $ExpectedOutout = <<OUTPUT;
\$TempValue = <<'BODY';
$Article{Body}
BODY

\$ArticleID = \$HelperObject->ArticleCreate(
    TicketID             => \$TicketID,
    ChannelName          => '$Article{CommunicationChannel}',
    Subject              => '$Article{Subject}',
    Body                 => \$TempValue,
    IsVisibleForCustomer => '$Article{IsVisibleForCustomer}',
    SenderType           => '$Article{SenderType}',
    From                 => '$Article{From}',
    To                   => '$Article{To}',
    Charset              => '$Article{Charset}',
    MimeType             => '$Article{MimeType}',
    HistoryType          => '$Param{HistoryType}',
    HistoryComment       => 'UnitTest',
    UserID               => \$UserID,
);

# trigger transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

$Self->Is(
    $Output,
    $ExpectedOutout,
    'TicketToUnitTest::HistoryType::AddNote',
);

my $HTMLBody = '<!DOCTYPE html><html><body><p>UnitTest HTML body</p>'
    . '<img src="cid:inline-image@example.com" alt=""></body></html>';

my $HTMLTicketID  = $HelperObject->TicketCreate();
my $HTMLArticleID = $HelperObject->ArticleCreate(
    TicketID             => $HTMLTicketID,
    ChannelName          => 'Email',
    SenderType           => 'customer',
    HistoryType          => 'EmailCustomer',
    Subject              => 'UnitTest HTML article',
    Body                 => $HTMLBody,
    MimeType             => 'text/html',
    Charset              => 'utf-8',
    From                 => 'Customer User <customer@example.com>',
    To                   => 'Agent User <agent@example.com>',
    IsVisibleForCustomer => 1,
    Attachment           => [
        {
            Content     => 'fake-png-bytes',
            ContentType => 'image/png',
            Filename    => 'inline.png',
            ContentID   => '<inline-image@example.com>',
            Disposition => 'inline',
        },
    ],
);

my $HTMLOutput = $TicketToUnitTestHistoryTypeObject->Run(
    TicketID    => $HTMLTicketID,
    ArticleID   => $HTMLArticleID,
    HistoryType => 'AddNote',
);

$Self->True(
    ( $HTMLOutput =~ m{MimeType\s+=>\s+'text/html'}sm ),
    'HTML article generator uses MimeType text/html',
);

$Self->True(
    ( $HTMLOutput =~ m{<p>UnitTest HTML body</p>}sm ),
    'HTML article generator includes HTML body',
);

$Self->True(
    ( $HTMLOutput =~ m{ChannelName\s+=>\s+'Email'}sm ),
    'HTML article generator keeps Email channel',
);

$Self->True(
    ( $HTMLOutput =~ m{require MIME::Base64;}sm ),
    'HTML article generator dumps attachments as Base64',
);

$Self->True(
    ( $HTMLOutput =~ m{Filename\s+=>\s+'inline\.png'}sm ),
    'HTML article generator includes inline image attachment',
);

$Self->True(
    ( $HTMLOutput =~ m{ContentID\s+=>\s+'<inline-image\@example\.com>'}sm ),
    'HTML article generator keeps inline ContentID',
);

1;
