# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::DynamicField::Driver::Checkbox;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::DynamicField::Driver::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Ticket::ColumnFilter',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::DynamicField::Driver::Checkbox

=head1 DESCRIPTION

DynamicFields Checkbox Driver delegate

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=head2 new()

usually, you want to create an instance of this
by using Kernel::System::DynamicField::Backend->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 1,
        'IsSortable'                   => 1,
        'IsFiltrable'                  => 1,
        'IsStatsCondition'             => 1,
        'IsCustomerInterfaceCapable'   => 1,
    };

    # get the Dynamic Field Backend custom extensions
    my $DynamicFieldDriverExtensions
        = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::Extension::Driver::Checkbox');

    EXTENSION:
    for my $ExtensionKey ( sort keys %{$DynamicFieldDriverExtensions} ) {

        # skip invalid extensions
        next EXTENSION if !IsHashRefWithData( $DynamicFieldDriverExtensions->{$ExtensionKey} );

        # create a extension config shortcut
        my $Extension = $DynamicFieldDriverExtensions->{$ExtensionKey};

        # check if extension has a new module
        if ( $Extension->{Module} ) {

            # check if module can be loaded
            if (
                !$Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass( $Extension->{Module} )
                )
            {
                die "Can't load dynamic fields backend module"
                    . " $Extension->{Module}! $@";
            }
        }

        # check if extension contains more behaviors
        if ( IsHashRefWithData( $Extension->{Behaviors} ) ) {

            %{ $Self->{Behaviors} } = (
                %{ $Self->{Behaviors} },
                %{ $Extension->{Behaviors} }
            );
        }
    }

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

    my $DFValue = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueGet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
    );

    return if !$DFValue;
    return if !IsArrayRefWithData($DFValue);
    return if !IsHashRefWithData( $DFValue->[0] );

    return $DFValue->[0]->{ValueInt};
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    # check value for just 1 or 0
    if ( defined $Param{Value} && !$Param{Value} ) {
        $Param{Value} = 0;
    }
    elsif ( $Param{Value} && $Param{Value} !~ m{\A [0|1]? \z}xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Value $Param{Value} is invalid for Checkbox fields!",
        );
        return;
    }

    my $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueSet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
        Value    => [
            {
                ValueInt => $Param{Value},
            },
        ],
        UserID => $Param{UserID},
    );

    return $Success;
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    # check value for just 1 or 0
    if ( defined $Param{Value} && !$Param{Value} ) {
        $Param{Value} = 0;
    }
    elsif ( $Param{Value} && $Param{Value} !~ m{\A [0|1]? \z}xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Value $Param{Value} is invalid for Checkbox fields!",
        );
        return;
    }

    my $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueValidate(
        Value => {
            ValueInt => $Param{Value},
        },
        UserID => $Param{UserID}
    );

    return $Success;
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    if ( !IsInteger( $Param{SearchTerm} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            'Priority' => 'error',
            'Message'  => "Unsupported Search Term $Param{SearchTerm}, should be an integer",
        );
        return;
    }

    my %Operators = (
        Equals => '=',
    );

    if ( $Param{Operator} eq 'Empty' ) {
        if ( $Param{SearchTerm} ) {
            return " $Param{TableAlias}.value_int IS NULL ";
        }
        else {
            return " $Param{TableAlias}.value_int IS NOT NULL ";
        }
    }
    elsif ( !$Operators{ $Param{Operator} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            'Priority' => 'error',
            'Message'  => "Unsupported Operator $Param{Operator}",
        );
        return;
    }

    my $SQL = " $Param{TableAlias}.value_int $Operators{ $Param{Operator} } ";
    $SQL
        .= $Kernel::OM->Get('Kernel::System::DB')->Quote( $Param{SearchTerm}, 'Integer' ) . ' ';
    return $SQL;
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    return "$Param{TableAlias}.value_int";
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my $Value;

    # set the field value or default
    if ( $Param{UseDefaultValue} ) {
        $Value = $FieldConfig->{DefaultValue} || '';
    }
    $Value = $Param{Value} // $Value;

    # extract the dynamic field value from the web request
    my $FieldValue = $Self->EditFieldValueGet(
        ReturnValueStructure => 1,
        %Param,
    );

    # set values from ParamObject if present
    if ( defined $FieldValue && IsHashRefWithData($FieldValue) ) {
        if (
            !defined $FieldValue->{FieldValue}
            && defined $FieldValue->{UsedValue}
            && $FieldValue->{UsedValue} eq '1'
            )
        {
            $Value = '0';
        }
        elsif (
            defined $FieldValue->{FieldValue}
            && $FieldValue->{FieldValue} eq '1'
            && defined $FieldValue->{UsedValue}
            && $FieldValue->{UsedValue} eq '1'
            )
        {
            $Value = '1';
        }
    }

    # set as checked if necessary
    my $FieldChecked = ( defined $Value && $Value eq '1' ? 'checked="checked"' : '' );

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldCheckbox';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    # set field as mandatory
    if ( $Param{Mandatory} ) {
        $FieldClass .= ' Validate_Required';
    }

    # set error css class
    if ( $Param{ServerError} ) {
        $FieldClass .= ' ServerError';
    }

    my $FieldNameUsed = $FieldName . "Used";

    my $HTMLString = <<"EOF";
