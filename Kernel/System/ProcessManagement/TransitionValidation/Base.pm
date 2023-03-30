# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionValidation::Base;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::Log',
    'Kernel::System::TemplateGenerator',
    'Kernel::System::Time',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionValidation::Base - Base Module for Transition Validation Module

=head1 DESCRIPTION

All Base functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TransitionValidationBaseObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::Base');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Validate()

Validates Data.

    my $Match = $TransitionValidationBaseObject->Validate(
        Data => {
            # TicketData
            TicketID          => 1,
            DynamicField_Make => [
               'Test1',
               'Test2',
               'Test3'
            ],
            # [...]
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
                    },
                },
            },
        },
        TransitionName     => 'Transition 2',
        TransitionEntityID => 'T1903007681700000',

        Condition          => {
            Match => 'Test4',
            Type  => 'String',
        },
        ConditionName    => 'Condition 1',
        ConditionType    => 'and',
        ConditionLinking => 'and',
    );

Returns:

    my $Valid = 1;        # or undef, only returns 1 if Queue is 'Raw'

=cut

sub Validate {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CheckValueGet()

Returns the value of field (FieldName, field to be checked) from Data
and also uses template generator to replace smart tags.

    my $CheckValue = $TransitionValidationBaseObject->CheckValueGet(
        Data       => {
            Queue => 'Raw',
            # ...
        },
        FieldName => 'Queue',
    );

    Returns:

    my $CheckValue = 'Raw';


Smart tags are also supported in simple structure.

    my $CheckValue = $TransitionValidationBaseObject->CheckValueGet(
        Data       => {
            Queue => 'Raw',
            DynamicField_Queue => 'Postmaster',
            # ...
        },
        FieldName => '<OTRS_TICKET_DynamicField_Queue>',
    );

Returns:

    my $CheckValue = 'Postmaster';


Smart tags are also supported in complex structure.

    my $CheckValue = $TransitionValidationBaseObject->CheckValueGet(
        Data       => {
            Queue => 'Raw',
            DynamicField_Queue => '<OTRS_TICKET_DynamicField_Junk>',
            DynamicField_Junk => 'Junk',
            # ...
        },
        FieldName => '<OTRS_TICKET_DynamicField_Queue>',
    );

Returns:

    my $CheckValue = 'Junk';

=cut

sub CheckValueGet {
    my ( $Self, %Param ) = @_;

    my $LogObject               = $Kernel::OM->Get('Kernel::System::Log');
    my $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

    NEEDED:
    for my $Needed (qw(FieldName Data)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # replace value of FieldName (FieldValue)
    my $FieldValue = $TemplateGeneratorObject->_Replace(
        RichText   => 0,
        Text       => $Param{FieldName},
        TicketID   => $Param{Data}->{TicketID},
        TicketData => $Param{Data},
        Data       => $Param{Data},
        UserID     => $Param{UserID} || 1,
    );

    if ( !$FieldValue || $FieldValue eq '-' ) {
        $FieldValue = $Param{FieldName};
    }

    my $CheckValue = $Param{Data}->{$FieldValue} // $FieldValue;
    return $CheckValue if !$CheckValue;

    # replace value of CheckValue
    my $ReplacedCheckValue = $TemplateGeneratorObject->_Replace(
        RichText   => 0,
        Text       => $CheckValue,
        TicketID   => $Param{Data}->{TicketID},
        Data       => $Param{Data},
        TicketData => $Param{Data},
        UserID     => $Param{UserID} || 1,
    );

    $ReplacedCheckValue = $Self->ValueValidate(
        Value => $ReplacedCheckValue,
    );

    return $ReplacedCheckValue;
}

=head2 MatchValueGet()

Actually the value that must match is stored in Match ($Param{Condition}->{Match}).
Since module validations contain the module itself, the value is stored in Value ($Param{Condition}->{Value}).
Uses template generator to replace smart tags.

    my $MatchValue = $TransitionValidationBaseObject->MatchValueGet(
        Data       => {
            Queue => 'Poster',
            # ...
        },
        MatchValue => 'Raw',
    );

Returns:

    my $MatchValue = 'Raw';


Smart tags are also supported in simple structure.

    my $MatchValue = $TransitionValidationBaseObject->MatchValueGet(
        Data       => {
            Queue => 'Raw',
            DynamicField_Queue => 'Postmaster',
            # ...
        },
        MatchValue => '<OTRS_TICKET_DynamicField_Queue>',
    );

Returns:

    my $MatchValue = 'Postmaster';

=cut

sub MatchValueGet {
    my ( $Self, %Param ) = @_;

    my $LogObject               = $Kernel::OM->Get('Kernel::System::Log');
    my $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

    NEEDED:
    for my $Needed (qw(Data MatchValue)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $MatchValue = $TemplateGeneratorObject->_Replace(
        RichText   => 0,
        Text       => $Param{MatchValue},
        TicketID   => $Param{Data}->{TicketID},
        TicketData => $Param{Data},
        Data       => $Param{Data},
        UserID     => $Param{UserID} || 1,
    );

    $MatchValue = $Self->ValueValidate(
        Value => $MatchValue,
    );

    return $MatchValue;
}

=head2 ValueValidate()

Description.

    my $Value = $TransitionValidationBaseObject->ValueValidate(
        Value => 123,
    );

Returns:

    my $Value = 1;

=cut

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

    NEEDED:
    for my $Needed (qw()) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # DateTime
    if ( $Param{Value} =~ /^(\d{4})-(\d{1,2})-(\d{1,2})\s(\d{1,2}):(\d{1,2})(:(\d{1,2}))?$/ ) {
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Param{Value},
            }
        );

        $Param{Value} = $DateTimeObject->ToEpoch();
    }

    # Date
    elsif ( $Param{Value} =~ /^(\d{4})-(\d{1,2})-(\d{1,2})$/ ) {
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Param{Value} . ' 00:00:00',
            }
        );

        $Param{Value} = $DateTimeObject->ToEpoch();
    }

    return $Param{Value};
}

