# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Common;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::Common - Base class for all Operations

=head1 PUBLIC INTERFACE

=head2 Auth()

performs user or customer user authorization

    my ( $UserID, $UserType ) = $CommonObject->Auth(
        Data => {
            SessionID         => 'AValidSessionIDValue'     # the ID of the user session
            UserLogin         => 'Agent1',                  # optional, provide UserLogin or CustomerUserLogin
            # or
            CustomerUserLogin => 'Customer1',               # optional, provide UserLogin or CustomerUserLogin

            Password          => 'some password',           # user password
        },
    );

    returns

    (
        1,                                              # the UserID from login or session data
        'User',                                         # || 'Customer' or 'User', the UserType.
    );

=cut

sub Auth {
    my ( $Self, %Param ) = @_;

    my $SessionID = $Param{Data}->{SessionID} || '';

    # check if a valid SessionID is present
    if ($SessionID) {
        my $ValidSessionID;

        # get session object
        my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

        if ($SessionID) {
            $ValidSessionID = $SessionObject->CheckSessionID( SessionID => $SessionID );
        }
        return 0 if !$ValidSessionID;

        # get session data
        my %UserData = $SessionObject->GetSessionIDData(
            SessionID => $SessionID,
        );

        # get UserID from SessionIDData
        if ( $UserData{UserID} && $UserData{UserType} ne 'Customer' ) {
            return ( $UserData{UserID}, $UserData{UserType} );
        }
        elsif ( $UserData{UserLogin} && $UserData{UserType} eq 'Customer' ) {

            # if UserCustomerLogin
            return ( $UserData{UserLogin}, $UserData{UserType} );
        }
        return 0;
    }

    if ( defined $Param{Data}->{UserLogin} && $Param{Data}->{UserLogin} ) {

        my $UserID = $Self->_AuthUser(%Param);

        # if UserLogin
        if ($UserID) {
            return ( $UserID, 'User' );
        }
    }
    elsif ( defined $Param{Data}->{CustomerUserLogin} && $Param{Data}->{CustomerUserLogin} ) {

        my $CustomerUserID = $Self->_AuthCustomerUser(%Param);

        # if UserCustomerLogin
        if ($CustomerUserID) {
            return ( $CustomerUserID, 'Customer' );
        }
    }

    return 0;
}

=head2 ReturnError()

helper function to return an error message.

    my $Return = $CommonObject->ReturnError(
        ErrorCode    => Ticket.AccessDenied,
        ErrorMessage => 'You don't have rights to access this ticket',
    );

=cut

sub ReturnError {
    my ( $Self, %Param ) = @_;

    $Self->{DebuggerObject}->Error(
        Summary => $Param{ErrorCode},
        Data    => $Param{ErrorMessage},
    );

    # return structure
    return {
        Success      => 1,
        ErrorMessage => "$Param{ErrorCode}: $Param{ErrorMessage}",
        Data         => {
            Error => {
                ErrorCode    => $Param{ErrorCode},
                ErrorMessage => $Param{ErrorMessage},
            },
        },
    };
}

=begin Internal:

=head2 _AuthUser()

performs user authentication

    my $UserID = $CommonObject->_AuthUser(
        UserLogin => 'Agent',
        Password  => 'some password',           # plain text password
    );

    returns

    $UserID = 1;                                # the UserID from login or session data

=cut

sub _AuthUser {
    my ( $Self, %Param ) = @_;

    my $ReturnData = 0;

    # get params
    my $PostUser = $Param{Data}->{UserLogin} || '';
    my $PostPw   = $Param{Data}->{Password}  || '';

    # check submitted data
    my $User = $Kernel::OM->Get('Kernel::System::Auth')->Auth(
        User => $PostUser,
        Pw   => $PostPw,
    );

    # login is valid
    if ($User) {

        # get UserID
        my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $User,
        );
        $ReturnData = $UserID;
    }

    return $ReturnData;
}

=head2 _AuthCustomerUser()

performs customer user authentication

    my $UserID = $CommonObject->_AuthCustomerUser(
        CustomerUserLogin' => 'Customer1',
        Password           => 'some password',           # plain text password
    );

    returns

    $UserID = 1;                               # the UserID from login or session data

=cut

sub _AuthCustomerUser {
    my ( $Self, %Param ) = @_;

    my $ReturnData = $Param{Data}->{CustomerUserLogin} || 0;

    # get params
    my $PostUser = $Param{Data}->{CustomerUserLogin} || '';
    my $PostPw   = $Param{Data}->{Password}          || '';

    # check submitted data
    my $User = $Kernel::OM->Get('Kernel::System::CustomerAuth')->Auth(
        User => $PostUser,
        Pw   => $PostPw,
    );

    # login is invalid
    if ( !$User ) {
        $ReturnData = 0;
    }

    return $ReturnData;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
