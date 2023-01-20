# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Webservice;

use strict;
use warnings;

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Mapping;

# for mocking purposes
use Kernel::GenericInterface::Transport;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::GenericInterface::Provider',
    'Kernel::System::Cache',
    'Kernel::System::Daemon::SchedulerDB',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Storable',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::UnitTest::Webservice - web service lib

=head1 SYNOPSIS

All web service functions

=head1 PUBLIC INTERFACE

=cut

=head2 new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'UnitTestWebservice';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    $Self->_RedefineTransport();

    return $Self;
}

=head2 Process()

Simulates an incoming web service call to test operations and the mapping.

    my $Response = $UnitTestWebserviceObject->Process(
        UnitTestObject => $Self,
        Webservice     => 'Name123', # or
        WebserviceID   => 123,
        Operation      => 'DesiredOperation',
        Payload        => {
            ...
        },
        Response => {               # optional, you can validate the response manually in the unit test via $Self->IsDeeply()
            Success      => 1,
            ErrorMessage => '',
            Data         => {
                ...
            },
        }
    );

    my $Response = {
        Success      => 1,
        ErrorMessage => '',
        Data         => {
            ...
        },
    };

=cut

sub Process {
    my ( $Self, %Param ) = @_;

    my $CacheObject    = $Kernel::OM->Get('Kernel::System::Cache');
    my $ProviderObject = $Kernel::OM->Get('Kernel::GenericInterface::Provider');

    NEEDED:
    for my $Needed (qw(UnitTestObject Operation Payload)) {
        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    NAMEORID:
    for my $NameOrID (qw(Webservice WebserviceID)) {
        next NAMEORID if !$Param{$NameOrID};

        $ENV{REQUEST_URI} = "nph-genericinterface.pl/$NameOrID/$Param{$NameOrID}/";    ## no critic

        last NAMEORID;
    }

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        Key   => 'Payload',
        TTL   => $Self->{CacheTTL},
        Value => {
            Success   => 1,
            Operation => $Param{Operation},
            Data      => $Param{Payload},
        },
    );

    $ProviderObject->Run();

    my $Response = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => 'Response',
    );

    return $Response if !IsHashRefWithData( $Param{Response} );

    $Param{UnitTestObject}->IsDeeply(
        $Response,
        $Param{Response},
        'Response to mocked provider call',
    );

    return $Response;
}

=head2 Mock()

Mocks all outgoing requests to a given mapping.

    my $Result = $UnitTestWebserviceObject->Mock(
        InvokerName123 => [
            {
                Data => {
                    OutgoingData => 'Value'
                },
                Result => {
                    Success      => 1,
                    ErrorMessage => '',
                    Data         => {
                        YAY => 'so true',
                    },
                }
            },
            ...
        ],
        ...
    );


    Now you can use the regular framework requester object to perform this request like:

    my $RequesterObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');

    my $Result = $RequesterObject->Run(
        WebserviceID => 1,                      # ID of the configured remote web service to use
        Invoker      => 'InvokerName123',       # Name of the Invoker to be used for sending the request
        Data         => {                       # Data payload for the Invoker request (remote web service)
            OutgoingData => 'Value'
        },
    );

    $Result = {
        Success => 1,
        Data    => {
            YAY => 'so true',
        },
    };

=cut

sub Mock {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # temporarily store the given request data
    for my $InvokerName ( sort keys %Param ) {
        $CacheObject->Set(
            Type  => $Self->{CacheType},
            Key   => $InvokerName,
            Value => $Param{$InvokerName},
            TTL   => $Self->{CacheTTL},
        );
    }

    return 1;
}

=head2 MockFromFile()

Loads a mapping from JSON file placed in 'var/mocks/' in the
Webservice sub directory named as the Invoker like e.g.:
'var/mocks/ExampleWebservice/SomeInvoker.json'

    $UnitTestWebserviceObject->MockFromFile(
        Webservice => 'ExampleWebservice',
        Invoker    => 'SomeInvoker',
        Data       => {

        }
    );

    $UnitTestWebserviceObject->MockFromFile(
        Location => $ConfigObject->Get('Home') . "/misc/mocks/WebserviceName/SomeInvoker.json";
        Invoker    => 'SomeInvoker',
        Data       => {

        }
    );

=cut

