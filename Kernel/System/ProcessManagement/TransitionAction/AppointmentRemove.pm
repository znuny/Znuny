# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::AppointmentRemove;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Calendar::Appointment',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::AppointmentRemove - A module to delete an appointment

=head1 SYNOPSIS

All AppointmentRemove functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    my $AppointmentRemoveObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::AppointmentRemove');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction AppointmentRemove.

    my $Success = $AppointmentRemoveActionObject->Run(
        UserID                   => 123,
        Ticket                   => \%Ticket,    # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',
        Config                   => {
            AppointmentID        => 1,           # (required) AppointmentID to delete the appointment
            UserID               => 1,           # (required) UserID
        }
    );

Returns:

    my $Success = 1;

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');

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

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    if ( !$Param{Config}->{AppointmentID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need AppointmentID to delete appointment!'
        );
        return;
    }

    $Success = $AppointmentObject->AppointmentDelete(
        AppointmentID => $Param{Config}->{AppointmentID},
        UserID        => $Param{UserID},
    );

    return $Success;

}

1;
