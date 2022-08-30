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
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $XMLObject    = $Kernel::OM->Get('Kernel::System::XML');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $Data         = $ConfigObject->Get('CustomerCompany');
my $DefaultValue = $Data->{Params}->{Table};

# ------------------------------------------------------------ #
# CustomerCompany test 1 (ForeignDB True)
# ------------------------------------------------------------ #

$Data->{Params} = {
    Table     => 'customer_company_test',
    ForeignDB => 1,
};

$ConfigObject->Set(
    Key   => 'CustomerCompany',
    Value => \%{$Data},
);

#Create on fly data table
my $XML = '
<Table Name="customer_company_test">
    <Column Name="customer_id" Required="true" PrimaryKey="true" Size="150" Type="VARCHAR"/>
    <Column Name="name" Required="true" Size="200" Type="VARCHAR"/>
    <Column Name="street" Required="false" Size="200" Type="VARCHAR"/>
    <Column Name="zip" Required="false" Size="200" Type="VARCHAR"/>
    <Column Name="city" Required="false" Size="200" Type="VARCHAR"/>
    <Column Name="country" Required="false" Size="200" Type="VARCHAR"/>
    <Column Name="url" Required="false" Size="200" Type="VARCHAR"/>
    <Column Name="comments" Required="false" Size="250" Type="VARCHAR"/>
    <Column Name="valid_id" Required="true" Type="SMALLINT"/>
    <Unique Name="customer_company_test_name">
        <UniqueColumn Name="name"/>
    </Unique>
</Table>
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

$Data->{Params} = {
    Table     => 'customer_company_test',
    ForeignDB => 1,
};

$ConfigObject->Set(
    Key   => 'CustomerCompany',
    Value => \%{$Data},
);

my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

for my $Key ( 1 .. 3, 'ä', 'カス' ) {

    my $CompanyRand = 'Example-Customer-Company' . $Key . $HelperObject->GetRandomID();

    my $CustomerID = $CustomerCompanyObject->CustomerCompanyAdd(
        CustomerID             => $CompanyRand,
        CustomerCompanyName    => $CompanyRand . ' Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyURL     => 'http://example.com',
        CustomerCompanyComment => 'some comment',
        ValidID                => 1,
        UserID                 => 1,
    );

    $Self->True(
        $CustomerID,
        "CustomerCompanyAdd() - $CustomerID",
    );

    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CustomerID,
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyName},
        "$CompanyRand Inc",
        "CustomerCompanyGet() - 'Company Name'",
    );

    $Self->Is(
        $CustomerCompany{CustomerID},
        "$CompanyRand",
        "CustomerCompanyGet() - CustomerID",
    );

    $Self->Is(
        $CustomerCompany{CreateTime},
        undef,
        "CustomerCompanyGet() - CreateTime Not define",
    );

    $Self->Is(
        $CustomerCompany{ChangeTime},
        undef,
        "CustomerCompanyGet() - ChangeTime Not Define",
    );

    # check cache
    %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CustomerID,
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyName},
        "$CompanyRand Inc",
        "CustomerCompanyGet() cached - 'Company Name'",
    );

    $Self->Is(
        $CustomerCompany{CustomerID},
        "$CompanyRand",
        "CustomerCompanyGet() cached - CustomerID",
    );

    $Self->Is(
        $CustomerCompany{CreateTime},
        undef,
        "CustomerCompanyGet() cached - CreateTime Not define",
    );

    $Self->Is(
        $CustomerCompany{ChangeTime},
        undef,
        "CustomerCompanyGet() cached - ChangeTime Not Define",
    );

    my $Update = $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerCompanyID      => $CompanyRand,
        CustomerID             => $CompanyRand . '- updated',
        CustomerCompanyName    => $CompanyRand . '- updated Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyURL     => 'http://updated.example.com',
        CustomerCompanyComment => 'some comment updated',
        ValidID                => 1,
        UserID                 => 1,
    );

    $Self->True(
        $Update,
        "CustomerCompanyUpdate() - $CustomerID",
    );

    %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CompanyRand . '- updated',
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyName},
        "$CompanyRand- updated Inc",
        "CustomerCompanyGet() - 'Company Name'",
    );

    $Self->Is(
        $CustomerCompany{CustomerID},
        "$CompanyRand- updated",
        "CustomerCompanyGet() - CustomerID",
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyComment},
        "some comment updated",
        "CustomerCompanyGet() - Comment",
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyURL},
        "http://updated.example.com",
        "CustomerCompanyGet() - Comment",
    );

    $Self->Is(
        $CustomerCompany{CreateTime},
        undef,
        "CustomerCompanyGet() - CreateTime Not define",
    );

    $Self->Is(
        $CustomerCompany{ChangeTime},
        undef,
        "CustomerCompanyGet() - ChangeTime Not Define",
    );

    $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerCompanyID      => $CompanyRand . '- updated',
        CustomerID             => $CompanyRand . '- updated',
        CustomerCompanyName    => $CompanyRand . '- updated Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'Germany',
        CustomerCompanyURL     => 'http://updated.example.com',
        CustomerCompanyComment => 'some comment updated',
        ValidID                => 1,
        UserID                 => 1,
    );

    %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CompanyRand . '- updated',
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyCountry},
        'Germany',
        "CustomerCompanyGet() cached - Changed country from USA to Germany and check value",
    );
}

