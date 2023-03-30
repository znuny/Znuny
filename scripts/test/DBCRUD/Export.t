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
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

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

my $Home = $ConfigObject->Get('Home');

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

$ConfigObject->{'UnitTestDBCRUD'} = {};

$ConfigObject->{'DBCRUDTest'}->{'Export'}->{DefaultFormat}    = 'yml';
$ConfigObject->{'DBCRUDTest'}->{'Export'}->{CSV}->{Separator} = ';';
$ConfigObject->{'DBCRUDTest'}->{'Export'}->{CSV}->{Quote}     = '"';

my $YMLString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.yml',
);

# Import yml
my $ImportYAML = $DBCRUDTestObject->DataImport(
    Format    => 'yml',
    Content   => ${$YMLString},
    Overwrite => 1,
);

# Export yml
my $ExportYAML = $DBCRUDTestObject->DataExport(
    Format => 'yml',
);

$ExportYAML =~ s/\'//gm;

$Self->Is(
    $ExportYAML,
    ${$YMLString},
    'DataExport - YAML',
);

my @List = $DBCRUDTestObject->DataListGet();

for my $Item (@List) {
    $DBCRUDTestObject->DataDelete(
        ID => $Item->{ID},
    );
}

my $CSVString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.csv',
);

# Import csv
my $ImportCSV = $DBCRUDTestObject->DataImport(
    Format    => 'csv',
    Content   => ${$CSVString},
    Overwrite => 1,
);

# Export csv
my $ExportCSV = $DBCRUDTestObject->DataExport(
    Format => 'csv',
);

$ExportCSV =~ s/\'//gm;

$Self->Is(
    $ExportCSV,
    ${$CSVString},
    'DataExport - CSV',
);

@List = $DBCRUDTestObject->DataListGet();

for my $Item (@List) {
    $DBCRUDTestObject->DataDelete(
        ID => $Item->{ID},
    );
}

# Import Excel
my $ExcelString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.xlsx',
);

my $ImportExcel = $DBCRUDTestObject->DataImport(
    Format    => 'Excel',
    Content   => ${$ExcelString},
    Overwrite => 1,
);

$Self->Is(
    $ImportExcel,
    1,
    'DataImport - Excel',
);

# Export Excel
my $ExportExcel = $DBCRUDTestObject->DataExport(
    Format => 'Excel',
);

$Self->True(
    $ExportExcel,
    'DataExport - Excel',
);

@List = $DBCRUDTestObject->DataListGet();

for my $Item (@List) {
    $DBCRUDTestObject->DataDelete(
        ID => $Item->{ID},
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
