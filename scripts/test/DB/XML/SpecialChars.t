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

use Encode;

# get needed objects
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');
my $XMLObject    = $Kernel::OM->Get('Kernel::System::XML');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# ------------------------------------------------------------ #
# XML test 5 - INSERT special characters test
# ------------------------------------------------------------ #

my $XML = '
<TableCreate Name="test_d">
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

my @SpecialCharacters = qw( - _ . : ; ' " \ [ ] { } ( ) < > ? ! $ % & / + * = ' ^ | ö ス);
push @SpecialCharacters, ( ',', '#', 'otrs test', 'otrs_test' );
my $Counter = 0;

for my $Character (@SpecialCharacters) {

    $EncodeObject->EncodeInput( \$Character );

    # insert
    my $Result = $DBObject->Do(
        SQL  => "INSERT INTO test_d (name_a, name_b) VALUES ( ?, ? )",
        Bind => [ \$Counter, \$Character ],
    );
    $Self->True(
        $Result,
        "#5.$Counter Do() INSERT",
    );

    # select = $Counter
    $Result = $DBObject->Prepare(
        SQL   => "SELECT name_b FROM test_d WHERE name_a = ?",
        Bind  => [ \$Counter ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter Prepare() SELECT = \$Counter",
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->True(
            $Row[0] eq $Character,
            "#5.$Counter Check special character $Character by 'eq' (db returned $Row[0])",
        );
        my $Hit = 0;
        if ( $Row[0] =~ /\Q$Character\E/ ) {
            $Hit = 1;
        }
        $Self->True(
            $Hit || 0,
            "#5.$Counter Check special character $Character by RegExp (db returned $Row[0])",
        );
    }

    # select = value
    $Result = $DBObject->Prepare(
        SQL   => "SELECT name_b FROM test_d WHERE name_b = ?",
        Bind  => [ \$Character ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter Prepare() SELECT = value",
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        $Self->True(
            $Row[0] eq $Character,
            "#5.$Counter Check special character $Character by 'eq' (db returned $Row[0])",
        );
        my $Hit = 0;
        if ( $Row[0] =~ /\Q$Character\E/ ) {
            $Hit = 1;
        }
        $Self->True(
            $Hit || 0,
            "#5.$Counter Check special character $Character by RegExp (db returned $Row[0])",
        );
    }

    # select like value
    my $CharacterLike = $DBObject->Quote( $Character, 'Like' );
    $Result = $DBObject->Prepare(
        SQL   => "SELECT name_b FROM test_d WHERE name_b LIKE ?",
        Bind  => [ \$CharacterLike ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter Prepare() SELECT LIKE value",
    );

    CHARACTER:
    while ( my @Row = $DBObject->FetchrowArray() ) {

        next CHARACTER if $Character eq '%';    # do not test %, because it's wanted as % for like

        $Self->True(
            $Row[0] eq $Character,
            "#5.$Counter Check special character $Character by 'eq' (db returned $Row[0])",
        );
        my $Hit = 0;

        if ( $Row[0] =~ /\Q$Character\E/ ) {
            $Hit = 1;
        }
        $Self->True(
            $Hit || 0,
            "#5.$Counter Check special character $Character by RegExp (db returned $Row[0])",
        );
    }

    $Counter++;
}

# special test for like with _ (underscore)
{

    # select like value (with space)
    my $Character     = 'otrs test';
    my $CharacterLike = $DBObject->Quote( $Character, 'Like' );
    my $SQL           = "SELECT COUNT(name_b) FROM test_d WHERE name_b LIKE ?";

    my $Result = $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$CharacterLike ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter Prepare() SELECT COUNT LIKE $Character (space)",
    );
    my $Count;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Count = $Row[0];
    }
    $Self->Is(
        $Count,
        1,
        "#5.$Counter $SQL (space)",
    );

    # select like value (with underscore)
    $Character     = 'otrs_test';
    $CharacterLike = $DBObject->Quote( $Character, 'Like' );

    # proof of concept that oracle needs special treatment
    # with underscores in LIKE argument, it always needs the ESCAPE parameter
    # if you want to search for a literal _ (underscore)
    # get like escape string needed for some databases (e.g. oracle)
    # this does no harm for other databases, so it should always be used where
    # a LIKE search is used
    my $LikeEscapeString = $DBObject->GetDatabaseFunction('LikeEscapeString');
    $SQL = "SELECT COUNT(name_b) FROM test_d WHERE name_b LIKE ? $LikeEscapeString";

    $Result = $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$CharacterLike ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter Prepare() SELECT COUNT LIKE $Character (underscore)",
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Count = $Row[0];
    }
    $Self->Is(
        $Count,
        1,
        "#5.$Counter $SQL (underscore)",
    );

    # do the same again for oracle but without the ESCAPE and expect this to fail
    if ( $DBObject->GetDatabaseFunction('Type') eq 'oracle' ) {
        $CharacterLike = $DBObject->Quote( $Character, 'Like' );
        $SQL           = "SELECT COUNT(name_b) FROM test_d WHERE name_b LIKE ?";
        $Result        = $DBObject->Prepare(
            SQL   => $SQL,
            Bind  => [ \$CharacterLike ],
            Limit => 1,
        );
        $Self->True(
            $Result,
            "#5.$Counter Prepare() SELECT COUNT LIKE $Character (underscore)",
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Count = $Row[0];
        }
        $Self->IsNot(
            $Count,
            1,
            "#5.$Counter $SQL (underscore)",
        );
    }
}

