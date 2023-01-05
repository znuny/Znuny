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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $DBCRUDTestObject = $Kernel::OM->Get('Kernel::System::UnitTest::DBCRUD');
my $UUIDColumnName   = $DBCRUDTestObject->{UUIDDatabaseTableColumnName};

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

# IsUUIDDatabaseTableColumnPresent
my $UUIDColumnPresent = $DBCRUDTestObject->IsUUIDDatabaseTableColumnPresent();

$Self->False(
    $UUIDColumnPresent,
    'IsUUIDDatabaseTableColumnPresent',
);

# CreateUUIDDatabaseTableColumn
my $UUIDColumnCreated = $DBCRUDTestObject->CreateUUIDDatabaseTableColumn();

$Self->True(
    $UUIDColumnCreated,
    'CreateUUIDDatabaseTableColumn',
);

$UUIDColumnPresent = $DBCRUDTestObject->IsUUIDDatabaseTableColumnPresent();

$Self->True(
    $UUIDColumnPresent,
    'IsUUIDDatabaseTableColumnPresent after CreateUUIDDatabaseTableColumn',
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

# MigrateUUIDDatabaseTableColumns()

$HelperObject->DatabaseXML(
    String => <<"EOF",
    <TableCreate Name="dbcrud_test">
        <Column AutoIncrement="true" Name="id" PrimaryKey="true" Required="true" Type="BIGINT"/>
        <Column Name="name" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="age" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="description" Required="false" Size="255" Type="VARCHAR"/>
        <Column Name="content_json" Required="false" Size="10000" Type="VARCHAR"/>
        <Column Name="database_backend_uuid" Required="true" Type="BIGINT"/>
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
        <Column Name="z4o_database_backend_uuid" Required="true" Type="BIGINT"/>
        <Column Name="create_time" Required="false" Type="DATE"/>
        <Column Name="create_by" Required="false" Type="INTEGER"/>
        <Column Name="change_time" Required="false" Type="DATE"/>
        <Column Name="change_by" Required="false" Type="INTEGER"/>
    </TableCreate>
EOF
);

$UUIDColumnPresent = $DBCRUDTestObject->IsUUIDDatabaseTableColumnPresent();

$Self->False(
    $UUIDColumnPresent,
    'MigrateUUIDDatabaseTableColumns - IsUUIDDatabaseTableColumnPresent',
);

my $UUIDColumnMigrated = $DBCRUDTestObject->MigrateUUIDDatabaseTableColumns();

$Self->True(
    $UUIDColumnMigrated,
    'MigrateUUIDDatabaseTableColumns - CreateUUIDDatabaseTableColumn',
);

$UUIDColumnPresent = $DBCRUDTestObject->IsUUIDDatabaseTableColumnPresent();

$Self->True(
    $UUIDColumnPresent,
    'MigrateUUIDDatabaseTableColumns - IsUUIDDatabaseTableColumnPresent after MigrateUUIDDatabaseTableColumns',
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
