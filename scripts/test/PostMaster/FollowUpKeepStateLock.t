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

use Kernel::System::PostMaster;

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);
$ConfigObject->Set(
    Key   => 'PostmasterFollowUpState',
    Value => 'open',
);

my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $AgentAddress    = 'agent@example.com';
my $CustomerAddress = 'external@example.com';

my $QueueID = $QueueObject->QueueAdd(
    Name            => 'FollowUpLockQueue',
    ValidID         => 1,
    GroupID         => 1,
    UnlockTimeout   => 480,
    FollowUpID      => 1,
    FollowUpLock    => 1,
    SystemAddressID => 1,
    SalutationID    => 1,
    SignatureID     => 1,
    Comment         => 'Follow-up lock queue',
    UserID          => 1,
);
$Self->True(
    $QueueID,
    'Queue created.',
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Closed ticket follow-up lock',
    QueueID      => $QueueID,
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'closed successful',
    CustomerUser => $CustomerAddress,
    OwnerID      => 1,
    UserID       => 1,
);
$TicketID //= '';

$Self->True(
    $TicketID,
    "Ticket created - TicketID=$TicketID.",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 0,
    UserID        => 1,
);

my @Tests = (
    {
        Name                          => 'Reopen locks closed ticket',
        Headers                       => '',
        PostmasterFollowUpStateClosed => '',
        ExpectedState                 => 'open',
        ExpectedLock                  => 'lock',
    },
    {
        Name                          => 'State-Keep keeps closed ticket unlocked',
        Headers                       => "X-OTRS-FollowUp-State-Keep: 1\n",
        PostmasterFollowUpStateClosed => '',
        ExpectedState                 => 'closed successful',
        ExpectedLock                  => 'unlock',
    },
    {
        Name                          => 'Closed follow-up state stays unlocked',
        Headers                       => "X-OTRS-FollowUp-State: closed unsuccessful\n",
        PostmasterFollowUpStateClosed => '',
        ExpectedState                 => 'closed unsuccessful',
        ExpectedLock                  => 'unlock',
    },
    {
        Name                          => 'PostmasterFollowUpStateClosed stays unlocked',
        Headers                       => '',
        PostmasterFollowUpStateClosed => 'closed unsuccessful',
        ExpectedState                 => 'closed unsuccessful',
        ExpectedLock                  => 'unlock',
    },
    {
        Name                          => 'Explicit FollowUp-Lock still locks when state is kept',
        Headers                       => "X-OTRS-FollowUp-State-Keep: 1\nX-OTRS-FollowUp-Lock: lock\n",
        PostmasterFollowUpStateClosed => '',
        ExpectedState                 => 'closed successful',
        ExpectedLock                  => 'lock',
    },
);

for my $Test (@Tests) {

    $ConfigObject->Set(
        Key   => 'PostmasterFollowUpStateClosed',
        Value => $Test->{PostmasterFollowUpStateClosed},
    );

    my $StateSet = $TicketObject->TicketStateSet(
        State    => 'closed successful',
        TicketID => $TicketID,
        UserID   => 1,
    );
    $Self->True(
        $StateSet,
        "$Test->{Name} - ticket reset to closed successful.",
    );

    my $LockSet = $TicketObject->TicketLockSet(
        Lock     => 'unlock',
        TicketID => $TicketID,
        UserID   => 1,
    );
    $Self->True(
        $LockSet,
        "$Test->{Name} - ticket reset to unlock.",
    );

    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport => 'Email',
            Direction => 'Incoming',
        },
    );
    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

    my $PostMasterObject = Kernel::System::PostMaster->new(
        CommunicationLogObject => $CommunicationLogObject,
        Email                  => "From: Provider <$CustomerAddress>
To: Agent <$AgentAddress>
Subject: FollowUp Ticket#$Ticket{TicketNumber}
$Test->{Headers}
Some Content in Body",
    );

    my @Return = $PostMasterObject->Run();

    $CommunicationLogObject->ObjectLogStop(
        ObjectLogType => 'Message',
        Status        => 'Successful',
    );
    $CommunicationLogObject->CommunicationStop(
        Status => 'Successful',
    );

    $Self->Is(
        $Return[0] || 0,
        2,
        "$Test->{Name} - follow-up.",
    );
    $Self->Is(
        $Return[1] || 0,
        $TicketID,
        "$Test->{Name} - TicketID.",
    );

    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Ticket'] );
    $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %FollowUpTicket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 0,
        UserID        => 1,
    );

    $Self->Is(
        $FollowUpTicket{State},
        $Test->{ExpectedState},
        "$Test->{Name} - state.",
    );
    $Self->Is(
        $FollowUpTicket{Lock},
        $Test->{ExpectedLock},
        "$Test->{Name} - lock.",
    );
}

1;
