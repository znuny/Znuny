# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
$ConfigObject->Set(
    Key   => 'TimeInputFormat',
    Value => 'Option',
);

my $SetConfig = sub {
    my %Param = @_;

    my $Success = $ConfigObject->Set(
        Key   => $Param{Key},
        Value => $Param{Value},
    );
    $Self->True(
        $Success,
        ( $Param{Message} || "SysConfig Set() for key $Param{Key}" ) . "with true",
    );
};

my @Tests = (

    {
        Name           => 'No options',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2016-02-10 09:04:23',                            # in OTRS time zone
        Config         => {},
        ExpectedValue  => '<select id="Month" name="Month" title="Month">
  <option value="2" selected="selected">02</option>
</select>
<select class=" " id="Day" name="Day" title="Day">
  <option value="10" selected="selected">10</option>
</select>
<select id="Year" name="Year" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>',
    },
    {
        Name           => 'No options',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2016-02-10 23:04:23',                            # in OTRS time zone
        Config         => {},
        ExpectedValue  => '<select id="Month" name="Month" title="Month">
  <option value="2" selected="selected">02</option>
</select>
<select class=" " id="Day" name="Day" title="Day">
  <option value="11" selected="selected">11</option>
</select>
<select id="Year" name="Year" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>',
    },
    {
        Name           => 'Long Format',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2016-02-10 09:04:23',    # in OTRS time zone
        Config         => {
            Format => 'DateInputFormatLong',
        },
        ExpectedValue => '<select id="Month" name="Month" title="Month">
  <option value="2" selected="selected">02</option>
</select>
<select class=" " id="Day" name="Day" title="Day">
  <option value="10" selected="selected">10</option>
</select>
<select id="Year" name="Year" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>
<select id="Hour" name="Hour" title="Hours">
  <option value="9" selected="selected">09</option>
</select>
<select id="Minute" name="Minute" title="Minutes">
  <option value="4" selected="selected">04</option>
</select>',
    },
    {
        Name           => 'Long Format',
        OTRSTimeZone   => 'Europe/Berlin',
        UserTimeZone   => 'America/New_York',
        DateTimeString => '2016-05-01 04:24:06',    # in OTRS time zone
        Config         => {
            Format => 'DateInputFormatLong',
        },
        ExpectedValue => '<select id="Month" name="Month" title="Month">
  <option value="4" selected="selected">04</option>
</select>
<select class=" " id="Day" name="Day" title="Day">
  <option value="30" selected="selected">30</option>
</select>
<select id="Year" name="Year" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>
<select id="Hour" name="Hour" title="Hours">
  <option value="22" selected="selected">22</option>
</select>
<select id="Minute" name="Minute" title="Minutes">
  <option value="24" selected="selected">24</option>
</select>',
    },
    {
        Name           => 'Optional',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2016-10-02 09:04:23',    # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" />
<select id="TestMonth" name="TestMonth" title="Month">
  <option value="10" selected="selected">10</option>
</select>
<select class=" " id="TestDay" name="TestDay" title="Day">
  <option value="2" selected="selected">02</option>
</select>
<select id="TestYear" name="TestYear" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>',
    },
    {
        Name           => 'Optional',
        OTRSTimeZone   => 'Europe/Berlin',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2016-10-02 00:04:23',    # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" />
<select id="TestMonth" name="TestMonth" title="Month">
  <option value="10" selected="selected">10</option>
</select>
<select class=" " id="TestDay" name="TestDay" title="Day">
  <option value="2" selected="selected">02</option>
</select>
<select id="TestYear" name="TestYear" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>',
    },
    {
        Name           => 'No Options (Input)',
        OTRSTimeZone   => 'Europe/Berlin',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2016-10-02 00:04:23',    # in OTRS time zone
        Config         => {},
        SetConfig      => {
            Key     => 'TimeInputFormat',
            Value   => 'Input',
            Message => 'Set TimeInputFormat to Input',
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="10" />
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="02" />
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2016" />',
    },
    {
        Name           => 'Long Format (Input)',
        OTRSTimeZone   => 'Europe/Berlin',
        UserTimeZone   => 'UTC',
        DateTimeString => '2016-10-02 00:04:23',    # in OTRS time zone
        Config         => {
            Format => 'DateInputFormatLong',
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="10" />
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="01" />
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2016" />
<input type="text" class="" name="Hour" id="Hour" size="2" maxlength="2" title="Hours" value="22" />
<input type="text" class="" name="Minute" id="Minute" size="2" maxlength="2" title="Minutes" value="04" />',
    },
    {
        Name           => 'Optional (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2016-06-08 23:04:23',    # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" />
<input type="text" class="" name="TestMonth" id="TestMonth" size="2" maxlength="2" title="Month" value="06" />
<input type="text" class=" " name="TestDay" id="TestDay" size="2" maxlength="2" title="Day" value="09" />
<input type="text" class="" name="TestYear" id="TestYear" size="4" maxlength="4" title="Year" value="2016" />',
    },

    # TODO: add more tests for the different parameters here!
    {
        Name           => 'Disabled',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2016-06-08 23:04:23',    # in OTRS time zone
        Config         => {
            Disabled => 1,
        },
        SetConfig => {
            Key     => 'TimeInputFormat',
            Value   => 'Option',
            Message => 'Set TimeInputFormat to Option',
        },
        ExpectedValue => '<select disabled="disabled" id="Month" name="Month" title="Month">
  <option value="6" selected="selected">06</option>
</select>
<select class=" " disabled="disabled" id="Day" name="Day" title="Day">
  <option value="8" selected="selected">08</option>
</select>
<select disabled="disabled" id="Year" name="Year" title="Year">
  <option value="2016" selected="selected">2016</option>
</select>',
    },
    {
        Name           => 'Disabled Long Format',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2014-06-08 23:24:23',    # in OTRS time zone
        Config         => {
            Format   => 'DateInputFormatLong',
            Disabled => 1,
        },
        ExpectedValue => '<select disabled="disabled" id="Month" name="Month" title="Month">
  <option value="6" selected="selected">06</option>
</select>
<select class=" " disabled="disabled" id="Day" name="Day" title="Day">
  <option value="9" selected="selected">09</option>
</select>
<select disabled="disabled" id="Year" name="Year" title="Year">
  <option value="2014" selected="selected">2014</option>
</select>
<select disabled="disabled" id="Hour" name="Hour" title="Hours">
  <option value="1" selected="selected">01</option>
</select>
<select disabled="disabled" id="Minute" name="Minute" title="Minutes">
  <option value="24" selected="selected">24</option>
</select>',
    },
    {
        Name           => 'Disabled Optional',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2014-06-08 23:24:23',    # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
            Disabled     => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" disabled="disabled"/>
<select disabled="disabled" id="TestMonth" name="TestMonth" title="Month">
  <option value="6" selected="selected">06</option>
</select>
<select class=" " disabled="disabled" id="TestDay" name="TestDay" title="Day">
  <option value="8" selected="selected">08</option>
</select>
<select disabled="disabled" id="TestYear" name="TestYear" title="Year">
  <option value="2014" selected="selected">2014</option>
</select>',
    },
    {
        Name           => 'Disabled (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2014-06-08 23:24:23',    # in OTRS time zone
        Config         => {
            Disabled => 1,
        },
        SetConfig => {
            Key     => 'TimeInputFormat',
            Value   => 'Input',
            Message => 'Set TimeInputFormat to Input',
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="08" readonly="readonly"/>
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>',
    },
    {
        Name           => 'Disabled (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2014-06-09 01:24:23',    # in OTRS time zone
        Config         => {
            Disabled => 1,
        },
        SetConfig => {
            Key     => 'TimeInputFormat',
            Value   => 'Input',
            Message => 'Set TimeInputFormat to Input',
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="09" readonly="readonly"/>
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>',
    },
    {
        Name           => 'Disabled Long Format (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2014-06-08 23:24:23',            # in OTRS time zone
        Config         => {
            Format   => 'DateInputFormatLong',
            Disabled => 1,
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="08" readonly="readonly"/>
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>
<input type="text" class="" name="Hour" id="Hour" size="2" maxlength="2" title="Hours" value="23" readonly="readonly"/>
<input type="text" class="" name="Minute" id="Minute" size="2" maxlength="2" title="Minutes" value="24" readonly="readonly"/>',
    },
    {
        Name           => 'Disabled Long Format (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2014-06-08 23:24:23',            # in OTRS time zone
        Config         => {
            Format   => 'DateInputFormatLong',
            Disabled => 1,
        },
        ExpectedValue =>
            '<input type="text" class="" name="Month" id="Month" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="Day" id="Day" size="2" maxlength="2" title="Day" value="09" readonly="readonly"/>
<input type="text" class="" name="Year" id="Year" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>
<input type="text" class="" name="Hour" id="Hour" size="2" maxlength="2" title="Hours" value="01" readonly="readonly"/>
<input type="text" class="" name="Minute" id="Minute" size="2" maxlength="2" title="Minutes" value="24" readonly="readonly"/>',
    },
    {
        Name           => 'Disabled Optional (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => undef,
        DateTimeString => '2014-06-08 23:24:23',         # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
            Disabled     => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" disabled="disabled"/>
<input type="text" class="" name="TestMonth" id="TestMonth" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="TestDay" id="TestDay" size="2" maxlength="2" title="Day" value="08" readonly="readonly"/>
<input type="text" class="" name="TestYear" id="TestYear" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>',
    },
    {
        Name           => 'Disabled Optional (Input)',
        OTRSTimeZone   => 'UTC',
        UserTimeZone   => 'Europe/Berlin',
        DateTimeString => '2014-06-08 23:24:23',         # in OTRS time zone
        Config         => {
            Prefix       => 'Test',
            TestOptional => 1,
            Disabled     => 1,
        },
        ExpectedValue =>
            '<input type="checkbox" name="TestUsed" id="TestUsed" value="1" class="" title="Check to activate this date" disabled="disabled"/>
<input type="text" class="" name="TestMonth" id="TestMonth" size="2" maxlength="2" title="Month" value="06" readonly="readonly"/>
<input type="text" class=" " name="TestDay" id="TestDay" size="2" maxlength="2" title="Day" value="09" readonly="readonly"/>
<input type="text" class="" name="TestYear" id="TestYear" size="4" maxlength="4" title="Year" value="2014" readonly="readonly"/>',
    },
);

TESTCASE:
for my $Test (@Tests) {

    $ConfigObject->Set(
        Key   => 'OTRSTimeZone',
        Value => $Test->{OTRSTimeZone},
    );

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Test->{DateTimeString},
        },
    );

    $Kernel::OM->ObjectParamAdd(
        'Kernel::Output::HTML::Layout' => {
            Lang         => 'en',
            UserTimeZone => $Test->{UserTimeZone},
        },
    );

    if ( $Test->{SetConfig} ) {
        $SetConfig->( %{ $Test->{SetConfig} } );
    }

    # run every test twice:
    # 1. Fixed date/time, BuildSelection retrieves its own date/time which will be the set fixed date/time
    # 2. Explicit date/time via parameters to BuildSelection
    #
    # Note: Due to calculation of TimeSecDiff in Kernel::System::Time based on the current date,
    # the Layout object has to be recreated within the test to be able to fetch a Time object
    # that has the fixed date/time set.
    for my $DateTimeAsParams ( 0, 1 ) {
        my %BuildSelectionParams = %{ $Test->{Config} };
        if ($DateTimeAsParams) {
            my $DateTimeValues = $DateTimeObject->Get();
            my $Prefix         = $BuildSelectionParams{Prefix} || '';
            $BuildSelectionParams{ $Prefix . 'Year' }   = $DateTimeValues->{Year};
            $BuildSelectionParams{ $Prefix . 'Month' }  = $DateTimeValues->{Month};
            $BuildSelectionParams{ $Prefix . 'Day' }    = $DateTimeValues->{Day};
            $BuildSelectionParams{ $Prefix . 'Hour' }   = $DateTimeValues->{Hour};
            $BuildSelectionParams{ $Prefix . 'Minute' } = $DateTimeValues->{Minute};
        }
        else {
            $HelperObject->FixedTimeSet( $DateTimeObject->ToEpoch() );
        }

        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
        my $HTML         = $LayoutObject->BuildDateSelection(%BuildSelectionParams);

        # remove non selected options for easy compare
        $HTML =~ s{\s+<option\s+value="\d+">\d+</option>}{}msxg;

        # remove /, : and - and convert them into new lines
        $HTML =~ s{</select>(?: / | : | \s-\s)<select}{</select>\n<select}msxg;
        $HTML =~ s{/>(?: / | : | \s-\s)<input}{/>\n<input}msxg;

        # remove checkbox space and convert it to new line
        $HTML =~ s{/>&nbsp;<}{/>\n<}msxg;

        $Self->Is(
            $HTML,
            $Test->{ExpectedValue},
            "BuildDateSelection(): $Test->{Name}, OTRS time zone $Test->{OTRSTimeZone}, "
                . ( $Test->{UserTimeZone} ? "user time zone $Test->{UserTimeZone}" : 'no user time zone' )
                . ", date/time " . ( $DateTimeAsParams ? 'as explicit parameters' : 'via fixed date/time' ),
        );

        $Kernel::OM->ObjectsDiscard(
            Objects => [ 'Kernel::Output::HTML::Layout', ],
        );

        $HelperObject->FixedTimeUnset();
    }
}

# DiffTime pending default: optionally skip weekends/holidays.
# These cases only use FixedTimeSet (no explicit Year/Month/Day override).
my @DiffTimeTests = (
    {
        Name                       => 'DiffTime Friday + 1 day, skip off lands on Saturday',
        DateTimeString             => '2026-01-09 10:00:00',                                   # Friday
        DiffTime                   => 86400,
        SkipUnavailableDays        => 0,
        PendingSkipUnavailableDays => 1,
        ExpectedDay                => 10,
        ExpectedMonth              => 1,
        ExpectedYear               => 2026,
    },
    {
        Name                       => 'DiffTime Friday + 1 day, skip on lands on Monday',
        DateTimeString             => '2026-01-09 10:00:00',                                   # Friday
        DiffTime                   => 86400,
        SkipUnavailableDays        => 1,
        PendingSkipUnavailableDays => 1,
        ExpectedDay                => 12,
        ExpectedMonth              => 1,
        ExpectedYear               => 2026,
    },
    {
        Name                       => 'DiffTime New Year\'s Eve + 1 day, skip on lands after New Year\'s Day',
        DateTimeString             => '2025-12-31 10:00:00',    # New Year's Eve (vacation)
        DiffTime                   => 86400,                    # -> Thursday Jan 1 holiday
        SkipUnavailableDays        => 1,
        PendingSkipUnavailableDays => 1,
        ExpectedDay                => 2,
        ExpectedMonth              => 1,
        ExpectedYear               => 2026,
    },
    {
        Name                       => 'DiffTime Friday + 1 day, skip on without pending flag stays Saturday',
        DateTimeString             => '2026-01-09 10:00:00',                                                    # Friday
        DiffTime                   => 86400,
        SkipUnavailableDays        => 1,
        PendingSkipUnavailableDays => 0,
        ExpectedDay                => 10,
        ExpectedMonth              => 1,
        ExpectedYear               => 2026,
    },
);

for my $Test (@DiffTimeTests) {

    $ConfigObject->Set(
        Key   => 'OTRSTimeZone',
        Value => 'UTC',
    );
    $ConfigObject->Set(
        Key   => 'TimeInputFormat',
        Value => 'Option',
    );
    $ConfigObject->Set(
        Key   => 'TimePendingSkipUnavailableDays',
        Value => $Test->{SkipUnavailableDays},
    );

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Test->{DateTimeString},
        },
    );
    $HelperObject->FixedTimeSet( $DateTimeObject->ToEpoch() );

    $Kernel::OM->ObjectParamAdd(
        'Kernel::Output::HTML::Layout' => {
            Lang         => 'en',
            UserTimeZone => 'UTC',
        },
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $HTML         = $LayoutObject->BuildDateSelection(
        DiffTime                   => $Test->{DiffTime},
        PendingSkipUnavailableDays => $Test->{PendingSkipUnavailableDays},
    );

    $HTML =~ s{\s+<option\s+value="\d+">\d+</option>}{}msxg;

    my $ExpectedValue = qq{<select id="Month" name="Month" title="Month">
  <option value="$Test->{ExpectedMonth}" selected="selected">}
        . sprintf( '%02d', $Test->{ExpectedMonth} )
        . qq{</option>
</select>
<select class=" " id="Day" name="Day" title="Day">
  <option value="$Test->{ExpectedDay}" selected="selected">} . sprintf( '%02d', $Test->{ExpectedDay} ) . qq{</option>
</select>
<select id="Year" name="Year" title="Year">
  <option value="$Test->{ExpectedYear}" selected="selected">$Test->{ExpectedYear}</option>
</select>};

    # remove /, : and - and convert them into new lines
    $HTML =~ s{</select>(?: / | : | \s-\s)<select}{</select>\n<select}msxg;

    $Self->Is(
        $HTML,
        $ExpectedValue,
        "BuildDateSelection(): $Test->{Name}",
    );

    $Kernel::OM->ObjectsDiscard(
        Objects => [ 'Kernel::Output::HTML::Layout', ],
    );
    $HelperObject->FixedTimeUnset();
}

1;
