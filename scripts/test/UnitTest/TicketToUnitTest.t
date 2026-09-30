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
        RestoreDatabase => 1,
    },
);

my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $TicketToUnitTestObject = $Kernel::OM->Get('Kernel::System::UnitTest::TicketToUnitTest');

my $WithoutTicketID = $TicketToUnitTestObject->CreateUnitTest();

$Self->False(
    defined $WithoutTicketID,
    'CreateUnitTest() without TicketID returns undef',
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'TicketToUnitTest CreateUnitTest boilerplate',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => 'UnitTestCustomer',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    'TicketCreate() for CreateUnitTest',
);

my $UnitTestScript = $TicketToUnitTestObject->CreateUnitTest(
    TicketID => $TicketID,
);

$Self->True(
    $UnitTestScript,
    'CreateUnitTest() returns generated script',
);

$Self->True(
    ( $UnitTestScript =~ m/Kernel::System::UnitTest::Helper/sm ),
    'Generated script includes UnitTest::Helper bootstrap',
);

$Self->True(
    ( $UnitTestScript =~ m/my \$TicketObject\s*=\s*\$Kernel::OM->Get\('Kernel::System::Ticket'\)/sm ),
    'Generated script includes Ticket object',
);

$Self->True(
    ( $UnitTestScript =~ m/# Create ticket history entries/sm ),
    'Generated script includes ticket history section',
);

$Self->True(
    ( $UnitTestScript =~ m/# HistoryType: 'NewTicket'/sm ),
    'Generated script includes NewTicket history marker',
);

$Self->True(
    ( $UnitTestScript =~ m/TicketCreate/sm ),
    'Generated script includes TicketCreate from history replay',
);

$Self->True(
    ( $UnitTestScript =~ m/delete \$HelperObject->\{TestTickets\}/sm ),
    'Generated script includes Helper TestTickets cleanup footer',
);

my $HTMLBody = '<!DOCTYPE html><html><body><p>UnitTest HTML body</p>'
    . '<img src="cid:inline-image@example.com" alt=""><p>more text</p></body></html>';

my $HTMLTicketID = $TicketObject->TicketCreate(
    Title        => 'TicketToUnitTest HTML mail',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => 'UnitTestCustomer',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $HTMLTicketID,
    'TicketCreate() for HTML CreateUnitTest',
);

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

$Self->True(
    $HTMLArticleID,
    'ArticleCreate() HTML mail for CreateUnitTest',
);

my $HTMLUnitTestScript = $TicketToUnitTestObject->CreateUnitTest(
    TicketID => $HTMLTicketID,
);

$Self->True(
    $HTMLUnitTestScript,
    'CreateUnitTest() returns generated script for HTML mail',
);

$Self->True(
    ( $HTMLUnitTestScript =~ m{MimeType\s+=>\s+'text/html'}sm ),
    'Generated script uses MimeType text/html for HTML mail',
);

$Self->True(
    ( $HTMLUnitTestScript =~ m{<p>UnitTest HTML body</p>}sm ),
    'Generated script includes HTML body of HTML mail',
);

$Self->True(
    ( $HTMLUnitTestScript =~ m{Filename\s+=>\s+'inline\.png'}sm ),
    'Generated script includes inline image of HTML mail',
);

1;
