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
        RestoreDatabase => 0,
    },
);

my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $PluginObject      = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');
my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');

my $Config = $ConfigObject->Get('AppointmentCalendar::Plugin::TicketCreate');

my $TicketCreateCatchUpThresholdMinutes = $Config->{TicketCreateCatchUpThreshold} // 5;
my $TicketCreateCatchUpThresholdSeconds = $TicketCreateCatchUpThresholdMinutes * 60;

my $RandomID         = $HelperObject->GetRandomID();
my $TicketCreateTime = '2019-06-02 22:45:00';

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
        Name          => "Run without ticket.",
        CommandModule => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Generate',
        Parameter     => [],
        ExitCode      => 0,
        Ticket        => 0,
        STDOUT        => qr/Number of created tickets:.*?\b0\b/,
        STDERR        => undef,
    },
    {
        Name                => "Run with ticket within catch-up threshold.",
        CommandModule       => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Generate',
        Parameter           => [],
        Ticket              => 1,
        ExitCode            => 0,
        FixedTimeAddSeconds => $TicketCreateCatchUpThresholdSeconds
            - 1,    # Ticket will be created because it's within catch-up threshold
        STDOUT => qr/Number of created tickets:.*?\b1\b/,
        STDERR => undef,
    },
    {
        Name          => "Run with ticket but exceeded catch-up threshold.",
        CommandModule => 'Kernel::System::Console::Command::Maint::Calendar::Ticket::Generate',
        Parameter     => [],
        Ticket        => 1,
        FixedTimeAddSeconds => 2,    # Ticket won't be created due to exceeded catch-up threshold
        ExitCode            => 0,
        STDOUT => qr/Number of created tickets:.*?\b0\b/,
        ,
        STDERR => undef,
    },
);

for my $Test (@Tests) {
    if ( $Test->{Ticket} ) {

        $HelperObject->FixedTimeAddSeconds( $Test->{FixedTimeAddSeconds} );

        # create test appointment
        my $AppointmentID = $AppointmentObject->AppointmentCreate(
            CalendarID => $Calendar{CalendarID},
            Title      => 'Test appointment ' . $RandomID,
            StartTime  => '2016-01-01 12:00:00',
            EndTime    => '2016-01-01 13:00:00',
            TimezoneID => 0,
            UserID     => 1,
        );

        $Self->True(
            $AppointmentID,
            "AppointmentCreate() - $AppointmentID",
        );

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

# delete all plugin data
my @Plugins = $PluginObject->DataListGet(
    UserID => 1,
);

for my $Plugin (@Plugins) {

    $PluginObject->DataDelete(
        ID     => $Plugin->{ID},
        UserID => 1,
    );
}

1;
