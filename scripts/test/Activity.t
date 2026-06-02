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

1;
