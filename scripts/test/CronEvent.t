# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

# Broken on certain Perl 5.28 versions due to a Perl crash that we can't work around.
my @BlacklistPerlVersions = (
    v5.26.1,
    v5.26.3,
    v5.28.1,
    v5.28.2,
    v5.30.0,
    v5.30.1,
    v5.30.2,
    v5.30.3,
);

if ( grep { $^V eq $_ } @BlacklistPerlVersions ) {
    $Self->True( 1, "Current Perl version $^V is known to be buggy for this test, skipping." );
    return 1;
}

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
$ConfigObject->Set(
    Key   => 'OTRSTimeZone',
    Value => 'UTC',
);

my $SystemTime = $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch();

# NextEventGet() tests
my @Tests = (
    {
        Name    => 'No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'No Schedule',
        Config => {
            StartTimeStamp => '2015-12-12 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule minute (greater)',
        Config => {
            Schedule => '60 * * * * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule minute (lower)',
        Config => {
            Schedule => '-1 * * * * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule hour (greater)',
        Config => {
            Schedule => '* 24 * * * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule hour (lower)',
        Config => {
            Schedule => '* -1 * * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule day of month (greater)',
        Config => {
            Schedule => '* * 32 * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule day of month (lower)',
        Config => {
            Schedule => '* * 0 * *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule month (greater)',
        Config => {
            Schedule => '* * * 13 *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule month (lower)',
        Config => {
            Schedule => '* * * 0 *',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule day of week (greater)',
        Config => {
            Schedule => '* * * * 8',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule day of week (lower)',
        Config => {
            Schedule => '* * * * -1',
        },
        Success => 0,
    },
    {
        Name   => 'Correct each 1 minute 0 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:00',
        },
        ExpectedValue => '2015-03-05 14:16:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 minute 30 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:30',
        },
        ExpectedValue => '2015-03-05 14:16:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 minute 59 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:59',
        },
        ExpectedValue => '2015-03-05 14:16:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 14:18:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 5 minutes',
        Config => {
            Schedule       => '*/5 * * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 14:20:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 hour',
        Config => {
            Schedule       => '0 * * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 15:00:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours',
        Config => {
            Schedule       => '0 */2 * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 16:00:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours on minute 30 (1)',
        Config => {
            Schedule       => '30 */2 * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 14:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours on minute 30 (2)',
        Config => {
            Schedule       => '30 */2 * * *',
            StartTimeStamp => '2015-03-05 14:36:00',
        },
        ExpectedValue => '2015-03-05 16:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct next day at 11:30',
        Config => {
            Schedule       => '30 11 * * *',
            StartTimeStamp => '2015-01-05 14:36:00',
        },
        ExpectedValue => '2015-01-06 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct on day 12th at 11:30',
        Config => {
            Schedule       => '30 11 12 * *',
            StartTimeStamp => '2015-12-05 14:36:00',
        },
        ExpectedValue => '2015-12-12 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct next month at 11:30',
        Config => {
            Schedule       => '30 11 5 * *',
            StartTimeStamp => '2015-03-05 14:36:00',
        },
        ExpectedValue => '2015-04-05 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes (next year)',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-12-31 23:59:00',
        },
        ExpectedValue => '2016-01-01 00:00:00',
        Success       => 1,
    },
    {
        Name   => 'Not existing date April 31',
        Config => {
            Schedule       => '2 2 31 4 *',
            StartTimeStamp => '2015-01-01 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'Not existing date February 30',
        Config => {
            Schedule       => '2 2 30 2 *',
            StartTimeStamp => '2015-01-01 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'Existing date February 29',
        Config => {
            Schedule       => '2 2 29 2 *',
            StartTimeStamp => '2015-01-01 00:00:00',
        },
        ExpectedValue => '2016-02-29 02:02:00',
        Success       => 1,
    },
    {
        Name   => 'Correct daylight saving time date each hour',
        Config => {
            Schedule       => '0 * * * *',
            StartTimeStamp => '2021-03-28 01:00:00',
            TimeZone       => 'Europe/Belgrade',
        },
        ExpectedValue => '2021-03-28 03:00:00',
        Success       => 1,
    },
);

# get cron event object
my $CronEventObject = $Kernel::OM->Get('Kernel::System::CronEvent');

for my $Test (@Tests) {

    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => $Test->{Config}->{TimeZone},
        );
    }

    if ( $Test->{Config}->{StartTimeStamp} ) {
        $Test->{Config}->{StartDateTime} = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{Config}->{StartTimeStamp},
            },
        );
    }

    my $EventTimeStamp = $CronEventObject->NextEventGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {

        $Self->Is(
            $EventTimeStamp,
            $Test->{ExpectedValue},
            "$Test->{Name} NextEvent() - Human TimeStamp Match",
        );
    }
    else {
        $Self->Is(
            $EventTimeStamp,
            undef,
            "$Test->{Name} NextEvent()",
        );
    }

    # Reset back OTRSTimeZone if it was changed.
    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => 'UTC',
        );
    }
}

# NextEventList() tests
@Tests = (
    {
        Name    => 'No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'No Schedule',
        Config => {
            StartTimeStamp => '2015-03-05 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'No StopTimeStamp',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 00:00:00',

        },
        Success => 0,
    },
    {
        Name   => 'Lower StoptimeStamp',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 00:00:01',
            StopTimeStamp  => '2015-03-05 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'Correct very small range (empty)',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 00:00:00',
            StopTimeStamp  => '2015-03-05 00:00:01',
        },
        ExpectedValue => [],
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 14:15:00',
            StopTimeStamp  => '2015-03-05 14:16:00'
        },
        ExpectedValue => ['2015-03-05 14:16:00'],
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes (2)',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 14:15:00',
            StopTimeStamp  => '2015-03-05 14:31:00'
        },
        ExpectedValue => [
            '2015-03-05 14:16:00',
            '2015-03-05 14:18:00',
            '2015-03-05 14:20:00',
            '2015-03-05 14:22:00',
            '2015-03-05 14:24:00',
            '2015-03-05 14:26:00',
            '2015-03-05 14:28:00',
            '2015-03-05 14:30:00',
        ],
        Success => 1,
    },
    {
        Name   => 'Correct each hour',
        Config => {
            Schedule       => '0 * * * *',
            StartTimeStamp => '2015-03-05 14:15:00',
            StopTimeStamp  => '2015-03-05 17:31:00'
        },
        ExpectedValue => [
            '2015-03-05 15:00:00',
            '2015-03-05 16:00:00',
            '2015-03-05 17:00:00',
        ],
        Success => 1,
    },

    {
        Name   => 'Correct each month on 1st at 1 AM (year overlapping)',
        Config => {
            Schedule       => '0 1 1 * *',
            StartTimeStamp => '2014-03-05 14:15:00',
            StopTimeStamp  => '2015-01-05 17:31:00'
        },
        ExpectedValue => [
            '2014-04-01 01:00:00',
            '2014-05-01 01:00:00',
            '2014-06-01 01:00:00',
            '2014-07-01 01:00:00',
            '2014-08-01 01:00:00',
            '2014-09-01 01:00:00',
            '2014-10-01 01:00:00',
            '2014-11-01 01:00:00',
            '2014-12-01 01:00:00',
            '2015-01-01 01:00:00',
        ],
        Success => 1,
    },
    {
        Name   => 'Correct daylight saving time each 10 minutes',
        Config => {
            Schedule       => '*/10 * * * *',
            StartTimeStamp => '2021-03-28 01:00:00',
            StopTimeStamp  => '2021-03-28 04:00:00',
            TimeZone       => 'Europe/Belgrade'
        },
        ExpectedValue => [
            '2021-03-28 01:10:00',
            '2021-03-28 01:20:00',
            '2021-03-28 01:30:00',
            '2021-03-28 01:40:00',
            '2021-03-28 01:50:00',
            '2021-03-28 03:00:00',
            '2021-03-28 03:10:00',
            '2021-03-28 03:20:00',
            '2021-03-28 03:30:00',
            '2021-03-28 03:40:00',
            '2021-03-28 03:50:00',
            '2021-03-28 04:00:00',
        ],
        Success => 1,
    },
);

for my $Test (@Tests) {

    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => $Test->{Config}->{TimeZone},
        );
    }

    if ( $Test->{Config}->{'StartTimeStamp'} ) {
        $Test->{Config}->{StartDateTime} = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{Config}->{'StartTimeStamp'},
            },
        );
    }
    if ( $Test->{Config}->{'StopTimeStamp'} ) {
        $Test->{Config}->{StopDateTime} = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{Config}->{'StopTimeStamp'},
            },
        );
    }

    my @NextEvents = $CronEventObject->NextEventList( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {

        $Self->IsDeeply(
            \@NextEvents,
            $Test->{ExpectedValue},
            "$Test->{Name} NextEventList() - Human TimeStamp Match",
        );
    }
    else {
        $Self->IsDeeply(
            \@NextEvents,
            [],
            "$Test->{Name} NextEventList()",
        );
    }

    # Reset back OTRSTimeZone if it was changed.
    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => 'UTC',
        );
    }
}

