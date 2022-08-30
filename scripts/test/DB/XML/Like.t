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

# ------------------------------------------------------------ #
# XML test 4 - SELECT * ... LIKE ...
# ------------------------------------------------------------ #
my $XML = '
<TableCreate Name="test_c">
    <Column Name="name_a" Required="true" Size="60" Type="VARCHAR"/>
    <Column Name="name_b" Required="true" Size="60" Type="VARCHAR"/>
</TableCreate>
';
my @XMLARRAY = $XMLObject->XMLParse( String => $XML );
my @SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
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

my $Inserts = [
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[1]Block[1]', 'Test1' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[1]Block[2]', 'Test2' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[2]Block[1]', 'Test3' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[2]Block[2]', 'Test4' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[11]Block[22]', 'Test5' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[22]Block[11]', 'Test6' )",
    "INSERT INTO test_c (name_a, name_b) VALUES ( 'Block[12]Block[12]', 'Test7' )",
];

for my $Insert ( @{$Inserts} ) {
    $Self->True(
        $DBObject->Do( SQL => $Insert ) || 0,
        'Do() INSERT',
    );
}

my $LikeTests = [
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[%]Block[%]", 'Like' )
            . "'",
        Result => {
            Test1 => 1,
            Test2 => 1,
            Test3 => 1,
            Test4 => 1,
            Test5 => 1,
            Test6 => 1,
            Test7 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[1]Block[%]", 'Like' )
            . "'",
        Result => {
            Test1 => 1,
            Test2 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[2]Block[%]", 'Like' )
            . "'",
        Result => {
            Test3 => 1,
            Test4 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[2]Block[1]", 'Like' )
            . "'",
        Result => {
            Test3 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[%]Block[1]", 'Like' )
            . "'",
        Result => {
            Test1 => 1,
            Test3 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[11]Block[%]", 'Like' )
            . "'",
        Result => {
            Test5 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[22]Block[%]", 'Like' )
            . "'",
        Result => {
            Test6 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[%]Block[%1]", 'Like' )
            . "'",
        Result => {
            Test1 => 1,
            Test3 => 1,
            Test6 => 1,
        },
    },
    {
        Select => "SELECT name_b FROM test_c WHERE name_a LIKE '"
            . $DBObject->Quote( "Block[12]Block[12]", 'Like' )
            . "'",
        Result => {
            Test7 => 1,
        },
    },
];

for my $TestRef ( @{$LikeTests} ) {
    my $SQLSelect = $TestRef->{Select};
    my $Result    = $TestRef->{Result};

    $DBObject->Prepare( SQL => $SQLSelect );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->True( $Result->{ $Row[0] }, "SELECT ... LIKE ... - $Row[0]" );
        delete $Result->{ $Row[0] };
    }
    for my $Test ( sort keys %{$Result} ) {
        $Self->False( $Test, "SELECT ... LIKE ... - $Test" );
        delete $Result->{$Test};
    }
}

$XML      = '<TableDrop Name="test_c"/>';
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
