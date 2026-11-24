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

my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $ActivityObject  = $Kernel::OM->Get('Kernel::System::Activity');
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');
my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $TicketActivityTransportObject
    = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::Activity');
my $CalendarActivityTransportObject = $Kernel::OM->Get('Kernel::System::Calendar::Event::Transport::Activity');

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
# IsValidLink()
#
my $TicketLink = $ActivityObject->GetLink( TicketID => 1 );

my @LinkTests = (
    {
        Name     => 'http URL',
        Link     => 'http://foo.invalid/',
        Expected => 1,
    },
    {
        Name     => 'https URL with query string',
        Link     => 'https://foo.invalid/index.pl?Action=AgentTicketZoom;TicketID=1',
        Expected => 1,
    },
    {
        Name     => 'Relative URL',
        Link     => 'index.pl?Action=AgentTicketZoom;TicketID=1',
        Expected => 1,
    },
    {
        Name     => 'Link from GetLink()',
        Link     => $TicketLink,
        Expected => 1,
    },
    {
        Name     => 'Empty string',
        Link     => '',
        Expected => 0,
    },
    {
        Name     => 'Undefined',
        Link     => undef,
        Expected => 0,
    },
    {
        Name     => 'javascript scheme',
        Link     => 'javascript:alert(1)',
        Expected => 0,
    },
    {
        Name     => 'javascript scheme in mixed case',
        Link     => 'JaVaScRiPt:alert(1)',
        Expected => 0,
    },
    {
        Name     => 'javascript scheme with leading space',
        Link     => ' javascript:alert(1)',
        Expected => 0,
    },
    {
        Name     => 'javascript scheme with tab',
        Link     => "java\tscript:alert(1)",
        Expected => 0,
    },
    {
        Name     => 'data scheme',
        Link     => 'data:text/html,alert(1)',
        Expected => 0,
    },
    {
        Name     => 'Protocol-relative URL',
        Link     => '//evil.invalid/',
        Expected => 0,
    },
    {
        Name     => 'HTML attribute break-out',
        Link     => '#"><u>marker</u><a href="#',
        Expected => 0,
    },
);

for my $Test (@LinkTests) {
    my $IsValid = $ActivityObject->IsValidLink(
        Link => $Test->{Link},
    );

    $Self->Is(
        $IsValid ? 1 : 0,
        $Test->{Expected},
        "IsValidLink() - $Test->{Name}",
    );
}

#
# Add() and Update() reject invalid state and link
#
my $InvalidActivityID = $ActivityObject->Add(
    Type     => 'activitytype',
    Title    => 'a title',
    Text     => 'nothing special',
    State    => 'new',
    Link     => '#"><u>marker</u><a href="#',
    CreateBy => $TestUserID,
    UserID   => $TestUserID,
);
$Self->False(
    $InvalidActivityID,
    'Add() - invalid link is rejected',
);

$InvalidActivityID = $ActivityObject->Add(
    Type     => 'activitytype',
    Title    => 'a title',
    Text     => 'nothing special',
    State    => 'x" onmouseover="alert(1)',
    Link     => 'http://foo.invalid/',
    CreateBy => $TestUserID,
    UserID   => $TestUserID,
);
$Self->False(
    $InvalidActivityID,
    'Add() - invalid state is rejected',
);

my $UpdateActivityID = $ActivityObject->Add(
    Type     => 'activitytype',
    Title    => 'update test',
    Text     => 'nothing special',
    State    => 'new',
    Link     => 'http://foo.invalid/',
    CreateBy => $TestUserID,
    UserID   => $TestUserID,
);
$Self->True(
    $UpdateActivityID,
    'Add() - activity for update tests created',
);

my $Success = $ActivityObject->Update(
    ID     => $UpdateActivityID,
    State  => 'seen',
    UserID => $TestUserID,
);
$Self->True(
    $Success,
    'Update() - state updated',
);

my %UpdatedActivity = $ActivityObject->Get(
    ID     => $UpdateActivityID,
    UserID => $TestUserID,
);
$Self->Is(
    $UpdatedActivity{State},
    'seen',
    'Update() - state is seen',
);
$Self->Is(
    $UpdatedActivity{Title},
    'update test',
    'Update() - title is unchanged',
);
$Self->Is(
    $UpdatedActivity{Link},
    'http://foo.invalid/',
    'Update() - link is unchanged',
);

$Success = $ActivityObject->Update(
    ID     => $UpdateActivityID,
    Link   => 'javascript:alert(1)',
    UserID => $TestUserID,
);
$Self->False(
    $Success,
    'Update() - invalid link is rejected',
);

$Success = $ActivityObject->Update(
    ID     => $UpdateActivityID,
    State  => 'x" onmouseover="alert(1)',
    UserID => $TestUserID,
);
$Self->False(
    $Success,
    'Update() - invalid state is rejected',
);

