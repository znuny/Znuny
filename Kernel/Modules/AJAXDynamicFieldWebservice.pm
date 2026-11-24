# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
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
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Encode',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Ticket',
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

    my $View        = $ParamObject->GetParam( Param => 'View' );
    my $Subaction   = $ParamObject->GetParam( Param => 'Subaction' );
    my $SearchTerms = $ParamObject->GetParam( Param => 'SearchTerms' ) || '';
    my $TicketID    = $ParamObject->GetParam( Param => 'TicketID' );
    my $UserID      = $LayoutObject->{UserID};

    my $UserType = $LayoutObject->{SessionSource} || '';
    if ($UserType) {
        $UserType =~ s/Interface//;
    }

    if ( $Subaction && ( $Subaction eq 'Autocomplete' || $Subaction eq 'AutoFill' ) ) {
        my $HasPermission = $Self->_RequestPermissionCheck(
            DynamicFieldName => $DynamicFieldName,
            TicketID         => $TicketID,
            UserID           => $UserID,
            UserType         => $UserType,
        );
        if ( !$HasPermission ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{}',
            );
        }
    }

    my %GetParam = $ParamObject->GetParams(
        Raw => 1
    );

    my $FieldValues = $Self->_SerializeFieldValues(
        Params       => \%GetParam,
        View         => $View,
        DynamicField => $DynamicFieldName
    );

    $GetParam{FieldValues} = $FieldValues;

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
        my $HasAdminPermission = $UserType eq 'Agent' && $Self->_HasAdminDynamicFieldWebservicePermission(
            UserID => $UserID,
        );
        if ( !$HasAdminPermission ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{}',
            );
        }

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
        TicketID           => $Param{TicketID},
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

    if ( !$Result->{Success} ) {
        if ( $Result->{ErrorMessage} ) {
            $Result->{ErrorMessage} = $LayoutObject->{LanguageObject}->Translate( $Result->{ErrorMessage} );
        }
        return $Result;
    }

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

sub _RequestPermissionCheck {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    return if !$Param{UserID};

    my $UserType = $Param{UserType} // '';

    if ( $Param{TicketID} ) {
        my $TicketPermissionFunction = $UserType eq 'Customer' ? 'TicketCustomerPermission' : 'TicketPermission';

        my $HasTicketPermission = $TicketObject->$TicketPermissionFunction(
            Type     => 'ro',
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
        );
        if ( !$HasTicketPermission ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                    "Web service dynamic field request denied: no permission on ticket $Param{TicketID} for user $Param{UserID}.",
            );
            return;
        }
    }

    return 1 if $UserType ne 'Customer';

    my $IsActive = $Self->_DynamicFieldIsActiveInCustomerInterface(
        DynamicFieldName => $Param{DynamicFieldName},
    );
    if ( !$IsActive ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                "Web service dynamic field request denied: dynamic field $Param{DynamicFieldName} is not active in the customer interface.",
        );
        return;
    }

    return 1;
}

