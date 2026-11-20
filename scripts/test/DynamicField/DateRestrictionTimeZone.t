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

use CGI;

use Kernel::System::Web::Request;

my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $DFBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $UserID = 1;

my %DateTimeFieldOnlyPast = (
    ID         => 123,
    Name       => 'DateTimeField',
    Label      => 'DateTimeField',
    FieldOrder => 123,
    FieldType  => 'DateTime',
    ObjectType => 'Ticket',
    Config     => {
        DateRestriction => 'DisableFutureDates',
    },
    ValidID => 1,
);

my %DateFieldOnlyPast = (
    ID         => 123,
    Name       => 'DateField',
    Label      => 'DateField',
    FieldOrder => 123,
    FieldType  => 'Date',
    ObjectType => 'Ticket',
    Config     => {
        DateRestriction => 'DisableFutureDates',
    },
    ValidID => 1,
);

my $ZnunyTimeZone = Kernel::System::DateTime->ZnunyTimeZoneGet();

# 23:00 in the Znuny time zone, so a zone further east is already on the next day.
my $Anchor = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String   => '2026-11-04 23:00:00',
        TimeZone => $ZnunyTimeZone,
    },
);

$HelperObject->FixedTimeSet( $Anchor->ToEpoch() );

my $ZnunyNow   = $Kernel::OM->Create('Kernel::System::DateTime');
my $ZnunyToday = $ZnunyNow->Format( Format => '%Y-%m-%d' );

my $UserTimeZone;
my @CandidateTimeZones = (
    'Pacific/Kiritimati',
    'Pacific/Auckland',
    'Asia/Tokyo',
    'Europe/Helsinki',
);

CANDIDATE:
for my $Candidate (@CandidateTimeZones) {
    next CANDIDATE if $Candidate eq $ZnunyTimeZone;

    my $CandidateNow = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            TimeZone => $Candidate,
        },
    );
    my $CandidateToday = $CandidateNow->Format( Format => '%Y-%m-%d' );

    if ( $CandidateToday gt $ZnunyToday ) {
        $UserTimeZone = $Candidate;
        last CANDIDATE;
    }
}

$Self->True(
    $UserTimeZone ? 1 : 0,
    "Found a user time zone that is already on the next calendar day (Znuny zone $ZnunyTimeZone, today $ZnunyToday)",
);

