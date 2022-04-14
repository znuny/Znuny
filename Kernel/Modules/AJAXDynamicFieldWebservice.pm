# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AJAXDynamicFieldWebservice;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Web::Request',
    'Kernel::System::DynamicField::Webservice',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $EncodeObject              = $Kernel::OM->Get('Kernel::System::Encode');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject                 = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $MainObject                = $Kernel::OM->Get('Kernel::System::Main');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicFieldName = $ParamObject->GetParam( Param => 'DynamicFieldName' );
    if ( !$DynamicFieldName ) {
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => '{}',
        );
    }

    my $Subaction   = $ParamObject->GetParam( Param => 'Subaction' );
    my $SearchTerms = $ParamObject->GetParam( Param => 'SearchTerms' ) || '';
    my $TicketID    = $ParamObject->GetParam( Param => 'TicketID' );
    my $UserID      = $LayoutObject->{UserID};

    my $UserType = $LayoutObject->{SessionSource} || '';
    if ($UserType) {
        $UserType =~ s/Interface//;
    }

    my %GetParam = $Self->_GetParams();

    # get the dynamic fields for this screen
    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => [ 'Ticket', 'Article' ],
    );

    # cycle trough the activated dynamic fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $GetParam{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
    }

    my $Data;
    if ( $Subaction eq 'Autocomplete' ) {

        $Data = $Self->_Autocomplete(
            DynamicFieldName => $DynamicFieldName,
            SearchTerms      => $SearchTerms,
            TicketID         => $TicketID,
            GetParam         => \%GetParam,
            UserID           => $UserID,
            UserType         => $UserType,
        );
    }
    elsif ( $Subaction eq 'AutoFill' ) {

        $Data = $Self->_AutoFill(
            DynamicFieldName => $DynamicFieldName,
            SearchTerms      => $SearchTerms || $GetParam{'SearchTerms[]'} || '',
            TicketID         => $TicketID,
            GetParam         => \%GetParam,
            UserID           => $UserID,
            UserType         => $UserType,
        );
    }
    elsif ( $Subaction eq 'Test' ) {
        my $ConfigRegex       = qr/\AConfig\[(.*?)\]\z/;
        my $ConfigParamsRegex = qr/\AConfig\[ConfigParams\]\[(.+?)\]\z/;
        my @ParamNames        = $ParamObject->GetParamNames();

        my @ConfigParamsParams = grep { $_ =~ m{$ConfigParamsRegex} } @ParamNames;

        @ParamNames = grep { $_ !~ m{$ConfigParamsRegex} } @ParamNames;
        my @ConfigParams = grep { $_ =~ m{$ConfigRegex} } @ParamNames;

        my $Config;
        for my $ConfigParam (@ConfigParams) {
            ( my $Key = $ConfigParam ) =~ s{$ConfigRegex}{$1};
            $Config->{$Key} = $ParamObject->GetParam( Param => $ConfigParam );
        }

        for my $ConfigParam (@ConfigParamsParams) {
            ( my $Key = $ConfigParam ) =~ s{$ConfigParamsRegex}{$1};
            $Config->{Params}->{$Key} = $ParamObject->GetParam( Param => $ConfigParam );
        }

        $Data = $Self->_Test(
            DynamicFieldName => $DynamicFieldName,
            FieldType        => $GetParam{FieldType},
            Config           => $Config,
            TicketID         => $TicketID,
            UserID           => $UserID,
            UserType         => $UserType,
        );
    }

    my $JSON = $LayoutObject->JSONEncode(
        Data => $Data,
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON // '',
        Type        => 'inline',
        NoCache     => 1,
    );
}