<input type="hidden" id="$FieldNameUsed" name="$FieldNameUsed" value="1" />
EOF

    if ( $Param{ConfirmationNeeded} ) {

        # set checked property
        my $FieldUsedChecked0 = '';
        my $FieldUsedChecked1 = '';
        if ( $FieldValue->{UsedValue} ) {
            $FieldUsedChecked1 = 'checked="checked"';
        }
        else {
            $FieldUsedChecked0 = 'checked="checked"';
        }

        my $FieldNameUsed0 = $FieldNameUsed . '0';
        my $FieldNameUsed1 = $FieldNameUsed . '1';
        my $TranslatedDesc = $Param{LayoutObject}->{LanguageObject}->Translate(
            'Ignore this field.',
        );

        if ( !$Param{NoIgnoreField} ) {
            $HTMLString = <<"EOF";
<input type="radio" id="$FieldNameUsed0" name="$FieldNameUsed" value="" $FieldUsedChecked0 />
$TranslatedDesc
<div class="clear"></div>
<input type="radio" id="$FieldNameUsed1" name="$FieldNameUsed" value="1" $FieldUsedChecked1 />
EOF
        }
    }

    my $FieldLabelEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $FieldLabel,
    );

    $HTMLString .= <<"EOF";
<input type="checkbox" class="$FieldClass" id="$FieldName" name="$FieldName" title="$FieldLabelEscaped" $FieldChecked value="1" />
EOF

    if ( $Param{Mandatory} ) {
        my $DivID = $FieldName . 'Error';

        my $FieldRequiredMessage = $Param{LayoutObject}->{LanguageObject}->Translate("This field is required.");

        # for client side validation
        $HTMLString .= <<"EOF";
<div id="$DivID" class="TooltipErrorMessage">
    <p>
        $FieldRequiredMessage
    </p>
</div>
EOF
    }

    if ( $Param{ServerError} ) {

        my $ErrorMessage = $Param{ErrorMessage} || 'This field is required.';
        $ErrorMessage = $Param{LayoutObject}->{LanguageObject}->Translate($ErrorMessage);
        my $DivID = $FieldName . 'ServerError';

        # for server side validation
        $HTMLString .= <<"EOF";
<div id="$DivID" class="TooltipErrorMessage">
    <p>
        $ErrorMessage
    </p>
</div>
EOF
    }

    if ( $Param{AJAXUpdate} ) {

        my $FieldsToUpdate = '';
        if ( IsArrayRefWithData( $Param{UpdatableFields} ) ) {

            # Remove current field from updatable fields list.
            my @FieldsToUpdate = grep { $_ ne $FieldName } @{ $Param{UpdatableFields} };

            # Quote all fields, put commas between them.
            $FieldsToUpdate = join( ', ', map {"'$_'"} @FieldsToUpdate );
        }

        # Add JS to call FormUpdate() on change event.
        $Param{LayoutObject}->AddJSOnDocumentComplete( Code => <<"EOF");
\$('#$FieldName').on('change', function () {
    Core.AJAX.FormUpdate(\$(this).parents('form'), 'AJAXUpdate', '$FieldName', [ $FieldsToUpdate ]);
});
EOF
    }

    # call EditLabelRender on the common backend
    my $LabelString = $Self->EditLabelRender(
        %Param,
        Mandatory => $Param{Mandatory} || '0',
        FieldName => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    my %Data;

    # check if there is a Template and retrieve the dynamic field value from there
    if (
        IsHashRefWithData( $Param{Template} ) && (
            defined $Param{Template}->{$FieldName}
            || defined $Param{Template}->{ $FieldName . 'Used' }
        )
        )
    {
        # get dynamic field value form Template
        $Data{FieldValue} = $Param{Template}->{$FieldName};

        # get dynamic field used value form Template
        $Data{UsedValue} = $Param{Template}->{ $FieldName . 'Used' };
    }

    # otherwise get dynamic field value from the web request
    elsif (
        defined $Param{ParamObject}
        && ref $Param{ParamObject} eq 'Kernel::System::Web::Request'
        )
    {

        # get dynamic field value from param
        $Data{FieldValue} = $Param{ParamObject}->GetParam( Param => $FieldName );

        # get dynamic field used value from param
        $Data{UsedValue} = $Param{ParamObject}->GetParam( Param => $FieldName . 'Used' );
    }

    # check if return value structure is needed
    if ( defined $Param{ReturnValueStructure} && $Param{ReturnValueStructure} eq '1' ) {
        return \%Data;
    }

    # check if return template structure is needed
    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq '1' ) {
        return {
            $FieldName          => $Data{FieldValue},
            $FieldName . 'Used' => $Data{UsedValue},
        };
    }

    # return undef if the hidden value is not present
    return if !$Data{UsedValue};

    # set the correct return value
    my $Value = '0';
    if ( $Data{FieldValue} ) {
        $Value = $Data{FieldValue};
    }

    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from the http request
    my $FieldValue = $Self->EditFieldValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ParamObject        => $Param{ParamObject},

        # not necessary for this backend but place it for consistency reasons
        ReturnValueStructure => 1,
    );
    my $Value = $FieldValue->{FieldValue} || '';

    my $ServerError;
    my $ErrorMessage;

    # perform necessary validations
    if ( $Param{Mandatory} && !$Value ) {
        $ServerError = 1;
    }

    # validate only 0 or 1 as possible values
    if ( $Value && $Value ne 1 ) {
        $ServerError  = 1;
        $ErrorMessage = 'The field content is invalid';
    }

    # create resulting structure
    my $Result = {
        ServerError  => $ServerError,
        ErrorMessage => $ErrorMessage,
    };

    return $Result;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    # check for Null value
    if ( !defined $Param{Value} ) {
        return {
            Value => '',
            Title => '',
            Link  => '',
        };
    }

    # convert value to user friendly string
    my $Value = 'Checked';
    if ( $Param{Value} ne 1 ) {
        $Value = 'Unchecked';
    }

    # always translate value
    $Value = $Param{LayoutObject}->{LanguageObject}->Translate($Value);

    # in this backend there is no need for HTMLOutput
    # Title is always equal to Value
    my $Title = $Value;

    # this field type does not support the Link Feature
    my $Link;

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
        Link  => $Link,
    };

    return $Data;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my $Value;
    my @DefaultValue;

    if ( defined $Param{DefaultValue} ) {
        @DefaultValue = split /;/, $Param{DefaultValue};
    }

    # set the field value
    if (@DefaultValue) {
        $Value = \@DefaultValue;
    }

    # get the field value, this function is always called after the profile is loaded
    my $FieldValue = $Self->SearchFieldValueGet(%Param);

    # set values from profile if present
    if ( defined $FieldValue ) {
        $Value = $FieldValue;
    }

    for my $Item ( @{$Value} ) {

        # value must be 1, '' or -1
        if ( !defined $Item || !$Item ) {
            $Item = '';
        }
        elsif ( $Item && $Item >= 1 ) {
            $Item = 1;
        }
        else {
            $Item = -1;
        }
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldDropdown Modernize';

    my $HTMLString = $Param{LayoutObject}->BuildSelection(
        Data => {
            1  => 'Checked',
            -1 => 'Unchecked',
        },
        Name         => $FieldName,
        SelectedID   => $Value || '',
        Translation  => 1,
        PossibleNone => 1,
        Class        => $FieldClass,
        Multiple     => 1,
        HTMLQuote    => 1,
    );

    # call EditLabelRender on the common backend
    my $LabelString = $Self->EditLabelRender(
        %Param,
        FieldName => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Value;

    # get dynamic field value from param object
    if ( defined $Param{ParamObject} ) {
        my @FieldValues = $Param{ParamObject}->GetArray(
            Param => 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name}
        );

        $Value = \@FieldValues;
    }

    # otherwise get the value from the profile
    elsif ( defined $Param{Profile} ) {
        $Value = $Param{Profile}->{ 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} };
    }
    else {
        return;
    }

    if ( defined $Param{ReturnProfileStructure} && $Param{ReturnProfileStructure} eq 1 ) {
        return {
            'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} => $Value,
        };
    }

    return $Value;
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # get field value
    my $Value = $Self->SearchFieldValueGet(%Param);

    my $DisplayValue;

    if ( defined $Value && !$Value ) {
        $DisplayValue = '';
    }

    if ($Value) {

        if ( ref $Value eq "ARRAY" ) {
            my @DisplayItemList;
            ITEM:
            for my $Item ( @{$Value} ) {

                # set the display value
                my $DisplayItem = $Item eq 1
                    ? 'Checked'
                    : $Item eq -1 ? 'Unchecked'
                    :               '';

                # translate the value
                if ( defined $Param{LayoutObject} ) {
                    $DisplayItem = $Param{LayoutObject}->{LanguageObject}->Translate($DisplayItem);
                }

                push @DisplayItemList, $DisplayItem;

                # set the correct value for "unchecked" (-1) search options
                if ( $Item && $Item eq -1 ) {
                    $Item = '0';
                }
            }

            # combine different values into one string
            $DisplayValue = join ' + ', @DisplayItemList;

        }
        else {

            # set the display value
            $DisplayValue = $Value eq 1
                ? 'Checked'
                : $Value eq -1 ? 'Unchecked'
                :                '';

            # translate the value
            if ( defined $Param{LayoutObject} ) {
                $DisplayValue = $Param{LayoutObject}->{LanguageObject}->Translate($DisplayValue);
            }
        }

        # set the correct value for "unchecked" (-1) search options
        if ( $Value && $Value eq -1 ) {
            $Value = '0';
        }
    }

    # return search parameter structure
    return {
        Parameter => {
            Equals => $Value,
        },
        Display => $DisplayValue,
    };
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    return {
        Values => {
            '1'  => 'Checked',
            '-1' => 'Unchecked',
        },
        Name               => $Param{DynamicFieldConfig}->{Label},
        Element            => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
        TranslatableValues => 1,
    };
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    my $Operator = 'Equals';
    my $Value    = $Param{Value};

    if ( IsArrayRefWithData($Value) ) {
        for my $Item ( @{$Value} ) {

            # set the correct value for "unchecked" (-1) search options
            if ( $Item && $Item eq '-1' ) {
                $Item = '0';
            }
        }
    }
    else {

        # set the correct value for "unchecked" (-1) search options
        if ( $Value && $Value eq '-1' ) {
            $Value = '0';
        }
    }

    return {
        $Operator => $Value,
    };
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    my $Value = defined $Param{Value} ? $Param{Value} : '';

    # Title is always equal to Value
    my $Title = $Value;

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
    };

    return $Data;
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # set the field types
    my $EditValueType   = 'SCALAR';
    my $SearchValueType = 'ARRAY';

    # return the correct structure
    if ( $Param{FieldType} eq 'Edit' ) {
        return {
            $FieldName => $EditValueType,
        };
    }
    elsif ( $Param{FieldType} eq 'Search' ) {
        return {
            'Search_' . $FieldName => $SearchValueType,
        };
    }
    else {
        return {
            $FieldName             => $EditValueType,
            'Search_' . $FieldName => $SearchValueType,
        };
    }
}

