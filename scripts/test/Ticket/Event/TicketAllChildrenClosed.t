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
use parent qw(Kernel::System::EventHandler);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');

my $UserID    = 1;
my $EventName = 'TicketAllChildrenClosed';

my $TicketAllChildrenClosedEventExecuted = sub {
    my @TicketAllChildrenClosedEvents = grep { $_->{Event} eq 'TicketAllChildrenClosed' }
        @{ $TicketObject->{EventHandlerPipe} };

    my $EventExecuted = @TicketAllChildrenClosedEvents ? 1 : 0;
    return $EventExecuted;
};

my $ParentTicketID = $HelperObject->TicketCreate(
    Title         => 'test',
    QueueID       => 1,
    Lock          => 'unlock',
    Priority      => '3 normal',
    StateID       => 1,
    TypeID        => 1,
    OwnerID       => 1,
    ResponsibleID => 1,
    UserID        => $UserID,
);

my @ChildTicketIDs;
for my $ChildTicketCounter ( 1 .. 3 ) {
    my $ChildTicketID = $HelperObject->TicketCreate(
        Title         => 'test' . $ChildTicketCounter,
        QueueID       => 1,
        Lock          => 'unlock',
        Priority      => '3 normal',
        StateID       => 1,
        TypeID        => 1,
        OwnerID       => 1,
        ResponsibleID => 1,
        UserID        => $UserID,
    );

    push @ChildTicketIDs, $ChildTicketID;

    my $TicketLinked = $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $ParentTicketID,
        TargetObject => 'Ticket',
        TargetKey    => $ChildTicketID,
        Type         => 'ParentChild',
        State        => 'Valid',
        UserID       => $UserID,
    );

    $Self->True(
        scalar $TicketLinked,
        'Child ticket must have been linked to parent ticket.',
    );
}

my @Tests = (
    {
        TicketID               => $ChildTicketIDs[0],
        ExpectedEventExecution => 0,
    },
    {
        TicketID               => $ChildTicketIDs[1],
        ExpectedEventExecution => 0,
    },
    {
        TicketID               => $ChildTicketIDs[2],
        ExpectedEventExecution => 1,
    },
);

my $EventExecuted = &$TicketAllChildrenClosedEventExecuted();

$Self->False(
    $EventExecuted,
    "Event $EventName must not have been triggered at this point.",
);

for my $Test (@Tests) {
    my $TicketStateSet = $TicketObject->TicketStateSet(
        State    => 'closed successful',
        TicketID => $Test->{TicketID},
        UserID   => 1,
    );

    $EventExecuted = &$TicketAllChildrenClosedEventExecuted();

    $Self->Is(
        $EventExecuted,
        $Test->{ExpectedEventExecution},
        "Event $EventName must"
            . ( $Test->{ExpectedEventExecution} ? '' : ' not' )
            . " have been triggered after child ticket state change.",
    );
}

1;
