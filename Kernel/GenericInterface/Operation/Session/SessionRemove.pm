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
            SessionID         => '12345678243',

            UserLogin         => 'Agent1',
            # or
            CustomerUserLogin => 'Customer1',       # optional, provide UserLogin or CustomerUserLogin
            Password          => 'some password',   # plain text password

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
            ErrorMessage => "SessionRemove: The request is empty!",
        );
    }

    for my $Needed (qw( SessionID )) {
        if ( !$Param{Data}->{$Needed} ) {
            return $Self->ReturnError(
                ErrorCode    => 'SessionRemove.MissingParameter',
                ErrorMessage => "SessionRemove: $Needed parameter is missing!",
            );
        }
    }

    # delete SessionID from $Param{Data} hash
    # UserLogin or CustomerUserLogin are needed to authenticate
    my $SessionID = $Param{Data}->{SessionID};
    delete $Param{Data}->{SessionID};

    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.AuthFail',
            ErrorMessage => "SessionRemove: Authorization failed!",
        );
    }

    my %UserData = $SessionObject->GetSessionIDData(
        SessionID => $SessionID,
    );

    # return if no SessionData exists
    if ( !%UserData ) {
        return {
            Success => 1,
            Data    => {
                Success => 1,
            },
        };
    }

    # check UserID of 'Customer' user
    if ( $UserType eq 'Customer' && $UserData{UserID} && $UserData{UserID} ne $UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.AuthFail',
            ErrorMessage => "SessionRemove: Authorization failing!",
        );
    }

    # check UserID of 'User' (agent)
    if ( $UserType eq 'User' && $UserData{UserID} && $UserData{UserID} ne $UserID ) {

        # Only users of group admin are allowed to remove foreign Sessions
        my %Groups = reverse $GroupObject->PermissionUserGroupGet(
            UserID => $UserID,
            Type   => 'rw',
        );
        if ( !%Groups || !$Groups{admin} ) {
            return $Self->ReturnError(
                ErrorCode    => 'SessionRemove.AuthFail',
                ErrorMessage => "SessionRemove: Authorization failed! User needs to be in group admin.",
            );
        }
    }

    my $Success = $SessionObject->RemoveSessionID(
        SessionID => $SessionID,
    );

    if ( $Success == 0 ) {

        return $Self->ReturnError(
            ErrorCode    => 'SessionRemove.Fail',
            ErrorMessage => "SessionRemove: Could not remove SessionID!",
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
