# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use Kernel::System::Ticket::Event::TicketPendingTimeReset;

use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $StateObject  = $Kernel::OM->Get('Kernel::System::State');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

my %StateList = $StateObject->StateList(
    UserID => 1,
    Valid  => 1,
);

my %StateListRev = reverse %StateList;

my $PendingReminderStateType = 'pending reminder';
my $PendingAutoStateType     = 'pending auto';
my $OpenStateType            = 'open';
my $ClosedStateType          = 'closed';

my %StateListType = $StateObject->StateTypeList(
    UserID => 1,
);

my %StateListTypeRev = reverse %StateListType;

my $StatePendingAutoID     = $StateListTypeRev{$PendingAutoStateType};
my $StatePendingReminderID = $StateListTypeRev{$PendingReminderStateType};

my $StateOpenID   = $StateListTypeRev{$OpenStateType};
my $StateClosedID = $StateListTypeRev{$ClosedStateType};

my @StatesData = (
    {
        Name    => 'pending auto close + (test)',
        ValidID => 1,
        TypeID  => $StatePendingAutoID,
        UserID  => 1,
    },
    {
        Name    => 'pending reminder (test)',
        ValidID => 1,
        TypeID  => $StatePendingReminderID,
        UserID  => 1,
    },
    {
        Name    => 'open (test)',
        ValidID => 1,
        TypeID  => $StateOpenID,
        UserID  => 1,
    },
    {
        Name    => 'closed (test)',
        ValidID => 1,
        TypeID  => $StateClosedID,
        UserID  => 1,
    },
);

for my $State (@StatesData) {
    if ( !$StateListRev{ $State->{Name} } ) {
        my $ID = $StateObject->StateAdd(
            Comment => 'test state',
            %{$State},
        );
        $Self->True(
            $ID,
            "Created not existing state: $ID",
        );
    }
    else {
        my $Success = $StateObject->StateUpdate(
            ID      => $StateListRev{ $State->{Name} },
            Comment => 'test state',
            %{$State},
        );

        $Self->True(
            $Success,
            "Updated existing ticket state: $State->{Name}",
        );
    }
}

my $Success = $ConfigObject->Set(
    Key   => 'Ticket::PendingReminderStateType',
    Value => 'pending reminder',
);

$Self->True(
    $Success,
    "Set Ticket::PendingReminderStateType to pending reminder",
);

$Success = $ConfigObject->Set(
    Key   => 'Ticket::PendingAutoStateType',
    Value => 'pending auto',
);

$Self->True(
    $Success,
    "Set Ticket::PendingAutoStateType to pending reminder",
);

my $DefaultEventConfig = {
    'Event'  => 'StateUpdate',
    'Module' => 'Kernel::System::Ticket::Event::TicketPendingTimeReset',
};

my $DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
);

my $DateTimeNowStrg = $DateTimeObject->ToString();

$DateTimeObject->Subtract(
    Years   => 0,
    Months  => 0,
    Weeks   => 0,
    Days    => 1,
    Hours   => 0,
    Minutes => 0,
    Seconds => 0,
);

my $DateTimePastStrg = $DateTimeObject->ToString();

my @Tests = (
    {
        Name  => '1. pending auto state - future pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'pending auto close + (test)',
            TicketPendingTimeSetParams => {
                Diff   => ( 7 * 24 * 60 ),    # time > 0
                UserID => 1,
            }
        },
        Expected => {
            Success    => 1,
            ResetValue => 0,
        }
    },
    {
        Name  => '2. pending auto state - now pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'pending auto close + (test)',
            TicketPendingTimeSetParams => {
                String => $DateTimeNowStrg,    # time = 0
                UserID => 1,
            }
        },
        Expected => {
            Success => 1,
        }
    },
    {
        Name  => '3. pending auto state - past pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'pending auto close + (test)',
            TicketPendingTimeSetParams => {
                String => $DateTimePastStrg,    # time < 0
                UserID => 1,
            }
        },
        Expected => {
            Success    => 1,
            ResetValue => 0,
        }
    },
    {
        Name  => '4. pending reminder state - future pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'pending reminder (test)',
            TicketPendingTimeSetParams => {
                Diff   => ( 7 * 24 * 60 ),    # time > 0
                UserID => 1,
            }
        },
        Expected => {
            Success    => 1,
            ResetValue => 0,
        }
    },
    {
        Name  => '5. open state - future pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'open (test)',
            TicketPendingTimeSetParams => {
                Diff   => ( 7 * 24 * 60 ),    # time > 0
                UserID => 1,
            }
        },
        Expected => {
            Success    => 1,
            ResetValue => 1,
        }
    },
    {
        Name  => '7. open state - now pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'open (test)',
            TicketPendingTimeSetParams => {
                String => $DateTimeNowStrg,    # time = 0
                UserID => 1,
            }
        },
        Expected => {
            Success => 1,
        }
    },
    {
        Name  => '8. closed state - past pending time',
        Event => "StateUpdate",
        Data  => {
            State                      => 'closed (test)',
            TicketPendingTimeSetParams => {
                String => $DateTimePastStrg,    # time < 0
                UserID => 1,
            }
        },
        Expected => {
            Success    => 1,
            ResetValue => 1,
        }
    },

);

my $CustomerUser = $Helper->GetRandomID() . '@example.com';
my %Result;

my $Module = $DefaultEventConfig->{Module}->new();

$Self->True(
    $Module,
    "Module is created - $DefaultEventConfig->{Module}",
);

# create new tickets
my @Tickets;
TICKET:
for ( my $i = 0; $i < scalar @Tests; $i++ ) {
    my $TicketNumber = $TicketObject->TicketCreateNumber();
    my $TicketID     = $TicketObject->TicketCreate(
        TN           => $TicketNumber,
        Title        => 'Test ticket',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => $Tests[$i]->{Data}->{State},
        CustomerNo   => '123465',
        CustomerUser => $CustomerUser,
        OwnerID      => 1,
        UserID       => 1,
    );

    $Self->True(
        $TicketID,
        "Ticket is created - $TicketID",
    );

    # set custom pending time
    my $Success = $TicketObject->TicketPendingTimeSet(
        %{ $Tests[$i]->{Data}->{TicketPendingTimeSetParams} },
        TicketID => $TicketID,
    );

    $Self->True(
        $Success,
        "Ticket pending time is set for ticket id: $TicketID",
    );

    $Tests[$i]->{Data}->{TicketID} = $TicketID;

    my $Result;
    if ($Success) {
        $Result = $Module->Run(
            Data   => $Tests[$i]->{Data},
            Event  => $Tests[$i]->{Event},
            Config => $DefaultEventConfig,
            UserID => 1,
        );
    }

    $Self->Is(
        $Tests[$i]->{Expected}->{Success},
        $Result,
        "Expected result success ($Tests[$i]->{Name})",
    );

    # get ticket
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        UserID        => 1,
        DynamicFields => 0,
    );

    # do not test cases with date time "now"
    # as this can pass or fail depending on
    # the performance
    if ( defined $Tests[$i]->{Expected}->{ResetValue} ) {
        if ( $Tests[$i]->{Expected}->{ResetValue} ) {
            $Self->Is(
                $Ticket{UntilTime},
                0,
                "Expected resetted value ($Tests[$i]->{Name})",
            );
        }
        else {
            $Self->IsNot(
                $Ticket{UntilTime},
                0,
                "Expected not resetted value ($Tests[$i]->{Name})",
            );
        }
    }
}

1;
