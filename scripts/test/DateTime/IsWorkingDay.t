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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# Make Monday a vacation day in calendar 2 so overrides are testable.
my $TimeVacationDays2 = $ConfigObject->Get('TimeVacationDays::Calendar2');
$TimeVacationDays2->{1}->{5} = 'Calendar 2 holiday';

# Give calendar 2 working hours on Sunday.
my $TimeWorkingHours2 = $ConfigObject->Get('TimeWorkingHours::Calendar2');
$TimeWorkingHours2->{Sun} = [ 8, 9, 10, 11, 12 ];

my @TestConfigs = (
    {
        Params => {
            Year  => 2026,
            Month => 1,
            Day   => 5,      # Monday
        },
        ExpectedResult => 1,
    },
    {
        Params => {
            Year  => 2026,
            Month => 1,
            Day   => 4,      # Sunday
        },
        ExpectedResult => 0,
    },
    {
        Params => {
            Year  => 2026,
            Month => 1,
            Day   => 3,      # Saturday
        },
        ExpectedResult => 0,
    },
    {
        Params => {
            Year  => 2026,
            Month => 1,
            Day   => 1,      # New Year's Day (Thursday)
        },
        ExpectedResult => 0,
    },
    {
        Params => {
            Year     => 2026,
            Month    => 1,
            Day      => 5,      # Monday, vacation in calendar 2
            Calendar => 2,
        },
        ExpectedResult => 0,
    },
    {
        Params => {
            Year     => 2026,
            Month    => 1,
            Day      => 4,      # Sunday with working hours in calendar 2
            Calendar => 2,
        },
        ExpectedResult => 1,
    },
);

for my $TestConfig (@TestConfigs) {
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => $TestConfig->{Params},
    );

    my $CalendarStr = $TestConfig->{Params}->{Calendar} ? " Calendar: $TestConfig->{Params}->{Calendar}" : '';
    my $TestName
        = "$TestConfig->{Params}->{Year}-$TestConfig->{Params}->{Month}-$TestConfig->{Params}->{Day}" . $CalendarStr;

    $Self->Is(
        $DateTimeObject->IsWorkingDay(
            Calendar => $TestConfig->{Params}->{Calendar},
        ),
        $TestConfig->{ExpectedResult},
        "$TestName IsWorkingDay()",
    );
}

1;
