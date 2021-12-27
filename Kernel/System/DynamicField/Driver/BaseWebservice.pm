# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::BaseWebservice;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::DynamicField::Webservice',
    'Kernel::System::Log',
);

#
# Ticket search for dynamic fields of type Webservice does not work by (display) value but instead
# by the stored value in the external web service table. To be able to build your own search forms where you
# can enter a text that will be searched in such fields, the following code translates this text into the stored values
# (by using the field driver's Autocomplete() function) which will then be given to AgentTicketSearch.
#
sub _CustomSearchFormTransformTextToStoredValue {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    return if !$Param{ParamObject};
    return if !$Param{LayoutObject};
    return if !defined $Param{LayoutObject}->{Action};
    return if $Param{LayoutObject}->{Action} ne 'AgentTicketSearch';

    return if !IsHashRefWithData( $Param{DynamicFieldConfig} );
    my $DynamicFieldName = $Param{DynamicFieldConfig}->{Name};

    my $IsCustomSearchForm = $Param{ParamObject}->GetParam( Param => 'DynamicFieldWebserviceCustomSearchForm' );
    return if !$IsCustomSearchForm;

    my @ParamNames               = $Param{ParamObject}->GetParamNames();
    my @DynamicFieldSearchParams = grep { $_ eq "Search_DynamicField_$DynamicFieldName" } @ParamNames;
    return if !@DynamicFieldSearchParams;

    my $DynamicFieldSearchParam = shift @DynamicFieldSearchParams;

    # Convert original search values to stored values of dynamic Webservice field, so that
    # ticket search can find them.
    my @OriginalSearchValues = $Param{ParamObject}->GetArray( Param => $DynamicFieldSearchParam );
    return if !@OriginalSearchValues;

    my @NewSearchValues;
    ORIGINALSEARCHVALUE:
    for my $OriginalSearchValue (@OriginalSearchValues) {
        my $DynamicFieldSearchResults = $DynamicFieldWebserviceObject->Autocomplete(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
            SearchTerms        => $OriginalSearchValue,
            UserID             => $Param{LayoutObject}->{UserID},
        );
        next ORIGINALSEARCHVALUE if !IsArrayRefWithData($DynamicFieldSearchResults);

        DYNAMICFIELDSEARCHRESULT:
        for my $DynamicFieldSearchResult ( @{$DynamicFieldSearchResults} ) {
            next DYNAMICFIELDSEARCHRESULT if !defined $DynamicFieldSearchResult->{StoredValue};
            next DYNAMICFIELDSEARCHRESULT if !length $DynamicFieldSearchResult->{StoredValue};

            push @NewSearchValues, $DynamicFieldSearchResult->{StoredValue};
        }
    }

    # Revert to original search values if autocomplete search didn't bring up results for them.
    if ( !@NewSearchValues ) {
        @NewSearchValues = @OriginalSearchValues;
    }
    @NewSearchValues = sort { lc($a) cmp lc($b) } @NewSearchValues;

    $Param{ParamObject}->{Query}->param(
        -name  => $DynamicFieldSearchParam,
        -value => \@NewSearchValues,
    );

    return;
}

# This is in here because the original Kernel::System::DynamicFieldValue::HistoricalValuesGet() uses a cache
sub _HistoricalValueGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(FieldID)) {
        next NEEDED if defined $Param{$Needed};
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    my $ValueType = 'value_text';

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT DISTINCT($ValueType) FROM dynamic_field_value WHERE field_id = ?",
        Bind => [ \$Param{FieldID} ],
    );

    my %Data;
    ROW:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        next ROW if !$Row[0] || $Data{ $Row[0] };
        $Data{ $Row[0] } = $Row[0];
    }

    return \%Data;
}

1;