sub MockFromFile {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(Webservice Invoker)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $MockFile
        = $Param{Location} || $ConfigObject->Get('Home') . "/var/mocks/$Param{Webservice}/$Param{Invoker}.json";

    my $JSONString = $MainObject->FileRead(
        Location => $MockFile,
        Mode     => 'utf8',
    );

    my $MockData = $JSONObject->Decode(
        Data => ${$JSONString},
    );

    $Self->Mock(
        $Param{Invoker} => [
            {
                Data   => $Param{Data} || {},
                Result => {
                    Success => 1,
                    Data    => $MockData,
                },
            },
        ],
    );

    return 1;
}

=head2 Result()

Returns the result of all requests since beginning or the last $UnitTestWebserviceObject->Result() call.
Result cache will be cleared.

    my $Result = $UnitTestWebserviceObject->Result();

    $Result = [
        {
            Success      => 0,
            ErrorMessage => "Can't find Mock data matching the given request Data structure.",
            Invoker      => 'UserDataGet',
            Data         => {
                Foo => 'Bar',
            },
        },
        {
            Success => 1,
            Invoker => 'Name',
            Data    => {
                UserID => 'han',
            },
            Result => {
                Success => 1,
                Data    => {
                    UserName => 'Han Solo',
                }
            },
            ResultCounter => 3,
        },
        ...
    ];

=cut

sub Result {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    my $CacheType       = 'UnitTestWebservice';
    my $CacheKeyResults = 'Results';

    my $StoredResults = $CacheObject->Get(
        Type => $CacheType,
        Key  => $CacheKeyResults,
    );
    $StoredResults //= [];

    $CacheObject->Delete(
        Type => $CacheType,
        Key  => $CacheKeyResults,
    );

    return $StoredResults;
}

=head2 ValidateResult()

Processes the results of expected mocked web service calls.
If no web service call was mocked, an error will be output.

    my $Result = $UnitTestWebserviceObject->ValidateResult(
        UnitTestObject => $Self,
        RequestCount   => 1, # default, defines the number of requests that should have been processed
    );

    $Result = [
        {
            Success      => 0,
            ErrorMessage => "Can't find Mock data matching the given request Data structure.",
            Invoker      => 'UserDataGet',
            Data         => {
                Foo => 'Bar',
            },
        },
        {
            Success => 1,
            Invoker => 'Name',
            Data    => {
                UserID => 'han',
            },
            Result => {
                Success => 1,
                Data    => {
                    UserName => 'Han Solo',
                }
            },
            ResultCounter => 3,
        },
        ...
    ];

=cut

