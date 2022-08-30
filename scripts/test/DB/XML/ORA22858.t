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
# XML test 12 (XML:TableCreate, XML:TableAlter,
# SQL:Insert (size check),  XML:TableDrop)
# Fix/Workaround for ORA-22858: invalid alteration of datatype
# ------------------------------------------------------------ #
my $XML = '
<TableCreate Name="test_a">
    <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="SMALLINT"/>
    <Column Name="name_a" Required="false" Size="60" Type="VARCHAR"/>
    <Column Name="name_b" Required="false" Size="60" Type="VARCHAR"/>
</TableCreate>
';
my @XMLARRAY = $XMLObject->XMLParse( String => $XML );
my @SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    '#12 SQLProcessor() CREATE TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "#12 Do() CREATE TABLE ($SQL)",
    );
}

# all values have the exact maximum size
my $ValueA = 'A';
my $ValueB = 'B';

# adding valid values in each column
$Self->True(
    $DBObject->Do(
        SQL =>
            'INSERT INTO test_a (name_a, name_b) VALUES (?, ?)',
        Bind => [ \$ValueA, \$ValueB ],
        )
        || 0,
    '#12 Do() SQL INSERT before column size change',
);

$XML = '
<TableAlter Name="test_a">
    <ColumnChange NameOld="name_a" NameNew="name_a" Type="VARCHAR" Size="1800000" Required="false"/>
    <ColumnChange NameOld="name_b" NameNew="name_b" Type="VARCHAR" Size="1800000" Required="false"/>
</TableAlter>
';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );
@SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    '#12 SQLProcessor() ALTER TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "#12 Do() ALTER TABLE ($SQL)",
    );
}

# all values have the exact maximum size
$ValueA = 'A' x 1800000;
$ValueB = 'B' x 1800000;

# adding valid values in each column
$Self->True(
    $DBObject->Do(
        SQL =>
            'INSERT INTO test_a (name_a, name_b) VALUES (?, ?)',
        Bind => [ \$ValueA, \$ValueB ],
        )
        || 0,
    '#12 Do() SQL INSERT after column size change',
);

$XML      = '<TableDrop Name="test_a"/>';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );
@SQL      = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    '#12 SQLProcessor() DROP TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "#12 Do() DROP TABLE ($SQL)",
    );
}

# cleanup cache is done by RestoreDatabase.

1;
