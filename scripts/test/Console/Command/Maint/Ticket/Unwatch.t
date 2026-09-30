# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## no critic(RequireExplicitPackage)

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

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::Ticket::Unwatch');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $StateObject   = $Kernel::OM->Get('Kernel::System::State');
my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $UserObject    = $Kernel::OM->Get('Kernel::System::User');

my @Tests = (
    {
        Name          => 'No watchers removed after less than a day',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2025-08-27 00:00:00',
        Watchers      => undef,    # expect whatever the ticket was created with
    },
    {
        Name          => 'No watchers removed after one day',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2025-08-27 00:00:00',
        Watchers      => undef,    # expect whatever the ticket was created with
    },
    {
        Name          => 'All watchers removed after eight days',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2025-09-04 00:00:00',
        Watchers      => 0,
    },
    {
        Name          => 'All watchers removed after 1 month',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2025-09-26 01:02:03',
        Watchers      => 0,
    },
    {
        Name          => 'All watchers removed after 5 years',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2030-08-26 01:02:03',
        Watchers      => 0,
    },
    {
        Name          => 'Invocation works with --no-invalid-users',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [qw( --days 30 --no-invalid-users )],
        ExitCode      => 0,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2030-10-26 01:02:03',
        Watchers      => 1,
    },
    {
        Name          => 'Command rejects invalid --days -42',
        CommandModule => 'Kernel::System::Console::Command::Maint::Ticket::Unwatch',
        Parameter     => [qw( --days -42 )],
        ExitCode      => 1,
        STDOUT        => '',
        STDERR        => undef,
        TimeStamp     => '2030-10-26 01:02:03',
        Watchers      => undef,
    },
);

my $WatcherNum = 0;
my $TestEnv    = $HelperObject->FillTestEnvironment(
    User    => 4,
    Service => 0,
    SLA     => 0,
    Type    => 0,
    Queue   => 0,
);
$ConfigObject->{'Ticket::Watcher'} = 1;    # Enable ticket watching

# Set first agent invalid
my $InvalidUserID = $TestEnv->{User}[0]{UserID};
my $InvalidID     = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
    Valid => 'invalid'
);
my %User = $UserObject->GetUserData(
    UserID => $InvalidUserID
);
my $Success = $UserObject->UserUpdate(
    %User,
    ChangeUserID => 1,
    ValidID      => $InvalidID,
);
$Self->True(
    $Success,
    "Successfully invalidated one agent"
);

my @WatcherIDs   = map { $_->{UserID} } @{ $TestEnv->{User} };
my @ClosedStates = $StateObject->StateGetStatesByType(
    StateType => 'closed',
    Result    => 'Name'
);
my @OpenStates = $StateObject->StateGetStatesByType(
    StateType => 'open',
    Result    => 'Name'
);

$Self->True(
    @ClosedStates >= 1,
    "Got at least one 'closed' ticket state"
);
$Self->True(
    @OpenStates >= 1,
    "Got at least one 'open' ticket state"
);

