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

#
# Tests for date/time correction on switch to daylight saving time (DST).
#
# Example:
# 2:00 AM on the day of the DST switch from winter to summer time in time zone
# Europe/Berlin (1:59 AM switches to 3:00 AM) does not exist and should result in 3:00 AM.
#
my @TestConfigs = (
    {
        DateTimeParams => {
            Year     => 2022,
            Month    => 3,
            Day      => 27,
            Hour     => 2,
            Minute   => 5,
            Second   => 12,
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 27,
            Hour      => 3,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            String   => '2022-03-27 02:05:12',
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 27,
            Hour      => 3,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            Year     => 2022,
            Month    => 3,
            Day      => 27,
            Hour     => 1,
            Minute   => 5,
            Second   => 12,
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 27,
            Hour      => 1,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            String   => '2022-03-27 01:05:12',
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 27,
            Hour      => 1,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            Year     => 2022,
            Month    => 3,
            Day      => 27,
            Hour     => 3,
            Minute   => 5,
            Second   => 12,
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 27,
            Hour      => 3,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            Year     => 2022,
            Month    => 3,
            Day      => 26,
            Hour     => 2,
            Minute   => 5,
            Second   => 12,
            TimeZone => 'Europe/Berlin',
        },
        ExpectedResult => {
            Year      => 2022,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 26,
            Hour      => 2,
            Minute    => 5,
            Second    => 12,
            DayOfWeek => 6,
            DayAbbr   => 'Sat',
            TimeZone  => 'Europe/Berlin',
        },
    },
    {
        DateTimeParams => {
            Year     => 2021,
            Month    => 10,
            Day      => 3,
            Hour     => 2,
            Minute   => 34,
            Second   => 6,
            TimeZone => 'Australia/Sydney',
        },
        ExpectedResult => {
            Year      => 2021,
            Month     => 10,
            MonthAbbr => 'Oct',
            Day       => 3,
            Hour      => 3,
            Minute    => 34,
            Second    => 6,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'Australia/Sydney',
        },
    },
    {
        DateTimeParams => {
            Year     => 2021,
            Month    => 3,
            Day      => 14,
            Hour     => 2,
            Minute   => 53,
            Second   => 34,
            TimeZone => 'America/New_York',
        },
        ExpectedResult => {
            Year      => 2021,
            Month     => 3,
            MonthAbbr => 'Mar',
            Day       => 14,
            Hour      => 3,
            Minute    => 53,
            Second    => 34,
            DayOfWeek => 7,
            DayAbbr   => 'Sun',
            TimeZone  => 'America/New_York',
        },
    },
);

TESTCONFIG:
for my $TestConfig (@TestConfigs) {

    # Test for creation of new DateTime object.
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => $TestConfig->{DateTimeParams},
    );

    $Self->IsDeeply(
        $DateTimeObject->Get(),
        $TestConfig->{ExpectedResult},
        'Date and time must match the expected values for creation of new DateTime object.',
    );

    # Test for change of time zone for existing DateTime object.
    $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            %{ $TestConfig->{DateTimeParams} },
            TimeZone => 'floating',
        },
    );

    $DateTimeObject->ToTimeZone( TimeZone => $TestConfig->{DateTimeParams}->{TimeZone} );

    $Self->IsDeeply(
        $DateTimeObject->Get(),
        $TestConfig->{ExpectedResult},
        'Date and time must match the expected values for changing the time zone of an existing DateTime object.',
    );
}

# Test with invalid datetime params.
my $DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String   => 'invalid date/time string',
        TimeZone => 'Europe/Berlin',
    },
);

$Self->False(
    scalar $DateTimeObject,
    'Invalid date/time string must lead to failing DateTime object creation.',
);

$DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String   => '2021-02-30 12:12:12',
        TimeZone => 'Europe/Berlin',
    },
);

$Self->False(
    scalar $DateTimeObject,
    'Invalid date/time string must lead to failing DateTime object creation.',
);

$DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String   => '2021-02-28 52:82:62',
        TimeZone => 'Europe/Berlin',
    },
);

$Self->False(
    scalar $DateTimeObject,
    'Invalid date/time string must lead to failing DateTime object creation.',
);

1;
