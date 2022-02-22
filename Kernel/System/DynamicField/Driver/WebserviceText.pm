# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::WebserviceText;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::DynamicField::Driver::Text);
use parent qw(Kernel::System::DynamicField::Driver::BaseWebservice);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField::Webservice',
    'Kernel::System::JSON',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::DynamicField::Driver::WebserviceText

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=head2 new()

create an object. Do not use it directly, instead use:

    my $DriverObject = $Kernel::OM->Get('Kernel::System::DynamicField::Driver::WebserviceText');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Self = {};
    bless( $Self, $Type );

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 0,
        'IsSortable'                   => 0,
        'IsFiltrable'                  => 0,
        'IsStatsCondition'             => 1,
        'IsCustomerInterfaceCapable'   => 1,
    };

    # get the Dynamic Field Backend custom extensions
    my $DynamicFieldDriverExtensions = $ConfigObject->Get('DynamicFields::Extension::Driver::Text');

    EXTENSION:
    for my $ExtensionKey ( sort keys %{$DynamicFieldDriverExtensions} ) {

        # skip invalid extensions
        next EXTENSION if !IsHashRefWithData( $DynamicFieldDriverExtensions->{$ExtensionKey} );

        # create a extension config shortcut
        my $Extension = $DynamicFieldDriverExtensions->{$ExtensionKey};

        # check if extension has a new module
        if ( $Extension->{Module} ) {

            # check if module can be loaded
            if ( !$MainObject->RequireBaseClass( $Extension->{Module} ) ) {
                die "Can't load dynamic fields backend module"
                    . " $Extension->{Module}! $@";
            }
        }

        # check if extension contains more behaviors
        next EXTENSION if !IsHashRefWithData( $Extension->{Behaviors} );

        %{ $Self->{Behaviors} } = (
            %{ $Self->{Behaviors} },
            %{ $Extension->{Behaviors} }
        );
    }

    return $Self;
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');
    my $JSONObject                   = $Kernel::OM->Get('Kernel::System::JSON');

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};
    my $TicketID    = $Param{LayoutObject}->{TicketID};

    my $Value             = '';
    my $DefaultSearchTerm = '';

    # set the field value or default
    if ( $Param{UseDefaultValue} ) {
        $Value = ( defined $FieldConfig->{DefaultValue} ? $FieldConfig->{DefaultValue} : '' );
    }
    $Value = $Param{Value} // $Value;

    if ( $FieldConfig->{DefaultSearchTerm} ) {
        $DefaultSearchTerm = $Param{LayoutObject}->Ascii2Html(
            Text => $FieldConfig->{DefaultSearchTerm},
        );
    }

    # extract the dynamic field value form the web request
    my $FieldValue = $Self->EditFieldValueGet(
        %Param,
    );

    # set values from ParamObject if present
    if ( defined $FieldValue ) {
        $Value = $FieldValue;
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldText';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    $FieldClass .= ' W' . ( $FieldConfig->{InputFieldWidth} // 50 ) . 'pc';

    # set field as mandatory
    if ( $Param{Mandatory} ) {
        $FieldClass .= ' Validate_Required';
    }

    # set error css class
    if ( $Param{ServerError} ) {
        $FieldClass .= ' ServerError';
    }

    my $ValueEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $Value,
    );

    my $AutocompleteValue = $Value;
    if ( IsStringWithData($Value) || IsArrayRefWithData($Value) ) {
        $AutocompleteValue = $DynamicFieldWebserviceObject->DisplayValueGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
            Value              => $Value,
            TicketID           => $TicketID
        );
    }
    my $AutocompleteValueEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $AutocompleteValue,
    );

    my $FieldLabelEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $FieldLabel,
    );

    if ( !IsArrayRefWithData( $FieldConfig->{AdditionalDFStorage} ) ) {
        $FieldConfig->{AdditionalDFStorage} = [];
    }

    my @AdditionalDFStorage = grep { $_->{Type} ne 'Backend' } @{ $FieldConfig->{AdditionalDFStorage} };
    my @AdditionalDFs       = map  { $_->{DynamicField} } @AdditionalDFStorage;

    my $AdditionalDFs = $JSONObject->Encode(
        Data => \@AdditionalDFs,
    );

    my $AutocompleteMinLength = int( $FieldConfig->{AutocompleteMinLength} || 3 );
    my $QueryDelay            = int( $FieldConfig->{QueryDelay}            || 1 );
    my $MaxResultsDisplayed   = int( $FieldConfig->{Limit}                 || 20 );

    my $HTMLString = <<"EOF";
