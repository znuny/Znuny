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

my $DataAdd = $DBCRUDTestObject->DataAdd(
    Name        => 'test',
    Age         => '14',
    Description => 'text',
    ContentJSON => 'text3',
);

$Self->True(
    scalar $DataAdd,
    'Added test entry for longblob',
);

#
# DataGet
#

my %DataGet = $DBCRUDTestObject->DataGet(
    ContentJSON => 'text3',
);

$Self->False(
    %DataGet ? 1 : 0,
    'DataGet with longblob column',
);

%DataGet = $DBCRUDTestObject->DataGet(
    Description => 'text',
);

$Self->True(
    %DataGet ? 1 : 0,
    'DataGet without longblob column',
);

#
# DataListGet
#

my @DataListGet = $DBCRUDTestObject->DataListGet(
    ContentJSON => 'text3',
);

$Self->False(
    @DataListGet ? 1 : 0,
    'DataListGet with longblob column',
);

@DataListGet = $DBCRUDTestObject->DataListGet(
    Description => 'text',
);

$Self->True(
    @DataListGet ? 1 : 0,
    'DataListGet without longblob column',
);

#
# DataSearch
#

my %DataSearch = $DBCRUDTestObject->DataSearch(
    Search      => 'text3',
    ContentJSON => 'text3',
);

$Self->False(
    %DataSearch ? 1 : 0,
    'DataSearch with longblob column',
);

%DataSearch = $DBCRUDTestObject->DataSearch(
    Search      => 'text',
    Description => 'text',
);

$Self->True(
    %DataSearch ? 1 : 0,
    'DataSearch without longblob column',
);

#
# DataDelete
#

my $DataDelete = $DBCRUDTestObject->DataDelete(
    ContentJSON => 'text3',
);

$Self->False(
    $DataDelete,
    'DataDelete with longblob column',
);

$DataDelete = $DBCRUDTestObject->DataDelete(
    Description => 'text',
);

$Self->True(
    scalar $DataDelete,
    'DataDelete without longblob column',
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
