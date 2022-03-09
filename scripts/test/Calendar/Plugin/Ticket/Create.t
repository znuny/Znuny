# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
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

my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CalendarObject           = $Kernel::OM->Get('Kernel::System::Calendar');
my $AppointmentObject        = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $GroupObject              = $Kernel::OM->Get('Kernel::System::Group');
my $TicketCreatePluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin::Ticket::Create');

my $TicketCreateTime = $TicketCreatePluginObject->CalculateTicketCreateTime(
    StartTimeStamp          => '2019-05-01 08:00:00',
    EndTimeStamp            => '2019-05-02 08:00:00',
    TicketCreateOffset      => 2,
    TicketCreateOffsetUnit  => 3600,
    TicketCreateOffsetPoint => 'beforestart',
);

$Self->Is(
    $TicketCreateTime,
    '2019-05-01 06:00:00',
    'CalculateTicketCreateTime beforestart',
);

$TicketCreateTime = $TicketCreatePluginObject->CalculateTicketCreateTime(
    StartTimeStamp          => '2019-05-01 08:00:00',
    EndTimeStamp            => '2019-05-02 08:00:00',
    TicketCreateOffset      => 2,
    TicketCreateOffsetUnit  => 3600,
    TicketCreateOffsetPoint => 'afterstart',
);

$Self->Is(
    $TicketCreateTime,
    '2019-05-01 10:00:00',
    'CalculateTicketCreateTime afterstart',
);

$TicketCreateTime = $TicketCreatePluginObject->CalculateTicketCreateTime(
    StartTimeStamp          => '2019-05-01 08:00:00',
    EndTimeStamp            => '2019-05-02 08:00:00',
    TicketCreateOffset      => 2,
    TicketCreateOffsetUnit  => 3600,
    TicketCreateOffsetPoint => 'beforeend',
);

$Self->Is(
    $TicketCreateTime,
    '2019-05-02 06:00:00',
    'CalculateTicketCreateTime beforeend',
);
$TicketCreateTime = $TicketCreatePluginObject->CalculateTicketCreateTime(
    StartTimeStamp          => '2019-05-01 08:00:00',
    EndTimeStamp            => '2019-05-02 08:00:00',
    TicketCreateOffset      => 2,
    TicketCreateOffsetUnit  => 3600,
    TicketCreateOffsetPoint => 'afterend',
);

$Self->Is(
    $TicketCreateTime,
    '2019-05-02 10:00:00',
    'CalculateTicketCreateTime afterend',
);

my $RandomID = $HelperObject->GetRandomID();

# create test group
my $GroupName = 'test-calendar-plugin-ticket-create-' . $RandomID;
my $GroupID   = $GroupObject->GroupAdd(
    Name    => $GroupName,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $GroupID,
    "Test group $GroupID created",
);

# create test user
my ( $UserLogin, $UserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'users', $GroupName ],
);

$Self->True(
    $UserID,
    "Test user $UserID created",
);

# create test calendar
my %Calendar = $CalendarObject->CalendarCreate(
    CalendarName => 'Test Calendar ' . $RandomID,
    Color        => '#3A87AD',
    GroupID      => $GroupID,
    UserID       => $UserID,
);

$Self->True(
    $Calendar{CalendarID},
    "CalendarCreate() - $Calendar{CalendarID}",
);

# create test appointment
my $AppointmentID = $AppointmentObject->AppointmentCreate(
    CalendarID => $Calendar{CalendarID},
    Title      => 'Test appointment ' . $RandomID,
    StartTime  => '2016-01-01 12:00:00',
    EndTime    => '2016-01-01 13:00:00',
    TimezoneID => 0,
    UserID     => $UserID,
);

$Self->True(
    $AppointmentID,
    "AppointmentCreate() - $AppointmentID",
);

1;
