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

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $BasePluginObject  = $Kernel::OM->Get('Kernel::System::Calendar::Plugin::Base');
my $PluginObject      = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');

my %Param;
my $Success;
my $RandomID = $HelperObject->GetRandomID();

$HelperObject->FixedTimeSetByTimeStamp('2022-04-07 21:11:00');

my $GroupName = 'test-calendar-plugin-base-' . $RandomID;
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

# RenderOutput
my @Tests = (
    {
        Name => 'Base - UnitTestTicketCreate',
        Data => {
            Param       => \%Param,
            GetParam    => {},
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => '1000',
                Param     => {
                    CustomerID => 'customer',
                },
            },
            PermissionLevel => 7,         # rw
            UserID          => $UserID,
        },
        Expected => '',
    },
);

for my $Test (@Tests) {

    my $HTML = $BasePluginObject->RenderOutput(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $HTML,
        $Test->{Expected},
        'RenderOutput - ' . $Test->{Name},
    );
}

# Create / Update / Delete
@Tests = (
    {
        Name            => 'Single appointment',
        AppointmentData => {
            CalendarID => $Calendar{CalendarID},
            Title      => 'Single appointment',
            StartTime  => '2016-01-01 16:00:00',
            EndTime    => '2016-01-01 17:00:00',
            AllDay     => 1,
            UserID     => $UserID,
        },
        ListData => {
            CalendarID => $Calendar{CalendarID},
            StartTime  => '2016-01-01 00:00:00',
            EndTime    => '2016-01-06 00:00:00',
        },
        CreatePluginData => {
            GetParam    => {},
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    LockID     => 1,
                    OwnerID    => 1,
                    PriorityID => 1,
                },
            },
            UserID => $UserID,
        },
        UpdatePluginData => {
            GetParam    => {},
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    CustomerID     => 'customer',
                    CustomerUserID => 'customer',
                    Link           => 1,
                    LockID         => 1,
                    OwnerID        => 1,
                    PriorityID     => 1,
                    QueueID        => 1,
                },
            },
            UserID => $UserID,
        },
        DeletePluginData => {
            GetParam    => {},
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    CustomerID => 'customer',
                },
            },
            UserID => $UserID,
        },
        Expected => {
            Count     => 1,
            StartTime => [
                '2016-01-01 16:00:00',
            ],
            EndTime => [
                '2016-01-01 17:00:00',
            ],
            CreatePluginData => {
                PluginKey  => 'UnitTestTicketCreate',
                ChangeBy   => $UserID,
                ChangeTime => '2022-04-07 21:11:00',
                Config     => {
                    LockID     => 1,
                    OwnerID    => 1,
                    PriorityID => 1,
                },
                CreateBy   => $UserID,
                CreateTime => '2022-04-07 21:11:00',
            },
            UpdatePluginData => {
                PluginKey  => 'UnitTestTicketCreate',
                ChangeBy   => $UserID,
                ChangeTime => '2022-04-07 21:11:00',
                Config     => {
                    CustomerID     => 'customer',
                    CustomerUserID => 'customer',
                    Link           => 1,
                    LockID         => 1,
                    OwnerID        => 1,
                    PriorityID     => 1,
                    QueueID        => 1,
                },
                CreateBy   => $UserID,
                CreateTime => '2022-04-07 21:11:00',
            },
            RecurringAppointments => 0,
        },
    },
    {
        Name            => 'Recurring - Once per day',
        AppointmentData => {
            CalendarID         => $Calendar{CalendarID},
            Title              => 'Recurring appointment',
            StartTime          => '2016-02-01 16:00:00',
            EndTime            => '2016-02-01 17:00:00',
            AllDay             => 1,
            Recurring          => 1,
            RecurrenceType     => 'Daily',
            RecurrenceInterval => 1,                         # once per day
            RecurrenceUntil    => '2016-02-06 00:00:00',     # included last day
            UserID             => $UserID,
        },
        ListData => {
            CalendarID => $Calendar{CalendarID},
            StartTime  => '2016-02-01 00:00:00',
            EndTime    => '2016-02-06 00:00:00',
        },
        CreatePluginData => {
            GetParam => {
                Recurring => 1
            },
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    LockID     => 1,
                    OwnerID    => 1,
                    PriorityID => 1,
                },
            },
            UserID => $UserID,
        },
        UpdatePluginData => {
            GetParam => {
                Recurring => 1
            },
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    CustomerID     => 'customer',
                    CustomerUserID => 'customer',
                    Link           => 1,
                    LockID         => 1,
                    OwnerID        => 1,
                    PriorityID     => 1,
                    QueueID        => 1,
                },
            },
            UserID => $UserID,
        },
        DeletePluginData => {
            GetParam => {
                Recurring => 1
            },
            Appointment => {},
            Plugin      => {
                Name      => 'Ticket Create',
                PluginKey => 'UnitTestTicketCreate',
                Block     => 'Ticket',
                Module    => 'Kernel::System::Calendar::Plugin::Ticket::Create',
                Prio      => 1000,
                Param     => {
                    CustomerID => 'customer',
                },
            },
            UserID => $UserID,
        },
        Expected => {
            Count     => 5,
            StartTime => [
                '2016-02-01 16:00:00',
                '2016-02-02 16:00:00',
                '2016-02-03 16:00:00',
                '2016-02-04 16:00:00',
                '2016-02-05 16:00:00',
            ],
            EndTime => [
                '2016-02-01 17:00:00',
                '2016-02-02 17:00:00',
                '2016-02-03 17:00:00',
                '2016-02-04 17:00:00',
                '2016-02-05 17:00:00',
            ],
            CreatePluginData => {
                PluginKey  => 'UnitTestTicketCreate',
                ChangeBy   => $UserID,
                ChangeTime => '2022-04-07 21:11:00',
                Config     => {
                    LockID     => 1,
                    OwnerID    => 1,
                    PriorityID => 1,
                },
                CreateBy   => $UserID,
                CreateTime => '2022-04-07 21:11:00',
            },
            UpdatePluginData => {
                PluginKey  => 'UnitTestTicketCreate',
                ChangeBy   => $UserID,
                ChangeTime => '2022-04-07 21:11:00',
                Config     => {
                    CustomerID     => 'customer',
                    CustomerUserID => 'customer',
                    Link           => 1,
                    LockID         => 1,
                    OwnerID        => 1,
                    PriorityID     => 1,
                    QueueID        => 1,
                },
                CreateBy   => $UserID,
                CreateTime => '2022-04-07 21:11:00',
            },
            RecurringAppointments => 5,
        },
    },

);

