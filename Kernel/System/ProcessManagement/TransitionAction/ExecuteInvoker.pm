# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::ExecuteInvoker;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::GenericInterface::Requester',
    'Kernel::System::GenericInterface::Webservice',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::ExecuteInvoker - A module to execute a Generic INterface invoker

=head1 SYNOPSIS

All ExecuteInvoker functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    my $ExecuteInvoker = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::ExecuteInvoker');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction ExecuteInvoker.

    my $ExecuteInvokerResult = $ExecuteInvokerActionObject->Run(
        UserID                   => 123,
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',
        Config                   => {
            Webservice   => 'Chat system',        # (required) Name of the webservice
            Invoker      => 'Notify by chat',     # (required) Name of the invoker
            Asynchronous => 0,                    # (optional) 1 for asynchronous execution
            UserID       => 1,                    # (optional) UserID
        }
    );

    Returns:

    my $ExecuteInvokerResult = 1;

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $RequesterObject  = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    # define a common message to output in case of any error
    my $CommonMessage = "Process: $Param{ProcessEntityID} Activity: $Param{ActivityEntityID}"
        . " Transition: $Param{TransitionEntityID}"
        . " TransitionAction: $Param{TransitionActionEntityID} - ";

    # check for missing or wrong params
    my $Success = $Self->_CheckParams(
        %Param,
        CommonMessage => $CommonMessage,
    );
    return if !$Success;

    # override UserID if specified as a parameter in the TA config
    $Param{UserID} = $Self->_OverrideUserID(%Param);

    # special case for DyanmicField UserID, convert form DynamicField_UserID to UserID
    if ( defined $Param{Config}->{DynamicField_UserID} ) {
        $Param{Config}->{UserID} = $Param{Config}->{DynamicField_UserID};
        delete $Param{Config}->{DynamicField_UserID};
    }

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    my $Webservice = $WebserviceObject->WebserviceGet( 'Name' => $Param{Config}->{Webservice} );
    if ( !IsHashRefWithData($Webservice) ) {
        $LogObject->Log(
            Priority => 'error',
            Message =>
                "Could found web service $Param{New}->{Webservice}",
        );
        return;
    }

    $RequesterObject->Run(
        WebserviceID => $Webservice->{ID},
        Invoker      => $Param{Config}->{Invoker},
        Asynchronous => $Param{Config}->{Asynchronous} || 0,
        Data         => {
            Origin                 => 'TransitionAction',
            TransitionActionConfig => $Param{Config},
            TicketID               => $Param{Ticket}->{TicketID},
        },
    );

    return 1;
}

1;