$XML      = '<TableDrop Name="customer_company_test"/>';
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

# ------------------------------------------------------------ #
# CustomerCompany test 1 (ForeignDB False)
# ------------------------------------------------------------ #

$Data->{Params} = {
    Table     => $DefaultValue,
    ForeignDB => 0,
};

$ConfigObject->Set(
    Key   => 'CustomerCompany',
    Value => \%{$Data},
);

# destroy customer company object
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::CustomerCompany'] );

$CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

for my $Key ( 1 .. 3, 'ä', 'カス' ) {

    my $CompanyRand = 'Example-Customer-Company' . $Key . $HelperObject->GetRandomID();

    my $CustomerID = $CustomerCompanyObject->CustomerCompanyAdd(
        CustomerID             => $CompanyRand,
        CustomerCompanyName    => $CompanyRand . ' Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyURL     => 'http://example.com',
        CustomerCompanyComment => 'some comment',
        ValidID                => 1,
        UserID                 => 1,
    );

    $Self->True(
        $CustomerID,
        "CustomerCompanyAdd() - $CustomerID",
    );

    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CustomerID,
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyName},
        "$CompanyRand Inc",
        "CustomerCompanyGet() - 'Company Name'",
    );

    $Self->Is(
        $CustomerCompany{CustomerID},
        "$CompanyRand",
        "CustomerCompanyGet() - CustomerID",
    );

    $Self->True(
        $CustomerCompany{CreateTime},
        "CustomerCompanyGet() - CreateTime",
    );

    $Self->True(
        $CustomerCompany{ChangeTime},
        "CustomerCompanyGet() - ChangeTime",
    );

    my $Update = $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerCompanyID      => $CompanyRand,
        CustomerID             => $CompanyRand . '- updated',
        CustomerCompanyName    => $CompanyRand . '- updated Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyURL     => 'http://updated.example.com',
        CustomerCompanyComment => 'some comment updated',
        ValidID                => 1,
        UserID                 => 1,
    );

    $Self->True(
        $Update,
        "CustomerCompanyUpdate() - $CustomerID",
    );

    %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CompanyRand . '- updated',
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyName},
        "$CompanyRand- updated Inc",
        "CustomerCompanyGet() - 'Company Name'",
    );

    $Self->Is(
        $CustomerCompany{CustomerID},
        "$CompanyRand- updated",
        "CustomerCompanyGet() - CustomerID",
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyComment},
        "some comment updated",
        "CustomerCompanyGet() - Comment",
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyURL},
        "http://updated.example.com",
        "CustomerCompanyGet() - Comment",
    );

    $Self->True(
        $CustomerCompany{CreateTime},
        "CustomerCompanyGet() - CreateTime",
    );

    $Self->True(
        $CustomerCompany{ChangeTime},
        "CustomerCompanyGet() - ChangeTime",
    );

    $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerCompanyID      => $CompanyRand . '- updated',
        CustomerID             => $CompanyRand . '- updated',
        CustomerCompanyName    => $CompanyRand . '- updated Inc',
        CustomerCompanyStreet  => 'Some Street',
        CustomerCompanyZIP     => '12345',
        CustomerCompanyCity    => 'Some city',
        CustomerCompanyCountry => 'Germany',
        CustomerCompanyURL     => 'http://updated.example.com',
        CustomerCompanyComment => 'some comment updated',
        ValidID                => 1,
        UserID                 => 1,
    );

    %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CompanyRand . '- updated',
    );

    $Self->Is(
        $CustomerCompany{CustomerCompanyCountry},
        'Germany',
        "CustomerCompanyGet() cached - Changed country from USA to Germany and check value",
    );
}

