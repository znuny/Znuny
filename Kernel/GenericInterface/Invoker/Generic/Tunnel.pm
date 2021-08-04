# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Invoker::Generic::Tunnel;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsString IsStringWithData);

# prevent 'Used once' warning for Kernel::OM
use Kernel::System::ObjectManager;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Invoker::Generic::Tunnel

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Invoker->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    if ( !$Param{DebuggerObject} ) {
        return {
            Success      => 0,
            ErrorMessage => "Got no DebuggerObject!"
        };
    }

    $Self->{DebuggerObject} = $Param{DebuggerObject};

    return $Self;
}

=head2 PrepareRequest()

prepare the invocation of the configured remote web service.

    my $Result = $InvokerObject->PrepareRequest(
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub PrepareRequest {
    my ( $Self, %Param ) = @_;

    return {
        Success => 1,
        Data    => $Param{Data},
    };
}

=head2 HandleResponse()

handle response data of the configured remote web service.

    my $Result = $InvokerObject->HandleResponse(
        ResponseSuccess      => 1,              # success status of the remote web service
        ResponseErrorMessage => '',             # in case of web service error
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub HandleResponse {
    my ( $Self, %Param ) = @_;

    # if there was an error in the response, forward it
    if ( !$Param{ResponseSuccess} ) {
        if ( !IsStringWithData( $Param{ResponseErrorMessage} ) ) {
            return $Self->{DebuggerObject}->Error(
                Summary => 'Got response error, but no response error message!',
            );
        }
        return {
            Success      => 0,
            ErrorMessage => $Param{ResponseErrorMessage},
        };
    }

    return {
        Success => 1,
        Data    => $Param{Data},
    };
}

1;
