# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::DynamicFieldIncrement;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::DynamicFieldIncrement - A module to increment value of dynamic field - counter

=head1 SYNOPSIS

All DynamicFieldIncrement functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    my $DynamicFieldIncrementObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldIncrement');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction DynamicFieldIncrement.

    my $Success = $DynamicFieldIncrementActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,       # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            Value         => 5,                     # optional, defines the value to increment or decrement (default: 1)
            DynamicField1 => 1,
            DynamicField2 => 1,
            DynamicField3 => 1,
            UserID        => 123,                   # optional, to override the UserID from the logged user
        }
    );

Returns:

    Config is the Config Hash stored in a Process::TransitionAction's Config key

    $Success = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                 = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

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

    my $Value = $Param{Config}->{Value} || 1;
    delete $Param{Config}->{Value};

    DYNAMICFIELDNAME:
    for my $DynamicFieldName ( sort keys %{ $Param{Config} } ) {
        next DYNAMICFIELDNAME if !$Param{Config}->{$DynamicFieldName};

        # get required DynamicField config
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );

        # check if we have a valid DynamicField
        if ( !IsHashRefWithData($DynamicFieldConfig) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . "Can't get config of dynamic field '$DynamicFieldName'!",
            );
            return;
        }

        my $DynamicFieldValue = $Param{Ticket}->{ 'DynamicField_' . $DynamicFieldName };

        # check if the value is an integer
        if ( !IsInteger($DynamicFieldValue) ) {
            $DynamicFieldValue = 0;
        }
        $DynamicFieldValue += $Value;

        # try to set the configured value
        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Ticket}->{TicketID},
            Value              => $DynamicFieldValue,
            UserID             => $Param{UserID},
        );

        # check if everything went right
        next DYNAMICFIELDNAME if $Success;

        $LogObject->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . "Can't set value '"
                . $Param{Config}->{$DynamicFieldName}
                . "' for DynamicField '$DynamicFieldName',"
                . "TicketID '" . $Param{Ticket}->{TicketID} . "'!",
        );
        return;
    }

    return 1;
}

1;
