# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::DynamicFieldSet;

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

Kernel::System::ProcessManagement::TransitionAction::DynamicFieldSet - A module to set ticket dynamic field values

=head1 DESCRIPTION

All DynamicFieldSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $DynamicFieldSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction DynamicFieldSet

    my $Success = $DynamicFieldSetActionObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            MasterSlave => 'Master',
            Approved    => '1',
            UserID      => 123,                 # optional, to override the UserID from the logged user
        }
    );

    If a dynamic field is named UserID (to avoid conflicts) it must be set in the config as:
    DynamicField_UserID => $Value,

Returns:

    my $Success = 1;     # 0

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

    for my $CurrentDynamicField ( sort keys %{ $Param{Config} } ) {

        # get required DynamicField config
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $CurrentDynamicField,
        );

        # check if we have a valid DynamicField
        if ( !IsHashRefWithData($DynamicFieldConfig) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . "Can't get DynamicField config for DynamicField: '$CurrentDynamicField'!",
            );
            return;
        }

        # Transform value from string to array for multiselect field (see bug#14900).
        if (
            $DynamicFieldConfig->{FieldType} eq 'Multiselect'
            && IsStringWithData( $Param{Config}->{$CurrentDynamicField} )
            )
        {
            $Param{Config}->{$CurrentDynamicField} = $Self->_ConvertScalar2ArrayRef(
                Data => $Param{Config}->{$CurrentDynamicField},
            );
        }

        # try to set the configured value
        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Ticket}->{TicketID},
            Value              => $Param{Config}->{$CurrentDynamicField},
            UserID             => $Param{UserID},
        );

        # check if everything went right
        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . "Can't set value '"
                    . $Param{Config}->{$CurrentDynamicField}
                    . "' for DynamicField '$CurrentDynamicField',"
                    . "TicketID '" . $Param{Ticket}->{TicketID} . "'!",
            );
            return;
        }
    }

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
