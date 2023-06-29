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

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject                   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject                   = $Kernel::OM->Get('Kernel::System::Ticket');
my $TimeAccountingWebserviceObject = $Kernel::OM->Get('Kernel::System::TimeAccountingWebservice');
my $TimeObject                     = $Kernel::OM->Get('Kernel::System::Time');
my $UnitTestWebserviceObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $ConfigObject                   = $Kernel::OM->Get('Kernel::Config');
my $ZnunyHelperObject              = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ValidObject                    = $Kernel::OM->Get('Kernel::System::Valid');
my $WebserviceObject               = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

my %ValidIDsByName = reverse $ValidObject->ValidList();
my $ValidID        = $ValidIDsByName{valid};

my $Home = $ConfigObject->Get('Home');

$ZnunyHelperObject->_WebserviceCreateIfNotExists(
    Webservices => {
        TimeAccounting => $Home . '/var/webservices/examples/TimeAccountingREST.yml'
    },
);

# Activate time accounting web service in case it is set to invalid.
my $Webservice = $WebserviceObject->WebserviceGet(
    Name => 'TimeAccounting',
);

$WebserviceObject->WebserviceUpdate(
    %{$Webservice},
    ValidID => $ValidID,
    UserID  => 1,
);

$ZnunyHelperObject->_GroupCreateIfNotExists(
    Name => 'timeaccounting_webservice',
);

my $SystemTime = $TimeObject->TimeStamp2SystemTime(
    String => '2017-01-01 10:00:00',
);
$HelperObject->FixedTimeSet($SystemTime);

my %UserData = $HelperObject->TestUserDataGet(
    UserPw   => 'blub',
    Groups   => [ 'admin', 'users' ],
    Language => 'de',
);

my %UserDataCheck = $HelperObject->TestUserDataGet(
    UserPw   => 'blub',
    Groups   => ['timeaccounting_webservice'],
    Language => 'de',
);

my $TicketID = $HelperObject->TicketCreate(
    Queue => 'Raw',
);

my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    UserID   => 1,
);

my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

$TicketObject->TicketAccountTime(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    TimeUnit  => '10.55',
    UserID    => $UserData{UserID},
);

$SystemTime = $TimeObject->TimeStamp2SystemTime(
    String => '2017-01-01 11:00:00',
);
$HelperObject->FixedTimeSet($SystemTime);

$TicketObject->TicketAccountTime(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    TimeUnit  => '20.55',
    UserID    => $UserData{UserID},
);

$TicketObject->TicketQueueSet(
    Queue    => 'Misc',
    TicketID => $TicketID,
    UserID   => 1,
);

$SystemTime = $TimeObject->TimeStamp2SystemTime(
    String => '2017-01-01 12:00:00',
);
$HelperObject->FixedTimeSet($SystemTime);

$TicketObject->TicketAccountTime(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    TimeUnit  => '30.55',
    UserID    => $UserData{UserID},
);

$TicketObject->TicketQueueSet(
    Queue    => 'Junk',
    TicketID => $TicketID,
    UserID   => 1,
);

my @List = $TimeAccountingWebserviceObject->TimeAccountingSearch(
    Start  => '2017-01-01 10:00:00',
    End    => '2018-01-01 10:00:00',
    UserID => $UserData{UserID},
);

my @ExpectedList = (
    {
        'Created'          => '2017-01-01 10:00:00',
        'Queue'            => 'Raw',
        'TicketNumber'     => $Ticket{TicketNumber},
        'TicketTitle'      => $Ticket{Title},
        'TicketCustomerID' => $Ticket{CustomerID},
        'TimeUnit'         => '10.55'
    },
    {
        'Created'          => '2017-01-01 11:00:00',
        'Queue'            => 'Misc',
        'TicketNumber'     => $Ticket{TicketNumber},
        'TicketTitle'      => $Ticket{Title},
        'TicketCustomerID' => $Ticket{CustomerID},
        'TimeUnit'         => '20.55'
    },
    {
        'Created'          => '2017-01-01 12:00:00',
        'Queue'            => 'Junk',
        'TicketNumber'     => $Ticket{TicketNumber},
        'TicketTitle'      => $Ticket{Title},
        'TicketCustomerID' => $Ticket{CustomerID},
        'TimeUnit'         => '30.55'
    }
);

$Self->IsDeeply(
    \@List,
    \@ExpectedList,
    'TimeAccountingSearch returned the correct result',
);

$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'TimeAccounting',
    Operation      => 'TimeAccountingGet',
    Payload        => {
        UserLogin               => $UserDataCheck{UserLogin},
        Password                => 'blub',
        TimeAccountingUserLogin => $UserData{UserLogin},
        TimeAccountingStart     => '2017-01-01 10:00:00',
        TimeAccountingEnd       => '2018-01-01 10:00:00',
    },
    Response => {
        Success => 1,
        Data    => {
            TimeAccountingResult => \@ExpectedList,
        },
    },
);

1;