my @UTF8Tests = (
    {

        # composed UTF8 char (german umlaut a)
        InsertData => Encode::encode( 'UTF8', "\x{E4}" ),
        SelectData => Encode::encode( 'UTF8', "\x{E4}" ),
        ResultData => "\x{E4}",
    },
    {

        # decomposed UTF8 char (german umlaut a)
        InsertData => Encode::encode( 'UTF8', "\x{61}\x{308}" ),
        SelectData => Encode::encode( 'UTF8', "\x{61}\x{308}" ),
        ResultData => "\x{61}\x{308}",
    },
    {

        # composed UTF8 char (lowercase a with grave)
        InsertData => Encode::encode( 'UTF8', "\x{E0}" ),
        SelectData => Encode::encode( 'UTF8', "\x{E0}" ),
        ResultData => "\x{E0}",
    },
    {

        # decomposed UTF8 char (lowercase a with grave)
        InsertData => Encode::encode( 'UTF8', "\x{61}\x{300}" ),
        SelectData => Encode::encode( 'UTF8', "\x{61}\x{300}" ),
        ResultData => "\x{61}\x{300}",
    },
);

UTF8TEST:
for my $UTF8Test (@UTF8Tests) {

    # extract needed test data
    my %TestData = %{$UTF8Test};

    $EncodeObject->EncodeInput( \$TestData{InsertData} );
    $EncodeObject->EncodeInput( \$TestData{SelectData} );

    my $Result = $DBObject->Do(
        SQL  => 'INSERT INTO test_d (name_a, name_b) VALUES (?, ?)',
        Bind => [ \$Counter, \$TestData{InsertData} ],
    );
    $Self->True(
        $Result,
        "#5.$Counter UTF8: insert test",
    );

    # check insert result
    next UTF8TEST if !$Result;

    $Result = $DBObject->Prepare(
        SQL   => 'SELECT name_b FROM test_d WHERE name_a = ? AND name_b = ?',
        Bind  => [ \$Counter, \$TestData{SelectData}, ],
        Limit => 1,
    );
    $Self->True(
        $Result,
        "#5.$Counter UTF8: prepare SELECT stmt",
    );

    # check prepare result
    next UTF8TEST if !$Result;

    my @UTF8ResultSet;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @UTF8ResultSet, $Row[0];
    }

    $Self->Is(
        $UTF8ResultSet[0],
        $TestData{ResultData},
        "#5.$Counter UTF8: check result data",
    );
}
continue {
    $Counter++;
}

$XML      = '<TableDrop Name="test_d"/>';
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