=head2 Equal()

    my $Match = $TransitionValidationBaseObject->Equal(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub Equal {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    if ( !IsArrayRefWithData($MatchValue) ) {
        $MatchValue = lc($MatchValue);
    }

    if ( IsArrayRefWithData($CheckValue) && IsArrayRefWithData($MatchValue) ) {

        # check if array's are equal
        my $DataIsDifferent = DataIsDifferent(
            Data1 => $CheckValue,
            Data2 => $MatchValue,
        );

        # check if array's are equal
        return 1 if !$DataIsDifferent;
        return 0 if defined $DataIsDifferent;
    }
    elsif ( IsArrayRefWithData($CheckValue) && IsStringWithData($MatchValue) ) {

        # if string is comma separated array 1, 2, 3
        if ( $MatchValue =~ m{,} ) {

            @{$CheckValue} = map {lc} @{$CheckValue};

            my @Split = split /\s*,\s*/, $MatchValue;
            $MatchValue = \@Split;

            # check if split-ed string is equal array
            my $DataIsDifferent = DataIsDifferent(
                Data1 => $CheckValue,
                Data2 => $MatchValue,
            );

            # check if array's are equal
            return 1 if !$DataIsDifferent;
            return 0 if defined $DataIsDifferent;
        }

        if ( scalar @{$CheckValue} eq 1 ) {
            return 1 if lc( $CheckValue->[0] ) eq lc($MatchValue);
        }
        return 0;
    }
    elsif ( IsStringWithData($CheckValue) && IsArrayRefWithData($MatchValue) ) {

        # if string is comma separated array 1, 2, 3
        if ( $CheckValue =~ m{,} ) {

            @{$MatchValue} = map {lc} @{$MatchValue};

            my @Split = split /\s*,\s*/, $CheckValue;
            $CheckValue = \@Split;

            # check if split-ed string is equal array
            my $DataIsDifferent = DataIsDifferent(
                Data1 => $CheckValue,
                Data2 => $MatchValue,
            );

            # check if array's are equal
            return 1 if !$DataIsDifferent;
            return 0 if defined $DataIsDifferent;
        }

        if ( scalar @{$MatchValue} eq 1 ) {
            return 1 if lc( $MatchValue->[0] ) eq lc($CheckValue);
        }
    }
    elsif ( IsStringWithData($CheckValue) && IsStringWithData($MatchValue) ) {
        $CheckValue = lc $CheckValue;
        return $CheckValue eq $MatchValue;
    }

    return;
}

=head2 NotEqual()

    my $Match = $TransitionValidationBaseObject->NotEqual(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub NotEqual {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    if ( IsArrayRefWithData($CheckValue) && IsArrayRefWithData($MatchValue) ) {

        my $DataIsDifferent = DataIsDifferent(
            Data1 => $CheckValue,
            Data2 => $MatchValue,
        );

        # check if array's are equal
        return 1 if defined $DataIsDifferent;
        return 0 if !$DataIsDifferent;
    }

    if ( IsArrayRefWithData($CheckValue) ) {
        my $Contains = grep { $MatchValue eq lc($_) } @{$CheckValue};
        return 1 if !$Contains;
    }
    else {
        $CheckValue = lc($CheckValue);
        $MatchValue = lc($MatchValue);

        return 1 if $CheckValue ne $MatchValue;
    }

    return 0;
}

=head2 GreaterThan()

    my $Match = $TransitionValidationBaseObject->GreaterThan(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub GreaterThan {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    return 0 if !IsInteger($CheckValue) || !IsInteger($MatchValue);
    return 1 if $CheckValue > $MatchValue;
    return 0;
}

=head2 LessThan()

    my $Match = $TransitionValidationBaseObject->LessThan(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub LessThan {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    return 0 if !IsInteger($CheckValue) || !IsInteger($MatchValue);
    return 1 if $CheckValue < $MatchValue;
    return 0;
}

=head2 GreaterThanOrEqual()

    my $Match = $TransitionValidationBaseObject->GreaterThanOrEqual(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub GreaterThanOrEqual {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    return 0 if !IsInteger($CheckValue) || !IsInteger($MatchValue);
    return 1 if $CheckValue >= $MatchValue;
    return 0;
}

=head2 LessThanOrEqual()

    my $Match = $TransitionValidationBaseObject->LessThanOrEqual(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub LessThanOrEqual {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    return 0 if !IsInteger($CheckValue) || !IsInteger($MatchValue);
    return 1 if $CheckValue <= $MatchValue;
    return 0;
}

=head2 Contains()

    my $Match = $TransitionValidationBaseObject->Contains(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub Contains {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    $MatchValue = lc($MatchValue);
    if ( IsArrayRefWithData($CheckValue) ) {
        my $Contains = grep { lc($_) =~ m{$MatchValue} } @{$CheckValue};
        return 1 if $Contains;
    }
    else {
        $CheckValue = lc($CheckValue);
        return 1 if $CheckValue =~ m{$MatchValue};
    }
    return 0;
}

=head2 NotContains()

    my $Match = $TransitionValidationBaseObject->NotContains(
        $CheckValue,
        $MatchValue,
    );

Returns:

    my $Match = 1;

=cut

sub NotContains {
    my ( $Self, $CheckValue, $MatchValue ) = @_;

    $MatchValue = lc($MatchValue);
    if ( IsArrayRefWithData($CheckValue) ) {
        my $Contains = grep { $MatchValue eq lc($_) } @{$CheckValue};
        return 1 if !$Contains;
    }
    else {
        $CheckValue = lc($CheckValue);
        return 1 if $CheckValue !~ m{$MatchValue};
    }
    return 0;
}

1;