<input type="hidden" class="Hidden" id="$FieldName" name="$FieldName" value="$ValueEscaped" data-dynamic-field-name="$Param{DynamicFieldConfig}->{Name}" data-dynamic-field-type="$Param{DynamicFieldConfig}->{FieldType}" data-selected-value-field-name="$FieldName" data-autocomplete-field-name="${FieldName}Autocomplete" data-autocomplete-min-length="$AutocompleteMinLength" data-ticket-id="$TicketID" />
<input type="text" class="$FieldClass" id="${FieldName}Autocomplete" name="${FieldName}Autocomplete" title="$FieldLabelEscaped" value="$AutocompleteValueEscaped" data-selected-autocomplete-display-value="$AutocompleteValueEscaped" />
EOF

    # Add autocomplete for webservice search.
    my $DynamicFieldJS = <<"EOF";
    // initialize dynamic field webservice autocomplete backend JS
    Znuny.DynamicField.Webservice.InitAutocomplete('$Param{DynamicFieldConfig}->{Name}', '$FieldName', '${FieldName}Autocomplete', $AutocompleteMinLength, $QueryDelay, $MaxResultsDisplayed, '$DefaultSearchTerm', '$TicketID', $AdditionalDFs);
EOF

    $Param{LayoutObject}->AddJSOnDocumentComplete( Code => $DynamicFieldJS );

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

    # call EditLabelRender on the common Driver
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

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    # Fetch display value from dynamic field Webservice.
    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    return $Self->SUPER::DisplayValueRender(%Param) if !defined $Param{Value};

    my $TicketID = $Param{LayoutObject}->{TicketID};
    $Param{Value} = $DynamicFieldWebserviceObject->DisplayValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Param{Value},
        TicketID           => $TicketID,
    );

    return $Self->SUPER::DisplayValueRender(%Param);
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};

    my $RenderAutocompleteSearchField = $Param{RenderAutocompleteSearchField}
        // $FieldConfig->{AutocompletionForSearchFields}
        // 0;

    # Use autocomplete search field for all actions except AgentTicketSearch and CustomerTicketSearch.
    # Those do not allow initializing autocompletion fields without customizations. Database dynamic
    # fields with many historical values should not be activated for search dialogs in general.
    my $Action = $Param{LayoutObject}->{Action} // '';

    $RenderAutocompleteSearchField = 0 if $Action =~ m{\A(Agent|Customer)TicketSearch\z};

    if ($RenderAutocompleteSearchField) {
        return $Self->_AutocompleteSearchFieldRender(%Param);
    }

    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    my $FieldName  = 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel = $Param{DynamicFieldConfig}->{Label};

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
    my $FieldValues = $Self->SearchFieldValueGet(
        %Param,
    );

    if ( defined $FieldValues ) {
        $Value = $FieldValues;
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldMultiSelect Modernize';

    my $SelectionData = $Param{PossibleValuesFilter} // {};

    # get historical values from database
    my $HistoricalValues = $Self->HistoricalValuesGet(%Param);

    # add historic values to current values (if they don't exist anymore)
    if ( IsHashRefWithData($HistoricalValues) ) {
        KEY:
        for my $Key ( sort keys %{$HistoricalValues} ) {
            next KEY if $SelectionData->{$Key};
            $SelectionData->{$Key} = $HistoricalValues->{$Key};
        }
    }

    # Assemble display values
    # If there are no available values, leave it empty.
    if ( IsHashRefWithData($SelectionData) ) {
        $SelectionData = $DynamicFieldWebserviceObject->DisplayValueGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
            Value              => [ keys %{$SelectionData} ],
        );
    }

    my $HTMLString = $Param{LayoutObject}->BuildSelection(
        Data         => $SelectionData,
        Name         => $FieldName,
        SelectedID   => $Value,
        Translation  => $FieldConfig->{TranslatableValues} || 0,
        PossibleNone => 0,
        Class        => $FieldClass,
        Multiple     => 1,
        HTMLQuote    => 1,
    );

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