sub _DynamicFieldIsActiveInCustomerInterface {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $DynamicFieldName = $Param{DynamicFieldName};
    return if !$DynamicFieldName;

    my $DynamicFieldScreenRegistrations = $ConfigObject->Get('DynamicFieldScreens') // {};

    my %ScreenConfigKeys = (
        'Ticket::Frontend::CustomerTicketZoom###FollowUpDynamicField' => 1,
    );

    REGISTRATION:
    for my $Registration ( sort keys %{$DynamicFieldScreenRegistrations} ) {
        my $Screens = $DynamicFieldScreenRegistrations->{$Registration};
        next REGISTRATION if !IsHashRefWithData($Screens);

        SCREENCONFIGKEY:
        for my $ScreenConfigKey ( sort keys %{$Screens} ) {
            next SCREENCONFIGKEY if ( $Screens->{$ScreenConfigKey} // '' ) !~ m{\ACustomer};

            $ScreenConfigKeys{$ScreenConfigKey} = 1;
        }
    }

    SCREENCONFIGKEY:
    for my $ScreenConfigKey ( sort keys %ScreenConfigKeys ) {
        my @Keys   = split '###', $ScreenConfigKey;
        my $Config = $ConfigObject->Get( shift @Keys );

        KEY:
        for my $Key (@Keys) {
            last KEY if !IsHashRefWithData($Config);
            $Config = $Config->{$Key};
        }
        next SCREENCONFIGKEY if !IsHashRefWithData($Config);

        return 1 if $Config->{$DynamicFieldName};
    }

    my $ActivityDialogs = $ConfigObject->Get('Process::ActivityDialog') // {};

    ACTIVITYDIALOGENTITYID:
    for my $ActivityDialogEntityID ( sort keys %{$ActivityDialogs} ) {
        my $ActivityDialog = $ActivityDialogs->{$ActivityDialogEntityID};
        next ACTIVITYDIALOGENTITYID if !IsHashRefWithData($ActivityDialog);
        next ACTIVITYDIALOGENTITYID if !IsHashRefWithData( $ActivityDialog->{Fields} );
        next ACTIVITYDIALOGENTITYID if !$ActivityDialog->{Fields}->{"DynamicField_$DynamicFieldName"};

        my $Interfaces = $ActivityDialog->{Interface} // [];
        if ( ref $Interfaces ne 'ARRAY' ) {
            $Interfaces = [$Interfaces];
        }

        return 1 if grep { $_ eq 'CustomerInterface' } @{$Interfaces};
    }

    return;
}

sub _HasAdminDynamicFieldWebservicePermission {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    return if !$Param{UserID};

    my $FrontendModules = $ConfigObject->Get('Frontend::Module') // {};
    my $ModuleReg       = $FrontendModules->{AdminDynamicFieldWebservice};
    return if !IsHashRefWithData($ModuleReg);

    my %PermissionTypes = (
        Group   => 'rw',
        GroupRo => 'ro',
    );

    PERMISSION:
    for my $Permission ( sort keys %PermissionTypes ) {
        my $Groups = $ModuleReg->{$Permission};
        next PERMISSION if !$Groups;

        if ( ref $Groups ne 'ARRAY' ) {
            $Groups = [$Groups];
        }

        GROUPNAME:
        for my $GroupName ( @{$Groups} ) {
            next GROUPNAME if !$GroupName;

            return 1 if $GroupObject->PermissionCheck(
                UserID    => $Param{UserID},
                GroupName => $GroupName,
                Type      => $PermissionTypes{$Permission},
            );
        }
    }

    return;
}

sub _SerializeFieldValues {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $FieldMapping       = $ConfigObject->Get('DynamicFieldWebservice::FieldMapping')       // {};
    my $CustomFieldMapping = $ConfigObject->Get('DynamicFieldWebservice::CustomFieldMapping') // {};

    my $AdditionalAttributesConfig           = $ConfigObject->Get('DynamicFieldWebservice::AdditionalAttributes') // {};
    my $StandardAttributesConfig             = $AdditionalAttributesConfig->{Standard}                            // {};
    my $SelectableAttributesConfig           = $AdditionalAttributesConfig->{Selectable}                          // {};
    my $DefaultStandardAttributes            = $StandardAttributesConfig->{Default}                               // {};
    my $DefaultSelectableAttributes          = $SelectableAttributesConfig->{Default}                             // {};
    my $AdditionalSelectableAttributesConfig = $SelectableAttributesConfig->{Option}                              // {};

    my $Params       = $Param{Params};
    my $View         = $Param{View};
    my $DynamicField = $Param{DynamicField};

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicField,
    );
    return if !IsHashRefWithData($DynamicFieldConfig);

    my $AdditionalAttributes        = $DynamicFieldConfig->{Config}->{AdditionalAttributes};
    my $AdditionalAttributesMapping = $DynamicFieldConfig->{Config}->{AdditionalAttributeKeys};

    my @FormFields = grep { $_ =~ m{FormFields\[.*\]\[ID\]} } keys %{$Params};

    my %CustomFields;

    CUSTOMFIELD:
    for my $CustomField ( sort keys %{$CustomFieldMapping} ) {
        SELECTOR:
        for my $Selector ( sort keys %{ $CustomFieldMapping->{$CustomField} } ) {
            my ($SelectorFormField) = grep { $_ =~ m{\Q$Selector\E} } @FormFields;
            next SELECTOR if !$SelectorFormField;

            my $SelectedID = $Params->{$SelectorFormField};
            next SELECTOR if !$SelectedID;

            for my $Priority ( sort keys %{ $CustomFieldMapping->{$CustomField}->{$Selector} } ) {
                my $PriorityValueField = $CustomFieldMapping->{$CustomField}->{$Selector}->{$Priority};
                my $SelectorValueField = $Params->{ "FormFields[" . $PriorityValueField . "_$SelectedID][ID]" };
                $CustomFields{$CustomField} = $SelectorValueField;

                next CUSTOMFIELD if $SelectorValueField;
            }
        }
    }

    my %FormattedFields;
    FORMFIELD:
    for my $FormField (@FormFields) {
        my ($Field) = $FormField =~ m{FormFields\[(.*?)\]}ms;

        my $Key;

        FIELD:
        for my $MappedField ( sort keys %{$FieldMapping} ) {
            next FIELD if !grep { $_ eq $Field } @{ $FieldMapping->{$MappedField} };

            $Key = $MappedField;
            last FIELD;
        }

        if ($Key) {
            next FORMFIELD if !grep { $Key eq $_ } @{$AdditionalAttributes};

            if ( $AdditionalSelectableAttributesConfig->{$Key} ) {

                # Queue needs to be clean.
                if (
                    $Key =~ m{Queue}
                    && $AdditionalAttributesMapping->{Queue}->{ID}
                    )
                {
                    my ($QueueCleanUp) = $Params->{$FormField} =~ /(.*)\|\|/ms;
                    $FormattedFields{ $DefaultSelectableAttributes->{$Key}->{ID} } = $QueueCleanUp
                        // $Params->{$FormField};
                }

                TYPE:
                for my $Type (qw(ID Name)) {
                    my $LocalType = "FormFields[$Field][$Type]";

                    next TYPE if $Key eq "Queue" && $Type eq "ID";
                    next TYPE if $FormattedFields{ $DefaultSelectableAttributes->{$Key}->{$Type} };
                    next TYPE if !$AdditionalAttributesMapping->{$Key}->{$Type};

                    $FormattedFields{ $DefaultSelectableAttributes->{$Key}->{$Type} }
                        = $Params->{$LocalType} eq '-' ? '' : $Params->{$LocalType};
                }
                next FORMFIELD;
            }

            next FORMFIELD if $FormattedFields{ $DefaultStandardAttributes->{$Key} };

            # If custom field fetched value set custom, if not take value from params.
            my $ParamFieldValue = $Params->{$FormField};
            my $FormattedField  = $ParamFieldValue;
            if ( $CustomFields{$Key} ) {
                $FormattedField = $CustomFields{$Key};
            }
            elsif ( $ParamFieldValue eq '-' ) {
                $FormattedField = '';
            }

            $FormattedFields{ $DefaultStandardAttributes->{$Key} } = $FormattedField;
        }
        elsif (
            $Field =~ m{DynamicField_}ms
            && grep { $_ eq 'DynamicField' } @{$AdditionalAttributes}
            )
        {
            $FormattedFields{$Field} = $Params->{$FormField};
            next FORMFIELD;
        }

        delete( $Params->{$FormField} );
    }

    return \%FormattedFields;
}

1;
