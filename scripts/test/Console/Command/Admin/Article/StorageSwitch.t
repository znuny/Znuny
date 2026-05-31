# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## no critic (RequireExplicitPackage)

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $CommandObject        = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::Article::StorageSwitch');
my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
    ChannelName => 'Internal',
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my @Backends     = $CommandObject->_GetStorageBackends();

my @InvalidTests = (
    {
        Name    => 'Mutex Created-Before',
        Options => [qw( --tickets-created-before-date 2020-02-02 --tickets-created-min-days 22 )],
        Error   => qr(are mutually exclusive),
    },
    {
        Name    => 'Mutex Closed-Before',
        Options => [qw( --tickets-closed-before-date 2020-02-02 --tickets-closed-min-days 22 )],
        Error   => qr(are mutually exclusive),
    },
    {
        Name    => 'Mutex Created-After',
        Options => [qw( --tickets-created-after-date 2020-02-02 --tickets-created-max-days 22 )],
        Error   => qr(are mutually exclusive),
    },
    {
        Name    => 'Mutex Closed-After',
        Options => [qw( --tickets-closed-after-date 2020-02-02 --tickets-closed-max-days 22 )],
        Error   => qr(are mutually exclusive),
    },
    {
        Name    => 'Invalid month',
        Options => [qw( --tickets-closed-after-date 2020-13-01 )],
        Error   => qr(Could not parse datetime),
    },
    {
        Name    => 'Invalid day',
        Options => [qw( --tickets-closed-after-date 2020-10-00 )],
        Error   => qr(Could not parse datetime),
    },
    {
        Name    => 'Invalid date order',
        Options => [qw( --tickets-closed-after-date 2020-12-02 --tickets-closed-before-date 2020-12-01 )],
        Error   => qr(This will not find anything),
    },
    {
        Name    => 'Invalid day order',
        Options => [qw( --tickets-closed-min-days 91 --tickets-closed-max-days 90 )],
        Error   => qr(This will not find anything),
    },
);

# Try to execute command without any options
my $ExitCode = $CommandObject->Execute();
$Self->Is(
    $ExitCode,
    1,
    "Fails with no options",
);

for my $Test (@InvalidTests) {
    my $Output;
    local *STDOUT;
    open STDOUT, '>:utf8', \$Output;    ## no critic

    my $ExitCode = $CommandObject->Execute(
        '--source', $Backends[0],
        '--target', $Backends[1],
        @{ $Test->{Options} },
    );
    $Self->Is(
        $ExitCode,
        1,
        "StorageSwitch rejects options: @{ $Test->{Options} }",
    );
    $Self->True(
        !!( $Output =~ $Test->{Error} ),
        "Error message matches $Test->{Error}",
    );
}

# Make sure ticket is created in ArticleStorageDB.
$Kernel::OM->Get('Kernel::Config')->Set(
    Valid => 1,
    Key   => 'Ticket::Article::Backend::MIMEBase::ArticleStorage',
    Value => 'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageDB',
);

# create isolated time environment during test
$HelperObject->FixedTimeSet(
    $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => '2000-10-20 00:00:00',
        },
    )->ToEpoch()
);

# create test ticket with attachments
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
    'TicketCreate()',
);

my $ArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    IsVisibleForCustomer => 0,
    SenderType           => 'agent',
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer <customer-a@example.com>',
    Subject              => 'some short description',
    Body                 => 'the message text',
    ContentType          => 'text/plain; charset=ISO-8859-15',
    HistoryType          => 'OwnerUpdate',
    HistoryComment       => 'Some free text!',
    UserID               => 1,
    Attachment           => [
        {
            Content     => 'empty',
            ContentType => 'text/csv',
            Filename    => 'Test 1.txt',
        },
        {
            Content     => 'empty',
            ContentType => 'text/csv',
            Filename    => 'Test_1.txt',
        },
        {
            Content     => 'empty',
            ContentType => 'text/csv',
            Filename    => 'Test-1.txt',
        },
        {
            Content     => 'empty',
            ContentType => 'text/csv',
            Filename    => 'Test_1-1.txt',
        },
    ],
    NoAgentNotify => 1,
);
$Self->True(
    $ArticleID,
    'ArticleCreate()',
);

for my $BackendIndex ( 0 .. $#Backends ) {
    my $SourceBackend = $Backends[$BackendIndex];
    my $TargetBackend = $Backends[ $BackendIndex + 1 % $#Backends ];

    # provide options
    $ExitCode = $CommandObject->Execute(
        '--source', $SourceBackend,
        '--target', $TargetBackend,
        '--tickets-closed-before-date',
        '2000-10-21 00:00:00'
    );
    $Self->Is(
        $ExitCode,
        0,
        "Option: --source $SourceBackend --target $TargetBackend --tickets-closed-before-date 2000-10-21 00:00:00",
    );
}

# delete test ticket
$TicketObject->TicketDelete(
    TicketID => $TicketID,
    UserID   => 1,
);
$Self->True(
    $TicketID,
    'TicketDelete()',
);

1;