sub ValidateResult {
    my ( $Self, %Param ) = @_;

    NEEDED:
    for my $Needed (qw(UnitTestObject)) {
        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{RequestCount} ||= 1;

    my $MockResults        = $Self->Result();
    my $IsArrayRefWithData = IsArrayRefWithData($MockResults);

    $Param{UnitTestObject}->True(
        $IsArrayRefWithData,
        'Webservice calls were executed',
    );

    return if !$IsArrayRefWithData;

    my $Counter = 0;

    MOCKRESULT:
    for my $MockResult ( @{$MockResults} ) {
        $Counter++;

        my $IsHashRefWithData = IsHashRefWithData($MockResult);

        $Param{UnitTestObject}->True(
            $IsHashRefWithData,
            "$Counter - Mock result has the right structure",
        );

        next MOCKRESULT if !$IsHashRefWithData;

        my $LogMessage = "$Counter - Request mock data was found";

        if ( !$MockResult->{Success} ) {
            $LogMessage .= ". Error Message: $MockResult->{ErrorMessage}";
        }
        else {
            $LogMessage .= " for Invoker '$MockResult->{Invoker}'";
        }

        $Param{UnitTestObject}->True(
            $MockResult->{Success},
            $LogMessage,
        );
    }

    $Param{UnitTestObject}->Is(
        $Counter,
        $Param{RequestCount},
        'Number of processed web service requests matches expected one.',
    );

    return $MockResults;
}

=head2 SchedulerRunAll()

Executes all asynchronous task handler tasks.

    my $Success = $UnitTestWebserviceObject->SchedulerRunAll(
        UnitTestObject => $Self,
    );

    my $Success = $UnitTestWebserviceObject->SchedulerRunAll(
        UnitTestObject => $Self,
        Type           => 'AsynchronousExecutor', # optional, default is 'GenericInterface'
    );

Returns:

    my $Success = 1;

=cut

sub SchedulerRunAll {
    my ( $Self, %Param ) = @_;

    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

    NEEDED:
    for my $Needed (qw(UnitTestObject)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Type = $Param{Type} || 'GenericInterface';

    my $TaskHandlerObject = $Kernel::OM->Get( 'Kernel::System::Daemon::DaemonModules::SchedulerTaskWorker::' . $Type );

    my @InvokerTasks = $SchedulerDBObject->TaskList(
        Type => $Type,
    );

    $Param{UnitTestObject}->IsNot(
        scalar @InvokerTasks,
        0,
        'Found invoker tasks to execute',
    );

    for my $TaskData (@InvokerTasks) {
        my %ConfirmTask = $SchedulerDBObject->TaskGet(
            TaskID => $TaskData->{TaskID},
        );

        $TaskHandlerObject->Run(
            TaskID   => $ConfirmTask{TaskID},
            TaskName => $ConfirmTask{Name},
            Data     => $ConfirmTask{Data},
        );

        $Param{UnitTestObject}->True(
            $ConfirmTask{Name},
            "Run invoker task with name '$ConfirmTask{Name}'",
        );

        $SchedulerDBObject->TaskDelete(
            TaskID => $ConfirmTask{TaskID},
        );
    }

    return 1;
}

=head2 SchedulerCleanUp()

Cleans up all tasks for the scheduler.

    my $Success = $UnitTestWebserviceObject->SchedulerCleanUp(
        UnitTestObject => $Self,
    );

    my $Success = $UnitTestWebserviceObject->SchedulerCleanUp(
        UnitTestObject => $Self,
        Type           => 'AsynchronousExecutor', # optional, default is 'GenericInterface'
    );

Returns:

    my $Success = 1;

=cut

sub SchedulerCleanUp {
    my ( $Self, %Param ) = @_;

    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

    NEEDED:
    for my $Needed (qw(UnitTestObject)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Type = $Param{Type} || 'GenericInterface';

    my @List = $SchedulerDBObject->TaskList(
        Type => $Type,
    );

    for my $Task (@List) {
        $SchedulerDBObject->TaskDelete(
            TaskID => $Task->{TaskID},
        );
    }

    $Param{UnitTestObject}->True(
        1,
        "CleanUp for all scheduler tasks of type '$Type'",
    );

    return 1;
}

=head2 OperationFunctionCall()

Initializes an operation to test specific functions of an operation.

    my $Success = $UnitTestWebserviceObject->OperationFunctionCall(
        Webservice    => 'webservice-name',
        Operation     => 'operation-name',
        Function      => 'function',
        Data          => {},
    );

    my $Success = $UnitTestWebserviceObject->OperationFunctionCall(
        Webservice           => 'webservice-name',
        Operation            => 'operation-name',
        Function             => 'function',
        Data                 => {},
        ObjectModifyFunction => sub {
            my (%Params) = @_;

            $Params{Object}->{BackendObject}->{MessageName} = 'SEND_UPDATE';

            return 1;
        },
    );

Returns:

    my $Success = 1;

=cut

sub OperationFunctionCall {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject       = $Kernel::OM->Get('Kernel::System::Main');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    NEEDED:
    for my $Needed (qw(Webservice Operation Function Data)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $WebserviceName = $Param{Webservice};
    my $Operation      = $Param{Operation};
    my $Function       = $Param{Function};
    my $Data           = $Param{Data};

    my $Webservice = $WebserviceObject->WebserviceGet(
        Name => $WebserviceName,
    );
    return if !IsHashRefWithData($Webservice);

    my $WebserviceID   = $Webservice->{ID};
    my $ProviderConfig = $Webservice->{Config}->{Provider};

    $MainObject->Require('Kernel::GenericInterface::Debugger');
    $MainObject->Require('Kernel::GenericInterface::Operation');

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig    => $Webservice->{Config}->{Debugger},
        WebserviceID      => $WebserviceID,
        CommunicationType => 'Provider',
        RemoteIP          => $ENV{REMOTE_ADDR},
    );

    my $OperationObject = Kernel::GenericInterface::Operation->new(
        DebuggerObject => $DebuggerObject,
        Operation      => $Operation,
        OperationType  => $ProviderConfig->{Operation}->{$Operation}->{Type},
        WebserviceID   => $WebserviceID,
    );
    return if ref $OperationObject ne 'Kernel::GenericInterface::Operation';

    $Self->_WebserviceObjectModify(
        %Param,
        Object => $OperationObject,
    );

    if ( ref $Data eq 'HASH' ) {
        return $OperationObject->{BackendObject}->$Function( %{ $Data || {} } );
    }
    elsif ( ref $Data eq 'ARRAY' ) {
        return $OperationObject->{BackendObject}->$Function( @{ $Data || [] } );
    }

    return;
}

=head2 InvokerFunctionCall()

Initialize an invoker to test specific functions of an invoker.

    my $Success = $UnitTestWebserviceObject->InvokerFunctionCall(
        Webservice => 'webservice-name',
        Invoker    => 'invoker-name',
        Function   => 'function',
        Data       => {},
    );

    my $Success = $UnitTestWebserviceObject->InvokerFunctionCall(
        Webservice => 'webservice-name',
        Invoker    => 'invoker-name',
        Function   => 'function',
        Data       => {},
        ObjectModifyFunction => sub {
            my (%Params) = @_;

            $Params{Object}->{BackendObject}->{MessageName} = 'SEND_UPDATE';

            return 1;
        },
    );

Returns:

    my $Success = 1;

=cut

sub InvokerFunctionCall {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject       = $Kernel::OM->Get('Kernel::System::Main');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    NEEDED:
    for my $Needed (qw(Webservice Invoker Function Data)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $WebserviceName = $Param{Webservice};
    my $Invoker        = $Param{Invoker};
    my $Function       = $Param{Function};
    my $Data           = $Param{Data};

    my $Webservice = $WebserviceObject->WebserviceGet(
        Name => $WebserviceName,
    );
    return if !IsHashRefWithData($Webservice);

    my $WebserviceID    = $Webservice->{ID};
    my $RequesterConfig = $Webservice->{Config}->{Requester};

    $MainObject->Require('Kernel::GenericInterface::Debugger');
    $MainObject->Require('Kernel::GenericInterface::Invoker');

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig    => $Webservice->{Config}->{Debugger},
        WebserviceID      => $WebserviceID,
        CommunicationType => 'Requester',
        RemoteIP          => $ENV{REMOTE_ADDR},
    );

    my $InvokerObject = Kernel::GenericInterface::Invoker->new(
        DebuggerObject => $DebuggerObject,
        Invoker        => $Invoker,
        InvokerType    => $RequesterConfig->{Invoker}->{$Invoker}->{Type},
        WebserviceID   => $WebserviceID,
    );
    return if ref $InvokerObject ne 'Kernel::GenericInterface::Invoker';

    $Self->_WebserviceObjectModify(
        %Param,
        Object => $InvokerObject,
    );

    if ( ref $Data eq 'HASH' ) {
        return $InvokerObject->{BackendObject}->$Function( %{ $Data || {} } );
    }
    elsif ( ref $Data eq 'ARRAY' ) {
        return $InvokerObject->{BackendObject}->$Function( @{ $Data || [] } );
    }

    return;
}

=head2 _WebserviceObjectModify()

Internal function which will be used for OperationFunctionCall and InvokerFunctionCall
to modify the object values of the initialized web service invoker or operation object.

    my $Success = $UnitTestWebserviceObject->_WebserviceObjectModify(
        Object               => \$OperationObject,
        ObjectModifyFunction => sub {
            my (%Params) = @_;

            $Params{Object}->{BackendObject}->{MessageName} = 'SEND_UPDATE';

            return 1;
        },
    );

Returns:

    my $Success = 1;

=cut

sub _WebserviceObjectModify {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Object)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    return if !defined $Param{ObjectModifyFunction};

    $Param{ObjectModifyFunction}->(
        Object => $Param{Object},
    );

    return 1;
}

=head2 CreateGenericInterfaceMappingObject()

Creates a mapping object to be used within unit tests.

    my $MappingObject = $UnitTestWebserviceObject->CreateGenericInterfaceMappingObject(
        UnitTestObject    => $Self,
        WebserviceName    => 'MyWebservice',
        CommunicationType => 'Provider',
        MappingConfig     => {
            Type => 'MyMapping', # name of mapping module
            Config => {
                # ...
            },
        },
    );

=cut

sub CreateGenericInterfaceMappingObject {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    NEEDED:
    for my $Needed (qw( UnitTestObject WebserviceName CommunicationType MappingConfig )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Webservice = $WebserviceObject->WebserviceGet( Name => $Param{WebserviceName} );
    $Param{UnitTestObject}->True(
        scalar IsHashRefWithData($Webservice),
        "Web service '$Param{WebserviceName}' must exist.",
    ) || return;

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig => {
            DebugThreshold => 'debug',
            TestMode       => 1,
        },
        WebserviceID      => $Webservice->{ID},
        CommunicationType => $Param{CommunicationType},
    );

    my $MappingObject = Kernel::GenericInterface::Mapping->new(
        DebuggerObject => $DebuggerObject,
        MappingConfig  => $Param{MappingConfig},
    );

    $Param{UnitTestObject}->Is(
        ref $MappingObject,
        'Kernel::GenericInterface::Mapping',
        'Creation of mapping object must be successful.',
    ) || return;

    return $MappingObject;
}

=head2 _RedefineTransport()

Redefines the functions of the transport object to handle tests and provide the results.

    $Object->_RedefineTransport();

=cut

sub _RedefineTransport {
    my ( $Self, %Param ) = @_;

    {
        no warnings 'redefine';    ## no critic

        sub Kernel::GenericInterface::Transport::ProviderProcessRequest {    ## no critic
            my ( $Self, %Param ) = @_;

            my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

            return $CacheObject->Get(
                Type => 'UnitTestWebservice',
                Key  => 'Payload',
            );
        }

        sub Kernel::GenericInterface::Transport::ProviderGenerateResponse {    ## no critic
            my ( $Self, %Param ) = @_;

            my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

            my $CacheType = 'UnitTestWebservice';
            my $CacheKey  = 'Response';
            my $CacheTTL  = 60 * 60 * 24 * 20;

            $CacheObject->Delete(
                Type => $CacheType,
                Key  => $CacheKey,
            );

            if ( !defined $Param{Success} ) {
                my $ErrorMessage = 'Missing parameter Success.';

                return $Self->{DebuggerObject}->Error(
                    Summary => 'Missing parameter Success.',
                );
            }

            if ( $Param{Data} && ref $Param{Data} ne 'HASH' ) {
                return $Self->{DebuggerObject}->Error(
                    Summary => 'Data is not a hash reference.',
                    Data    => $Param{Data},
                );
            }

            $CacheObject->Set(
                Type  => $CacheType,
                Key   => $CacheKey,
                Value => \%Param,
                TTL   => $CacheTTL,
            );

            return {
                Success => 1,
            };
        }

        sub Kernel::GenericInterface::Transport::RequesterPerformRequest {    ## no critic
            my ( $Self, %Param ) = @_;

            my $CacheObject    = $Kernel::OM->Get('Kernel::System::Cache');
            my $StorableObject = $Kernel::OM->Get('Kernel::System::Storable');

            my $CacheType       = 'UnitTestWebservice';
            my $CacheTTL        = 60 * 60 * 24 * 20;
            my $CacheKeyResults = 'Results';

            my $StoredResults = $CacheObject->Get(
                Type => $CacheType,
                Key  => $CacheKeyResults,
            );
            $StoredResults ||= [];

            if ( !$Param{Operation} ) {
                my $ErrorMessage = 'Missing parameter Operation.';

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $CacheObject->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            if ( $Param{Data} && ref $Param{Data} ne 'HASH' ) {
                my $ErrorMessage = "Data is not a hash reference for Invoker '$Param{Operation}'.";

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $CacheObject->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $InvokerData = $CacheObject->Get(
                Type => $CacheType,
                Key  => $Param{Operation},
            );

            if ( !IsArrayRefWithData($InvokerData) ) {
                my $ErrorMessage = "Can't find matching Mock data for Invoker '$Param{Operation}'.";

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $CacheObject->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            my $Counter = 0;
            my $Result;

            POSSIBLEREQUEST:
            for my $PossibleRequest ( @{$InvokerData} ) {
                $Counter++;

                next POSSIBLEREQUEST if DataIsDifferent(
                    Data1 => $PossibleRequest->{Data},
                    Data2 => $Param{Data},
                );

                $Result = $StorableObject->Clone(
                    Data => $PossibleRequest->{Result},
                );

                last POSSIBLEREQUEST;
            }

            if ( !IsHashRefWithData($Result) ) {
                my $ErrorMessage
                    = "Can't find Mock data matching the given request Data structure for Invoker '$Param{Operation}'.";

                push @{$StoredResults}, {
                    Success      => 0,
                    ErrorMessage => $ErrorMessage,
                    Invoker      => $Param{Operation},
                    Data         => $Param{Data},
                };

                $CacheObject->Set(
                    Type  => $CacheType,
                    Key   => $CacheKeyResults,
                    Value => $StoredResults,
                    TTL   => $CacheTTL,
                );

                return $Self->{DebuggerObject}->Error(
                    Summary => $ErrorMessage,
                    Data    => $Param{Data},
                );
            }

            push @{$StoredResults}, {
                Success       => 1,
                Invoker       => $Param{Operation},
                Data          => $Param{Data},
                Result        => $Result,
                ResultCounter => $Counter,
            };

            $CacheObject->Set(
                Type  => $CacheType,
                Key   => $CacheKeyResults,
                Value => $StoredResults,
                TTL   => $CacheTTL,
            );

            return $Result;
        }
    }

    return 1;
}

1;
