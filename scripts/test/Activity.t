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

1;
