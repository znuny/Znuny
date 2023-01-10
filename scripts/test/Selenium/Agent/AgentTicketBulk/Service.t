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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ServiceObject     = $Kernel::OM->Get('Kernel::System::Service');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $TimeObject        = $Kernel::OM->Get('Kernel::System::Time');
my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $SeleniumObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

if ( !$SeleniumObject->{SeleniumTestsActive} ) {
    $Self->True( 1, 'Selenium testing is not active, skipping tests.' );
    return 1;
}

my $Success;

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::Service',
    Value => 1,
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::Service::Default::UnknownCustomer',
    Value => 1,
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Ticket::Frontend::AgentTicketBulk###Service',
    Value => 1,
);

my $Service = 'AAAUnitTestService';

my $ServiceID = $ZnunyHelperObject->_ServiceCreateIfNotExists(
    Name        => $Service,
    TypeID      => 2,             # itsm
    Criticality => '3 normal',    # itsm
);

$Self->True(
    $ServiceID,
    "Created Service '$Service' successfully.",
);

$ServiceID = $ServiceObject->ServiceLookup(
    Name => $Service,
);

$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => '<DEFAULT>',
    ServiceID         => $ServiceID,
    Active            => 1,
    UserID            => 1,
);

my %UserData = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de',
);

$Self->True(
    scalar keys %UserData,
    "Test User created successfully.",
);
my $QueueID = $ZnunyHelperObject->_QueueCreateIfNotExists(
    Name    => 'UT' . $HelperObject->GetRandomNumber(),
    GroupID => 1,
);

$Self->True(
    $QueueID,
    "Test Queue created successfully.",
);
my $CustomerUserLogin = 'test-customer-user-' . $HelperObject->GetRandomNumber();

$HelperObject->TestCustomerUserCreate(
    UserLogin      => $CustomerUserLogin,
    UserFirstname  => 'Test user firstname',
    UserLastname   => 'Test user lastname',
    UserCustomerID => 'Customer',
    UserEmail      => $CustomerUserLogin . '@example.com',
);

my @TicketIDs;
push @TicketIDs, $HelperObject->TicketCreate(
    QueueID => $QueueID,
);
push @TicketIDs, $HelperObject->TicketCreate(
    QueueID => $QueueID,
);

for my $TicketID (@TicketIDs) {

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID => $TicketID,
    );
}

my @Tickets;

for my $TicketID (@TicketIDs) {
    push @Tickets, {
        $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        ),
    };
}

my $SeleniumTest = sub {

    # initialize Znuny4OTRS Helpers and other needed objects
    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    # create test user and login
    my %UserData = $SeleniumObject->AgentLogin(
        Groups   => [ 'admin', 'users' ],
        Language => 'de'
    );

    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketBulk',
        TicketID    => \@TicketIDs,
        WaitForAJAX => 0,
    );

    $Success = $SeleniumObject->InputSet(
        Attribute   => 'ServiceID',
        WaitForAJAX => 1,
        Content     => $Service,
        Options     => {
            KeyOrValue    => 'Value',
            TriggerChange => 1,
        },
    );

    $SeleniumObject->find_element( '#Subject', 'css' )->VerifiedSubmit();
};

$SeleniumObject->RunTest($SeleniumTest);

my @TicketsChanged;

my $Counter = 0;
for my $TicketID (@TicketIDs) {

    $TicketObject->_TicketCacheClear( TicketID => $TicketID );

    push @TicketsChanged, {
        $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        ),
    };

    $Self->Is(
        $TicketsChanged[$Counter]->{"Service"},
        $Service,
        "TicketID: $TicketID Service: $Service - difference found between original Ticket and the updated Ticket.",
    );

    $Counter++;
}

1;
