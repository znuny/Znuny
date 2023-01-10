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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');
my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $GroupObject   = $Kernel::OM->Get('Kernel::System::Group');
my $QueueObject   = $Kernel::OM->Get('Kernel::System::Queue');
my $UserObject    = $Kernel::OM->Get('Kernel::System::User');

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
    "User created - UserAdd()"
);

my $RandomID = $HelperObject->GetRandomID();

my $GID = $GroupObject->GroupAdd(
    Name    => 'CheckCategoryUserPermission-' . $RandomID,
    Comment => 'comment describing the group',
    ValidID => 1,
    UserID  => 1,
);

my $QueueID = $QueueObject->QueueAdd(
    Name    => "QueueExampleTest1",
    GroupID => $GID,
    ValidID => 1,
    UserID  => 1,
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'TestTicket #1',
    Queue        => 'QueueExampleTest1',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID
);

my @Ticket = $TicketObject->TicketSearch(
    UserID   => $UserID,
    TicketID => $TicketID
);

$Self->Is(
    $Ticket[0],
    undef,
    "No ticket found for User - PermissionCheck",
);

my $Success = $MentionObject->AddMention(
    MentionedUserID => $UserID,
    TicketID        => $TicketID,
    ArticleID       => $ArticleID,
    UserID          => 1,
);

@Ticket = $TicketObject->TicketSearch(
    UserID   => $UserID,
    TicketID => $TicketID
);

my $PermissionMentionCheck = $Kernel::OM->Get('Kernel::System::Ticket::Permission::MentionCheck')->Run(
    TicketID => $TicketID,
    UserID   => $UserID,
    Type     => 'ro'
);

$Self->True(
    $PermissionMentionCheck,
    "Agent has access to ticket.",
);

1;
