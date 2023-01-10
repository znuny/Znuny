# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo - Demo for Transition Validation Module

=head1 DESCRIPTION

All ValidateDemo functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ValidateDemoObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Validate()

Validate Data

    my $Match = $ValidateModuleObject->Validate(
        Data => {
            # TicketData
            TicketID => 1,
            Queue    => 'Postmaster',
        },
        FieldName    => 'DynamicField_Make',
        'Transition' => {
            'Name'      => 'Transition 2',
            'Condition' => {
                'Type'             => 'and',
                'ConditionLinking' => 'and',
                'Condition 1'      => {
                    'Fields' => {
                        'DynamicField_Make' => $VAR1->{'Condition'}
                    }
                }
            }
        },
        TransitionName     => 'Transition 2',
        TransitionEntityID => 'T1903007681700000',

        Condition          => {
            Match => 'Postmaster',
            Type  => 'Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo.pm'
        },
        ConditionName    => 'Condition 1',
        ConditionType    => 'and',
        ConditionLinking => 'and'
    );

Returns:

    $ValidateResult = 1;        # or undef, only returns 1 if Queue is 'Raw'

    );

=cut

sub Validate {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Data)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # Check if we have Data to check against transitions conditions
    if ( !IsHashRefWithData( $Param{Data} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Data has no values!",
        );
        return;
    }

    if ( $Param{Data}->{Queue} && $Param{Data}->{Queue} eq 'Raw' ) {
        return 1;
    }

    return;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
