# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Operation::Session::SessionRemove;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(
    Kernel::GenericInterface::Operation::Common
    Kernel::GenericInterface::Operation::Session::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::Session::SessionRemove - GenericInterface Session Remove Operation backend

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=head2 Run()

Removes a session. Returns true (session deleted), false (if session can not get deleted).

    my $Result = $OperationObject->Run(
        Data => {
            SessionID => '12345678243',
        },
    );

    $Result = {
        Success      => 1,                                                  # 0 or 1
        ErrorMessage => 'SessionRemove: Could not remove SessionID!',       # In case of an error
        Data         => {
            Success => $Success,
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $GroupObject   = $Kernel::OM->Get('Kernel::System::Group');

    if ( !IsHashRefWithData( $Param{Data} ) ) {
        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.MissingParameter',
            ErrorMessage => "SessionRemove: Parameter 'Data' is missing or empty.",
        );
    }

    if ( !IsStringWithData( $Param{Data}->{SessionID} ) ) {
        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.MissingParameter',
            ErrorMessage => "SessionRemove: Parameter 'SessionID' in 'Data' is missing or empty.",
        );
    }

    my $Success = $SessionObject->RemoveSessionID(
        SessionID => $Param{Data}->{SessionID},
    );

    if ( !$Success ) {
        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.Fail',
            ErrorMessage => "SessionRemove: Could not remove session with ID '$Param{Data}->{SessionID}'.",
        );
    }

    return {
        Success => 1,
        Data    => {
            Success => $Success,
        },
    };
}

1;
