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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $AppointmentObject  = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $CalendarObject     = $Kernel::OM->Get('Kernel::System::Calendar');
my $GroupObject        = $Kernel::OM->Get('Kernel::System::Group');
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject  = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::AppointmentRemove');

my $GroupID = $GroupObject->GroupLookup(
    Group => 'users',
);

my $CalendarName = 'Calendar ' . $HelperObject->GetRandomNumber();
my %Calendar     = $CalendarObject->CalendarCreate(
    CalendarName => $CalendarName,
    GroupID      => $GroupID,
    Color        => '#FF7700',
    UserID       => 1,
    ValidID      => 1,
);

my @DynamicFields = (
    {
        Name       => 'AppointmentID',
        Label      => 'AppointmentID',
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

my $AppointmentID = $AppointmentObject->AppointmentCreate(
    UserID                     => 1,
    CalendarID                 => $Calendar{CalendarID},
    Title                      => 'Webinar',
    StartTime                  => '2021-01-01',
    EndTime                    => '2021-01-02',
    DynamicField_AppointmentID => 'AppointmentID',
    UserID                     => 1,
);
my %Appointment = $AppointmentObject->AppointmentGet(
    AppointmentID => $AppointmentID,
    CalendarID    => $Calendar{CalendarID},
);
$Self->Is(
    $Appointment{Title},
    'Webinar',
    'Appointment got created successfully',
);

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'AppointmentID',
);
$BackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $AppointmentID,
    UserID             => 1,
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);
$Self->True(
    $Ticket{DynamicField_AppointmentID},
    'DynamicField_AppointmentID got filled correctly',
);

my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        AppointmentID => '<OTRS_TICKET_DynamicField_AppointmentID>',
        UserID        => 1,
    },
);
$Self->True(
    $TransitionActionResult,
    'TransitionActionObject->Run()',
);

my %DeletedAppointment = $AppointmentObject->AppointmentGet(
    AppointmentID => $Ticket{DynamicField_AppointmentID},
    CalendarID    => $Calendar{CalendarID},
);
$Self->False(
    $DeletedAppointment{AppointmentID},
    'Appointment got deleted successfully',
);

1;