#
# Renders search field as autocomplete instead of multiselect.
#
# This means that the field queries the web service instead of showing all used values
# as multiselect. This can be used for displaying fields which would have thousands of selectable
# values. These would not be displayed as modernized multiselect.
#
# Note that this method *CANNOT* be used within the Znuny standard search dialog because there the
# JavaScript to initialize the autocomplete won't be executed. It can only be used in dialogs
# where the search field will be loaded/displayed on page load.
#
# This method will be automatically executed by SearchFieldRender() if parameter RenderAutocompleteSearchField
# will be passed to it.
#
sub _AutocompleteSearchFieldRender {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

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
    my $FieldValues = $Self->SearchFieldValueGet(
        %Param,
    );

    if ( defined $FieldValues ) {
        $Value = $FieldValues;
    }

    $Value //= '';

    my $DisplayValue;
    if ( length $Value ) {
        $DisplayValue = $DynamicFieldWebserviceObject->DisplayValueGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
            Value              => $Value,
            UserID             => 1,
        );
    }
    $DisplayValue //= '';

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldText W50pc';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    my $FieldLabelEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $FieldLabel,
    );

    my $AutocompleteMinLength = int( $FieldConfig->{AutocompleteMinLength} || 3 );

    my $HTMLString = <<"EOF";
<input type="hidden" class="Hidden" id="$FieldName" name="$FieldName" value="$Value" data-dynamic-field-name="$Param{DynamicFieldConfig}->{Name}" data-dynamic-field-type="$Param{DynamicFieldConfig}->{FieldType}" data-selected-value-field-name="$FieldName" data-autocomplete-field-name="${FieldName}Autocomplete" data-autocomplete-min-length="$AutocompleteMinLength" data-ticket-id="" />
<input type="text" class="$FieldClass" id="${FieldName}Autocomplete" name="${FieldName}Autocomplete" title="$FieldLabelEscaped" value="$DisplayValue" data-selected-autocomplete-display-value="" />
EOF

    # Add autocomplete for database search.
    my $DynamicFieldJS = <<"EOF";
    // Initialize JS for dynamic field.
    Znuny.DynamicField.Webservice.InitAutocomplete('$Param{DynamicFieldConfig}->{Name}', '$FieldName', '${FieldName}Autocomplete', $AutocompleteMinLength);
EOF
    $Param{LayoutObject}->AddJSOnDocumentComplete( Code => $DynamicFieldJS );

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

    $Self->_CustomSearchFormTransformTextToStoredValue(%Param);

    return Kernel::System::DynamicField::Driver::BaseSelect::SearchFieldValueGet( $Self, %Param );
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    return Kernel::System::DynamicField::Driver::BaseSelect::SearchFieldParameterBuild( $Self, %Param );
}

# This is in here because the original Kernel::System::DynamicFieldValue::HistoricalValuesGet() uses a cache
sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # set PossibleValues
    my $Values = $Param{DynamicFieldConfig}->{Config}->{PossibleValues} // {};

    # get historical values from webservice
    my $HistoricalValues = $Self->_HistoricalValueGet(
        FieldID => $Param{DynamicFieldConfig}->{ID},
    );

    # add historic values to current values (if they don't exist anymore)
    KEY:
    for my $Key ( sort keys %{$HistoricalValues} ) {
        next KEY if $Values->{$Key};
        $Values->{$Key} = $HistoricalValues->{$Key};
    }

    # use PossibleValuesFilter if defined
    $Values = $Param{PossibleValuesFilter} // $Values;

    return {
        Values             => $Values,
        Name               => $Param{DynamicFieldConfig}->{Label},
        Element            => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
        TranslatableValues => $Param{DynamicFieldconfig}->{Config}->{TranslatableValues},
        Block              => 'MultiSelectField',
    };
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    return Kernel::System::DynamicField::Driver::BaseSelect::StatsSearchFieldParameterBuild( $Self, %Param );
}

1;