my %CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList( Valid => 0 );
my $CompanyList         = %CustomerCompanyList ? 1 : 0;

# check CustomerCompanyList with Valid=>0
$Self->True(
    $CompanyList,
    "CustomerCompanyList() with Valid=>0",
);

%CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
    Search => 'Example',
    Valid  => 0,
);

$Self->True(
    scalar keys %CustomerCompanyList,
    "CustomerCompanyList() with Search",
);

%CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
    Search => 'Foo-123FALSE-Example*',
    Valid  => 0,
);

$Self->False(
    scalar keys %CustomerCompanyList,
    "CustomerCompanyList() with Search",
);

# Create Invalid customer company.
my $CompanyInvalid    = 'Invalid' . $HelperObject->GetRandomID();
my $CustomerCompanyID = $CustomerCompanyObject->CustomerCompanyAdd(
    CustomerID             => $CompanyInvalid,
    CustomerCompanyName    => $CompanyInvalid . '- Inc',
    CustomerCompanyStreet  => 'Some Street',
    CustomerCompanyZIP     => '12345',
    CustomerCompanyCity    => 'Some city',
    CustomerCompanyCountry => 'Germany',
    CustomerCompanyURL     => 'http://updated.example.com',
    CustomerCompanyComment => 'some comment updated',
    ValidID                => 2,
    UserID                 => 1,
);

# Search for valid customer company, expecting no result found, company is invalid.
%CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
    Search => $CompanyInvalid,
    Valid  => 1,
);
$Self->False(
    scalar keys %CustomerCompanyList,
    "CustomerCompanyList() with Search - Valid 1 param",
);

# Search for invalid customer company.
%CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
    Search => $CompanyInvalid,
    Valid  => 0,
);
$Self->True(
    scalar keys %CustomerCompanyList,
    "CustomerCompanyList() with Search - Valid 0 param",
);

# Test bug#14861 (https://bugs.otrs.org/show_bug.cgi?id=14861).
# Remove CustomerCompanyValid from config map.
delete $Data->{CustomerCompanyValid};

$ConfigObject->Set(
    Key   => 'CustomerCompany',
    Value => \%{$Data},
);

# Destroy and recreate customer company object.
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::CustomerCompany'] );
$CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

# Clean cache.
$Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
    Type => 'CustomerCompany_CustomerCompanyList',
);

# Search for valid customer company, with CustomerCompanyValid disabled mapping.
# Expecting to find results even if they are invalid.
%CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
    Search => $CompanyInvalid,
    Valid  => 1,
);
$Self->True(
    scalar keys %CustomerCompanyList,
    "CustomerCompanyList() with Search - Valid 1 param and disabled CustomerCompanyValid in config",
);

# cleanup is done by RestoreDatabase

1;
