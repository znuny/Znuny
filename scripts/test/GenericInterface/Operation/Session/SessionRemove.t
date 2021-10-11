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

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation::Session::SessionCreate;
use Kernel::GenericInterface::Operation::Session::SessionRemove;

use Kernel::System::VariableCheck qw(:all);

my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $WebserviceObject       = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $SessionObject          = $Kernel::OM->Get('Kernel::System::AuthSession');
my $RequesterSessionObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');

# skip SSL certificate verification
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);

my $RandomID = $HelperObject->GetRandomID();

# create web service object
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

# get remote host with some precautions for certain unit test systems
my $Host = $HelperObject->GetTestHTTPHostname();

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
                NameSpace => 'http://znuny.org/SoapTestInterface/',
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
                NameSpace => 'http://znuny.org/SoapTestInterface/',
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

# Get SessionID via SessionCreate
# create requester object
$Self->Is(
    'Kernel::GenericInterface::Requester',
    ref $RequesterSessionObject,
    'SessionID - Create requester object'
);

my $Password = $RandomID;

# create session id via backend
# create a new user for current test
my ( $ForeignUserLogin, $OldUserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
    UserPw => $Password,
);

my $ForeignUserSessionID = $SessionObject->CreateSessionID(
    UserID    => $OldUserID,
    UserType  => 'User',
    UserLogin => $ForeignUserLogin,
    Password  => $Password,
);

# create a new user for current test
my ( $UserLogin, $UserID ) = $HelperObject->TestUserCreate(
    Groups => ['users'],
    UserPw => $Password,
);
my ( $AdminUserLogin, $AdminUserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
    UserPw => $Password,
);

my $CustomerUserLogin = $HelperObject->TestCustomerUserCreate(
    Language     => 'de',
    UserPassword => $Password,
);
my $CustomerUserID = $CustomerUserLogin;

my @Tests = (
    {
        Name                  => 'SessionID is missing',
        SuccessRequest        => 1,
        SuccessRemove         => 0,
        ExpectedOperationData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.MissingParameter',
                    ErrorMessage => 'SessionRemove: SessionID parameter is missing!'
                },
            },
            ErrorMessage => 'SessionRemove.MissingParameter: SessionRemove: SessionID parameter is missing!',
            Success      => 1
        },
        ExpectedRequestData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.MissingParameter',
                    ErrorMessage => 'SessionRemove: SessionID parameter is missing!'
                },
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Wrong auth',
        SuccessRequest => 1,
        SuccessRemove  => 0,
        Auth           => {
            UserLogin => 'UNKNOWN',
            Password  => 'UNKNOWN',
        },
        RequestData => {
            SessionID => 'NEW'
        },
        ExpectedOperationData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.AuthFail',
                    ErrorMessage => 'SessionRemove: Authorization failed!',
                },
            },
            ErrorMessage => 'SessionRemove.AuthFail: SessionRemove: Authorization failed!',
            Success      => 1
        },
        ExpectedRequestData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.AuthFail',
                    ErrorMessage => 'SessionRemove: Authorization failed!',
                },
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'SessionID does not exist',
        SuccessRequest => 1,
        SuccessRemove  => 1,
        RequestData    => {
            SessionID => '123456789'
        },
        ExpectedOperationData => {
            Data => {
                Success => 1
            },
            Success => 1
        },
        ExpectedRequestData => {
            Data => {
                Success => 1
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Agent - removes Session',
        SuccessRequest => 1,
        SuccessRemove  => 1,
        Auth           => {
            UserID    => $UserID,
            UserLogin => $UserLogin,
            Password  => $Password,
        },
        RequestData => {
            SessionID => 'NEW',
        },
        ExpectedOperationData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        ExpectedRequestData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Agent can not remove foreign SessionID - removes Session',
        SuccessRequest => 1,
        SuccessRemove  => 0,
        Auth           => {
            UserID    => $UserID,
            UserLogin => $UserLogin,
            Password  => $Password,
        },
        RequestData => {
            SessionID => $ForeignUserSessionID,
        },
        ExpectedOperationData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.AuthFail',
                    ErrorMessage => 'SessionRemove: Authorization failed! User needs to be in group admin.',
                },
            },
            ErrorMessage =>
                'SessionRemove.AuthFail: SessionRemove: Authorization failed! User needs to be in group admin.',
            Success => 1
        },
        ExpectedRequestData => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.AuthFail',
                    ErrorMessage => 'SessionRemove: Authorization failed! User needs to be in group admin.',
                },
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Admin removes foreign SessionID - removes Session',
        SuccessRequest => 1,
        SuccessRemove  => 1,
        Auth           => {
            UserID    => $AdminUserID,
            UserLogin => $AdminUserLogin,
            Password  => $Password,
        },
        RequestData => {
            SessionID => $ForeignUserSessionID,
        },
        ExpectedOperationData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        ExpectedRequestData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
    {
        Name           => 'Customer - removes Session',
        SuccessRequest => 1,
        SuccessRemove  => 1,
        Auth           => {
            CustomerUserID    => $CustomerUserID,
            CustomerUserLogin => $CustomerUserLogin,
            Password          => $Password,
        },
        CreateSessionID => {
            UserType          => 'Customer',
            CustomerUserLogin => $CustomerUserLogin,
        },
        RequestData => {
            SessionID => 'NEW'
        },

        ExpectedOperationData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        ExpectedRequestData => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
        Operation => 'SessionRemove',
    },
);

for my $Test (@Tests) {

    $HelperObject->FixedTimeSetByTimeStamp('2021-08-24 10:00:00');

    my %CreateSessionID = (
        UserType  => 'User',       # User|Customer
        UserLogin => $UserLogin,
    );

    if ( IsHashRefWithData( $Test->{CreateSessionID} ) ) {
        %CreateSessionID = %{ $Test->{CreateSessionID} };
    }

    # create new session id via backend
    my $SessionID = $SessionObject->CreateSessionID(
        %CreateSessionID,
    );

    my %Auth = (
        UserID    => $UserID,      # User|Customer
        UserType  => 'User',       # User|Customer
        UserLogin => $UserLogin,
        Password  => $Password,
    );

    if ( IsHashRefWithData( $Test->{Auth} ) ) {
        %Auth = %{ $Test->{Auth} };
    }

    if ( $Test->{RequestData}->{SessionID} && $Test->{RequestData}->{SessionID} eq 'NEW' ) {
        $Test->{RequestData}->{SessionID} = $SessionID;
    }

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

    # start requester with our web service directly
    my $LocalResult = $LocalObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => {
            %Auth,
            %{ $Test->{RequestData} },
        },
    );

    $Self->IsDeeply(
        $LocalResult,
        $Test->{ExpectedOperationData},
        "$Test->{Name} - Local result matched with expected data.",
    );

    # wait 5 seconds between requests to have different timestamps
    $HelperObject->FixedTimeAddSeconds(5);

    # check result
    $Self->Is(
        'HASH',
        ref $LocalResult,
        "$Test->{Name} - Local result structure is valid",
    );

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

    $Self->IsDeeply(
        $RequesterResult,
        $Test->{ExpectedRequestData},
        "$Test->{Name} - Requester result matched with expected data.",
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
my $CleanUp = $SessionObject->CleanUp();

1;
