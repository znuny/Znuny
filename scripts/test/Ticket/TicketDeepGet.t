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

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');
my $SLAObject             = $Kernel::OM->Get('Kernel::System::SLA');
my $ServiceObject         = $Kernel::OM->Get('Kernel::System::Service');
my $HelperObject          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

my $UserID = 1;

my $CustomerUser = $HelperObject->TestCustomerUserCreate(
    Language => 'de',    # optional, defaults to 'en' if not set
);

my $CustomerID = $CustomerCompanyObject->CustomerCompanyAdd(
    CustomerID             => 'UnitTestCustomerCompany',
    CustomerCompanyName    => 'UnitTestCustomerCompany Inc',
    CustomerCompanyStreet  => 'Some Street',
    CustomerCompanyZIP     => '12345',
    CustomerCompanyCity    => 'Some city',
    CustomerCompanyCountry => 'USA',
    CustomerCompanyURL     => 'http://example.com',
    CustomerCompanyComment => 'some comment',
    ValidID                => 1,
    UserID                 => 1,
);

my $ServiceID = $ServiceObject->ServiceAdd(
    Name    => 'UnitTestService',
    ValidID => 1,
    UserID  => 1,

    # ITSMCore
    TypeID      => 2,
    Criticality => '3 normal',
);

my $SLAID = $SLAObject->SLAAdd(
    ServiceIDs          => [$ServiceID],
    Name                => 'UnitTestSLA',
    Calendar            => 'Calendar1',
    FirstResponseTime   => 3,
    FirstResponseNotify => 2,
    UpdateTime          => 5,
    UpdateNotify        => 4,
    SolutionTime        => 10,
    SolutionNotify      => 8,
    ValidID             => 1,
    UserID              => 1,

    # ITSMCore
    TypeID      => 2,
    Criticality => '3 normal',
);

#
# TicketDeepGet()
#
my $TicketID = $HelperObject->TicketCreate(
    CustomerID   => $CustomerID,
    CustomerUser => $CustomerUser,
    SLAID        => $SLAID,
    ServiceID    => $ServiceID,
    Queue        => 'Postmaster',
);

my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my $Article2ID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my %TicketDeepGet = $TicketObject->TicketDeepGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    UserID    => $UserID,
);

for my $Key (
    qw(CustomerUser CustomerCompany QueueData TypeData PriorityData ServiceData SLAData OwnerData ResponsibleData CreateByData Article)
    )
{
    $Self->True(
        IsHashRefWithData( $TicketDeepGet{$Key} ),
        "TicketDeepGet - $Key",
    );
}

# _TicketDeepGetDataCleanUp()
my $Data = $TicketObject->_TicketDeepGetDataCleanUp(
    Data => {
        Test   => 'ok',
        config => 'removed',
        secret => 'removed',
        passw  => 'removed',
        userpw => 'removed',
        auth   => 'removed',
        token  => 'removed',
        Field  => 'ok',
    }
);

$Self->IsDeeply(
    $Data,
    {
        Test  => 'ok',
        Field => 'ok',
    },
    '_TicketDeepGetDataCleanUp',
);

1;
