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

my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $ServiceObject         = $Kernel::OM->Get('Kernel::System::Service');
my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
my $CustomerUserObject    = $Kernel::OM->Get('Kernel::System::CustomerUser');
my $IsITSMInstalled       = $Kernel::OM->Get('Kernel::System::Util')->IsITSMInstalled();

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);
$ConfigObject->Set(
    Key   => 'Ticket::Service::Default::UnknownCustomer',
    Value => 0,
);
$ConfigObject->Set(
    Key   => 'Ticket::Service::Behavior::CustomerCompany',
    Value => 1,
);

my %ITSMServiceParams;
if ($IsITSMInstalled) {
    %ITSMServiceParams = (
        TypeID      => 1,
        Criticality => '3 normal',
    );
}

my $ServiceID1 = $ServiceObject->ServiceAdd(
    Name    => 'CompanyService1' . $HelperObject->GetRandomNumber(),
    Comment => 'Some Comment',
    ValidID => 1,
    UserID  => 1,
    %ITSMServiceParams,
);
$Self->True(
    $ServiceID1,
    'ServiceAdd1()',
);

my $ServiceID2 = $ServiceObject->ServiceAdd(
    Name    => 'CompanyService2' . $HelperObject->GetRandomNumber(),
    Comment => 'Some Comment',
    ValidID => 1,
    UserID  => 1,
    %ITSMServiceParams,
);
$Self->True(
    $ServiceID2,
    'ServiceAdd2()',
);

my $CustomerID1 = $CustomerCompanyObject->CustomerCompanyAdd(
    CustomerID             => 'CompanyCID1' . $HelperObject->GetRandomNumber(),
    CustomerCompanyName    => 'Demo Company 1 ' . $HelperObject->GetRandomNumber(),
    CustomerCompanyStreet  => '5201 Blue Lagoon Drive',
    CustomerCompanyZIP     => '33126',
    CustomerCompanyCity    => 'Miami',
    CustomerCompanyCountry => 'USA',
    CustomerCompanyURL     => 'http://www.example.org',
    CustomerCompanyComment => 'some comment',
    ValidID                => 1,
    UserID                 => 1,
);
$Self->True(
    $CustomerID1,
    'CustomerCompanyAdd1()',
);

my $CustomerID2 = $CustomerCompanyObject->CustomerCompanyAdd(
    CustomerID             => 'CompanyCID2' . $HelperObject->GetRandomNumber(),
    CustomerCompanyName    => 'Demo Company 2 ' . $HelperObject->GetRandomNumber(),
    CustomerCompanyStreet  => '5201 Blue Lagoon Drive',
    CustomerCompanyZIP     => '33126',
    CustomerCompanyCity    => 'Miami',
    CustomerCompanyCountry => 'USA',
    CustomerCompanyURL     => 'http://www.example.org',
    CustomerCompanyComment => 'some comment',
    ValidID                => 1,
    UserID                 => 1,
);
$Self->True(
    $CustomerID2,
    'CustomerCompanyAdd2()',
);

$Self->False(
    scalar $ServiceObject->CustomerCompanyServiceMemberList(
        CustomerID => $CustomerID1,
        Result     => 'ID',
    ),
    'CustomerCompanyServiceMemberList() - empty for company 1',
);

$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID1,
    ServiceID  => $ServiceID1,
    Active     => 1,
    UserID     => 1,
);
$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID1,
    ServiceID  => $ServiceID2,
    Active     => 1,
    UserID     => 1,
);
$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID2,
    ServiceID  => $ServiceID1,
    Active     => 1,
    UserID     => 1,
);
$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID2,
    ServiceID  => $ServiceID2,
    Active     => 1,
    UserID     => 1,
);

my @Company1Services = sort $ServiceObject->CustomerCompanyServiceMemberList(
    CustomerID => $CustomerID1,
    Result     => 'ID',
);
$Self->IsDeeply(
    \@Company1Services,
    [ sort ( $ServiceID1, $ServiceID2 ) ],
    'CustomerCompanyServiceMemberList() - company 1 has both services',
);

my $CustomerUser = $HelperObject->TestCustomerUserCreate()
    || die "Did not get test customer user";