for my $Test (@Tests) {

    my $AppointmentID = $AppointmentObject->AppointmentCreate(
        %{ $Test->{AppointmentData} },
    );

    $Self->True(
        $AppointmentID,
        $Test->{Name} . " - AppointmentCreate - " . $AppointmentID,
    );

    # check count
    my @Appointments = $AppointmentObject->AppointmentList(
        %{ $Test->{ListData} // {} },
    );

    $Self->Is(
        scalar @Appointments,
        $Test->{Expected}->{Count},
        $Test->{Name} . " - List count",
    );

    # check start times
    my @StartTimes;
    for my $Appointment (@Appointments) {
        push @StartTimes, $Appointment->{StartTime};
    }
    $Self->IsDeeply(
        \@StartTimes,
        $Test->{Expected}->{StartTime},
        $Test->{Name} . " - Start time result",
    );

    # check end times
    my @EndTimes;
    for my $Appointment (@Appointments) {
        push @EndTimes, $Appointment->{EndTime};
    }

    $Self->IsDeeply(
        \@EndTimes,
        $Test->{Expected}->{EndTime},
        $Test->{Name} . " - End time result",
    );

    my %Appointment = $AppointmentObject->AppointmentGet(
        AppointmentID => $AppointmentID,
    );

    $Test->{CreatePluginData}->{Appointment} = \%Appointment;
    $Test->{UpdatePluginData}->{Appointment} = \%Appointment;
    $Test->{DeletePluginData}->{Appointment} = \%Appointment;

    # create
    $Success = $BasePluginObject->Update(
        %{ $Test->{CreatePluginData} },
    );

    $Self->True(
        $Success,
        $Test->{Name} . " - create via Update",
    );

    my %Data = $PluginObject->DataGet(
        AppointmentID => $AppointmentID,
        PluginKey     => $Test->{CreatePluginData}->{Plugin}->{PluginKey},
        UserID        => 1,
    );

    $Self->IsDeeply(
        \%Data,
        {
            ID            => $Data{ID},
            AppointmentID => $AppointmentID,
            %{ $Test->{Expected}->{CreatePluginData} },
        },
        $Test->{Name} . ' - Update IsDeeply',
    );

    # delete
    $Success = $BasePluginObject->Delete(
        %{ $Test->{DeletePluginData} },
    );

    # update
    $Success = $BasePluginObject->Update(
        %{ $Test->{UpdatePluginData} },
    );

    $Self->True(
        $Success,
        $Test->{Name} . " - update via Update",
    );

    %Data = $PluginObject->DataGet(
        AppointmentID => $AppointmentID,
        PluginKey     => $Test->{UpdatePluginData}->{Plugin}->{PluginKey},
        UserID        => 1,
    );

    $Self->IsDeeply(
        \%Data,
        {
            ID            => $Data{ID},
            AppointmentID => $AppointmentID,
            %{ $Test->{Expected}->{UpdatePluginData} },
        },
        $Test->{Name} . ' - Update IsDeeply',
    );

    my @RecurringAppointments = $AppointmentObject->AppointmentRecurringGet(
        AppointmentID => $AppointmentID,
    );

    $Self->Is(
        scalar @RecurringAppointments,
        $Test->{Expected}->{RecurringAppointments},
        $Test->{Name} . ' - AppointmentRecurringGet',
    );

    my @Data = $PluginObject->DataListGet(
        PluginKey => $Test->{CreatePluginData}->{Plugin}->{PluginKey},
        UserID    => 1,
    );

    $Self->Is(
        scalar @Data,
        $Test->{Expected}->{RecurringAppointments} + 1,
        $Test->{Name} . ' - DataListGet',
    );

    # delete
    $Success = $BasePluginObject->Delete(
        %{ $Test->{DeletePluginData} },
    );

    $Self->True(
        $Success,
        $Test->{Name} . " - Delete",
    );

    $AppointmentObject->AppointmentDelete(
        AppointmentID => $AppointmentID,
        UserID        => 1,
    );

    @RecurringAppointments = $AppointmentObject->AppointmentRecurringGet(
        AppointmentID => $AppointmentID,
    );

    $Self->Is(
        scalar @RecurringAppointments,
        0,
        $Test->{Name} . ' - AppointmentRecurringGet',
    );
}

1;