sub _Autocomplete {
    my ( $Self, %Param ) = @_;

    my $LogObject                    = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject           = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    NEEDED:
    for my $Needed (qw(DynamicFieldName SearchTerms UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{DynamicFieldName},
    );
    if ( !$DynamicFieldConfig ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Dynamic field with name $Param{DynamicFieldName} not found.",
        );
        return;
    }

    my $Data = $DynamicFieldWebserviceObject->Autocomplete(
        DynamicFieldConfig => $DynamicFieldConfig,
        SearchTerms        => $Param{SearchTerms},
        TicketID           => $Param{TicketID},
        GetParam           => $Param{GetParam},
        UserID             => $Param{UserID},
        UserType           => $Param{UserType},
    );

    return $Data;
}

sub _AutoFill {
    my ( $Self, %Param ) = @_;

    my $LogObject                    = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject           = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    NEEDED:
    for my $Needed (qw(DynamicFieldName SearchTerms UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    return {} if !$Param{SearchTerms};

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{DynamicFieldName},
    );
    if ( !$DynamicFieldConfig ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Dynamic field with name $Param{DynamicFieldName} not found.",
        );
        return;
    }

    my $Data = $DynamicFieldWebserviceObject->AutoFill(
        DynamicFieldConfig => $DynamicFieldConfig,
        SearchTerms        => $Param{SearchTerms},
        UserID             => $Param{UserID},
        UserType           => $Param{UserType},
    );

    return $Data;
}

sub _Test {
    my ( $Self, %Param ) = @_;

    my $LogObject                    = $Kernel::OM->Get('Kernel::System::Log');
    my $LayoutObject                 = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    NEEDED:
    for my $Needed (qw(DynamicFieldName Config FieldType)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Result = $DynamicFieldWebserviceObject->Test(
        DynamicFieldName => $Param{DynamicFieldName},
        FieldType        => $Param{FieldType},
        Config           => $Param{Config},
        TicketID         => $Param{TicketID},
        UserID           => $Param{UserID},
        UserType         => $Param{UserType},
    );

    return $Result if !$Result->{Success};

    for my $Attribute ( sort keys %{ $Result->{Search} } ) {
        $LayoutObject->Block(
            Name => 'SearchAttributesHeader',
            Data => {
                Value => $Attribute,
            },
        );
        $LayoutObject->Block(
            Name => 'SearchAttributesColumn',
            Data => {
                Value => $Result->{Search}->{$Attribute},
            },
        );
    }

    # table head
    for my $Attribute ( @{ $Result->{Attributes} } ) {
        my $IsStoredValue  = grep { $Attribute eq $_ } @{ $Result->{StoredValue} };
        my $IsDisplayValue = grep { $Attribute eq $_ } @{ $Result->{DisplayedValues} };

        $LayoutObject->Block(
            Name => 'TestDataHeader',
            Data => {
                Value          => $Attribute,
                IsStoredValue  => $IsStoredValue,
                IsDisplayValue => $IsDisplayValue,
            },
        );
    }

    if ( !IsArrayRefWithData( $Result->{Data} ) ) {
        $Result->{Data} = ();
    }

    # table body
    for my $Data ( @{ $Result->{Data} } ) {
        $LayoutObject->Block(
            Name => 'TestDataRow',
        );
        for my $Attribute ( @{ $Result->{Attributes} } ) {
            $LayoutObject->Block(
                Name => 'TestDataColumn',
                Data => {
                    Value => $Data->{$Attribute},
                },
            );
        }
    }

    my $TestDataHTML = $LayoutObject->Output(
        TemplateFile => 'AdminDynamicFieldWebservice/TestData',
    );

    $Result->{TestDataHTML} = $TestDataHTML;
    return $Result;
}

sub _GetParams {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParams;

    my @ParamNames = $ParamObject->GetParamNames();
    for my $ParamName (@ParamNames) {
        $GetParams{$ParamName} = $ParamObject->GetParam( Param => $ParamName );

        my @Param = $ParamObject->GetArray(
            Param => $ParamName,
            Raw   => 1,
        );

        if ( @Param && scalar @Param gt 1 ) {
            $GetParams{$ParamName} = \@Param;
        }
    }

    return %GetParams;
}

1;