# PreviousEventList() tests
@Tests = (
    {
        Name    => 'No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'No Schedule',
        Config => {
            StartDate => '2015-12-12 00:00:00',
        },
        Success => 0,
    },
    {
        Name   => 'Invalid Schedule minute (greater)',
        Config => {
            Schedule => '60 * * * * *',
        },
        Success => 0,
    },

    {
        Name   => 'Correct each 1 minute 0 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:00',
        },
        ExpectedValue => '2015-03-05 14:15:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 minute 30 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:30',
        },
        ExpectedValue => '2015-03-05 14:15:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 minute 59 secs',
        Config => {
            Schedule       => '*/1 * * * *',
            StartTimeStamp => '2015-03-05 14:15:59',
        },
        ExpectedValue => '2015-03-05 14:15:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes',
        Config => {
            Schedule       => '*/2 * * * *',
            StartTimeStamp => '2015-03-05 14:15:59',
        },
        ExpectedValue => '2015-03-05 14:14:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 5 minutes',
        Config => {
            Schedule       => '*/5 * * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 14:15:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 1 hour',
        Config => {
            Schedule       => '0 * * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 14:00:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours',
        Config => {
            Schedule       => '0 */2 * * *',
            StartTimeStamp => '2015-03-05 13:59:50',
        },
        ExpectedValue => '2015-03-05 12:00:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours on minute 30 (1)',
        Config => {
            Schedule       => '30 */2 * * *',
            StartTimeStamp => '2015-03-05 14:16:00',
        },
        ExpectedValue => '2015-03-05 12:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 hours on minute 30 (2)',
        Config => {
            Schedule       => '30 */2 * * *',
            StartTimeStamp => '2015-03-05 14:36:00',
        },
        ExpectedValue => '2015-03-05 14:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct previous day at 11:30',
        Config => {
            Schedule       => '30 11 * * *',
            StartTimeStamp => '2015-01-05 10:36:00',
        },
        ExpectedValue => '2015-01-04 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct on day 12th at 11:30',
        Config => {
            Schedule       => '30 11 12 * *',
            StartTimeStamp => '2015-11-05 11:29:00',
        },
        ExpectedValue => '2015-10-12 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct previous month at 11:30',
        Config => {
            Schedule       => '30 11 5 * *',
            StartTimeStamp => '2015-03-05 10:36:00',
        },
        ExpectedValue => '2015-02-05 11:30:00',
        Success       => 1,
    },
    {
        Name   => 'Correct each 2 minutes (previous year)',
        Config => {
            Schedule       => '*/2 23 * * *',
            StartTimeStamp => '2016-01-01 00:00:00',
        },
        ExpectedValue => '2015-12-31 23:58:00',
        Success       => 1,
    },
    {
        Name   => 'Correct daylight saving time date on 30 minutes',
        Config => {
            Schedule       => '30 * * * *',
            StartTimeStamp => '2021-03-28 03:15:00',
            TimeZone       => 'Europe/Belgrade',
        },
        ExpectedValue => '2021-03-28 01:30:00',
        Success       => 1,
    },
);

