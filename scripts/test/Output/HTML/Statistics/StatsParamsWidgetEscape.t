
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
    'Kernel::Output::HTML::Layout' => {
        UserID    => 1,
        Lang      => 'en',
        SessionID => 123,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $StatsObject  = $Kernel::OM->Get('Kernel::System::Stats');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$Kernel::OM->Get('Kernel::Output::HTML::Layout');

my $StatisticContent = $MainObject->FileRead(
    Location => $ConfigObject->Get('Home') . '/var/stats/Stats.NewTickets.en.xml',
);
$Self->True(
    $StatisticContent,
    'Loaded NewTickets sample statistic',
);

my $StatID = $StatsObject->Import(
    Content => ${$StatisticContent},
    UserID  => 1,
);
$Self->True(
    $StatID,
    "Imported statistic StatID $StatID",
);

my $Stat = $StatsObject->StatsGet(
    StatID => $StatID,
    UserID => 1,
);
$Self->True(
    $Stat,
    'StatsGet() after import',
);

my $XAxis;
ATTRIBUTE:
for my $Attribute ( @{ $Stat->{UseAsXvalue} // [] } ) {
    next ATTRIBUTE if !$Attribute->{Selected};
    next ATTRIBUTE if ( $Attribute->{Element} // '' ) ne 'CreateTime';
    $XAxis = $Attribute;
    last ATTRIBUTE;
}

$Self->True(
    $XAxis,
    'Found selected CreateTime X-axis attribute',
);

# Mutate in memory only: the escape path must protect already-stored values too.
$XAxis->{TimeScaleCount}            = '1<img src=x onerror=alert(1)>';
$XAxis->{TimeRelativeCount}         = '2<img src=y>';
$XAxis->{TimeRelativeUpcomingCount} = '3<img src=z>';

my $ViewObject = $Kernel::OM->Get('Kernel::Output::HTML::Statistics::View');
my $HTML       = $ViewObject->StatsParamsWidget(
    Stat   => $Stat,
    UserID => 1,
);

$Self->True(
    $HTML,
    'StatsParamsWidget() rendered',
);

$Self->False(
    index( $HTML // '', '<img src=x' ) > -1,
    'TimeScaleCount: live img tag is not present',
);
$Self->True(
    index( $HTML // '', '&lt;img src=x' ) > -1,
    'TimeScaleCount: img markup is HTML-escaped',
);

$Self->False(
    index( $HTML // '', '<img src=y' ) > -1,
    'TimeRelativeCount: live img tag is not present',
);
$Self->True(
    index( $HTML // '', '&lt;img src=y' ) > -1,
    'TimeRelativeCount: img markup is HTML-escaped',
);

$Self->False(
    index( $HTML // '', '<img src=z' ) > -1,
    'TimeRelativeUpcomingCount: live img tag is not present',
);
$Self->True(
    index( $HTML // '', '&lt;img src=z' ) > -1,
    'TimeRelativeUpcomingCount: img markup is HTML-escaped',
);

1;
