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
# check foreign keys
# ------------------------------------------------------------ #
my $XML = '
<SQL>
    <TableCreate Name="test_foreignkeys_1">
        <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="SMALLINT"/>
        <Column Name="name_a" Required="true" Type="INTEGER" />
        <Column Name="name_b" Required="false" Default="0" Type="INTEGER" />
        <Unique>
            <UniqueColumn Name="name_a"/>
        </Unique>
    </TableCreate>
    <TableCreate Name="test_foreignkeys_2">
        <Column Name="name_a" Required="true" Type="INTEGER" />
        <Column Name="name_b" Required="false" Default="0" Type="INTEGER" />
        <ForeignKey ForeignTable="test_foreignkeys_1">
            <Reference Local="name_a" Foreign="name_a"/>
        </ForeignKey>
    </TableCreate>
    <Insert Table="test_foreignkeys_1">
        <Data Key="name_a">1</Data>
        <Data Key="name_b">1</Data>
    </Insert>
    <Insert Table="test_foreignkeys_1">
        <Data Key="name_a">2</Data>
        <Data Key="name_b">2</Data>
    </Insert>
    <Insert Table="test_foreignkeys_1">
        <Data Key="name_a">3</Data>
        <Data Key="name_b">3</Data>
    </Insert>
    <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">1</Data>
        <Data Key="name_b">100</Data>
    </Insert>
        <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">1</Data>
        <Data Key="name_b">101</Data>
    </Insert>
    <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">2</Data>
        <Data Key="name_b">200</Data>
    </Insert>
    <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">2</Data>
        <Data Key="name_b">201</Data>
    </Insert>
    <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">3</Data>
        <Data Key="name_b">300</Data>
    </Insert>
    <Insert Table="test_foreignkeys_2">
        <Data Key="name_a">3</Data>
        <Data Key="name_b">301</Data>
    </Insert>
</SQL>
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

@SQL = $DBObject->SQLProcessorPost();
$Self->True(
    $SQL[0],
    'SQLProcessorPost() CREATE TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() CREATE TABLE ($SQL)",
    );
}

# try to add the same foreign key again
$XML = '
<TableAlter Name="test_foreignkeys_2">
    <ForeignKeyCreate ForeignTable="test_foreignkeys_1">
        <Reference Local="name_a" Foreign="name_a"/>
    </ForeignKeyCreate>
</TableAlter>
';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );

@SQL = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() ALTER TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() ALTER TABLE ($SQL)",
    );
}

# remove the foreign key
$XML = '
<TableAlter Name="test_foreignkeys_2">
    <ForeignKeyDrop ForeignTable="test_foreignkeys_1">
        <Reference Local="name_a" Foreign="name_a"/>
    </ForeignKeyDrop>
</TableAlter>
';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );

@SQL = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() ALTER TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() ALTER TABLE ($SQL)",
    );
}

# remove the same foreign key again (should be fine)
$XML = '
<TableAlter Name="test_foreignkeys_2">
    <ForeignKeyDrop ForeignTable="test_foreignkeys_1">
        <Reference Local="name_a" Foreign="name_a"/>
    </ForeignKeyDrop>
</TableAlter>
';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );

@SQL = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() ALTER TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() ALTER TABLE ($SQL)",
    );
}

# delete the column
$XML = '
<TableAlter Name="test_foreignkeys_1">
    <ColumnDrop Name="name_a"/>
</TableAlter>
';
@XMLARRAY = $XMLObject->XMLParse( String => $XML );

@SQL = $DBObject->SQLProcessor( Database => \@XMLARRAY );
$Self->True(
    $SQL[0],
    'SQLProcessor() ALTER TABLE',
);

for my $SQL (@SQL) {
    $Self->True(
        $DBObject->Do( SQL => $SQL ) || 0,
        "Do() ALTER TABLE ($SQL)",
    );
}

# drop the test tables
$XML = '
<SQL>
    <TableDrop Name="test_foreignkeys_1"/>
    <TableDrop Name="test_foreignkeys_2"/>
</SQL>
';
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
