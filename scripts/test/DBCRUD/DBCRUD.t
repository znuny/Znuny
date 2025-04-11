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
my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');

my $TimeStamp = $TimeObject->CurrentTimestamp();

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'DBCRUDTest::EventModulePost###000-UnitTestAdd',    # setting name
    Value => {
        'Module' => 'Kernel::System::UnitTest::DBCRUD::Event::DBCRUD',
        'Event'  => 'DBCRUD(.+)',
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

my $TimeStampCreate = '2004-08-14 22:45:00';
$HelperObject->FixedTimeSetByTimeStamp($TimeStampCreate);

my @Users = (
    {
        Name        => 'user 1',
        Age         => 21,
        Description => 'description user 1',
        ContentJSON => { First => { Value => 1 } },
        CreateTime  => $TimeStampCreate,
        ChangeTime  => $TimeStampCreate,
    },
    {
        Name        => 'user 2',
        Age         => 22,
        Description => 'description user 2',
        ContentJSON => { Second => { Value => 1 } },
        CreateTime  => $TimeStampCreate,
        ChangeTime  => $TimeStampCreate,
    },
    {
        Name        => 'user 3',
        Age         => 23,
        Description => 'description user 3',
        ContentJSON => { Third => { Value => 1 } },
        CreateTime  => $TimeStampCreate,
        ChangeTime  => $TimeStampCreate,
    },
);

for my $User (@Users) {
    $ConfigObject->{UnitTestDBCRUD} = {};

    my $ID = $DBCRUDTestObject->DataAdd( %{$User} );

    $Self->True(
        scalar $ID,
        'DataAdd() - add user "' . $User->{Name} . '"',
    );

    $Self->True(
        scalar $ConfigObject->{UnitTestDBCRUD}->{DBCRUDAdd},
        'DataAdd() - event got executed',
    );

    $User->{ID} = $ID;

    my %Result = $DBCRUDTestObject->DataGet(
        ID => $ID,
    );

    $Self->True(
        scalar %Result,
        'DataGet() - get user "' . $User->{Name} . '"',
    );
    $Self->True(
        scalar $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDGet},
        'DataGet() - event got executed',
    );

    for my $Attribute ( sort keys %{$User} ) {
        if ( $Attribute eq 'ContentJSON' ) {
            my $DataIsDifferent = DataIsDifferent(
                Data1 => $User->{$Attribute},
                Data2 => $Result{$Attribute},
            );

            $Self->False(
                scalar $DataIsDifferent,
                'DataGet() - check attribute "' . $Attribute . '" user "' . $User->{Name} . '"',
            );

            my @HistoryDataListGet = $DBCRUDTestObject->HistoryDataListGet(
                DBCRUDTestID => $ID,
                Field        => $Attribute,
                SortBy       => 'ID',
                OrderBy      => 'DESC',
                Limit        => 1,
            );

            $DataIsDifferent = DataIsDifferent(
                Data1 => $User->{$Attribute},
                Data2 => $HistoryDataListGet[0]->{NewValue},
            );

            $Self->False(
                scalar $DataIsDifferent,
                'HistoryDataListGet() - check attribute "' . $Attribute . '" user "' . $User->{Name} . '"',
            );
        }
        else {

            $Self->Is(
                $User->{$Attribute},
                $Result{$Attribute},
                'DataGet() - check attribute "' . $Attribute . '" user "' . $User->{Name} . '"',
            );
        }
    }
}

# DataListGet
$ConfigObject->{'UnitTestDBCRUD'} = {};
my @List = $DBCRUDTestObject->DataListGet();

$Self->Is(
    scalar @List,
    scalar @Users,
    'DataListGet() - count list',
);
$Self->True(
    scalar $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDListGet},
    'DataListGet() - event got executed',
);

@List = $DBCRUDTestObject->DataListGet(
    Age => 21,
);

$Self->Is(
    scalar @List,
    1,
    'DataListGet() - get list for age 21',
);

# DataSearch
$ConfigObject->{'UnitTestDBCRUD'} = {};
my @Search = $DBCRUDTestObject->DataSearch(
    Search => '*',
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    scalar @Users,
    'DataSearch() - count list',
);
$Self->True(
    scalar $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDSearch},
    'DataSearch() - event got executed',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    scalar @Users,
    'DataSearch() - search for "user" list',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user+1',
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    1,
    'DataSearch() - search for "user+1" list',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => '21',
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    1,
    'DataSearch() - search for "user" and age 21 list',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => [ 21, 22, 23 ],
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    3,
    'DataSearch() - search for "user" and age 21,22,23 list',
);

# DataDelete
$ConfigObject->{'UnitTestDBCRUD'} = {};

my @AgedIDs = map { $_->{ID} } grep { $_->{Age} == 21 } @Users;

my $Success = $DBCRUDTestObject->DataDelete(
    Age => undef,
);

$Self->True(
    scalar $Success,
    'DataDelete() - delete user with undefined age, must not delete any test user',
);
$Self->True(
    $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDDelete},
    'DataDelete() - event got executed',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => [ 21, 22, 23 ],
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    3,
    'DataSearch() - search for "users" after trying to delete those with undefined age must return expected users',
);

