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

my $ArticleObject          = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SalutationObject       = $Kernel::OM->Get('Kernel::System::Salutation');
my $SignatureObject        = $Kernel::OM->Get('Kernel::System::Signature');
my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
my $StdAttachmentObject    = $Kernel::OM->Get('Kernel::System::StdAttachment');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject      = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $SystemAddressObject    = $Kernel::OM->Get('Kernel::System::SystemAddress');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::ArticleSend');

my $TicketID = $HelperObject->TicketCreate(
    Queue => 'Raw',
);
my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$StdAttachmentObject->StdAttachmentAdd(
    Name        => 'stdatt1',
    ValidID     => 1,
    Content     => 'StdAttachmentAdd_BLUB',
    ContentType => 'text/xml',
    Filename    => 'blub.txt',
    UserID      => 1,
);
$StandardTemplateObject->StandardTemplateAdd(
    Name         => 'stdtemplate1',
    Template     => '<OTRS_TICKET_Queue> StandardTemplateAdd_BLUB',
    ContentType  => 'text/plain; charset=utf-8',
    TemplateType => 'Answer',
    ValidID      => 1,
    UserID       => 1,
);
$SalutationObject->SalutationAdd(
    Name        => 'salu1',
    Text        => "<OTRS_TICKET_Queue> SalutationAdd_BLUB",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);
$SignatureObject->SignatureAdd(
    Name        => 'sig1',
    Text        => "<OTRS_TICKET_Queue> SignatureAdd_BLUB",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

#
# send article
#

my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        SenderType           => 'agent',
        IsVisibleForCustomer => 1,
        To                   => 'Some Customer A <customer-a@example.com>',
        Subject              => 'some short description',
        Body           => 'the message text | <OTRS_TA_Signature> | <OTRS_TA_Salutation> | <OTRS_TA_Template> | hohoho',
        Charset        => 'utf-8',
        MimeType       => 'text/plain',
        HistoryType    => 'AddNote',
        HistoryComment => 'Some free text!',

        Attachments => 'stdatt1',
        Template    => 'stdtemplate1',
        Salutation  => 'salu1',
        Signature   => 'sig1',
        UserID      => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

my @Articles = $ArticleObject->ArticleList(
    TicketID => $TicketID,
    OnlyLast => 1,
);

my %Article = $ArticleObject->ArticleGet(
    ArticleID => $Articles[0]->{ArticleID},
    TicketID  => $TicketID,
    UserID    => 1,
);

$Self->Is(
    $Article{Subject},
    '[Ticket#' . $Ticket{TicketNumber} . '] some short description',
    'ArticleSend has correct subject',
);
$Self->Is(
    $Article{Body},
    'the message text | Raw SignatureAdd_BLUB | Raw SalutationAdd_BLUB | Raw StandardTemplateAdd_BLUB | hohoho',
    'ArticleSend has correct body',
);

# ConvertText

my $Text = $TransitionActionObject->ConvertText(
    RichText    => 0,
    Content     => '<b>123</b> 123 123',
    ContentType => 'text/html',
);

$Self->Is(
    $Text,
    '123 123 123',
    'ConvertText()',
);

$Text = $TransitionActionObject->ConvertText(
    RichText => 1,
    Content  => 'a
b
c',
    ContentType => 'text/plain',
);

$Self->Is(
    $Text,
    'a<br/>
b<br/>
c',
    'ConvertText()',
);

# FromGet

my $ID = $SystemAddressObject->SystemAddressAdd(
    Name     => 'hoho@example.com',
    Realname => 'Hotline',
    ValidID  => 1,
    QueueID  => 1,
    Comment  => 'some comment',
    UserID   => 1,
);

$TicketID = $HelperObject->TicketCreate();

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Text = $TransitionActionObject->FromGet(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        From => 'hoho@example.com',
    },
);

$Self->Is(
    $Text,
    'Hotline <hoho@example.com>',
    'FromGet(hoho@example.com)',
);

$Text = $TransitionActionObject->FromGet(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        From => 'unkown@example.com',
    },
);

$Self->Is(
    $Text,
    'Znuny System <znuny@localhost>',
    'FromGet(unkown@example.com)',
);

$Text = $TransitionActionObject->FromGet(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Queue => 'Postmaster',
    },
);

$Self->Is(
    $Text,
    'Znuny System <znuny@localhost>',
    'FromGet(unkown@example.com)',
);

1;
