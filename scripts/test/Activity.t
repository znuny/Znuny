# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## no critic (RequireExplicitPackage)

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

my $HelperObject   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
my $ActivityObject = $Kernel::OM->Get('Kernel::System::Activity');

my $HttpType    = $ConfigObject->Get('HttpType');
my $Hostname    = $ConfigObject->Get('FQDN');
my $ScriptAlias = $ConfigObject->Get('ScriptAlias') // '';
my $BaseURL     = "$HttpType://$Hostname/$ScriptAlias" . "index.pl";

my $ActivityConfig = $ConfigObject->Get('Activity') // {};
$ActivityConfig->{MaxKeepActivities} = 10;
$ConfigObject->Set( 'Activity', $ActivityConfig );

my @Tests = (
    {
        Name => 'TicketID',
        Data => {
            TicketID => 123,
        },
        Expected => $BaseURL . "?Action=AgentTicketZoom;TicketID=" . 123,
    },
    {
        Name => 'AppointmentID',
        Data => {
            AppointmentID => 456,
        },
        Expected => $BaseURL . "?Action=AgentAppointmentCalendarOverview;AppointmentID=" . 456,
    },
    {
        Create => 10,
        Name   => 'TicketID',
        Data   => {
            Type     => 'activitytype',
            Title    => 'a title',
            Text     => 'nothing special',
            State    => 'new',
            Link     => 'http://foo.invalid/',
            CreateBy => 1,
            UserID   => 1,
        },
        Expected => 10,
    },
    {
        Create => 1,
        Name   => 'TicketID',
        Data   => {
            Type     => 'activitytype',
            Title    => 'a title',
            Text     => 'nothing special',
            State    => 'new',
            Link     => 'http://foo.invalid/',
            CreateBy => 1,
            UserID   => 1,
        },
        Expected => 10,
    },
    {
        Create => 10,
        Name   => 'TicketID',
        Data   => {
            Type     => 'activitytype',
            Title    => 'a title',
            Text     => 'nothing special',
            State    => 'new',
            Link     => 'http://foo.invalid/',
            CreateBy => 1,
            UserID   => 1,
        },
        Expected => 10,
    },
);

TEST:
for my $Test (@Tests) {

    if ( $Test->{Create} ) {
        for my $ActivityNumber ( 1 .. $Test->{Create} ) {
            my $Success = $ActivityObject->Add(
                %{ $Test->{Data} }
            );
            $Self->True(
                $Success,
                "Created activity $ActivityNumber",
            );
        }

        my @Activities = $ActivityObject->ListGet(
            UserID => $Test->{Data}->{UserID},
        );
        $Self->Is(
            scalar @Activities,
            $Test->{Expected},
            "Found $Test->{Expected} activities",
        );
        next TEST;
    }
    my $String = $ActivityObject->GetLink(
        %{ $Test->{Data} }
    );

    $Self->Is(
        $String,
        $Test->{Expected},
        'GetLink - ' . $Test->{Name},
    );
}

#
# Specifically test limit of kept activities and that the oldest ones will be deleted first and for different users.
#
$ActivityConfig->{MaxKeepActivities} = 5;
$ConfigObject->Set( 'Activity', $ActivityConfig );

my $NumberOfActivitiesAboveLimit = 2;

my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();

my @UserIDs = ( 1, $TestUserID );
for my $UserID (@UserIDs) {

    # "+ $NumberOfActivitiesAboveLimit" over MaxKeepActivities to test that the oldest entries will be deleted.
    for my $ActivityNumber ( 1 .. $ActivityConfig->{MaxKeepActivities} + $NumberOfActivitiesAboveLimit ) {
        my $Success = $ActivityObject->Add(
            Type     => 'activitytype',
            Title    => "Limit test entry $UserID $ActivityNumber",
            Text     => 'nothing special',
            State    => 'new',
            Link     => 'http://foo.invalid/',
            CreateBy => $UserID,
            UserID   => 1,
        );

        $Self->True(
            $Success,
            "Created activity $ActivityNumber",
        );
    }
}

