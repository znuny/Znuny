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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::AppointmentCreate');

my $GroupID = $GroupObject->GroupLookup(
    Group => 'users',
);

my %Calendar = $CalendarObject->CalendarCreate(
    CalendarName => 'Calendar 1',
    GroupID      => $GroupID,
    Color        => '#FF7700',
    UserID       => 1,
    ValidID      => 1,
);

my @DynamicFields = (
    {
        Name       => 'appid',
        Label      => 'appid',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
            Link         => '',
        },
    },
);
$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

my $TicketID = $HelperObject->TicketCreate(
    Queue => 'Raw',
);
my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        CalendarName               => 'Calendar 1',
        Title                      => 'Webinar',
        StartTime                  => '2016-01-01',
        EndTime                    => '2016-01-02',
        DynamicField_AppointmentID => 'appid',
        UserID                     => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    'TransitionActionObject->Run()',
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    $Ticket{DynamicField_appid},
    'DynamicField_AppointmentID got filled correctly',
);

my %Appointment = $AppointmentObject->AppointmentGet(
    AppointmentID => $Ticket{DynamicField_appid},
    CalendarID    => $Calendar{CalendarID},
);

$Self->Is(
    $Appointment{Title},
    'Webinar',
    'Appointment got created successfully',
);

1;