sub RandomValueSet {
    my ( $Self, %Param ) = @_;

    my $Value = int( rand(2) );

    my $Success = $Self->ValueSet(
        %Param,
        Value => $Value,
    );

    if ( !$Success ) {
        return {
            Success => 0,
        };
    }
    return {
        Success => 1,
        Value   => $Value,
    };
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # return false if field is not defined
    return 0 if ( !defined $Param{ObjectAttributes}->{$FieldName} );

    # return false if not match
    if ( $Param{ObjectAttributes}->{$FieldName} ne $Param{Value} ) {
        return 0;
    }

    return 1;
}

sub HistoricalValuesGet {
    my ( $Self, %Param ) = @_;

    # get historical values from database
    my $HistoricalValues = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Integer',
    );

    # return the historical values from database
    return $HistoricalValues;
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Key};

    return '' if $Param{Key} eq '';

    my $Value = defined $Param{Key} && $Param{Key} eq '1' ? 'Checked' : 'Unchecked';

    # check if translation is possible
    if ( defined $Param{LanguageObject} ) {

        # translate value
        $Value = $Param{LanguageObject}->Translate($Value);
    }

    return $Value;
}

sub ColumnFilterValuesGet {
    my ( $Self, %Param ) = @_;

    # set PossibleValues
    my $SelectionData = {
        0 => 'Unchecked',
        1 => 'Checked',
    };

    # get historical values from database
    my $ColumnFilterValues = $Kernel::OM->Get('Kernel::System::Ticket::ColumnFilter')->DynamicFieldFilterValuesGet(
        TicketIDs => $Param{TicketIDs},
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Integer',
    );

    # get the display value if still exist in dynamic field configuration
    for my $Key ( sort keys %{$ColumnFilterValues} ) {
        if ( $SelectionData->{$Key} ) {
            $ColumnFilterValues->{$Key} = $SelectionData->{$Key};
        }
    }

    # translate the value
    for my $ValueKey ( sort keys %{$ColumnFilterValues} ) {

        my $OriginalValueName = $ColumnFilterValues->{$ValueKey};
        $ColumnFilterValues->{$ValueKey} = $Param{LayoutObject}->{LanguageObject}->Translate($OriginalValueName);
    }

    return $ColumnFilterValues;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