# Separate loop to be sure that activities for both users have been processed.
for my $UserID (@UserIDs) {
    my @ExistingActivities = $ActivityObject->DataListGet(
        CreateBy => $UserID,
        SortBy   => [ $ActivityObject->{Identifier}, ],
        OrderBy  => [ 'ASC', ],
        UserID   => 1,
    );

    my @ExistingActivityTitles = map { $_->{Title} } @ExistingActivities;
    my @ExpectedActivityTitles;

    # The oldest ones above the limit should have been deleted at this point.
    for my $ExpectedActivityNumber (
        1 + $NumberOfActivitiesAboveLimit .. $ActivityConfig->{MaxKeepActivities} + $NumberOfActivitiesAboveLimit
        )
    {
        push @ExpectedActivityTitles, "Limit test entry $UserID $ExpectedActivityNumber";
    }

    $Self->IsDeeply(
        \@ExistingActivityTitles,
        \@ExpectedActivityTitles,
        'Expected activities have been found.',
    );
}

#
# Test cleanup of excess activities for migration and backlog scenarios.
#
$ActivityConfig->{MaxKeepActivities} = 5;
$ConfigObject->Set( 'Activity', $ActivityConfig );

my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

my ( $CleanupUserLogin, $CleanupUserID ) = $HelperObject->TestUserCreate();

my $BacklogCount = 8;

for my $ActivityNumber ( 1 .. $BacklogCount ) {
    my $Success = $ActivityObject->DataAdd(
        Type     => 'activitytype',
        Title    => "Cleanup backlog $ActivityNumber",
        Text     => 'nothing special',
        State    => 'new',
        Link     => 'http://foo.invalid/',
        CreateBy => 1,
        UserID   => $CleanupUserID,
    );

    $Self->True(
        $Success,
        "Created backlog activity $ActivityNumber",
    );
}

my $ScheduledTaskCount = $ActivityObject->CleanupExcessActivities();

$Self->True(
    $ScheduledTaskCount,
    'CleanupExcessActivities scheduled cleanup tasks',
);

my @ScheduledTasks = $SchedulerDBObject->TaskList(
    Type => 'AsynchronousExecutor',
);

my $ExpectedTaskName = "Activity-TrimToMaxKeepActivities-UserID-$CleanupUserID-CreateBy-1";
my ($CleanupTask) = grep { ( $_->{Name} // '' ) eq $ExpectedTaskName } @ScheduledTasks;

$Self->True(
    $CleanupTask,
    'CleanupExcessActivities scheduled a cleanup task for the backlog activities',
);

my %CleanupTaskData;
if ($CleanupTask) {
    %CleanupTaskData = $SchedulerDBObject->TaskGet(
        TaskID => $CleanupTask->{TaskID},
    );
}

$Self->IsDeeply(
    $CleanupTaskData{Data},
    {
        Object   => 'Kernel::System::Activity',
        Function => 'TrimToMaxKeepActivities',
        Params   => {
            UserID   => $CleanupUserID,
            CreateBy => 1,
        },
    },
    'Scheduled cleanup task contains the expected payload',
);

# The scheduler daemon does not process tasks during unit tests, so run the trimming directly.
my $DeletedCount = $ActivityObject->TrimToMaxKeepActivities(
    UserID   => $CleanupUserID,
    CreateBy => 1,
);

$Self->Is(
    $DeletedCount,
    $BacklogCount - $ActivityConfig->{MaxKeepActivities},
    'TrimToMaxKeepActivities deleted the excess backlog activities',
);

my @RemainingActivities = $ActivityObject->DataListGet(
    CreateBy => 1,
    SortBy   => [ $ActivityObject->{Identifier}, ],
    OrderBy  => [ 'ASC', ],
    UserID   => $CleanupUserID,
);

$Self->Is(
    scalar @RemainingActivities,
    $ActivityConfig->{MaxKeepActivities},
    'Cleanup kept the configured number of activities',
);

my @RemainingActivityTitles = map { $_->{Title} } @RemainingActivities;
my @ExpectedRemainingTitles;

for my $ExpectedActivityNumber ( $BacklogCount - $ActivityConfig->{MaxKeepActivities} + 1 .. $BacklogCount ) {
    push @ExpectedRemainingTitles, "Cleanup backlog $ExpectedActivityNumber";
}

$Self->IsDeeply(
    \@RemainingActivityTitles,
    \@ExpectedRemainingTitles,
    'Cleanup kept the newest activities',
);

1;
