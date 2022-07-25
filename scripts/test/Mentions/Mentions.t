# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
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

my $HelperObject         = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MentionObject        = $Kernel::OM->Get('Kernel::System::Mention');
my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );
my $UserObject           = $Kernel::OM->Get('Kernel::System::User');

# do not really send emails
$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::DoNotSendEmail',
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

# Add test agent.
my $UserRand = 'example-user' . $HelperObject->GetRandomID();
my $TestUser = $HelperObject->TestUserCreate();
my $UserID   = $UserObject->UserLookup( UserLogin => $TestUser );

$Self->True(
    $TestUser,
    "User creates"
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'TestTicket #1',
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
    'TicketCreate()'
);

my @ArticleIDs;
for my $Item ( 0 .. 2 ) {

    # Create articles with empty body.
    my $ArticleID = $ArticleBackendObject->ArticleCreate(
        TicketID             => $TicketID,
        SenderType           => 'agent',
        IsVisibleForCustomer => 1,
        From                 => 'Some Agent <email@example.com>',
        To                   => 'Some Customer A <customer-a@example.com>',
        Charset              => 'iso-8859-15',
        MimeType             => 'text/plain',
        HistoryType          => 'SendAnswer',
        HistoryComment       => 'Some free text!',
        UserID               => 1,
    );

    $Self->True(
        $ArticleID,
        'ArticleCreate()'
    );

    push @ArticleIDs, $ArticleID;
}

for my $ArticleID (@ArticleIDs) {
    my $Success = $MentionObject->AddMention(
        Recipient => {
            UserID => $UserID
        },
        TicketID  => $TicketID,
        ArticleID => $ArticleID
    );
    $Self->True(
        $Success,
        "AddMention(): Mention successfully added for article ID $ArticleID.",
    );
}

my $TicketMentions = $MentionObject->GetTicketMentions(
    TicketID => $TicketID,
) // [];

$Self->Is(
    scalar @{$TicketMentions},
    3,
    'GetTicketMentions(): Successful.',
);

my $MentionRemoved = $MentionObject->RemoveMention(
    TicketID => $TicketID,
    UserID   => $UserID,
);

$Self->True(
    $MentionRemoved,
    'RemoveMention(): Successfully removed mention from ticket.',
);

my $Success = $MentionObject->AddMention(
    Recipient => {
        UserID => $UserID
    },
    TicketID  => $TicketID,
    ArticleID => $ArticleIDs[0]
);

$Self->True(
    $Success,
    "AddMention(): Mention succesfully added for article ID $ArticleIDs[0].",
);

my $Mentions = $MentionObject->GetUserMentions(
    UserID => $UserID,
) // [];

$Self->Is(
    $Mentions->[0]->{TicketID},
    $TicketID,
    'GetUserMentions: Get all mentions of user.',
);

1;