my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
    User => $CustomerUser,
);

my $CustomerUserUpdate = $CustomerUserObject->CustomerUserUpdate(
    %CustomerUser,
    ID             => $CustomerUser,
    UserCustomerID => $CustomerID1,
    ValidID        => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserUpdate,
    'CustomerUserUpdate()',
);

my $CustomerUserCustomerMemberAdd = $CustomerUserObject->CustomerUserCustomerMemberAdd(
    CustomerUserID => $CustomerUser,
    CustomerID     => $CustomerID2,
    Active         => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserCustomerMemberAdd,
    'CustomerUserCustomerMemberAdd()',
);

my @AllCompanyServices = sort $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->IsDeeply(
    \@AllCompanyServices,
    [ sort ( $ServiceID1, $ServiceID2 ) ],
    'CustomerUserServiceMemberList() - all company services without CustomerID',
);

# One service per company for the filtered lookup.
$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID1,
    ServiceID  => $ServiceID2,
    Active     => 0,
    UserID     => 1,
);
$ServiceObject->CustomerCompanyServiceMemberAdd(
    CustomerID => $CustomerID2,
    ServiceID  => $ServiceID1,
    Active     => 0,
    UserID     => 1,
);

my @AllCustomerIDs = sort $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->Is(
    scalar @AllCustomerIDs,
    2,
    'CustomerUserServiceMemberList() - both companies without CustomerID filter',
);

my @FirstCustomerID = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    CustomerID             => $CustomerID1,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->IsDeeply(
    \@FirstCustomerID,
    [$ServiceID1],
    'CustomerUserServiceMemberList() - first customer ID only',
);

my @SecondCustomerID = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    CustomerID             => $CustomerID2,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->IsDeeply(
    \@SecondCustomerID,
    [$ServiceID2],
    'CustomerUserServiceMemberList() - second customer ID only',
);

# Fallback: with direct user services, company services are ignored.
$ConfigObject->Set(
    Key   => 'Ticket::Service::Behavior::CustomerCompany',
    Value => 0,
);

$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $CustomerUser,
    ServiceID         => $ServiceID1,
    Active            => 1,
    UserID            => 1,
);

my @FallbackWithDirect = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    CustomerID             => $CustomerID2,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->IsDeeply(
    \@FallbackWithDirect,
    [$ServiceID1],
    'CustomerUserServiceMemberList() - fallback uses direct services only',
);

$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $CustomerUser,
    ServiceID         => $ServiceID1,
    Active            => 0,
    UserID            => 1,
);

my @FallbackWithoutDirect = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin      => $CustomerUser,
    CustomerID             => $CustomerID2,
    Result                 => 'ID',
    DefaultServices        => 0,
    CustomerCompanyService => 1,
);
$Self->IsDeeply(
    \@FallbackWithoutDirect,
    [$ServiceID2],
    'CustomerUserServiceMemberList() - fallback uses company services when user has none',
);

my %Company2 = $CustomerCompanyObject->CustomerCompanyGet(
    CustomerID => $CustomerID2,
);
my $NewCustomerID2 = 'New' . $CustomerID2;

my $CompanyUpdated = $CustomerCompanyObject->CustomerCompanyUpdate(
    %Company2,
    CustomerCompanyID => $CustomerID2,
    CustomerID        => $NewCustomerID2,
    UserID            => 1,
);
$Self->True(
    $CompanyUpdated,
    'CustomerCompanyUpdate() - customer ID changed',
);

my @ServicesNewCustomerID = $ServiceObject->CustomerCompanyServiceMemberList(
    CustomerID => $NewCustomerID2,
    Result     => 'ID',
);
$Self->IsDeeply(
    \@ServicesNewCustomerID,
    [$ServiceID2],
    'CustomerCompanyServiceMemberList() - services follow the new customer ID',
);

$Self->False(
    scalar $ServiceObject->CustomerCompanyServiceMemberList(
        CustomerID => $CustomerID2,
        Result     => 'ID',
    ),
    'CustomerCompanyServiceMemberList() - old customer ID has no services left',
);

# cleanup is done by RestoreDatabase

1;
