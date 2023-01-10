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

my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $PluginObject      = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');
my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');

my $TicketCreateTime = '2019-06-02 22:45:00';
my $RandomID         = $HelperObject->GetRandomID();

$HelperObject->FixedTimeSetByTimeStamp($TicketCreateTime);

my %Calendar = $CalendarObject->CalendarCreate(
    CalendarName => 'Test Calendar ' . $RandomID,
    Color        => '#3A87AD',
    GroupID      => 1,
    UserID       => 1,
);

$Self->True(
    $Calendar{CalendarID},
    "CalendarCreate() - $Calendar{CalendarID}",
);

my @Tests = (
    {
        Name          => "Run without any data.",
        CommandModule => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Cleanup',
        Parameter     => [],
        ExitCode      => 0,
        STDOUT        => qr/Number of deleted calendar base ticket creation data:.*?\b0\b/,
        STDERR        => undef,
    },
    {
        Name          => "Run with valid appointment.",
        CommandModule => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Cleanup',
        Parameter     => [],
        Appointment   => {
            Title => 'Test with valid appointment ' . $RandomID,
        },
        PluginData => {
            PluginKey => 'TicketCreate',
        },
        ExitCode => 0,
        STDOUT   => qr/Number of deleted calendar base ticket creation data:.*?\b0\b/,
        STDERR   => undef,
    },
    {
        Name          => "Run with invalid appointment.",
        CommandModule => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Cleanup',
        Parameter     => [],
        Appointment   => {
            Title => 'Test with valid appointment ' . $RandomID,
        },
        PluginData => {
            PluginKey     => 'TicketCreate',
            AppointmentID => '1',
        },
        ExitCode => 0,
        STDOUT   => qr/Number of deleted calendar base ticket creation data:.*?\b1\b/,
        STDERR   => undef,
    },
);

for my $Test (@Tests) {

    my $AppointmentID;

    if ( $Test->{Appointment} ) {

        $HelperObject->FixedTimeAddSeconds( $Test->{FixedTimeAddSeconds} );

        # create test appointment
        $AppointmentID = $AppointmentObject->AppointmentCreate(
            CalendarID => $Calendar{CalendarID},
            Title      => 'Test appointment ' . $RandomID,
            StartTime  => '2016-01-01 12:00:00',
            EndTime    => '2016-01-01 13:00:00',
            TimezoneID => 0,
            UserID     => 1,
            %{ $Test->{Appointment} },
        );

        $Self->True(
            $AppointmentID,
            "AppointmentCreate() - $AppointmentID",
        );
    }

    if ( $Test->{PluginData} ) {

        # create test appointment plugin data
        my $CreatedID = $PluginObject->DataAdd(
            AppointmentID => $AppointmentID,
            PluginKey     => 'TicketCreate',
            Config        => {
                QueueID           => 1,
                LockID            => 1,
                Link              => 1,
                TypeID            => 1,
                ServiceID         => 1,
                SLAID             => 1,
                PriorityID        => 1,
                StateID           => 1,
                UserID            => 1,
                ResponsibleUserID => 1,
                CustomerID        => 1,
                CustomerUserID    => 1,
                TicketCreated     => 0,
                TicketCreateTime  => $TicketCreateTime,
                OwnerID           => 1,
            },
            CreateBy => 1,
            ChangeBy => 1,
            UserID   => 1,
            %{ $Test->{PluginData} },
        );
    }

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => $Test->{CommandModule},
        Parameter     => $Test->{Parameter},
    );

    $Self->True(
        scalar IsHashRefWithData($Result),
        "ConsoleCommand returns a HashRef with data ($Test->{Name})",
    ) || return 1;

    $Self->Is(
        $Result->{ExitCode},
        $Test->{ExitCode},
        "Expected ExitCode ($Test->{Name})",
    );

    STREAM:
    for my $Stream (qw(STDOUT STDERR)) {
        next STREAM if !defined $Test->{$Stream};

        $Self->True(
            scalar( $Result->{$Stream} =~ m{$Test->{$Stream}}sm ),
            "$Stream contains '$Test->{ $Stream }' ($Test->{Name})",
        );
    }
}

1;
