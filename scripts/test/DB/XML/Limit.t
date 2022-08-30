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
# XML test 3 (XML:TableCreate, XML:Insert, SQL:Select (Start/Limit checks) XML:TableDrop)
# ------------------------------------------------------------ #
my $XML = '
<TableCreate Name="test_b">
    <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="SMALLINT"/>
    <Column Name="name_a" Required="true" Size="60" Type="VARCHAR"/>
    <Column Name="name_b" Required="true" Size="500" Type="VARCHAR"/>
    <Index Name="index_test_name_a">
        <IndexColumn Name="name_a"/>
    </Index>
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

# xml
for my $Count ( 1 .. 40 ) {
    my $Value  = 'Some140' . $Count;
    my $Length = length($Value);
    $XML = '
        <Insert Table="test_b">
            <Data Key="name_a" Type="Quote">' . $Value . '</Data>
            <Data Key="name_b" Type="Quote">' . $Count . '</Data>
        </Insert>
    ';
    @XMLARRAY = $XMLObject->XMLParse( String => $XML );
    @SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
    $Self->True(
        $SQL[0],
        "SQLProcessor() INSERT - $Count",
    );

    for my $SQL (@SQL) {

        # insert
        $Self->True(
            $DBObject->Do( SQL => $SQL ) || 0,
            "Do() XML INSERT - $Count ",
        );

        # select
        $DBObject->Prepare(
            SQL => 'SELECT name_a FROM test_b WHERE name_b = \'' . $Count . '\'',
        );
        my $LengthBack = 0;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $LengthBack = length( $Row[0] );
        }
        $Self->Is(
            $LengthBack,
            $Length,
            "Do() SQL SELECT - $Count",
        );
    }
}

$Self->True(
    $DBObject->Prepare(
        SQL   => 'SELECT * FROM test_b WHERE name_a like \'Some%\' ORDER BY id',
        Start => 15,
        Limit => 12,
        )
        || 0,
    'Prepare() SELECT - Prepare - Start 15 - Limit 12 - like',
);

my $Count = 0;
my $Start = '';
my $End   = '';
while ( my @Row = $DBObject->FetchrowArray() ) {
    if ( !$Start ) {
        $Start = $Row[2];
    }
    $End = $Row[2];
    $Count++;
}

$Self->Is(
    $Count,
    12,
    'FetchrowArray () SELECT - Start 15 - Limit 12 - like - count',
);

$Self->Is(
    $Start,
    16,
    'FetchrowArray () SELECT - Start 15 - Limit 12 - like - start',
);

$Self->Is(
    $End,
    27,
    'FetchrowArray () SELECT - Start 15 - Limit 12 - like - end',
);

$Count = 0;
$Start = '';
$End   = '';
$Self->True(
    $DBObject->Prepare(
        SQL   => 'SELECT * FROM test_b WHERE name_a like \'Some%\' ORDER BY id',
        Start => 15,
        Limit => 40,
        )
        || 0,
    'Prepare() SELECT - Prepare - Start 15 - Limit 40 - like',
);
while ( my @Row = $DBObject->FetchrowArray() ) {
    if ( !$Start ) {
        $Start = $Row[2];
    }
    $End = $Row[2];
    $Count++;
}

$Self->Is(
    $Count,
    25,
    'FetchrowArray () SELECT - Start 15 - Limit 40 - like - count',
);

$Self->Is(
    $Start,
    16,
    'FetchrowArray () SELECT - Start 15 - Limit 40 - like - start',
);

$Self->Is(
    $End,
    40,
    'FetchrowArray () SELECT - Start 15 - Limit 40 - like - end',
);

$Count = 0;
$Start = 0;
$End   = 0;
$Self->True(
    $DBObject->Prepare(
        SQL   => 'SELECT * FROM test_b WHERE name_a like \'Some%\' ORDER BY id',
        Start => 200,
        Limit => 10,
        )
        || 0,
    'Prepare() SELECT - Prepare - Start 10 - Limit 200 - like',
);
while ( my @Row = $DBObject->FetchrowArray() ) {
    if ( !$Start ) {
        $Start = $Row[2];
    }
    $End = $Row[2];
    $Count++;
}

$Self->Is(
    $Count,
    0,
    'FetchrowArray () SELECT - Start 10 - Limit 200 - like - count',
);

$Self->Is(
    $Start,
    0,
    'FetchrowArray () SELECT - Start 10 - Limit 200 - like - start',
);

$Self->Is(
    $End,
    0,
    'FetchrowArray () SELECT - Start 10 - Limit 200 - like - end',
);

$XML      = '<TableDrop Name="test_b"/>';
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
