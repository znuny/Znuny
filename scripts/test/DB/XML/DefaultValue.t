# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# define needed variable
my $UID;

# ------------------------------------------------------------ #
# XML test 6 - default value test (create table)
# ------------------------------------------------------------ #
my $XML = '
<TableCreate Name="test_e">
    <Column Name="id" Required="true" Type="INTEGER"/>
    <Column Name="name_a" Required="false" Default="1" Type="INTEGER" />
    <Column Name="name_b" Required="false" Default="0" Type="INTEGER" />
    <Column Name="name_c" Required="true" Default="2" Type="INTEGER" />
    <Column Name="name_d" Required="true" Default="0" Type="INTEGER" />
    <Column Name="name_e" Required="false" Default="Test1" Size="20" Type="VARCHAR" />
    <Column Name="name_f" Required="false" Default="" Size="20" Type="VARCHAR" />
    <Column Name="name_g" Required="true" Default="Test2" Size="20" Type="VARCHAR" />
    <Column Name="name_h" Required="true" Default="" Size="20" Type="VARCHAR" />
</TableCreate>
';

my @XMLARRAY = $XMLObject->XMLParse( String => $XML );

my @SQL = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() CREATE TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() CREATE TABLE ($SQL)",
    );
}

my $DefaultTest = [

    # general function test
    {
        Insert => {
            name_a => 10,
            name_b => 10,
            name_c => 10,
            name_d => 10,
            name_e => q{'Test'},
            name_f => q{'Test'},
            name_g => q{'Test'},
            name_h => q{'Test'},
        },
        Select => {
            name_a => 10,
            name_b => 10,
            name_c => 10,
            name_d => 10,
            name_e => 'Test',
            name_f => 'Test',
            name_g => 'Test',
            name_h => 'Test',
        },
    },

    # check integer columns
    {
        Insert => {
            name_e => q{''},
            name_f => q{''},
            name_g => q{'Test'},
            name_h => q{'Test'},
        },
        Select => {
            name_a => 1,
            name_b => 0,
            name_c => 2,
            name_d => 0,
            name_e => '',
            name_f => '',
            name_g => 'Test',
            name_h => 'Test',
        },
    },

    # check text columns
    {
        Insert => {
            name_a => 0,
            name_b => 0,
            name_c => 0,
            name_d => 0,
        },
        Select => {
            name_a => 0,
            name_b => 0,
            name_c => 0,
            name_d => 0,
            name_e => 'Test1',
            name_f => '',
            name_g => 'Test2',
            name_h => '',
        },
    },
];

my $Counter = 1;
for my $Test ( @{$DefaultTest} ) {

    # create unique id
    my $ID = $UID++;

    my @InsertColumnsSorted = sort { $a cmp $b } keys %{ $Test->{Insert} };
    my @InsertValuesSorted  = map  { $Test->{Insert}->{$_} } @InsertColumnsSorted;
    my $InsertColumns = join q{, }, @InsertColumnsSorted;
    my $InsertValues  = join q{, }, @InsertValuesSorted;

    my $SQLInsert = "INSERT INTO test_e (id, $InsertColumns) VALUES ($ID, $InsertValues)";

    $Self->True(
        $DBObject->Do( SQL => $SQLInsert ) || 0,
        "#6.$Counter Do() INSERT",
    );

    for my $Column ( sort { $a cmp $b } keys %{ $Test->{Select} } ) {

        my $SelectedValue;
        my $ReferenceValue = $Test->{Select}->{$Column};

        $DBObject->Prepare(
            SQL   => "SELECT $Column FROM test_e WHERE id = $ID",
            Limit => 1,
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {

            $SelectedValue  = defined $Row[0]         ? $Row[0]         : '';
            $ReferenceValue = defined $ReferenceValue ? $ReferenceValue : '';

            $Self->Is(
                $SelectedValue,
                $ReferenceValue,
                "#6.$Counter SELECT check selected value of column '$Column':",
            );
        }
    }

    $Counter++;
}

$XML      = '<TableDrop Name="test_e"/>';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );
@SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() DROP TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() DROP TABLE ($SQL)",
    );
}

# cleanup cache is done by RestoreDatabase.

1;
