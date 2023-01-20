# --
# Copyright (C) 2021 Perl-Services.de
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use MIME::Base64;

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation::Session::SessionCreate;
use Kernel::GenericInterface::Operation::Ticket::TicketGet;

use Kernel::System::VariableCheck qw(:all);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# disable SessionCheckRemoteIP setting
$ConfigObject->Set(
    Key   => 'SessionCheckRemoteIP',
    Value => 0,
);

# Skip SSL certificate verification.
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# get a random number
my $RandomID = $HelperObject->GetRandomNumber();

# create a new user for current test
my $UserLogin = $HelperObject->TestUserCreate(
    Groups => ['users'],
);
my $Password = $UserLogin;

my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
    UserLogin => $UserLogin,
);

my @NrOfArticles = ( 3, 5 );
my $ArticleLimit = 100;

my @TicketIDs = CreateTickets(@NrOfArticles);

# set web-service name
my $WebserviceName = 'Operation::Ticket::TicketGetBulkWithArticleLimit-Test-' . $RandomID;

# create web-service object
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
$Self->Is(
    'Kernel::System::GenericInterface::Webservice',
    ref $WebserviceObject,
    "Create web service object",
);

my $WebserviceID = $WebserviceObject->WebserviceAdd(
    Name   => $WebserviceName,
    Config => {
        Debugger => {
            DebugThreshold => 'debug',
        },
        Provider => {
            Transport => {
                Type => '',
            },
        },
    },
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $WebserviceID,
    "Added Web Service",
);

# get remote host with some precautions for certain unit test systems
my $Host = $HelperObject->GetTestHTTPHostname();

# prepare web-service config
my $RemoteSystem =
    $ConfigObject->Get('HttpType')
    . '://'
    . $Host
    . '/'
    . $ConfigObject->Get('ScriptAlias')
    . '/nph-genericinterface.pl/WebserviceID/'
    . $WebserviceID;

my $WebserviceConfig = {

    #    Name => '',
    Description =>
        'Test for Ticket Connector using SOAP transport backend.',
    Debugger => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    Provider => {
        Transport => {
            Type   => 'HTTP::REST',
            Config => {
                MaxLength => 10000000,
                NameSpace => 'http://otrs.org/SoapTestInterface/',
                Endpoint  => $RemoteSystem,
            },
        },
        Operation => {
            TicketGet => {
                Type => 'Ticket::TicketGet',
            },
            SessionCreate => {
                Type => 'Session::SessionCreate',
            },
        },
    },
};

# update web-service with real config
# the update is needed because we are using
# the WebserviceID for the Endpoint in config
my $WebserviceUpdate = $WebserviceObject->WebserviceUpdate(
    ID      => $WebserviceID,
    Name    => $WebserviceName,
    Config  => $WebserviceConfig,
    ValidID => 1,
    UserID  => $UserID,
);

$Self->True(
    $WebserviceUpdate,
    "Updated Web Service $WebserviceID - $WebserviceName",
);

# debugger object
my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => $WebserviceID,
    CommunicationType => 'Provider',
);
$Self->Is(
    ref $DebuggerObject,
    'Kernel::GenericInterface::Debugger',
    'DebuggerObject instantiate correctly',
);

# create local object
my $LocalObject = "Kernel::GenericInterface::Operation::Ticket::TicketGet"->new(
    DebuggerObject => $DebuggerObject,
    WebserviceID   => $WebserviceID,
);

$Self->Is(
    "Kernel::GenericInterface::Operation::Ticket::TicketGet",
    ref $LocalObject,
    "Create local object",
);

my %Auth = (
    UserLogin => $UserLogin,
    Password  => $Password,
);

# start requester with our web-service
my $LocalResult = $LocalObject->Run(
    WebserviceID => $WebserviceID,
    Invoker      => 'TicketGet',
    Data         => {
        %Auth,
        TicketID     => ( join ", ", @TicketIDs ),
        AllArticles  => 1,
        ArticleLimit => 100,
    },
);

# check result
$Self->Is(
    'HASH',
    ref $LocalResult,
    "Local result structure is valid",
);

for my $Index ( 0 .. $#NrOfArticles ) {
    $Self->Is(
        scalar( @{ $LocalResult->{Data}->{Ticket}->[$Index]->{Article} } ),
        $NrOfArticles[$Index],
        "correct number of articles for ticket " . ( $Index + 1 )
    );
}

# cleanup

# delete web service
my $WebserviceDelete = $WebserviceObject->WebserviceDelete(
    ID     => $WebserviceID,
    UserID => $UserID,
);
$Self->True(
    $WebserviceDelete,
    "Deleted Web Service $WebserviceID",
);

# delete tickets
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
for my $TicketID (@TicketIDs) {
    my $TicketDelete = $TicketObject->TicketDelete(
        TicketID => $TicketID,
        UserID   => $UserID,
    );

    # sanity check
    $Self->True(
        $TicketDelete,
        "TicketDelete() successful for Ticket ID $TicketID",
    );
}

# cleanup cache
$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

sub CreateTickets {
    my @RequestedArticles = @_;

    my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );

    #ticket id container
    my @TicketIDs;

    for my $NrArticles (@RequestedArticles) {

        # create ticket
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Ticket for Unittest',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customerOne@example.com',
            OwnerID      => 1,
            UserID       => 1,
        );

        # sanity check
        $Self->True(
            $TicketID,
            "TicketCreate() successful (ID: $TicketID)"
        );

        # add ticket id
        push @TicketIDs, $TicketID;

        for ( 1 .. $NrArticles ) {

            # first article
            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $TicketID,
                SenderType           => 'agent',
                IsVisibleForCustomer => 1,
                From                 => 'Agent Some Agent Some Agent <email@example.com>',
                To                   => 'Customer A <customer-a@example.com>',
                Cc                   => 'Customer B <customer-b@example.com>',
                ReplyTo              => 'Customer B <customer-b@example.com>',
                Subject              => 'first article',
                Body                 => 'A text for the body, Title äöüßÄÖÜ€ис',
                ContentType          => 'text/plain; charset=ISO-8859-15',
                HistoryType          => 'OwnerUpdate',
                HistoryComment       => 'first article',
                UserID               => 1,
                NoAgentNotify        => 1,
            );
        }
    }

    return @TicketIDs;
}

1;
