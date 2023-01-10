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

my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::AppointmentCreate');

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

my $AppointmentTitle1 = 'Appointment ' . $HelperObject->GetRandomNumber();
my $AppointmentTitle2 = 'Appointment ' . $HelperObject->GetRandomNumber();
my @Tests             = (
    {
        Name   => 'Create appointment',
        Config => {
            CalendarName               => $CalendarName,
            Title                      => $AppointmentTitle1,
            StartTime                  => '2022-01-01',
            EndTime                    => '2022-01-02',
            DynamicField_AppointmentID => 'AppointmentID',
            UserID                     => 1
        },
        Result => {
            Title     => $AppointmentTitle1,
            StartTime => '2022-01-01 00:00:00',
            EndTime   => '2022-01-02 00:00:00',
        },
    },
    {
        Name   => 'Create recurring appointment',
        Config => {
            CalendarName               => $CalendarName,
            Title                      => $AppointmentTitle2,
            StartTime                  => '2022-02-01 10:00:00',
            EndTime                    => '2022-02-02 11:00:00',
            DynamicField_AppointmentID => 'AppointmentID',
            UserID                     => 1,
            Recurring                  => '1',
            RecurrenceType             => 'CustomWeekly',
            RecurrenceFrequency        => '2, 3',
            RecurrenceID               => '2022-02-01 09:30:00',
            RecurrenceInterval         => 2,
            RecurrenceUntil            => '',
        },
        Result => {
            Title               => $AppointmentTitle2,
            StartTime           => '2022-02-01 10:00:00',
            EndTime             => '2022-02-02 11:00:00',
            RecurrenceFrequency => [
                2, 3
            ],
            RecurrenceID       => '2022-02-01 09:30:00',
            RecurrenceInterval => '2',
            RecurrenceType     => 'CustomWeekly',
            Recurring          => '1'
        },
    },
);

for my $Test (@Tests) {

    # run function
    my $TransitionActionResult = $TransitionActionObject->Run(
        UserID                   => 1,
        Ticket                   => \%Ticket,
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',
        Config                   => {
            %{ $Test->{Config} }
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
        $Ticket{DynamicField_AppointmentID},
        'DynamicField_AppointmentID got filled correctly',
    );

    my %Appointment = $AppointmentObject->AppointmentGet(
        AppointmentID => $Ticket{DynamicField_AppointmentID},
        CalendarID    => $Calendar{CalendarID},
    );

    for my $Field ( sort keys %{ $Test->{Result} } ) {

        $Self->IsDeeply(
            $Appointment{$Field},
            $Test->{Result}->{$Field},
            $Test->{Name} . ' - appointment field ' . $Field . ' is correct',
        );
    }
}

1;
