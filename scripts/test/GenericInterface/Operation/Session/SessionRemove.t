# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation::Session::SessionCreate;
use Kernel::GenericInterface::Operation::Session::SessionRemove;

use Kernel::System::VariableCheck qw(:all);

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# get helper object
# skip SSL certificate verification
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $Helper->GetRandomID();

my $TestUserLogin         = $Helper->TestUserCreate(
    Groups => [ 'admin', 'users', ],
);

my $UserObject = $Kernel::OM->Get('Kernel::System::User');

my $UserID = $UserObject->UserLookup(
    UserLogin => $TestUserLogin,
);

my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup( Valid => 'invalid' );

# sanity test
$Self->IsNot(
    $InvalidID,
    undef,
    "ValidLookup() for 'invalid' should not be undef"
);

# create web service object
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
$Self->Is(
    'Kernel::System::GenericInterface::Webservice',
    ref $WebserviceObject,
    "Create web service object",
);

# set web service name
my $WebserviceName = '-Test-' . $RandomID;

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
    "Added web service",
);

# get remote host with some precautions for certain unit test systems
my $Host = $Helper->GetTestHTTPHostname();

# prepare web service config
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
            Type   => 'HTTP::SOAP',
            Config => {
                MaxLength => 10000000,
                NameSpace => 'http://otrs.org/SoapTestInterface/',
                Endpoint  => $RemoteSystem,
            },
        },
        Operation => {
            SessionCreate => {
                Type => 'Session::SessionCreate',
            },
            SessionRemove => {
                Type => 'Session::SessionRemove',
            },
        },
    },
    Requester => {
        Transport => {
            Type   => 'HTTP::SOAP',
            Config => {
                NameSpace => 'http://otrs.org/SoapTestInterface/',
                Encoding  => 'UTF-8',
                Endpoint  => $RemoteSystem,
                Timeout   => 120,
            },
        },
        Invoker => {
            SessionCreate => {
                Type => 'Test::TestSimple',
            },
            SessionRemove => {
                Type => 'Test::TestSimple',
            },
        },
    },
};

# update web service with real config
my $WebserviceUpdate = $WebserviceObject->WebserviceUpdate(
    ID      => $WebserviceID,
    Name    => $WebserviceName,
    Config  => $WebserviceConfig,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $WebserviceUpdate,
    "Updated web service $WebserviceID - $WebserviceName",
);

# Get SessionID
# create requester object
my $RequesterSessionObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
$Self->Is(
    'Kernel::GenericInterface::Requester',
    ref $RequesterSessionObject,
    'SessionID - Create requester object'
);

# create a new user for current test
my $UserLogin = $Helper->TestUserCreate(
    Groups => [ 'admin', 'users' ],
);
my $Password = $UserLogin;

# start requester with our web service
my $RequesterSessionResult = $RequesterSessionObject->Run(
    WebserviceID => $WebserviceID,
    Invoker      => 'SessionCreate',
    Data         => {
        UserLogin => $UserLogin,
        Password  => $Password,
    },
);

my $NewSessionID = $RequesterSessionResult->{Data}->{SessionID};

my @Tests = (
    {
        Name           => 'SessionID is missing',
        SuccessRequest => 1,
        SuccessRemove  => 0,
        RequestData    => {
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'SessionRemove.MissingParameter',
                }
            },
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Remove Session',
        SuccessRequest => 1,
        SuccessRemove  => 1,
        RequestData    => {
            SessionID => $NewSessionID
        },
        Operation => 'SessionRemove',
    },
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

for my $Test (@Tests) {

    # create local object
    my $LocalObject = "Kernel::GenericInterface::Operation::Session::$Test->{Operation}"->new(
        DebuggerObject => $DebuggerObject,
        WebserviceID   => $WebserviceID,
    );

    $Self->Is(
        "Kernel::GenericInterface::Operation::Session::$Test->{Operation}",
        ref $LocalObject,
        "$Test->{Name} - Create local object",
    );

    my %Auth = (
        UserLogin => $UserLogin,
        Password  => $Password,
    );
    if ( IsHashRefWithData( $Test->{Auth} ) ) {
        %Auth = %{ $Test->{Auth} };
    }

    # start requester with our web service
    my $LocalResult = $LocalObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => {
            %Auth,
            %{ $Test->{RequestData} },
        },
    );

    # sleep between requests to have different timestamps
    # because of failing tests on windows
    sleep 1;

    # check result
    $Self->Is(
        'HASH',
        ref $LocalResult,
        "$Test->{Name} - Local result structure is valid",
    );

    # create requester object
    my $RequesterObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    $Self->Is(
        'Kernel::GenericInterface::Requester',
        ref $RequesterObject,
        "$Test->{Name} - Create requester object",
    );

    # start requester with our web service
    my $RequesterResult = $RequesterObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => {
            %Auth,
            %{ $Test->{RequestData} },
        },
    );

    # check result
    $Self->Is(
        'HASH',
        ref $RequesterResult,
        "$Test->{Name} - Requester result structure is valid",
    );

    $Self->Is(
        $RequesterResult->{Success},
        $Test->{SuccessRequest},
        "$Test->{Name} - Requester successful result",
    );

    # tests supposed to succeed
    if ( $Test->{SuccessRemove} ) {

        # local results
        $Self->Is(
            $LocalResult->{Data}->{Success},
            1,
            "$Test->{Name} - Local result Success with True.",
        );

        # requester results
        $Self->Is(
            $RequesterResult->{Data}->{Success},
            1,
            "$Test->{Name} - Requester result Success with True.",
        );
    }

    # tests supposed to fail
    else {
        $Self->Is(
            $LocalResult->{Data}->{Success},
            undef,
            "$Test->{Name} - Local result Success with undef.",
        );

        # remove ErrorMessage parameter from direct call
        # result to be consistent with SOAP call result
        if ( $LocalResult->{ErrorMessage} ) {
            delete $LocalResult->{ErrorMessage};
        }

        # sanity check
        $Self->False(
            $LocalResult->{ErrorMessage},
            "$Test->{Name} - Local result ErrorMessage (outside Data hash) got removed to compare"
                . " local and remote tests.",
        );

        $Self->IsDeeply(
            $LocalResult,
            $RequesterResult,
            "$Test->{Name} - Local result matched with remote result.",
        );
    }
}

# clean up web service
my $WebserviceDelete = $WebserviceObject->WebserviceDelete(
    ID     => $WebserviceID,
    UserID => 1,
);
$Self->True(
    $WebserviceDelete,
    "Deleted web service $WebserviceID",
);

# cleanup sessions
my $CleanUp = $Kernel::OM->Get('Kernel::System::AuthSession')->CleanUp();

1;