TEST:
for my $Test (@Tests) {
    my ( $TicketID, $OpenTicketID, $AllWatchersTicketID, $Success );
    my %ClosedTickets;
    my @Watchers;

    # Set time stamp before creating tickets
    $HelperObject->FixedTimeSetByTimeStamp('2025-08-26 01:02:03');

    # Create a closed ticket for each of the "closed" StateTypes
    for my $State (@ClosedStates) {

        # Create one ticket with one and two watchers respectively
        for my $NumWatchers ( 1 .. 2 ) {
            $TicketID = $TicketObject->TicketCreate(
                Queue    => 'Raw',
                State    => 'open',
                Priority => '3 normal',
                Lock     => 'lock',
                OwnerID  => 1,
                UserID   => 1,
            );
            $Self->True(
                $TicketID,
                "Ticket created ($Test->{Name})"
            );

            for ( 1 .. $NumWatchers ) {

                # Iterate through all watchers
                $WatcherNum = ( $WatcherNum + 1 ) % @WatcherIDs;
                my $WatchedBy = $WatcherIDs[$WatcherNum];
                my $Success   = $TicketObject->TicketWatchSubscribe(
                    TicketID    => $TicketID,
                    WatchUserID => $WatchedBy,
                    UserID      => 1,
                );
                $Self->True(
                    $Success,
                    "Ticket $TicketID watched by agent $WatchedBy ($Test->{Name})"
                );
            }

            $Success = $TicketObject->TicketStateSet(
                State    => $State,
                TicketID => $TicketID,
                UserID   => 1,
            );
            $Self->True(
                $Success,
                "Ticket $TicketID set to $State ($Test->{Name})"
            );

            $ClosedTickets{$TicketID} = $Test->{Watchers} // $NumWatchers;
        }
    }

    # Create one ticket that will be closed and reopened
    $OpenTicketID = $TicketObject->TicketCreate(
        Queue    => 'Raw',
        State    => 'open',
        Priority => '3 normal',
        Lock     => 'lock',
        OwnerID  => 1,
        UserID   => 1,
    );
    $Self->True(
        $OpenTicketID,
        "Ticket created ($Test->{Name})"
    );

    for ( 1 .. 2 ) {

        # Iterate through all watchers
        $WatcherNum = ( $WatcherNum + 1 ) % @WatcherIDs;
        my $WatchedBy = $WatcherIDs[$WatcherNum];
        my $Success   = $TicketObject->TicketWatchSubscribe(
            TicketID    => $OpenTicketID,
            WatchUserID => $WatchedBy,
            UserID      => 1,
        );
        $Self->True(
            $Success,
            "Ticket $OpenTicketID watched by agent $WatchedBy ($Test->{Name})"
        );
    }

    $Self->True(
        $OpenTicketID,
        "Opened a ticket to be closed and reopened ($Test->{Name})",
    );
    $Success = $TicketObject->TicketStateSet(
        State    => $ClosedStates[0],
        TicketID => $OpenTicketID,
        UserID   => 1,
    );
    $Self->True(
        $Success,
        "Ticket $OpenTicketID set to $ClosedStates[0] ($Test->{Name})"
    );
    $Success = $TicketObject->TicketStateSet(
        State    => $OpenStates[0],
        TicketID => $OpenTicketID,
        UserID   => 1,
    );
    $Self->True(
        $Success,
        "Ticket $OpenTicketID set to $OpenStates[0] ($Test->{Name})"
    );

    # Open and close another ticket watched by everybody, including the invalid agent
    $AllWatchersTicketID = $TicketObject->TicketCreate(
        Queue    => 'Raw',
        State    => 'open',
        Priority => '3 normal',
        Lock     => 'lock',
        OwnerID  => 1,
        UserID   => 1,
    );
    $Self->True(
        $AllWatchersTicketID,
        "Ticket created ($Test->{Name})"
    );

    for ( 1 .. @WatcherIDs ) {

        # Iterate through all watchers
        $WatcherNum = ( $WatcherNum + 1 ) % @WatcherIDs;
        my $WatchedBy = $WatcherIDs[$WatcherNum];
        my $Success   = $TicketObject->TicketWatchSubscribe(
            TicketID    => $AllWatchersTicketID,
            WatchUserID => $WatchedBy,
            UserID      => 1,
        );
        $Self->True(
            $Success,
            "Ticket $AllWatchersTicketID watched by agent $WatchedBy ($Test->{Name})"
        );
    }
    $Success = $TicketObject->TicketStateSet(
        State    => $ClosedStates[0],
        TicketID => $AllWatchersTicketID,
        UserID   => 1,
    );
    $Self->True(
        $Success,
        "Ticket $AllWatchersTicketID set to $ClosedStates[0] ($Test->{Name})"
    );

    # Set time stamp specified in the test before running the console command
    $HelperObject->FixedTimeSetByTimeStamp( $Test->{TimeStamp} );

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => $Test->{CommandModule},
        Parameter     => $Test->{Parameter},
    );

    my $TrueSuccess = $Self->True(
        scalar IsHashRefWithData($Result),
        "ConsoleCommand returns a HashRef with data ($Test->{Name})",
    );
    return 1 if !$TrueSuccess;

    $Self->Is(
        $Result->{ExitCode},
        $Test->{ExitCode},
        "Expected ExitCode ($Test->{Name})",
    );

    STD:
    for my $STD (qw(STDOUT STDERR)) {

        next STD if !IsStringWithData( $Test->{$STD} );

        $Self->True(
            index( $Result->{$STD}, $Test->{$STD} ) > -1,
            "$STD contains '$Test->{ $STD }' ($Test->{Name})",
        );
    }

    my $IsInvalidArgsTest = grep { $_ eq '-42' } @{ $Test->{Parameter} };
    next TEST if $IsInvalidArgsTest;

    if ( grep { $_ eq '--no-invalid-users' } @{ $Test->{Parameter} } ) {
        @Watchers = $TicketObject->TicketWatchGet(
            TicketID => $AllWatchersTicketID,
            Result   => 'ARRAY',
        );
        $Self->Is(
            scalar(@Watchers),
            $Test->{Watchers},
            "Ticket watched by an invalid user has that user left watching after cleanup using --non-invalid-users ($Test->{Name})"
        );
        next TEST;
    }

    @Watchers = $TicketObject->TicketWatchGet(
        TicketID => $OpenTicketID,
        Result   => 'ARRAY',
    );
    $Self->Is(
        scalar(@Watchers),
        2,
        "Open ticket $OpenTicketID has two watchers after cleanup ($Test->{Name})"
    );

    for my $ClosedTicketID ( sort keys %ClosedTickets ) {
        @Watchers = $TicketObject->TicketWatchGet(
            TicketID => $ClosedTicketID,
            Result   => 'ARRAY',
        );
        my $ExpectedWatchers = $Test->{Watchers} // $ClosedTickets{$ClosedTicketID};
        $Self->Is(
            scalar(@Watchers),
            $ExpectedWatchers,
            "Closed ticket $ClosedTicketID has $ExpectedWatchers watchers after cleanup ($Test->{Name})"
        );
    }
}

1;
