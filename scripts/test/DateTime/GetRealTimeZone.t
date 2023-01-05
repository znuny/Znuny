# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

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

use DateTime::TimeZone;

use Kernel::System::DateTime;

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

#
# Tests for creating DateTime object with time zone link.
# Time zone links are obsolete time zone names that are mapped to other valid time zones.
# It must be possible to use these but internally they should be mapped to the valid time zone.
# The DateTime object then also must report the valid time zone.
#
my %RealByLinkedTimeZones = DateTime::TimeZone->links();

# Reduce to three linked time zones for tests.
my $LinkedTimeZoneCounter = 0;
for my $LinkedTimeZone ( sort keys %RealByLinkedTimeZones ) {
    $LinkedTimeZoneCounter++;
    delete $RealByLinkedTimeZones{$LinkedTimeZone} if $LinkedTimeZoneCounter > 3;
}

#
# Tests for GetRealTimeZone.
#
LINKEDTIMEZONE:
for my $LinkedTimeZone ( sort keys %RealByLinkedTimeZones ) {
    my $RealTimeZone         = Kernel::System::DateTime->GetRealTimeZone( TimeZone => $LinkedTimeZone );
    my $ExpectedRealTimeZone = $RealByLinkedTimeZones{$LinkedTimeZone};

    $Self->Is(
        scalar $RealTimeZone,
        $ExpectedRealTimeZone,
        "GetRealTimeZone() must report real time zone $ExpectedRealTimeZone for time zone $LinkedTimeZone.",
    );
}

my $RealTimeZone         = Kernel::System::DateTime->GetRealTimeZone( TimeZone => 'Europe/Berlin' );
my $ExpectedRealTimeZone = 'Europe/Berlin';

$Self->Is(
    scalar $RealTimeZone,
    $ExpectedRealTimeZone,
    "GetRealTimeZone() must report real time zone $ExpectedRealTimeZone for time zone 'Europe/Berlin'.",
);

$RealTimeZone = Kernel::System::DateTime->GetRealTimeZone( TimeZone => 'INVALIDTIMEZONE' );

$Self->False(
    $RealTimeZone,
    "GetRealTimeZone() must report false value for invalid time zone.",
);

#
# Tests for TimeZoneList()
#
my $TimeZones = Kernel::System::DateTime->TimeZoneList();
my %TimeZones = map { $_ => 1 } @{$TimeZones};

$Self->True(
    $TimeZones{'Europe/Berlin'},
    'TimeZoneList() without parameters must return list with time zone "Europe/Berlin".',
);
$Self->False(
    $TimeZones{'Africa/Kinshasa'},
    'TimeZoneList() without parameters must return list without obsolete time zone "Africa/Kinshasa".',
);

$TimeZones = Kernel::System::DateTime->TimeZoneList(
    IncludeTimeZone => 'Africa/Kinshasa',
);
%TimeZones = map { $_ => 1 } @{$TimeZones};

$Self->True(
    $TimeZones{'Africa/Kinshasa'},
    'TimeZoneList() with parameter IncludeTimeZone must return list with obsolete time zone "Africa/Kinshasa".',
);

$TimeZones = Kernel::System::DateTime->TimeZoneList(
    IncludeTimeZone => 'INVALIDTIMEZONE',
);
%TimeZones = map { $_ => 1 } @{$TimeZones};

$Self->False(
    $TimeZones{INVALIDTIMEZONE},
    'TimeZoneList() with parameter IncludeTimeZone with invalid time zone must return list without invalid time zone.',
);

#
# Tests for SystemTimeZoneGet()
#
my $ExpectedSystemTimeZone = 'Europe/Berlin';
local $ENV{TZ} = $ExpectedSystemTimeZone;
my $SystemTimeZone = Kernel::System::DateTime->SystemTimeZoneGet();

$Self->Is(
    $SystemTimeZone,
    $ExpectedSystemTimeZone,
    'System time zone must match expected one.'
);

1;
