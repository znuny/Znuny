# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::DynamicFieldRemove;

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

Kernel::System::ProcessManagement::TransitionAction::DynamicFieldRemove - A module to remove a dynamic field value

=head1 DESCRIPTION

All DynamicFieldRemove functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $DynamicFieldRemoveObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldRemove');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction DynamicFieldRemove.

    my $Success = $DynamicFieldRemoveActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            FieldName   => 1,                   # required, name of field to be deleted without
                                                # DynamicField_ decorator.
            UserID      => 123,                 # optional, to override the logged in user.
                                                # Fields with the name UserID cannot be deleted.
        }
    );

    If a dynamic field is named UserID (to avoid conflicts) it must be set in the config as:
    DynamicField_UserID => $Value,

Returns:

    my $Success = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

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

    # get dynamic field objects
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    for my $DynamicFieldName ( sort keys %{ $Param{Config} } ) {

        # get required DynamicField config
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );

        # check if we have a valid DynamicField
        if ( !IsHashRefWithData($DynamicFieldConfig) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . "Can't get config of dynamic field '$DynamicFieldName'!",
            );
            return;
        }

        # Transform value from string to array for multiselect field (see bug#14900).
        if (
            $DynamicFieldConfig->{FieldType} eq 'Multiselect'
            && IsStringWithData( $Param{Config}->{$DynamicFieldName} )
            )
        {
            $Param{Config}->{$DynamicFieldName} = $Self->_ConvertScalar2ArrayRef(
                Data => $Param{Config}->{$DynamicFieldName},
            );
        }

        # try to set the configured value
        my $Success = $DynamicFieldBackendObject->ValueDelete(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Ticket}->{TicketID},
            UserID             => $Param{UserID},
        );

        # check if everything went right
        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . "Can't remove value for dynamic field '$DynamicFieldName', "
                    . "ticket ID '" . $Param{Ticket}->{TicketID} . "'!",
            );
        }
        return if !$Success;
    }

    return 1;
}

1;
