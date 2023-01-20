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

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# ArticleStorageDB

my $Backend = 'ArticleStorageDB';
$ConfigObject->Set(
    Key   => 'Ticket::Article::Backend::MIMEBase::ArticleStorage',
    Value => "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
);

my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

$Self->Is(
    $ArticleBackendObject->{ArticleStorageModule},
    "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
    'Article backend loaded the correct storage module'
);

my $ArticleStorage = $ConfigObject->Get('Ticket::Article::Backend::MIMEBase::ArticleStorage');

$Self->Is(
    $ArticleStorage,
    "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
    "ArticleStorage $ArticleStorage",
);

my $TicketID  = $HelperObject->TicketCreate();
my $ArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer <customer-a@example.com>',
    Subject              => 'some short description',
    Body                 => 'the message text',
    ContentType          => 'text/plain; charset=ISO-8859-15',
    HistoryType          => 'OwnerUpdate',
    HistoryComment       => 'Some free text!',
    UserID               => 1,
    NoAgentNotify        => 1,
);

$Self->True(
    $ArticleID,
    "ArticleBackendObject ArticleCreate()",
);

my $ArticleWriteAttachment = $ArticleBackendObject->ArticleWriteAttachment(
    ArticleID   => $ArticleID,
    Filename    => "$Backend",
    ContentType => 'text/html',
    ContentID   => 'testing123@example.com',
    Content     => '123',
    UserID      => 1,
);

$Self->True(
    $ArticleWriteAttachment,
    "$Backend ArticleWriteAttachment()",
);

my $ArticleCount = $ArticleObject->ArticleCount(
    TicketID => $TicketID,
);

$Self->Is(
    $ArticleCount,
    1,
    'ArticleCount',
);

my $ArticleAttachmentCount = $ArticleObject->ArticleAttachmentCount(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
);

$Self->Is(
    $ArticleAttachmentCount,
    1,
    'ArticleAttachmentCount',
);

# ArticleStorageFS
$Backend = 'ArticleStorageFS';

$ConfigObject->Set(
    Key   => 'Ticket::Article::Backend::MIMEBase::ArticleStorage',
    Value => "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket::Article'],
);

$ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
$ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

$Self->Is(
    $ArticleBackendObject->{ArticleStorageModule},
    "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
    'Article backend loaded the correct storage module'
);

$ArticleStorage = $ConfigObject->Get('Ticket::Article::Backend::MIMEBase::ArticleStorage');

$Self->Is(
    $ArticleStorage,
    "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
    "ArticleStorage $ArticleStorage",
);

$TicketID  = $HelperObject->TicketCreate();
$ArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer <customer-a@example.com>',
    Subject              => 'some short description',
    Body                 => 'the message text',
    ContentType          => 'text/plain; charset=ISO-8859-15',
    HistoryType          => 'OwnerUpdate',
    HistoryComment       => 'Some free text!',
    UserID               => 1,
    NoAgentNotify        => 1,
);

$Self->True(
    $ArticleID,
    "ArticleBackendObject ArticleCreate()",
);

# create attachment
$ArticleWriteAttachment = $ArticleBackendObject->ArticleWriteAttachment(
    ArticleID   => $ArticleID,
    Filename    => "$Backend",
    ContentType => 'text/html',
    ContentID   => 'testing123@example.com',
    Content     => '123',
    UserID      => 1,
);

$Self->True(
    $ArticleWriteAttachment,
    "$Backend ArticleWriteAttachment()",
);

$ArticleCount = $ArticleObject->ArticleCount(
    TicketID => $TicketID,
);

$Self->Is(
    $ArticleCount,
    1,
    'ArticleCount',
);

$ArticleAttachmentCount = $ArticleObject->ArticleAttachmentCount(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
);

$Self->Is(
    $ArticleAttachmentCount,
    1,
    'ArticleAttachmentCount',
);

1;