$ConfigObject->{'UnitTestDBCRUD'} = {};
$Success = $DBCRUDTestObject->DataDelete(
    Age => [21],
);

$Self->True(
    scalar $Success,
    'DataDelete() - delete user with age 21',
);
$Self->True(
    $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDDelete},
    'DataDelete() - event got executed',
);

# HistoryDataListGet
my @AgedHistory = $DBCRUDTestObject->HistoryDataListGet(
    DBCRUDTestID => \@AgedIDs,
);

$Self->False(
    @AgedHistory ? 1 : 0,
    'HistoryDataListGet() - found history entry for users with age 21',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => [ 21, 22, 23 ],
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    2,
    'DataSearch() - search for "user" and age 21,22,23 list',
);

$Success = $DBCRUDTestObject->DataDelete(
    Age => 23,
);

$Self->True(
    scalar $Success,
    'DataDelete() - delete user with age 23',
);

my %Data = $DBCRUDTestObject->DataGet(
    Age => [23],
);

$Self->False(
    keys %Data ? 1 : 0,
    'DataGet() - get for age 23',
);

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => [ 21, 22, 23 ],
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    1,
    'DataSearch() - search for "user" and age 21,22,23 list',
);

# DataUpdate
my $TimeStampUpdate = '2004-08-14 22:45:00';
$HelperObject->FixedTimeSetByTimeStamp($TimeStampUpdate);

for my $User (@Search) {
    $ConfigObject->{'UnitTestDBCRUD'} = {};
    $Success = $DBCRUDTestObject->DataUpdate(
        %{$User},
        Age => 50,
    );

    $Self->True(
        scalar $Success,
        "DataUpdate() - update $User->{Name} to age 50",
    );
    $Self->True(
        scalar $ConfigObject->{'UnitTestDBCRUD'}->{DBCRUDUpdate},
        'DataUpdate() - event got executed',
    );

    my @HistoryDataListGet = $DBCRUDTestObject->HistoryDataListGet(
        DBCRUDTestID => $User->{ID},
        Field        => 'Age',
        SortBy       => 'ID',
        OrderBy      => 'DESC',
        Limit        => 1,
    );

    $Self->Is(
        scalar $HistoryDataListGet[0]->{Field},
        'Age',
        "HistoryDataListGet() - update $User->{Name} to age 50",
    );
    $Self->Is(
        scalar $HistoryDataListGet[0]->{NewValue},
        50,
        "HistoryDataListGet() - update $User->{Name} to age 50",
    );
}

@List = $DBCRUDTestObject->DataListGet();

for my $User (@Search) {
    my $IsResult = $Self->Is(
        $User->{ChangeTime},
        $TimeStampUpdate,
        "TimeStampUpdate field 'UpdateTime' is set correctly to '$TimeStampUpdate'",
    );

    $Self->True(
        scalar $Success,
        'DataUpdate() - update user to age 50',
    );
}

@Search = $DBCRUDTestObject->DataSearch(
    Search => 'user',
    Age    => [ 21, 22, 23 ],
    Result => 'ARRAY',
);

$Self->Is(
    scalar @Search,
    0,
    'DataSearch() - search for "user" and age 21,22,23 list',
);

# DataExport
my $Export = $DBCRUDTestObject->DataExport(
    Cache => 0,
);

$Self->Is(
    $Export,
    "---
- Age: '50'
  Description: description user 2
  Name: user 2
",
    'Export',
);

my $YMLString = '---
- Age: 50
  Description: description user NEW
  Name: user 2
  ContentJSON:
    ID: 1
    First:
        Value: 2
        ID: 2
';

# Import yml
my $Import = $DBCRUDTestObject->DataImport(
    Format    => 'yml',
    Content   => $YMLString,
    Overwrite => 1,
);

$Self->Is(
    scalar $Import,
    1,
    'Import',
);

@List = $DBCRUDTestObject->DataListGet();

# DataCopy

$HelperObject->FixedTimeSetByTimeStamp($TimeStamp);
my %CopyData = %{ $List[0] };

my $ObjectID = $DBCRUDTestObject->DataCopy(
    ID     => $CopyData{ID},
    UserID => 1,
);

$Self->IsNot(
    $ObjectID,
    $CopyData{ID},
    "DataCopy() - ObjectIDs are different $CopyData{ID} <-> $ObjectID",
);

%Data = $DBCRUDTestObject->DataGet(
    ID => $ObjectID,
);

$Self->IsDeeply(
    \%Data,
    {
        ID          => '4',        # new
        Name        => 'user 2',
        Age         => '50',
        ContentJSON => {
            ID    => 1,
            First => {
                ID    => $CopyData{ContentJSON}->{First}->{ID},
                Value => '2',
            }
        },
        CreateTime  => $TimeStamp,    # new
        ChangeTime  => $TimeStamp,    # new
        Description => undef,         # new | CopyDelete => 1,
    },
    'DataGet - of copied data.',
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
