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

use Kernel::System::ObjectManager;
use Kernel::System::VariableCheck qw(:all);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'DBCRUDTest::EventModulePost###000-UnitTestAdd',    # setting name
    Value => {
        'Module' => 'Kernel::System::UnitTest::DBCRUD::Event::DBCRUD',
        'Event'  => '.*(Add|Update|Get|Search|Delete)',
    },
);

my $DBCRUDTestObject = $Kernel::OM->Get('Kernel::System::UnitTest::DBCRUD');
my $UUIDColumnName   = $DBCRUDTestObject->{UUIDDatabaseTableColumnName};

# Note: Exception: Here, the UUID column will be created via XML. This tests that auto-creation of UUID
# columns also recognizes already existing UUID columns.
$HelperObject->DatabaseXML(
    String => <<"EOF",
    <TableCreate Name="dbcrud_test">
        <Column AutoIncrement="true" Name="id" PrimaryKey="true" Required="true" Type="BIGINT"/>
        <Column Name="name" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="age" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="description" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="content_json" Required="false" Size="10000" Type="VARCHAR"/>
        <Column Name="create_time" Required="true" Type="DATE"/>
        <Column Name="change_time" Required="true" Type="DATE"/>
        <Column Name="$UUIDColumnName" Required="false" Type="VARCHAR" Size="36"/>
    </TableCreate>
EOF
);
$HelperObject->DatabaseXML(
    String => <<"EOF",
    <TableCreate Name="dbcrud_test_history">
        <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
        <Column Name="event" Required="false" Size="250" Type="VARCHAR"/>
        <Column Name="field" Required="false" Size="250" Type="VARCHAR"/>
        <Column Name="old_value" Required="false" Size="1800000" Type="VARCHAR"/>
        <Column Name="new_value" Required="false" Size="1800000" Type="VARCHAR"/>
        <Column Name="dbcrud_test_id" Required="true" Type="BIGINT"/>
        <Column Name="create_time" Required="false" Type="DATE"/>
        <Column Name="create_by" Required="false" Type="INTEGER"/>
        <Column Name="change_time" Required="false" Type="DATE"/>
        <Column Name="change_by" Required="false" Type="INTEGER"/>
        <Column Name="$UUIDColumnName" Required="false" Type="VARCHAR" Size="36"/>
    </TableCreate>
EOF
);

#
# create user
#

my $TimeStampCreate = '2017-12-05 14:00:00';
$HelperObject->FixedTimeSetByTimeStamp($TimeStampCreate);

my %User = (
    Name        => 'user 1',
    Age         => 21,
    Description => 'description user 1',
    ContentJSON => { First => { Value => 1 } },
);

$User{ID} = $DBCRUDTestObject->DataAdd(%User);

$Self->True(
    scalar $User{ID},
    "created user $User{Name} with ID $User{ID}",
);

#
# create update user on 14:30:00
#

$TimeStampCreate = '2017-12-05 14:30:00';
$HelperObject->FixedTimeSetByTimeStamp($TimeStampCreate);

my $Success = $DBCRUDTestObject->DataUpdate(
    %User,
    Name => 'user 1 change 1',
    Age  => 50,
);

$Self->True(
    scalar $Success,
    "updated user $User{Name} with ID $User{ID} to age 50",
);

#
# create update user on 15:00:00
#

$TimeStampCreate = '2017-12-05 15:00:00';
$HelperObject->FixedTimeSetByTimeStamp($TimeStampCreate);

$Success = $DBCRUDTestObject->DataUpdate(
    %User,
    Name => 'user 1 change 2',
    Age  => 75,
);

$Self->True(
    scalar $Success,
    "updated user $User{Name} with ID $User{ID} to age 50",
);

#
# check history data for 14:00:00
#

my %DataHistoryGet = $DBCRUDTestObject->DataHistoryGet(
    DBCRUDTestID => $User{ID},
    TimeStamp    => '2017-12-05 14:00:00',
);
$Self->True(
    %DataHistoryGet ? 1 : 0,
    "history data get (TimeStamp) user $User{Name} with ID $User{ID}",
);
$Self->Is(
    $DataHistoryGet{Age},
    21,
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has age 21",
);
$Self->Is(
    $DataHistoryGet{Name},
    'user 1',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has name 'user 1 change 1'",
);
$Self->Is(
    $DataHistoryGet{CreateTime},
    '2017-12-05 14:00:00',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has create time '2017-12-05 14:00:00'",
);

