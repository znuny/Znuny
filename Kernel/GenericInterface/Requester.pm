# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Requester;

use strict;
use warnings;

use Storable;

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Invoker;
use Kernel::GenericInterface::Mapping;
use Kernel::GenericInterface::Transport;
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::Log',
    'Kernel::GenericInterface::ErrorHandling',
);

=head1 NAME

Kernel::GenericInterface::Requester - GenericInterface handler for sending web service requests to remote providers

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not create it directly, instead use:

    my $RequesterObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

receives the current incoming web service request, handles it,
and returns an appropriate answer based on the configured requested
web service.

    my $Result = $RequesterObject->Run(
        WebserviceID => 1,                      # ID of the configured remote web service to use OR
        Invoker      => 'some_operation',       # Name of the Invoker to be used for sending the request
        Asynchronous => 1,                      # Optional, 1 or 0, defaults to 0
        Data         => {                       # Data payload for the Invoker request (remote web service)
           #...
        },
        PastExecutionData => {                  # Meta data containing information about previous request attempts, optional
            #...
        }
    );

    $Result = {
        Success      => 1,   # 0 or 1
        ErrorMessage => '',  # if an error occurred
        Data         => {    # Data payload of Invoker result (web service response)
            #...
        },
    };

in case of an error if the request has been made asynchronously it can be re-schedule in future if
the invoker returns the appropriate information

    $Result = {
        Success      => 0,   # 0 or 1
        ErrorMessage => 'some error message',
        Data         => {
            ReSchedule    => 1,
            ExecutionTime => '2015-01-01 00:00:00',     # optional
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(WebserviceID Invoker Data)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Got no $Needed!",
            );

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!",
            };
        }
    }

    #
    # Locate desired web service and load its configuration data.
    #

    my $WebserviceID = $Param{WebserviceID};

    my $Webservice = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
        ID => $WebserviceID,
    );

    if ( !IsHashRefWithData($Webservice) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Could not load web service configuration for web service $Param{WebserviceID}",
        );

        return {
            Success => 0,
            ErrorMessage =>
                "Could not load web service configuration for web service $Param{WebserviceID}",
        };
    }

    my $RequesterConfig = $Webservice->{Config}->{Requester};

    #
    # Create a debugger instance which will log the details of this
    #   communication entry.
    #

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig    => $Webservice->{Config}->{Debugger},
        WebserviceID      => $WebserviceID,
        CommunicationType => 'Requester',
    );

    if ( ref $DebuggerObject ne 'Kernel::GenericInterface::Debugger' ) {

        return {
            Success      => 0,
            ErrorMessage => "Could not initialize debugger",
        };
    }

    $DebuggerObject->Debug(
        Summary => 'Communication sequence started',
        Data    => $Param{Data},
    );

    #
    # Create Invoker object and prepare the request on it.
    #

    $DebuggerObject->Debug(
        Summary => "Using invoker '$Param{Invoker}'",
    );

    my $InvokerObject = Kernel::GenericInterface::Invoker->new(
        DebuggerObject => $DebuggerObject,
        Invoker        => $Param{Invoker},
        InvokerType    => $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{Type},
        WebserviceID   => $WebserviceID,
    );

    # Bail out if invoker initialization failed.
    if ( ref $InvokerObject ne 'Kernel::GenericInterface::Invoker' ) {

        return $DebuggerObject->Error(
            Summary => 'InvokerObject could not be initialized',
            Data    => $InvokerObject,
        );
    }

    # Prepare the data include configuration and payload.
    my %DataInclude = (
        RequesterRequestInput => $Param{Data},
    );

    # Combine all data for error handler we got so far.
    my %HandleErrorData = (
        InvokerObject     => $InvokerObject,
        Invoker           => $Param{Invoker},
        DebuggerObject    => $DebuggerObject,
        WebserviceID      => $WebserviceID,
        WebserviceConfig  => $Webservice->{Config},
        PastExecutionData => $Param{PastExecutionData},
    );

    my $FunctionResult = $InvokerObject->PrepareRequest(
        Webservice  => $Webservice,
        InvokerName => $Param{Invoker},
        Data        => $Param{Data},
    );

    if ( !$FunctionResult->{Success} ) {

        my $Summary = $FunctionResult->{ErrorMessage} // 'InvokerObject returned an error, cancelling Request';
        return $Self->_HandleError(
            %HandleErrorData,
            DataInclude => \%DataInclude,
            ErrorStage  => 'RequesterRequestPrepare',
            Summary     => $Summary,
            Data        => $FunctionResult->{Data} // $Summary,
        );
    }

    # Not always a success on the invoker prepare request means that invoker need to do something
    #   there are cases in which the requester does not need to do anything, for this cases
    #   StopCommunication can be sent. in this cases the request will be successful with out sending
    #   the request actually.
    elsif ( $FunctionResult->{StopCommunication} && $FunctionResult->{StopCommunication} eq 1 ) {

        return {
            Success => 1,
        };
    }

    # Extend the data include payload/
    $DataInclude{RequesterRequestPrepareOutput} = $FunctionResult->{Data};

    #
    # Map the outgoing data.
    #

    my $DataOut = $FunctionResult->{Data};

    $DebuggerObject->Debug(
        Summary => "Outgoing data before mapping",
        Data    => $DataOut,
    );

    # Decide if mapping needs to be used or not.
    if (
        IsHashRefWithData(
            $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{MappingOutbound}
        )
        )
    {
        my $MappingOutObject = Kernel::GenericInterface::Mapping->new(
            DebuggerObject => $DebuggerObject,
            Invoker        => $Param{Invoker},
            InvokerType    => $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{Type},
            MappingConfig =>
                $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{MappingOutbound},
        );

        # If mapping initialization failed, bail out.
        if ( ref $MappingOutObject ne 'Kernel::GenericInterface::Mapping' ) {
            $DebuggerObject->Error(
                Summary => 'MappingOut could not be initialized',
                Data    => $MappingOutObject,
            );

            return $DebuggerObject->Error(
                Summary => $FunctionResult->{ErrorMessage},
            );
        }

        $FunctionResult = $MappingOutObject->Map(
            Data        => $DataOut,
            DataInclude => \%DataInclude,
        );

        if ( !$FunctionResult->{Success} ) {

            my $Summary = $FunctionResult->{ErrorMessage} // 'MappingOutObject returned an error, cancelling Request';
            return $Self->_HandleError(
                %HandleErrorData,
                DataInclude => \%DataInclude,
                ErrorStage  => 'RequesterRequestMap',
                Summary     => $Summary,
                Data        => $FunctionResult->{Data} // $Summary,
            );
        }

        # Extend the data include payload.
        $DataInclude{RequesterRequestMapOutput} = $FunctionResult->{Data};

        $DataOut = $FunctionResult->{Data};

        $DebuggerObject->Debug(
            Summary => "Outgoing data after mapping",
            Data    => $DataOut,
        );
    }

    my $TransportObject = Kernel::GenericInterface::Transport->new(
        DebuggerObject  => $DebuggerObject,
        TransportConfig => $RequesterConfig->{Transport},
    );

    # Bail out if transport initialization failed.
    if ( ref $TransportObject ne 'Kernel::GenericInterface::Transport' ) {

        return $DebuggerObject->Error(
            Summary => 'TransportObject could not be initialized',
            Data    => $TransportObject,
        );
    }

    # Read request content.
    $FunctionResult = $TransportObject->RequesterPerformRequest(
        Webservice => $Webservice,
        Sort       => $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{SortOutbound},
        Operation  => $Param{Invoker},
        Data       => $DataOut,
    );

    my $IsAsynchronousCall = $Param{Asynchronous} ? 1 : 0;

    if ( !$FunctionResult->{Success} ) {

        my $Summary     = $FunctionResult->{ErrorMessage} // 'TransportObject returned an error, cancelling Request';
        my $ErrorReturn = $Self->_HandleError(
            %HandleErrorData,
            DataInclude => \%DataInclude,
            ErrorStage  => 'RequesterRequestPerform',
            Summary     => $Summary,
            Data        => $FunctionResult->{Data} // $Summary,
        );

        # Send error to Invoker.
        my $Response = $InvokerObject->HandleResponse(
            ResponseSuccess      => 0,
            ResponseErrorMessage => $FunctionResult->{ErrorMessage},
        );

        if ($IsAsynchronousCall) {

            RESPONSEKEY:
            for my $ResponseKey ( sort keys %{$Response} ) {

                # Skip Success and ErrorMessage as they are set already.
                next RESPONSEKEY if $ResponseKey eq 'Success';
                next RESPONSEKEY if $ResponseKey eq 'ErrorMessage';

                # Add any other key from the invoker HandleResponse() in Data.
                $ErrorReturn->{$ResponseKey} = $Response->{$ResponseKey};
            }
        }

        return $ErrorReturn;
    }

    # Extend the data include payload.
    $DataInclude{RequesterResponseInput} = $FunctionResult->{Data};

    my $DataIn       = $FunctionResult->{Data};
    my $SizeExceeded = $FunctionResult->{SizeExceeded} || 0;

    if ($SizeExceeded) {
        $DebuggerObject->Debug(
            Summary => "Incoming data before mapping was too large for logging",
            Data => 'See SysConfig option GenericInterface::Operation::ResponseLoggingMaxSize to change the maximum.',
        );
    }
    else {
        $DebuggerObject->Debug(
            Summary => "Incoming data before mapping",
            Data    => $DataIn,
        );
    }

    # Decide if mapping needs to be used or not.
    if (
        IsHashRefWithData(
            $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{MappingInbound}
        )
        )
    {
        my $MappingInObject = Kernel::GenericInterface::Mapping->new(
            DebuggerObject => $DebuggerObject,
            Invoker        => $Param{Invoker},
            InvokerType    => $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{Type},
            MappingConfig =>
                $RequesterConfig->{Invoker}->{ $Param{Invoker} }->{MappingInbound},
        );

        # If mapping initialization failed, bail out.
        if ( ref $MappingInObject ne 'Kernel::GenericInterface::Mapping' ) {
            $DebuggerObject->Error(
                Summary => 'MappingOut could not be initialized',
                Data    => $MappingInObject,
            );

            return $DebuggerObject->Error(
                Summary => $FunctionResult->{ErrorMessage},
            );
        }

        $FunctionResult = $MappingInObject->Map(
            Data        => $DataIn,
            DataInclude => \%DataInclude,
        );

        if ( !$FunctionResult->{Success} ) {

            my $Summary = $FunctionResult->{ErrorMessage} // 'MappingInObject returned an error, cancelling Request';
            return $Self->_HandleError(
                %HandleErrorData,
                DataInclude => \%DataInclude,
                ErrorStage  => 'RequesterResponseMap',
                Summary     => $Summary,
                Data        => $FunctionResult->{Data} // $Summary,
            );
        }

        # Extend the data include payload.
        $DataInclude{RequesterResponseMapOutput} = $FunctionResult->{Data};

        $DataIn = $FunctionResult->{Data};

        if ($SizeExceeded) {
            $DebuggerObject->Debug(
                Summary => "Incoming data after mapping was too large for logging",
                Data =>
                    'See SysConfig option GenericInterface::Operation::ResponseLoggingMaxSize to change the maximum.',
            );
        }
        else {
            $DebuggerObject->Debug(
                Summary => "Incoming data after mapping",
                Data    => $DataIn,
            );
        }
    }

    #
    # Handle response data in Invoker.
    #

    $FunctionResult = $InvokerObject->HandleResponse(
        ResponseSuccess => 1,
        Data            => $DataIn,
    );

    if ( !$FunctionResult->{Success} ) {

        my $Summary     = $FunctionResult->{ErrorMessage} // 'InvokerObject returned an error, cancelling Request';
        my $ErrorReturn = $Self->_HandleError(
            %HandleErrorData,
            DataInclude => \%DataInclude,
            ErrorStage  => 'RequesterResponseProcess',
            Summary     => $Summary,
            Data        => $FunctionResult->{Data} // $Summary,
        );

        if ($IsAsynchronousCall) {

            RESPONSEKEY:
            for my $ResponseKey ( sort keys %{$FunctionResult} ) {

                # Skip Success and ErrorMessage as they are set already.
                next RESPONSEKEY if $ResponseKey eq 'Success';
                next RESPONSEKEY if $ResponseKey eq 'ErrorMessage';

                # Add any other key from the invoker HandleResponse() in Data.
                $ErrorReturn->{$ResponseKey} = $FunctionResult->{$ResponseKey};
            }
        }

        return $ErrorReturn;
    }

    $DataIn = $FunctionResult->{Data};

    return {
        Success => 1,
        Data    => $DataIn,
    };
}

