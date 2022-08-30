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
my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
my $ServiceObject      = $Kernel::OM->Get('Kernel::System::Service');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# don't check email address validity
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

# save all original default services
my @OriginalDefaultServices = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => '<DEFAULT>',
    Result            => 'ID',
    DefaultServices   => 0,
);

# delete all default services
for my $ServiceID (@OriginalDefaultServices) {
    $ServiceObject->CustomerUserServiceMemberAdd(
        CustomerUserLogin => '<DEFAULT>',
        ServiceID         => $ServiceID,
        Active            => 0,
        UserID            => 1,
    );
}

# add service1
my $ServiceRand1 = 'SomeService' . $HelperObject->GetRandomID();
my $ServiceID1   = $ServiceObject->ServiceAdd(
    Name    => $ServiceRand1,
    Comment => 'Some Comment',
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $ServiceID1,
    'ServiceAdd1()',
);

# add service2
my $ServiceRand2 = 'SomeService' . $HelperObject->GetRandomID();
my $ServiceID2   = $ServiceObject->ServiceAdd(
    Name    => $ServiceRand2,
    Comment => 'Some Comment',
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $ServiceID2,
    'ServiceAdd2()',
);

my $CustomerUser1 = $HelperObject->TestCustomerUserCreate()
    || die "Did not get test customer user";
my $CustomerUser2 = $HelperObject->TestCustomerUserCreate()
    || die "Did not get test customer user";

# allocation test 1
my @Allocation1 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->False(
    scalar @Allocation1,
    'CustomerUserServiceMemberList1()',
);

# allocation test 2
my @Allocation2 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
);

$Self->False(
    scalar @Allocation2,
    'CustomerUserServiceMemberList2()',
);

# allocation test 3
my @Allocation3 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->False(
    scalar @Allocation3,
    'CustomerUserServiceMemberList3()',
);

# allocation test 4
my @Allocation4 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
);

$Self->False(
    scalar @Allocation4,
    'CustomerUserServiceMemberList4()',
);

# set allocation 1
$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => '<DEFAULT>',
    ServiceID         => $ServiceID1,
    Active            => 1,
    UserID            => 1,
);

# allocation test 5
my @Allocation5 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->False(
    scalar @Allocation5,
    'CustomerUserServiceMemberList5()',
);

# allocation test 6
my @Allocation6 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
);

my $Allocation6Count = @Allocation6;
my $Allocation6Ok    = 0;
if ( $Allocation6Count eq 1 && $Allocation6[0] eq $ServiceID1 ) {
    $Allocation6Ok = 1;
}

$Self->True(
    $Allocation6Ok,
    'CustomerUserServiceMemberList6()',
);

# allocation test 7
my @Allocation7 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->False(
    scalar @Allocation7,
    'CustomerUserServiceMemberList7()',
);

# allocation test 8
my @Allocation8 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
);

my $Allocation8Count = @Allocation8;
my $Allocation8Ok    = 0;
if ( $Allocation8Count eq 1 && $Allocation8[0] eq $ServiceID1 ) {
    $Allocation8Ok = 1;
}

$Self->True(
    $Allocation8Ok,
    'CustomerUserServiceMemberList8()',
);

# set allocation 2
$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $CustomerUser1,
    ServiceID         => $ServiceID2,
    Active            => 1,
    UserID            => 1,
);

# allocation test 9
my @Allocation9 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
    DefaultServices   => 0,
);

my $Allocation9Count = @Allocation9;
my $Allocation9Ok    = 0;
if ( $Allocation9Count eq 1 && $Allocation9[0] eq $ServiceID2 ) {
    $Allocation9Ok = 1;
}

$Self->True(
    $Allocation9Ok,
    'CustomerUserServiceMemberList9()',
);

# allocation test 10
my @Allocation10 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
);

my $Allocation10Count = @Allocation10;
my $Allocation10Ok    = 0;
if ( $Allocation10Count eq 1 && $Allocation10[0] eq $ServiceID2 ) {
    $Allocation10Ok = 1;
}

