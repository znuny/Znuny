# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Session::SessionRemove;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsStringWithData IsHashRefWithData);

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

    # check needed objects
    for my $Needed (
        qw(DebuggerObject WebserviceID)
        )
    {
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

removes a session and returns true (session deleted), false (if
session can't get deleted)

    my $Result = $OperationObject->Run(
        Data => {
            SessionID         => '12345678243',
        },
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        ErrorMessage => '',                               # In case of an error
        Data         => {
            SessionID => $SessionID,
        },
    };
    
=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !IsHashRefWithData( $Param{Data} ) ) {

        return $Self->ReturnError(
            ErrorCode    => 'SessionCreate.MissingParameter',
            ErrorMessage => "SessionCreate: The request is empty!",
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
    my $Success
        = $Kernel::OM->Get('Kernel::System::AuthSession')->RemoveSessionID( SessionID => $Param{Data}->{SessionID} );

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

=head1 TERMS AND CONDITIONS

This software is part of the Znuny project (L<https://znuny.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