for my $Test (@Tests) {

    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => $Test->{Config}->{TimeZone},
        );
    }

    if ( $Test->{Config}->{StartTimeStamp} ) {
        $Test->{Config}->{StartDateTime} = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{Config}->{StartTimeStamp},
            },
        );
    }

    my $EventTimeStamp = $CronEventObject->PreviousEventGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {

        $Self->Is(
            $EventTimeStamp,
            $Test->{ExpectedValue},
            "$Test->{Name} PreviousEvent() - Human TimeStamp Match",
        );
    }
    else {
        $Self->Is(
            $EventTimeStamp,
            undef,
            "$Test->{Name} NextEvent()",
        );
    }

    # Reset back OTRSTimeZone if it was changed.
    if ( $Test->{Config}->{TimeZone} ) {
        $ConfigObject->Set(
            Key   => 'OTRSTimeZone',
            Value => 'UTC',
        );
    }
}

# GenericAgentSchedule2CronTab() tests
@Tests = (
    {
        Name    => 'Empty Config',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'Missing ScheduleMinutes',
        Config => {
            ScheduleHours => [20],
            ScheduleDays  => [7],
        },
        Success => 0,
    },
    {
        Name   => 'Missing ScheduleHours',
        Config => {
            ScheduleMinutes => [5],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Missing ScheduleDays',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleMinutes format',
        Config => {
            ScheduleMinutes => '05',
            ScheduleHours   => [20],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleHours format',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => '20',
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleDays format',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
            ScheduleDays    => '6',
        },
        Success => 0,
    },
    {
        Name   => 'Empty ScheduleMinutes',
        Config => {
            ScheduleMinutes => [],
            ScheduleHours   => [20],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Empty ScheduleHours',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Empty ScheduleDays',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
            ScheduleDays    => [],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleMinutes data',
        Config => {
            ScheduleMinutes => ['a'],
            ScheduleHours   => [20],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleHours data',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => ['a'],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleDays data',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
            ScheduleDays    => ['a'],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleMinutes lower limit',
        Config => {
            ScheduleMinutes => [-1],
            ScheduleHours   => [20],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleHours lower limit',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [-1],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleDays lower limit',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
            ScheduleDays    => [-1],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleMinutes upper limit',
        Config => {
            ScheduleMinutes => [60],
            ScheduleHours   => [20],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleHours upper limit',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [60],
            ScheduleDays    => [6],
        },
        Success => 0,
    },
    {
        Name   => 'Wrong ScheduleDays upper limit',
        Config => {
            ScheduleMinutes => [5],
            ScheduleHours   => [20],
            ScheduleDays    => [7],
        },
        Success => 0,
    },
    {
        Name   => 'Each hour on minute 20',
        Config => {
            ScheduleMinutes => [20],
            ScheduleHours   => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ],
            ScheduleDays    => [ 0, 1, 2, 3, 4, 5, 6 ]
        },
        ExpectedValue => '20 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 * * 1,2,3,4,5,6,7',
        Success       => 1,
    },
    {
        Name   => '1-10 minutes On hour 13',
        Config => {
            ScheduleMinutes => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
            ScheduleHours   => [13],
            ScheduleDays    => [ 0, 1, 2, 3, 4, 5, 6 ]
        },
        ExpectedValue => '1,2,3,4,5,6,7,8,9,10 13 * * 1,2,3,4,5,6,7',
        Success       => 1,
    },
    {
        Name   => '20 - 30 minutes from 9 to 11 each Sunday',
        Config => {
            ScheduleMinutes => [ 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 ],
            ScheduleHours   => [ 9,  10, 11 ],
            ScheduleDays    => [0],
        },
        ExpectedValue => '20,21,22,23,24,25,26,27,28,29,30 9,10,11 * * 7',
        Success       => 1,
    },
    {
        Name   => '40 to 35 minutes at 11 pm each Monday',
        Config => {
            ScheduleMinutes => [ 40, 41, 42, 43, 44, 45 ],
            ScheduleHours   => [23],
            ScheduleDays    => [1],
        },
        ExpectedValue => '40,41,42,43,44,45 23 * * 1',
        Success       => 1,
    },
    {
        Name   => 'On minute 51 at 1 and 2 pm each Saturday',
        Config => {
            ScheduleMinutes => [51],
            ScheduleHours   => [ 13, 14 ],
            ScheduleDays    => [6],
        },
        ExpectedValue => '51 13,14 * * 6',
        Success       => 1,
    },
    {
        Name   => 'Only Wednesday at 7pm o\'clock',
        Config => {
            ScheduleMinutes => [0],
            ScheduleHours   => [19],
            ScheduleDays    => [3],
        },
        ExpectedValue => '0 19 * * 3',
        Success       => 1,
    },
    {
        Name   => 'Only Tuesdays and Fridays at 10:30, 10:45 and 20:30, 20:45',
        Config => {
            ScheduleMinutes => [ 30, 45 ],
            ScheduleHours   => [ 10, 20 ],
            ScheduleDays    => [ 2,  5 ],
        },
        ExpectedValue => '30,45 10,20 * * 2,5',
        Success       => 1,
    },
);

TESTCASE:
for my $Test (@Tests) {

    my $Schedule = $CronEventObject->GenericAgentSchedule2CronTab( %{ $Test->{Config} } );

    if ( !$Test->{Success} ) {
        $Self->Is(
            $Schedule,
            undef,
            "$Test->{Name} GenericAgentSchedule2CronTab() - result should be undef",
        );

        next TESTCASE;
    }

    $Self->Is(
        $Schedule,
        $Test->{ExpectedValue},
        "$Test->{Name} GenericAgentSchedule2CronTab() - result",
    );

    my $EventSystemTime = $CronEventObject->NextEventGet(
        Schedule => $Schedule,
    );
    $Self->IsNot(
        $EventSystemTime,
        undef,
        "$Test->{Name} GenericAgentSchedule2CronTab() - next event should not be undef",
    );

}
1;