=head2 _HandleError()

handles errors by
- informing invoker about it (if supported)
- calling an error handling layer

    my $ReturnData = $RequesterObject->_HandleError(
        InvokerObject     => $InvokerObject,
        Invoker           => 'InvokerName',
        DebuggerObject    => $DebuggerObject,
        WebserviceID      => 1,
        WebserviceConfig  => $WebserviceConfig,
        DataInclude       => $DataIncludeStructure,
        ErrorStage        => 'PrepareRequest',              # at what point did the error occur?
        Summary           => 'an error occurred',
        Data              => $ErrorDataStructure,
        PastExecutionData => $PastExecutionDataStructure,   # optional
    );

    my $ReturnData = {
        Success      => 0,
        ErrorMessage => $Param{Summary},
    };

=cut

sub _HandleError {
    my ( $Self, %Param ) = @_;

    NEEDED:
    for my $Needed (
        qw(InvokerObject Invoker DebuggerObject WebserviceID WebserviceConfig DataInclude ErrorStage Summary Data)
        )
    {
        next NEEDED if $Param{$Needed};
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Got no $Needed!",
        );

        return {
            Success      => 0,
            ErrorMessage => "Got no $Needed!",
        };
    }

    my $ErrorHandlingResult = $Kernel::OM->Get('Kernel::GenericInterface::ErrorHandling')->HandleError(
        WebserviceID      => $Param{WebserviceID},
        WebserviceConfig  => $Param{WebserviceConfig},
        CommunicationID   => $Param{DebuggerObject}->{CommunicationID},
        CommunicationType => 'Requester',
        CommunicationName => $Param{Invoker},
        ErrorStage        => $Param{ErrorStage},
        Summary           => $Param{Summary},
        Data              => $Param{Data},
        PastExecutionData => $Param{PastExecutionData},
    );

    my $ReturnData = {
        Success      => 0,
        ErrorMessage => $ErrorHandlingResult->{ErrorMessage} || $Param{Summary},
        Data         => $ErrorHandlingResult->{ReScheduleData},
    };

    return $ReturnData if !$Param{InvokerObject}->{BackendObject}->can('HandleError');

    my $HandleErrorData;
    if ( !defined $Param{Data} || IsString( $Param{Data} ) ) {
        $HandleErrorData = $Param{Data} // '';
    }
    else {
        $HandleErrorData = Storable::dclone( $Param{Data} );
    }
    $Param{DebuggerObject}->Debug(
        Summary => 'Error data before mapping',
        Data    => $HandleErrorData,
    );

    # TODO: Use separate mapping config for errors.
    my $InvokerConfig = $Param{WebserviceConfig}->{Requester}->{Invoker}->{ $Param{Invoker} };
    if ( IsHashRefWithData( $InvokerConfig->{MappingInbound} ) ) {

        my $MappingErrorObject = Kernel::GenericInterface::Mapping->new(
            DebuggerObject => $Param{DebuggerObject},
            Invoker        => $Param{Invoker},
            InvokerType    => $InvokerConfig->{Type},
            MappingConfig  => $InvokerConfig->{MappingInbound},
        );

        # If mapping init failed, bail out.
        if ( ref $MappingErrorObject ne 'Kernel::GenericInterface::Mapping' ) {
            $Param{DebuggerObject}->Error(
                Summary => 'MappingErr could not be initialized',
                Data    => $MappingErrorObject,
            );

            return $ReturnData;
        }

        # Map error data.
        my $MappingErrorResult = $MappingErrorObject->Map(
            Data => {
                Fault => $HandleErrorData,
            },
            DataInclude => {
                %{ $Param{DataInclude} },
                RequesterErrorHandlingOutput => $ErrorHandlingResult->{Data},
            },
        );
        if ( !$MappingErrorResult->{Success} ) {
            $Param{DebuggerObject}->Error(
                Summary => $MappingErrorResult->{ErrorMessage},
            );

            return $ReturnData;
        }

        $HandleErrorData = $MappingErrorResult->{Data};

        $Param{DebuggerObject}->Debug(
            Summary => 'Error data after mapping',
            Data    => $HandleErrorData,
        );
    }

    my $InvokerHandleErrorOutput = $Param{InvokerObject}->HandleError(
        Data => $HandleErrorData,
    );
    if ( !$InvokerHandleErrorOutput->{Success} ) {
        $Param{DebuggerObject}->Error(
            Summary => 'Error handling error data in Invoker',
            Data    => $InvokerHandleErrorOutput->{ErrorMessage},
        );
    }

    return $ReturnData;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