if ($UserTimeZone) {

    my $UserNow = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            TimeZone => $UserTimeZone,
        },
    );
    my $UserToday = $UserNow->Format( Format => '%Y-%m-%d' );

    $Self->True(
        $UserToday gt $ZnunyToday ? 1 : 0,
        "User time zone $UserTimeZone is on $UserToday, after the Znuny day $ZnunyToday",
    );

    my $UserPast = $UserNow->Clone();
    $UserPast->Subtract( Minutes => 5 );
    my $UserPastParts = $UserPast->Get();

    my $UserFuture = $UserNow->Clone();
    $UserFuture->Add( Minutes => 30 );
    my $UserFutureParts = $UserFuture->Get();

    my $UserTomorrow = $UserNow->Clone();
    $UserTomorrow->Add( Days => 1 );
    my $UserTomorrowDate = $UserTomorrow->Format( Format => '%Y-%m-%d' );

    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::Output::HTML::Layout'] );
    $Kernel::OM->ObjectParamAdd(
        'Kernel::Output::HTML::Layout' => {
            Lang         => 'en',
            UserTimeZone => $UserTimeZone,
        },
    );
    $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $PastWebRequest = CGI->new(
        {
            DynamicField_DateTimeFieldUsed   => 1,
            DynamicField_DateTimeFieldYear   => $UserPastParts->{Year},
            DynamicField_DateTimeFieldMonth  => $UserPastParts->{Month},
            DynamicField_DateTimeFieldDay    => $UserPastParts->{Day},
            DynamicField_DateTimeFieldHour   => $UserPastParts->{Hour},
            DynamicField_DateTimeFieldMinute => $UserPastParts->{Minute},
        }
    );

    my $PastParamObject = Kernel::System::Web::Request->new(
        WebRequest => $PastWebRequest,
    );

    my $PastResult = $DFBackendObject->EditFieldValueValidate(
        DynamicFieldConfig => \%DateTimeFieldOnlyPast,
        ParamObject        => $PastParamObject,
    );

    $Self->False(
        $PastResult->{ServerError} || 0,
        'DateTime a few minutes ago in the user time zone is allowed when only past dates are allowed',
    );

    my $FutureWebRequest = CGI->new(
        {
            DynamicField_DateTimeFieldUsed   => 1,
            DynamicField_DateTimeFieldYear   => $UserFutureParts->{Year},
            DynamicField_DateTimeFieldMonth  => $UserFutureParts->{Month},
            DynamicField_DateTimeFieldDay    => $UserFutureParts->{Day},
            DynamicField_DateTimeFieldHour   => $UserFutureParts->{Hour},
            DynamicField_DateTimeFieldMinute => $UserFutureParts->{Minute},
        }
    );

    my $FutureParamObject = Kernel::System::Web::Request->new(
        WebRequest => $FutureWebRequest,
    );

    my $FutureResult = $DFBackendObject->EditFieldValueValidate(
        DynamicFieldConfig => \%DateTimeFieldOnlyPast,
        ParamObject        => $FutureParamObject,
    );

    $Self->Is(
        $FutureResult->{ServerError},
        1,
        'DateTime in the future of the user time zone is still rejected',
    );

    my ( $TodayYear, $TodayMonth, $TodayDay ) = split /-/, $UserToday;

    my $TodayWebRequest = CGI->new(
        {
            DynamicField_DateFieldUsed  => 1,
            DynamicField_DateFieldYear  => $TodayYear,
            DynamicField_DateFieldMonth => $TodayMonth,
            DynamicField_DateFieldDay   => $TodayDay,
        }
    );

    my $TodayParamObject = Kernel::System::Web::Request->new(
        WebRequest => $TodayWebRequest,
    );

    my $TodayResult = $DFBackendObject->EditFieldValueValidate(
        DynamicFieldConfig => \%DateFieldOnlyPast,
        ParamObject        => $TodayParamObject,
    );

    $Self->False(
        $TodayResult->{ServerError} || 0,
        'Date on the user calendar day is allowed when that day is still tomorrow in the Znuny time zone',
    );

    my $TodayValidate = $DFBackendObject->ValueValidate(
        DynamicFieldConfig => \%DateFieldOnlyPast,
        Value              => $UserToday . ' 00:00:00',
        UserID             => $UserID,
    );

    $Self->Is(
        $TodayValidate,
        1,
        'ValueValidate accepts the user calendar day for a past-only Date field',
    );

    my ( $TomorrowYear, $TomorrowMonth, $TomorrowDay ) = split /-/, $UserTomorrowDate;

    my $TomorrowWebRequest = CGI->new(
        {
            DynamicField_DateFieldUsed  => 1,
            DynamicField_DateFieldYear  => $TomorrowYear,
            DynamicField_DateFieldMonth => $TomorrowMonth,
            DynamicField_DateFieldDay   => $TomorrowDay,
        }
    );

    my $TomorrowParamObject = Kernel::System::Web::Request->new(
        WebRequest => $TomorrowWebRequest,
    );

    my $TomorrowResult = $DFBackendObject->EditFieldValueValidate(
        DynamicFieldConfig => \%DateFieldOnlyPast,
        ParamObject        => $TomorrowParamObject,
    );

    $Self->Is(
        $TomorrowResult->{ServerError},
        1,
        'Date after the user calendar day is rejected',
    );

    my $TomorrowValidate = $DFBackendObject->ValueValidate(
        DynamicFieldConfig => \%DateFieldOnlyPast,
        Value              => $UserTomorrowDate . ' 00:00:00',
        UserID             => $UserID,
    );

    $Self->Is(
        $TomorrowValidate,
        undef,
        'ValueValidate rejects the day after the user calendar day',
    );

    # Without a frontend layout the same user wall-clock time is read as Znuny time
    # and is still in the future.
    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::Output::HTML::Layout'] );

    my $PastWithoutLayout = $DFBackendObject->EditFieldValueValidate(
        DynamicFieldConfig => \%DateTimeFieldOnlyPast,
        ParamObject        => $PastParamObject,
    );

    $Self->Is(
        $PastWithoutLayout->{ServerError},
        1,
        'DateTime user wall-clock time is rejected when it is not converted from the user time zone',
    );

    my $TodayWithoutLayout = $DFBackendObject->ValueValidate(
        DynamicFieldConfig => \%DateFieldOnlyPast,
        Value              => $UserToday . ' 00:00:00',
        UserID             => $UserID,
    );

    $Self->Is(
        $TodayWithoutLayout,
        undef,
        'ValueValidate uses the Znuny calendar day when no frontend layout exists',
    );
}

$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::Output::HTML::Layout'] );
$HelperObject->FixedTimeUnset();

1;
