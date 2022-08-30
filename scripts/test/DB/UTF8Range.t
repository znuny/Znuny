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

# get DB object
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

# create database for tests
my $XML = '
<Table Name="test_utf8_range">
    <Column Name="test_message" Required="true" Size="255" Type="VARCHAR"/>
</Table>
';
my @XMLARRAY = $Kernel::OM->Get('Kernel::System::XML')->XMLParse( String => $XML );
my @SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "CREATE TABLE ($SQL)",
    );
}

my @Tests = (
    {
        Name => "Ascii / UTF8 1 byte",
        Data => 'aou',
    },
    {
        Name => "UTF8 2 byte",
        Data => 'äöü',
    },
    {
        Name => "UTF8 3 byte",
        Data => 'ऄ',           # DEVANAGARI LETTER SHORT A (e0 a4 84)
    },
    {
        Name                => "UTF8 4 byte",
        Data                => '💩',          # PILE OF POO (f0 9f 92 a9)
        ExpectedDataOnMysql => '�',
    },
);

for my $Test (@Tests) {

    my $Success = $DBObject->Do(
        SQL => 'INSERT INTO test_utf8_range ( test_message )'
            . ' VALUES ( ? )',
        Bind => [ \$Test->{Data} ],
    );

    $Self->True(
        $Success,
        "$Test->{Name} - INSERT",
    );

    my $ExpectedData = $Test->{Data};
    if ( $Test->{ExpectedDataOnMysql} && $DBObject->{Backend}->{'DB::Type'} eq 'mysql' ) {
        $ExpectedData = $Test->{ExpectedDataOnMysql};
    }

    # Fetch withouth WHERE
    $DBObject->Prepare(
        SQL   => 'SELECT test_message FROM test_utf8_range',
        Limit => 1,
    );

    my $RowCount = 0;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->Is(
            $Row[0],
            $ExpectedData,
            "$Test->{Name} - SELECT all",
        );
        $RowCount++;
    }

    $Self->Is(
        $RowCount,
        1,
        "$Test->{Name} - SELECT all row count",
    );

    # Fetch 1 with WHERE
    $DBObject->Prepare(
        SQL => '
            SELECT test_message
            FROM test_utf8_range
            WHERE test_message = ?',
        Bind  => [ \$Test->{Data}, ],
        Limit => 1,
    );

    $RowCount = 0;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->Is(
            $Row[0],
            $ExpectedData,
            "$Test->{Name} - SELECT all",
        );
        $RowCount++;
    }

    $Self->Is(
        $RowCount,
        1,
        "$Test->{Name} - SELECT all row count",
    );

    $Success = $DBObject->Do(
        SQL => 'DELETE FROM test_utf8_range',
    );

    $Self->True(
        $Success,
        "$Test->{Name} - DELETE",
    );
}

# cleanup
$Self->True(
    $DBObject->Do( SQL => 'DROP TABLE test_utf8_range' ) || 0,
    "DROP TABLE",
);

1;
