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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);

my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
my $HelperObject     = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $SessionObject    = $Kernel::OM->Get('Kernel::System::AuthSession');
my $RequesterObject  = $Kernel::OM->Get('Kernel::GenericInterface::Requester');

my $RandomID = $HelperObject->GetRandomID();

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
$WebserviceObject->WebserviceUpdate(
    ID      => $WebserviceID,
    Name    => $WebserviceName,
    Config  => $WebserviceConfig,
    ValidID => 1,
    UserID  => 1,
);

my $Password = $RandomID;

# create a new user for current test
my ( $UserLogin, $UserID ) = $HelperObject->TestUserCreate();

my @Tests = (
    {
        Name                  => 'Data parameter is missing',
        Operation             => 'SessionRemove',
        ExpectedRequestResult => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.MissingParameter',
                    ErrorMessage => "SessionRemove: Parameter 'Data' is missing or empty.",
                },
            },
            Success => 1
        },
    },
    {
        Name        => 'SessionID parameter is missing in key "Data"',
        Operation   => 'SessionRemove',
        RequestData => {
            Foo => 1,    # Just in here so that Data is filled, but missing SessionID
        },
        ExpectedRequestResult => {
            Data => {
                Error => {
                    ErrorCode    => 'SessionRemove.MissingParameter',
                    ErrorMessage => "SessionRemove: Parameter 'SessionID' in 'Data' is missing or empty.",
                },
            },
            Success => 1
        },
    },
    {
        Name        => 'Successfully removing session',
        Operation   => 'SessionRemove',
        RequestData => {
            SessionID => 'NEW',
        },
        ExpectedRequestResult => {
            Data => {
                Success => 1,
            },
            Success => 1
        },
    },
);

for my $Test (@Tests) {

    # create new session ID via backend
    my $SessionID = $SessionObject->CreateSessionID(
        UserType        => 'User',                                                       # User|Customer
        UserLogin       => $UserLogin,
        UserID          => $UserID,
        UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    );

    if ( $Test->{RequestData}->{SessionID} && $Test->{RequestData}->{SessionID} eq 'NEW' ) {
        $Test->{RequestData}->{SessionID} = $SessionID;
    }

    # start requester with our web service
    my $RequesterResult = $RequesterObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => $Test->{RequestData},
    );

    # check result
    $Self->Is(
        'HASH',
        ref $RequesterResult,
        "$Test->{Name} - Requester result structure is valid",
    );

    $Self->IsDeeply(
        $RequesterResult,
        $Test->{ExpectedRequestResult},
        "$Test->{Name} - Requester result matches expected result",
    );
}

$WebserviceObject->WebserviceDelete(
    ID     => $WebserviceID,
    UserID => 1,
);

# cleanup sessions
my $CleanUp = $SessionObject->CleanUp();

1;