$Self->True(
    $Allocation10Ok,
    'CustomerUserServiceMemberList10()',
);

# allocation test 11
my @Allocation11 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->False(
    scalar @Allocation11,
    'CustomerUserServiceMemberList11()',
);

# allocation test 12
my @Allocation12 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
);

my $Allocation12Count = @Allocation12;
my $Allocation12Ok    = 0;
if ( $Allocation12Count eq 1 && $Allocation12[0] eq $ServiceID1 ) {
    $Allocation12Ok = 1;
}

$Self->True(
    $Allocation12Ok,
    'CustomerUserServiceMemberList12()',
);

# set allocation 3
$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $CustomerUser2,
    ServiceID         => $ServiceID1,
    Active            => 1,
    UserID            => 1,
);
$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $CustomerUser2,
    ServiceID         => $ServiceID2,
    Active            => 1,
    UserID            => 1,
);

# allocation test 13
my @Allocation13 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
    DefaultServices   => 0,
);

my $Allocation13Ok = 0;
if ( scalar @Allocation13 eq 1 && $Allocation13[0] eq $ServiceID2 ) {
    $Allocation13Ok = 1;
}

$Self->True(
    $Allocation13Ok,
    'CustomerUserServiceMemberList13()',
);

# allocation test 14
my @Allocation14 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser1,
    Result            => 'ID',
);

my $Allocation14Count = @Allocation14;
my $Allocation14Ok    = 0;
if ( $Allocation14Count eq 1 && $Allocation14[0] eq $ServiceID2 ) {
    $Allocation14Ok = 1;
}

$Self->True(
    $Allocation14Ok,
    'CustomerUserServiceMemberList14()',
);

# allocation test 15
my @Allocation15 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
    DefaultServices   => 0,
);

my $Allocation15Count = @Allocation15;
my $Allocation15Ok    = 0;
if (
    $Allocation15Count eq 2 && (
        ( $Allocation15[0] eq $ServiceID1 && $Allocation15[1] eq $ServiceID2 ) ||
        ( $Allocation15[0] eq $ServiceID2 && $Allocation15[1] eq $ServiceID1 )
    )
    )
{
    $Allocation15Ok = 1;
}

$Self->True(
    $Allocation15Ok,
    'CustomerUserServiceMemberList15()',
);

# allocation test 16
my @Allocation16 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $CustomerUser2,
    Result            => 'ID',
);

my $Allocation16Count = @Allocation16;
my $Allocation16Ok    = 0;
if (
    $Allocation16Count eq 2 && (
        ( $Allocation16[0] eq $ServiceID1 && $Allocation16[1] eq $ServiceID2 ) ||
        ( $Allocation16[0] eq $ServiceID2 && $Allocation16[1] eq $ServiceID1 )
    )
    )
{
    $Allocation16Ok = 1;
}

$Self->True(
    $Allocation16Ok,
    'CustomerUserServiceMemberList16()',
);

# rename customer user1
my %Customer = $CustomerUserObject->CustomerUserDataGet(
    User => $CustomerUser1,
);
my $NewCustomerUser1 = $HelperObject->GetRandomID();
my $Update           = $CustomerUserObject->CustomerUserUpdate(
    %Customer,
    ID        => $Customer{UserLogin},
    UserLogin => $NewCustomerUser1,
    UserID    => 1,
);
$Self->True(
    $Update,
    "CustomerUserUpdate - $Customer{UserLogin} - $NewCustomerUser1",
);

# allocation test after rename
# instantiate new service object because of caching!
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Service'] );
$ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

my @Allocation17 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $Customer{UserLogin},
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->Is(
    scalar @Allocation17,
    0,
    "No services allocated to old customer $CustomerUser1 after rename",
);
my @Allocation18 = $ServiceObject->CustomerUserServiceMemberList(
    CustomerUserLogin => $NewCustomerUser1,
    Result            => 'ID',
    DefaultServices   => 0,
);

$Self->Is(
    scalar @Allocation18,
    1,
    "Services allocated to new customer $NewCustomerUser1 after rename",
);

# cleanup is done by RestoreDatabase

1;
