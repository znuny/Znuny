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

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$HelperObject->FixedTimeSet();

# Use test email backend.
$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::Test',
);

my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

# Create test ticket.
my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Some Ticket_Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'closed successful',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $TicketID,
    'TicketCreate()'
);

my $ArticleBackendObject = $Kernel::OM->Get("Kernel::System::Ticket::Article::Backend::Email");
my $MessageID            = '<' . $HelperObject->GetRandomID() . '@example.com>';
my %ArticleHash          = (
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 1,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer A <customer-a@example.com>',
    Cc                   => 'Some Customer B <customer-b@example.com>',
    Subject              => 'some short description',
    Body                 => 'the message text',
    MessageID            => $MessageID,
    Charset              => 'ISO-8859-15',
    MimeType             => 'text/plain',
    HistoryType          => 'OwnerUpdate',
    HistoryComment       => 'Some free text!',
    UserID               => 1,
    UnlockOnAway         => 1,
    FromRealname         => 'Some Agent',
    ToRealname           => 'Some Customer A',
    CcRealname           => 'Some Customer B',
);
$Self->True(
    $ArticleBackendObject,
    "Got 'Email' article backend object"
);

# Create test article.
my $ArticleID = $ArticleBackendObject->ArticleCreate(
    %ArticleHash,
);

$Self->True(
    $ArticleID,
    "ArticleCreate - Added article '$ArticleID'"
);

my $TransmissionLogObject = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Email');

$Self->True(
    $TransmissionLogObject,
    'TransmissionLogObject new()'
);

my @Events;

local *Kernel::System::Ticket::Article::Backend::Email::EventHandler = sub {
    my ( $Self, %Param ) = @_;
    push @Events, \%Param;
};

$Self->True(
    !@Events,
    'Event array is empty',
);

my $Result;

$Result = $TransmissionLogObject->ArticleCreateTransmissionError(
    ArticleID => $ArticleID,
    MessageID => $MessageID,
);

$Self->True(
    $Result,
    'TransmissionLogObject create()'
);

$Self->True(
    @Events,
    'Event array is not empty',
);

$Self->Is(
    $Events[0]->{Event},
    'ArticleCreateTransmissionError',
    'Check correct event name after transmission error create'
);

my $Object  = $TransmissionLogObject->ArticleGetTransmissionError( ArticleID => $ArticleID );
my $Success = IsHashRefWithData($Object);
$Self->True(
    $Success,
    'TransmissionLogObject create()'
);

$Result = $TransmissionLogObject->ArticleUpdateTransmissionError(
    ArticleID => $ArticleID,
    Message   => 'Test',
);

$Self->True(
    $Result,
    'TransmissionLogObject update()'
);

$Self->Is(
    scalar(@Events),
    2,
    'Event array is not empty',
);

$Self->Is(
    $Events[1]->{Event},
    'ArticleUpdateTransmissionError',
    'Check correct event name after transmission error update'
);

$Object = $TransmissionLogObject->ArticleGetTransmissionError( ArticleID => $ArticleID );

$Self->True( $Object->{Message} eq 'Test', 'Updated Status ok.' );

1;