%UpdatedActivity = $ActivityObject->Get(
    ID     => $UpdateActivityID,
    UserID => $TestUserID,
);
$Self->Is(
    $UpdatedActivity{Link},
    'http://foo.invalid/',
    'Update() - link is unchanged after rejected update',
);
$Self->Is(
    $UpdatedActivity{State},
    'seen',
    'Update() - state is unchanged after rejected update',
);

my $HTMLTitle = '<b>bold</b> title';
$Success = $ActivityObject->Update(
    ID     => $UpdateActivityID,
    Title  => $HTMLTitle,
    UserID => $TestUserID,
);
$Self->True(
    $Success,
    'Update() - title updated',
);

%UpdatedActivity = $ActivityObject->Get(
    ID     => $UpdateActivityID,
    UserID => $TestUserID,
);
$Self->Is(
    $UpdatedActivity{Title},
    $HTMLUtilsObject->ToAscii( String => $HTMLTitle ),
    'Update() - title is converted to plain text',
);

$Success = $ActivityObject->Update(
    ID     => $UpdateActivityID,
    State  => 'new',
    UserID => 1,
);
$Self->False(
    $Success,
    'Update() - activity of another user cannot be updated',
);

#
# HeaderActivity template escapes all values
#
$LayoutObject->Block(
    Name => 'ActivityList',
    Data => {
        ID         => 1,
        State      => 'new"><u>state</u>',
        Link       => '#"><u>marker</u><a href="#',
        LinkTarget => '_self',
        Icon       => 'fa fa-ticket',
        Title      => '<img src=x onerror=alert(1)>',
        Text       => '<u>text</u>',
        CreateTime => '2026-11-09 12:00:00',
    },
);

my $Output = $LayoutObject->Output(
    TemplateFile => 'HeaderActivity',
);

$Self->False(
    scalar $Output =~ m{<u>|<img}xms,
    'HeaderActivity - output contains no unescaped markup',
);
$Self->True(
    index( $Output, '&lt;img src=x onerror=alert(1)&gt;' ) != -1,
    'HeaderActivity - title is HTML-escaped',
);
$Self->True(
    index( $Output, 'href="#&quot;&gt;&lt;u&gt;marker&lt;/u&gt;&lt;a href=&quot;#"' ) != -1,
    'HeaderActivity - link is HTML-escaped',
);

#
# Notification transports store an entity-encoded subject as decoded plain text, the bell must escape it
#
my $EncodedSubject = "CVD &lt;img src=x onerror=fetch('/cvd-xss-fired')&gt;";
my $DecodedSubject = "CVD <img src=x onerror=fetch('/cvd-xss-fired')>";

my @TransportTests = (
    {
        Name            => 'Ticket notification transport',
        TransportObject => $TicketActivityTransportObject,
        Params          => {
            TicketID => 123,
        },
    },
    {
        Name            => 'Appointment notification transport',
        TransportObject => $CalendarActivityTransportObject,
        Params          => {
            AppointmentID => 456,
            CalendarID    => 1,
            Event         => 'AppointmentCreate',
        },
    },
);

for my $Test (@TransportTests) {
    my @ActivitiesBefore    = $ActivityObject->ListGet( UserID => $TestUserID );
    my %ExistingActivityIDs = map { $_->{ID} => 1 } @ActivitiesBefore;

    my $Sent = $Test->{TransportObject}->SendNotification(
        %{ $Test->{Params} },
        UserID       => 1,
        Notification => {
            Name    => 'Activity XSS test',
            Subject => $EncodedSubject,
            Body    => 'Activity bell XSS probe.',
        },
        Recipient => {
            UserID       => $TestUserID,
            Type         => 'Agent',
            UserFullname => $TestUserLogin,
        },
    );
    $Self->True(
        $Sent,
        "$Test->{Name} - notification sent",
    );

    my @ActivitiesAfter = $ActivityObject->ListGet( UserID => $TestUserID );
    my @NewActivities   = grep { !$ExistingActivityIDs{ $_->{ID} } } @ActivitiesAfter;

    $Self->Is(
        scalar @NewActivities,
        1,
        "$Test->{Name} - one activity created",
    );

    my $Activity = $NewActivities[0] // {};

    $Self->Is(
        $Activity->{Title},
        $DecodedSubject,
        "$Test->{Name} - title is stored as decoded plain text",
    );

    $LayoutObject->Block(
        Name => 'ActivityList',
        Data => {
            %{$Activity},
            LinkTarget => '_self',
        },
    );

    my $TransportOutput = $LayoutObject->Output(
        TemplateFile => 'HeaderActivity',
    );

    $Self->False(
        scalar $TransportOutput =~ m{<img}xms,
        "$Test->{Name} - bell output contains no img element",
    );
    $Self->True(
        index( $TransportOutput, '&lt;img src=x onerror=' ) != -1,
        "$Test->{Name} - title is HTML-escaped in bell output",
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
