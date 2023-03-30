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

$HelperObject->DatabaseXML(
    String => <<"EOF",
    <TableCreate Name="dbcrud_test">
        <Column AutoIncrement="true" Name="id" PrimaryKey="true" Required="true" Type="BIGINT"/>
        <Column Name="name" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="age" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="description" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="content_json" Required="false" Type="LONGBLOB"/>
        <Column Name="create_time" Required="true" Type="DATE"/>
        <Column Name="change_time" Required="true" Type="DATE"/>
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
    </TableCreate>
EOF
);

$HelperObject->FixedTimeSetByTimeStamp('2016-04-14 10:45:00');

my $DataAdd = $DBCRUDTestObject->DataAdd(
    Name        => 'test',
    Age         => '14',
    Description => 'text',
);

$Self->True(
    $DataAdd,
    'Added 1. test entry for WhereTimeStamp',
);

$HelperObject->FixedTimeSetByTimeStamp('2016-04-16 10:45:00');

$DataAdd = $DBCRUDTestObject->DataAdd(
    Name        => 'test2',
    Age         => '16',
    Description => 'text2',
);

$Self->True(
    $DataAdd,
    'Added 2. test entry for WhereTimeStamp',
);

#
# DataGet
#

# ChangeTimeNewerDate
my %ExpectedData = (
    ChangeTime => '2016-04-14 10:45:00',
    CreateTime => '2016-04-14 10:45:00',
    Name       => 'test',
);

my %DataGet = $DBCRUDTestObject->DataGet(
    ChangeTimeNewerDate => '2016-04-14 10:44:00',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataGet{$Attribute},
        $ExpectedData{$Attribute},
        "DataGet ChangeTimeNewerDate - $Attribute: $ExpectedData{$Attribute}",
    );
}

# CreateTimeNewerDate
%ExpectedData = (
    ChangeTime => '2016-04-16 10:45:00',
    CreateTime => '2016-04-16 10:45:00',
    Name       => 'test2',
);

%DataGet = $DBCRUDTestObject->DataGet(
    CreateTimeNewerDate => '2016-04-16 10:44:00',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataGet{$Attribute},
        $ExpectedData{$Attribute},
        "DataGet ChangeTimeNewerDate - $Attribute: $ExpectedData{$Attribute}",
    );
}

# ChangeTimeNewerValue
# ChangeTimeNewerUnit
%ExpectedData = (
    ChangeTime => '2016-04-16 10:45:00',
    CreateTime => '2016-04-16 10:45:00',
    Name       => 'test2',
);

# current Time                   = '2016-04-16 10:45:00'
# calculated ChangeTimeNewerDate = '2016-04-16 10:43:00'

%DataGet = $DBCRUDTestObject->DataGet(
    ChangeTimeNewerValue => 2,
    ChangeTimeNewerUnit  => 'Minutes',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataGet{$Attribute},
        $ExpectedData{$Attribute},
        "DataGet ChangeTimeNewerValue - $Attribute: $ExpectedData{$Attribute}",
    );
}

# ChangeTimeNewerValue
# ChangeTimeNewerUnit
# ChangeTimeNewerDate
%ExpectedData = (
    ChangeTime => '2016-04-16 10:45:00',
    CreateTime => '2016-04-16 10:45:00',
    Name       => 'test2',
);

# current Time                   = '2016-04-16 10:45:00'
# ChangeTimeNewerDate            = '2016-04-15 10:45:00'
# calculated ChangeTimeNewerDate = '2016-04-15 10:43:00'

%DataGet = $DBCRUDTestObject->DataGet(
    ChangeTimeNewerValue => 2,
    ChangeTimeNewerUnit  => 'Minutes',
    ChangeTimeNewerDate  => '2016-04-15 10:45:00',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataGet{$Attribute},
        $ExpectedData{$Attribute},
        "DataGet ChangeTimeNewerValue + ChangeTimeNewerDate - $Attribute: $ExpectedData{$Attribute}",
    );
}

#
# DataListGet
#

# ChangeTimeOlderDate
%ExpectedData = (
    ChangeTime => '2016-04-14 10:45:00',
    CreateTime => '2016-04-14 10:45:00',
    Name       => 'test',
);

my @DataListGet = $DBCRUDTestObject->DataListGet(
    ChangeTimeOlderDate => '2016-04-16 10:44:00',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataListGet[0]->{$Attribute},
        $ExpectedData{$Attribute},
        "DataListGet ChangeTimeOlderDate - $Attribute: $ExpectedData{$Attribute}",
    );
}

#
# DataSearch
#

# ChangeTimeOlderDate
%ExpectedData = (
    ChangeTime => '2016-04-14 10:45:00',
    CreateTime => '2016-04-14 10:45:00',
    Name       => 'test',
);

my @DataSearch = $DBCRUDTestObject->DataSearch(
    Search              => 'text',
    ChangeTimeOlderDate => '2016-04-16 10:44:00',
    Result              => 'ARRAY',
);

for my $Attribute ( sort keys %ExpectedData ) {
    $Self->Is(
        $DataSearch[0]->{$Attribute},
        $ExpectedData{$Attribute},
        "ChangeTimeOlderDate - $Attribute: $ExpectedData{$Attribute}",
    );
}

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