my $SystemTime = $TimeObject->TimeStamp2SystemTime(
    String => '2017-12-05 14:00:00',
);
%DataHistoryGet = $DBCRUDTestObject->DataHistoryGet(
    DBCRUDTestID => $User{ID},
    SystemTime   => $SystemTime,
);
$Self->True(
    %DataHistoryGet ? 1 : 0,
    "history data get (SystemTime) user $User{Name} with ID $User{ID}",
);
$Self->Is(
    $DataHistoryGet{Age},
    21,
    "history data get (SystemTime) user $User{Name} with ID $User{ID} has age 21",
);
$Self->Is(
    $DataHistoryGet{Name},
    'user 1',
    "history data get (SystemTime) user $User{Name} with ID $User{ID} has name 'user 1 change 1'",
);
$Self->Is(
    $DataHistoryGet{CreateTime},
    '2017-12-05 14:00:00',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has create time '2017-12-05 14:00:00'",
);

%DataHistoryGet = $DBCRUDTestObject->DataHistoryGet(
    DBCRUDTestID => $User{ID},
    StopYear     => 2017,
    StopMonth    => 12,
    StopDay      => 5,
    StopHour     => 14,
    StopMinute   => 0,
    StopSecond   => 0,
);
$Self->True(
    %DataHistoryGet ? 1 : 0,
    "history data (StopTime) get user $User{Name} with ID $User{ID}",
);
$Self->Is(
    $DataHistoryGet{Age},
    21,
    "history data (StopTime) get user $User{Name} with ID $User{ID} has age 21",
);
$Self->Is(
    $DataHistoryGet{Name},
    'user 1',
    "history data (StopTime) get user $User{Name} with ID $User{ID} has name 'user 1 change 1'",
);
$Self->Is(
    $DataHistoryGet{CreateTime},
    '2017-12-05 14:00:00',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has create time '2017-12-05 14:00:00'",
);

#
# check history data for 14:30:00
#

%DataHistoryGet = $DBCRUDTestObject->DataHistoryGet(
    DBCRUDTestID => $User{ID},
    TimeStamp    => '2017-12-05 14:30:00',
);
$Self->True(
    %DataHistoryGet ? 1 : 0,
    "history data get user $User{Name} with ID $User{ID}",
);
$Self->Is(
    $DataHistoryGet{Age},
    50,
    "history data get user $User{Name} with ID $User{ID} has age 21",
);
$Self->Is(
    $DataHistoryGet{Name},
    'user 1 change 1',
    "history data get user $User{Name} with ID $User{ID} has name 'user 1 change 1'",
);
$Self->Is(
    $DataHistoryGet{CreateTime},
    '2017-12-05 14:00:00',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has create time '2017-12-05 14:00:00'",
);

#
# check history data for 15:00:00
#

%DataHistoryGet = $DBCRUDTestObject->DataHistoryGet(
    DBCRUDTestID => $User{ID},
    TimeStamp    => '2017-12-05 15:00:00',
);
$Self->True(
    %DataHistoryGet ? 1 : 0,
    "history data get user $User{Name} with ID $User{ID}",
);
$Self->Is(
    $DataHistoryGet{Age},
    75,
    "history data get user $User{Name} with ID $User{ID} has age 21",
);
$Self->Is(
    $DataHistoryGet{Name},
    'user 1 change 2',
    "history data get user $User{Name} with ID $User{ID} has name 'user 1 change 2'",
);
$Self->Is(
    $DataHistoryGet{CreateTime},
    '2017-12-05 14:00:00',
    "history data get (TimeStamp) user $User{Name} with ID $User{ID} has create time '2017-12-05 14:00:00'",
);

$HelperObject->DatabaseXML(
    String => <<'EOF',
    <TableDrop Name="dbcrud_test" />
EOF
);
$HelperObject->DatabaseXML(
    String => <<'EOF',
    <TableDrop Name="dbcrud_test_history" />
EOF
);

1;
