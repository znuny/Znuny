# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');
my $ZnunyHelperObject            = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $DynamicFieldObject           = $Kernel::OM->Get('Kernel::System::DynamicField');
my $WebserviceObject             = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $UnitTestWebserviceObject     = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $HelperObject                 = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my %Param;
$Param{WebserviceName}                           = 'DynamicFieldWebservice';
$Param{DynamicFieldTextNameInvokerSearch}        = $Param{WebserviceName} . 'SystemTextInvokerSearch';
$Param{DynamicFieldMultiselectNameInvokerSearch} = $Param{WebserviceName} . 'SystemMultiselectInvokerSearch';
$Param{DynamicFieldTextNameInvokerGet}           = $Param{WebserviceName} . 'SystemTextInvokerGet';
$Param{DynamicFieldMultiselectNameInvokerGet}    = $Param{WebserviceName} . 'SystemMultiselectInvokerGet';

$Param{InvokerSearch}            = 'TestSearch';
$Param{InvokerGet}               = 'TestGet';
$Param{Webservice}               = $Param{WebserviceName};
$Param{Backend}                  = 'DirectRequest';
$Param{StoredValue}              = 'Key';
$Param{SearchKeys}               = 'Key';
$Param{DisplayedValues}          = 'Key,Value';
$Param{DisplayedValuesSeparator} = '|';
$Param{Limit}                    = 1;
$Param{AutocompleteMinLength}    = 3;
$Param{SearchTerms}              = '***';
$Param{InputFieldWidth}          = 70;
$Param{QueryDelay}               = 10;

my %DefaultMock = (
    TestSearch => [
        {
            Data   => {},
            Result => {
                Success => 1,
                Data    => [
                    {
                        Key   => 'Znuny3',
                        Value => 'Znuny3',
                    },
                    {
                        Key   => 'Rocks4',
                        Value => 'Rocks4',
                    },
                ],
            },
        },
    ],
    TestGet => [
        {
            Data   => {},
            Result => {
                Success => 1,
                Data    => {
                    Key   => 'Znuny3',
                    Value => 'Znuny3',
                },
            },
        },
    ],
);

$ZnunyHelperObject->_WebserviceCreate(
    Webservices => {
        $Param{WebserviceName} => 'scripts/test/sample/Webservice/' . $Param{WebserviceName} . '.yml',
    }
);
my $Webservice = $WebserviceObject->WebserviceGet(
    Name => $Param{WebserviceName},
);

$Self->True(
    $Webservice,
    "WebserviceGet() - $Param{WebserviceName}",
);

my @DynamicFields = (
    {
        Name          => 'TestDynamicField1',
        Label         => "TestDynamicField1",
        InternalField => 0,                     # optional, 0 or 1, internal fields are protected
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => "",
        },
    },
    {
        Name          => 'TestDynamicField2',
        Label         => "TestDynamicField2",
        InternalField => 0,                     # optional, 0 or 1, internal fields are protected
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => "",
        },
    },
    {
        Name       => $Param{DynamicFieldTextNameInvokerSearch},
        Label      => $Param{DynamicFieldTextNameInvokerSearch},
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceDropdown',
        Config     => {
            InvokerSearch            => $Param{InvokerSearch},
            InvokerGet               => $Param{InvokerSearch},
            Webservice               => $Param{Webservice},
            Backend                  => $Param{Backend},
            SearchKeys               => $Param{SearchKeys},
            StoredValue              => $Param{StoredValue},
            DisplayedValues          => $Param{DisplayedValues},
            DisplayedValuesSeparator => $Param{DisplayedValuesSeparator},
            Limit                    => $Param{Limit},
            AutocompleteMinLength    => $Param{AutocompleteMinLength},
            InputFieldWidth          => $Param{InputFieldWidth},
            QueryDelay               => $Param{QueryDelay},
            AdditionalDFStorage      => [
                {
                    DynamicField => 'TestDynamicField1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend',
                },
                {
                    DynamicField => 'TestDynamicField2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend',
                },
            ],
            Link         => '',
            LinkPreview  => '',
            DefaultValue => '',

        },
    },
    {
        Name       => $Param{DynamicFieldMultiselectNameInvokerSearch},
        Label      => $Param{DynamicFieldMultiselectNameInvokerSearch},
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceMultiselect',
        Config     => {
            InvokerSearch            => $Param{InvokerSearch},
            InvokerGet               => $Param{InvokerSearch},
            Webservice               => $Param{Webservice},
            Backend                  => $Param{Backend},
            SearchKeys               => $Param{SearchKeys},
            StoredValue              => $Param{StoredValue},
            DisplayedValues          => $Param{DisplayedValues},
            DisplayedValuesSeparator => $Param{DisplayedValuesSeparator},
            Limit                    => $Param{Limit},
            AutocompleteMinLength    => $Param{AutocompleteMinLength},
            InputFieldWidth          => $Param{InputFieldWidth},
            QueryDelay               => $Param{QueryDelay},
            AdditionalDFStorage      => [
                {
                    DynamicField => 'TestDynamicField1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend',
                },
                {
                    DynamicField => 'TestDynamicField2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend',
                },
            ],
            Link         => '',
            LinkPreview  => '',
            DefaultValue => '',

        },
    },
    {
        Name       => $Param{DynamicFieldTextNameInvokerGet},
        Label      => $Param{DynamicFieldTextNameInvokerGet},
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceDropdown',
        Config     => {
            InvokerSearch            => $Param{InvokerSearch},
            InvokerGet               => $Param{InvokerGet},
            Webservice               => $Param{Webservice},
            Backend                  => $Param{Backend},
            SearchKeys               => $Param{SearchKeys},
            StoredValue              => $Param{StoredValue},
            DisplayedValues          => $Param{DisplayedValues},
            DisplayedValuesSeparator => $Param{DisplayedValuesSeparator},
            Limit                    => $Param{Limit},
            AutocompleteMinLength    => $Param{AutocompleteMinLength},
            InputFieldWidth          => $Param{InputFieldWidth},
            QueryDelay               => $Param{QueryDelay},
            AdditionalDFStorage      => [
                {
                    DynamicField => 'TestDynamicField1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend',
                },
                {
                    DynamicField => 'TestDynamicField2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend',
                },
            ],
            Link         => '',
            LinkPreview  => '',
            DefaultValue => '',

        },
    },
    {
        Name       => $Param{DynamicFieldMultiselectNameInvokerGet},
        Label      => $Param{DynamicFieldMultiselectNameInvokerGet},
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceMultiselect',
        Config     => {
            InvokerSearch            => $Param{InvokerSearch},
            InvokerGet               => $Param{InvokerGet},
            Webservice               => $Param{Webservice},
            Backend                  => $Param{Backend},
            SearchKeys               => $Param{SearchKeys},
            StoredValue              => $Param{StoredValue},
            DisplayedValues          => $Param{DisplayedValues},
            DisplayedValuesSeparator => $Param{DisplayedValuesSeparator},
            Limit                    => $Param{Limit},
            AutocompleteMinLength    => $Param{AutocompleteMinLength},
            InputFieldWidth          => $Param{InputFieldWidth},
            QueryDelay               => $Param{QueryDelay},
            AdditionalDFStorage      => [
                {
                    DynamicField => 'TestDynamicField1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend',
                },
                {
                    DynamicField => 'TestDynamicField2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend',
                },
            ],
            Link         => '',
            LinkPreview  => '',
            DefaultValue => '',

        },
    },
);
my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    '_DynamicFieldsCreate',
);

my $DynamicFieldConfigTextInvokerSearch = $DynamicFieldObject->DynamicFieldGet(
    Name => $Param{DynamicFieldTextNameInvokerSearch},
);

my $BackendConfigTextInvokerSearch = $DynamicFieldWebserviceObject->_BackendConfigGet(
    DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
);

$Self->IsDeeply(
    $BackendConfigTextInvokerSearch,
    {
        'AdditionalDFStorage' => [
            {
                'DynamicField' => 'TestDynamicField1',
                'Key'          => 'Key',
                'Type'         => 'FrontendBackend',
            },
            {
                'DynamicField' => 'TestDynamicField2',
                'Key'          => 'Value',
                'Type'         => 'FrontendBackend',
            },
        ],
        'Webservice'               => 'DynamicFieldWebservice',
        'InvokerSearch'            => 'TestSearch',
        'InvokerGet'               => 'TestSearch',
        'Backend'                  => 'DirectRequest',
        'DisplayedValues'          => 'Key,Value',
        'DisplayedValuesSeparator' => '|',
        'Link'                     => '',
        'Limit'                    => '1',
        'StoredValue'              => 'Key',
        'AutocompleteMinLength'    => '3',
        'InputFieldWidth'          => '70',
        'QueryDelay'               => '10',
        'SearchKeys'               => 'Key',
        'DefaultValue'             => '',
    },
    '_BackendConfigGet - WebserviceDropdown',
);

my $DynamicFieldConfigMultiselectInvokerSearch = $DynamicFieldObject->DynamicFieldGet(
    Name => $Param{DynamicFieldMultiselectNameInvokerSearch},
);
my $BackendConfigMultiselectInvokerSearch = $DynamicFieldWebserviceObject->_BackendConfigGet(
    DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
);

$Self->IsDeeply(
    $BackendConfigMultiselectInvokerSearch,
    {
        'AdditionalDFStorage' => [
            {
                'DynamicField' => 'TestDynamicField1',
                'Key'          => 'Key',
                'Type'         => 'FrontendBackend',
            },
            {
                'DynamicField' => 'TestDynamicField2',
                'Key'          => 'Value',
                'Type'         => 'FrontendBackend',
            },
        ],
        'Webservice'               => 'DynamicFieldWebservice',
        'InvokerSearch'            => 'TestSearch',
        'InvokerGet'               => 'TestSearch',
        'Backend'                  => 'DirectRequest',
        'DisplayedValues'          => 'Key,Value',
        'DisplayedValuesSeparator' => '|',
        'Link'                     => '',
        'Limit'                    => '1',
        'StoredValue'              => 'Key',
        'AutocompleteMinLength'    => '3',
        'InputFieldWidth'          => '70',
        'QueryDelay'               => '10',
        'SearchKeys'               => 'Key',
        'DefaultValue'             => '',
    },
    '_BackendConfigGet - WebserviceMultiselect',
);

my $DynamicFieldConfigTextInvokerGet = $DynamicFieldObject->DynamicFieldGet(
    Name => $Param{DynamicFieldTextNameInvokerGet},
);

my $BackendConfigTextInvokerGet = $DynamicFieldWebserviceObject->_BackendConfigGet(
    DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
);

$Self->IsDeeply(
    $BackendConfigTextInvokerGet,
    {
        'AdditionalDFStorage' => [
            {
                'DynamicField' => 'TestDynamicField1',
                'Key'          => 'Key',
                'Type'         => 'FrontendBackend',
            },
            {
                'DynamicField' => 'TestDynamicField2',
                'Key'          => 'Value',
                'Type'         => 'FrontendBackend',
            },
        ],
        'Webservice'               => 'DynamicFieldWebservice',
        'InvokerSearch'            => 'TestSearch',
        'InvokerGet'               => 'TestGet',
        'Backend'                  => 'DirectRequest',
        'DisplayedValues'          => 'Key,Value',
        'DisplayedValuesSeparator' => '|',
        'Link'                     => '',
        'Limit'                    => '1',
        'StoredValue'              => 'Key',
        'AutocompleteMinLength'    => '3',
        'InputFieldWidth'          => '70',
        'QueryDelay'               => '10',
        'SearchKeys'               => 'Key',
        'DefaultValue'             => '',
    },
    '_BackendConfigGet - WebserviceDropdown',
);

my $DynamicFieldConfigMultiselectInvokerGet = $DynamicFieldObject->DynamicFieldGet(
    Name => $Param{DynamicFieldMultiselectNameInvokerGet},
);
my $BackendConfigMultiselectInvokerGet = $DynamicFieldWebserviceObject->_BackendConfigGet(
    DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
);

$Self->IsDeeply(
    $BackendConfigMultiselectInvokerGet,
    {
        'AdditionalDFStorage' => [
            {
                'DynamicField' => 'TestDynamicField1',
                'Key'          => 'Key',
                'Type'         => 'FrontendBackend',
            },
            {
                'DynamicField' => 'TestDynamicField2',
                'Key'          => 'Value',
                'Type'         => 'FrontendBackend',
            },
        ],
        'Webservice'               => 'DynamicFieldWebservice',
        'InvokerSearch'            => 'TestSearch',
        'InvokerGet'               => 'TestGet',
        'Backend'                  => 'DirectRequest',
        'DisplayedValues'          => 'Key,Value',
        'DisplayedValuesSeparator' => '|',
        'Link'                     => '',
        'Limit'                    => '1',
        'StoredValue'              => 'Key',
        'AutocompleteMinLength'    => '3',
        'InputFieldWidth'          => '70',
        'QueryDelay'               => '10',
        'SearchKeys'               => 'Key',
        'DefaultValue'             => '',
    },
    '_BackendConfigGet - WebserviceMultiselect',
);

# _BackendObjectGet
my $BackendObjectTextInvokerGet = $DynamicFieldWebserviceObject->_BackendObjectGet(
    BackendConfig => $BackendConfigTextInvokerGet
);

$Self->True(
    $BackendObjectTextInvokerGet,
    '_BackendObjectGet - WebserviceDropdown',
);

my $BackendObjectMultiselectInvokerGet = $DynamicFieldWebserviceObject->_BackendObjectGet(
    BackendConfig => $BackendConfigMultiselectInvokerGet
);

$Self->True(
    $BackendObjectMultiselectInvokerGet,
    '_BackendObjectGet - WebserviceMultiselect',
);

# Search

my @SearchTest = (

    # DynamicFieldConfigTextInvokerSearch
    {
        Name => 'Search (succeeding) - (TextInvokerSearch) - ***',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => '***',
            UserID             => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4'
            }
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerSearch) - Key LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                 # LIKE | EQUALS
            SearchKeys         => 'Key',                                  # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerSearch) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                 # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Value',
            ],
            Attributes => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerSearch) - Key EQUALS Rocks4',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Rocks4',
            SearchType         => 'EQUALS',                               # LIKE | EQUALS
            SearchKeys         => 'Key',                                  # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (TextInvokerSearch) - Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                               # LIKE | EQUALS
            SearchKeys         => 'Key',                                  # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerSearch) - Name or Key EQUALS Rocks4',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Rocks4',
            SearchType         => 'EQUALS',                               # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (TextInvokerSearch) - Name or Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                               # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },

    # DynamicFieldConfigMultiselectInvokerSearch
    {
        Name => 'Search (succeeding) - (MultiselectInvokerSearch) - ***',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => '***',
            UserID             => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4'
            }
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerSearch) - Key LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                        # LIKE | EQUALS
            SearchKeys         => 'Key',                                         # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerSearch) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                        # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Value',
            ],
            Attributes => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerSearch) - Key EQUALS Rocks4',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Rocks4',
            SearchType         => 'EQUALS',                                      # LIKE | EQUALS
            SearchKeys         => 'Key',                                         # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (MultiselectInvokerSearch) - Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                                      # LIKE | EQUALS
            SearchKeys         => 'Key',                                         # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerSearch) - Name or Key EQUALS Rocks4',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Rocks4',
            SearchType         => 'EQUALS',                                      # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (MultiselectInvokerSearch) - Name or Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                                      # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },

    # DynamicFieldConfigTextInvokerGet
    {
        Name => 'Search (succeeding) - (TextInvokerGet) - ***',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => '***',
            UserID             => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4'
            }
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerGet) - Key LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                              # LIKE | EQUALS
            SearchKeys         => 'Key',                               # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerGet) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                              # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Value',
            ],
            Attributes => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerGet) - Key EQUALS Znuny3',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Znuny3',
            SearchType         => 'EQUALS',                            # LIKE | EQUALS
            SearchKeys         => 'Key',                               # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (TextInvokerGet) - Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                            # LIKE | EQUALS
            SearchKeys         => 'Key',                               # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },
    {
        Name => 'Search (succeeding) - (TextInvokerGet) - Name or Key EQUALS Znuny3',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Znuny3',
            SearchType         => 'EQUALS',                            # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (TextInvokerGet) - Name or Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerGet,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                            # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },

    # DynamicFieldConfigMultiselectInvokerGet
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - ***',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => '***',
            UserID             => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
            {
                'Key'   => 'Rocks4',
                'Value' => 'Rocks4'
            }
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - Key LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                     # LIKE | EQUALS
            SearchKeys         => 'Key',                                      # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Znuny',
            SearchType         => 'LIKE',                                     # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Value',
            ],
            Attributes => [
                'Key',
                'Value',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3'
            },
        ],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - Key EQUALS Znuny3',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Znuny3',
            SearchType         => 'EQUALS',                                   # LIKE | EQUALS
            SearchKeys         => 'Key',                                      # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (MultiselectInvokerGet) - Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                                   # LIKE | EQUALS
            SearchKeys         => 'Key',                                      # id, deepens on webservice
            Attributes         => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - Name or Key EQUALS Znuny3',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Znuny3',
            SearchType         => 'EQUALS',                                   # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
    {
        Name => 'Search (failing) - (MultiselectInvokerGet) - Name or Key EQUALS Rocks',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Rocks',
            SearchType         => 'EQUALS',                                   # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID => 1,
        },
        ExpectedResult => [],
    },
    {
        Name => 'Search (succeeding) - (MultiselectInvokerGet) - UserType Agent',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerGet,
            SearchTerms        => 'Znuny3',
            SearchType         => 'EQUALS',                                   # LIKE | EQUALS
            SearchKeys         => [
                'Name',
                'Key',
            ],
            Attributes => [
                'Key',
                'Value',
                'Name',
                'ID',
            ],
            UserID   => 1,
            UserType => 'Agent',
        },
        ExpectedResult => [
            {
                'Key'   => 'Znuny3',
                'Value' => 'Znuny3',
                'Name'  => '',
                'ID'    => '',
            },
        ],
    },
);

for my $Test (@SearchTest) {
    $UnitTestWebserviceObject->Mock(
        %DefaultMock,
        %{ $Test->{Mock} },
    );

    my $Results = $DynamicFieldWebserviceObject->Search(
        %{ $Test->{Data} },
    );
    $Self->IsDeeply(
        $Results,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# Test
my @Tests = (

    {
        Name => 'Test (succeeding) - (TextInvokerSearch)',
        Data => {
            Config => {
                'Webservice'               => $Param{WebserviceName},
                'InvokerSearch'            => 'TestSearch',
                'InvokerGet'               => 'TestSearch',
                'Backend'                  => 'DirectRequest',
                'StoredValue'              => 'Key',
                'DisplayedValues'          => 'Key,Value',
                'DisplayedValuesSeparator' => '|',
                'Limit'                    => 5,
                'SearchTerms'              => '***',
            },
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $Param{DynamicFieldTextName},
            UserID           => 1,
        },
        ExpectedResult => {
            Attributes => [
                'DisplayValue',
                'Key',
                'Value'
            ],
            Data => [
                {
                    DisplayValue => 'Znuny3|Znuny3',
                    Key          => 'Znuny3',
                    Value        => 'Znuny3'
                },
                {
                    DisplayValue => 'Rocks4|Rocks4',
                    Key          => 'Rocks4',
                    Value        => 'Rocks4'
                }
            ],
            DisplayedValues => [
                'Key',
                'Value'
            ],
            Search      => undef,
            StoredValue => [
                'Key'
            ],
            Success => 1
        },
    },
    {
        Name => 'Test (succeeding) - (MultiselectInvokerSearch)',
        Data => {
            Config => {
                'Webservice'               => $Param{WebserviceName},
                'InvokerSearch'            => 'TestSearch',
                'InvokerGet'               => 'TestGet',
                'Backend'                  => 'DirectRequest',
                'StoredValue'              => 'Key',
                'DisplayedValues'          => 'Key,Value',
                'DisplayedValuesSeparator' => '|',
                'Limit'                    => 5,
                'SearchTerms'              => '***',
            },
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $Param{DynamicFieldMultiselectNameInvokerSearch},
            UserID           => 1,
        },
        ExpectedResult => {
            Attributes => [
                'DisplayValue',
                'Key',
                'Value'
            ],
            Data => [
                {
                    DisplayValue => 'Znuny3|Znuny3',
                    Key          => 'Znuny3',
                    Value        => 'Znuny3'
                },
                {
                    DisplayValue => 'Rocks4|Rocks4',
                    Key          => 'Rocks4',
                    Value        => 'Rocks4'
                }
            ],
            DisplayedValues => [
                'Key',
                'Value'
            ],
            Search      => undef,
            StoredValue => [
                'Key'
            ],
            Success => 1
        },
    },
    {
        Name => 'Test (succeeding) - (TextInvokerGet)',
        Data => {
            Config => {
                'Webservice'               => $Param{WebserviceName},
                'InvokerSearch'            => 'TestSearch',
                'InvokerGet'               => 'TestGet',
                'Backend'                  => 'DirectRequest',
                'StoredValue'              => 'Key',
                'DisplayedValues'          => 'Key,Value',
                'DisplayedValuesSeparator' => '|',
                'Limit'                    => 5,
                'SearchTerms'              => '***',
            },
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $Param{DynamicFieldTextName},
            UserID           => 1,
        },
        ExpectedResult => {
            Attributes => [
                'DisplayValue',
                'Key',
                'Value'
            ],
            Data => [
                {
                    DisplayValue => 'Znuny3|Znuny3',
                    Key          => 'Znuny3',
                    Value        => 'Znuny3'
                },
                {
                    DisplayValue => 'Rocks4|Rocks4',
                    Key          => 'Rocks4',
                    Value        => 'Rocks4'
                }
            ],
            DisplayedValues => [
                'Key',
                'Value'
            ],
            Search      => undef,
            StoredValue => [
                'Key'
            ],
            Success => 1
        },
    },
    {
        Name => 'Test (succeeding) - (MultiselectInvokerGet)',
        Data => {
            Config => {
                'Webservice'               => $Param{WebserviceName},
                'InvokerSearch'            => 'TestSearch',
                'InvokerGet'               => 'TestGet',
                'Backend'                  => 'DirectRequest',
                'StoredValue'              => 'Key',
                'DisplayedValues'          => 'Key,Value',
                'DisplayedValuesSeparator' => '|',
                'Limit'                    => 5,
                'SearchTerms'              => '***',
            },
            FieldType        => 'WebserviceMultiselect',
            DynamicFieldName => $Param{DynamicFieldMultiselectNameInvokerSearch},
            UserID           => 1,
        },
        ExpectedResult => {
            Attributes => [
                'DisplayValue',
                'Key',
                'Value'
            ],
            Data => [
                {
                    DisplayValue => 'Znuny3|Znuny3',
                    Key          => 'Znuny3',
                    Value        => 'Znuny3'
                },
                {
                    DisplayValue => 'Rocks4|Rocks4',
                    Key          => 'Rocks4',
                    Value        => 'Rocks4'
                }
            ],
            DisplayedValues => [
                'Key',
                'Value'
            ],
            Search      => undef,
            StoredValue => [
                'Key'
            ],
            Success => 1
        },
    },
);

for my $Test (@Tests) {

    my $TestResult = $DynamicFieldWebserviceObject->Test(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $TestResult,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# AdditionalDynamicFieldValuesStore
my @AdditionalDynamicFieldValuesStoreTest = (
    {
        Name => 'AdditionalDynamicFieldValuesStore (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            DynamicField       => $Param{DynamicFieldTextNameInvokerSearch},
            Value              => 'Znuny3',
        },
        ExpectedResult => {
            Success                      => 1,
            AdditionalDynamicFieldValues => {
                TestDynamicField1 => 'Znuny3',
                TestDynamicField2 => 'Znuny3',
            },
        },
    },
    {
        Name => 'AdditionalDynamicFieldValuesStore (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            DynamicField       => $Param{DynamicFieldTextNameInvokerSearch},
            Value              => 'NOTEXISTS',
        },
        ExpectedResult => {
            Success                      => 1,
            AdditionalDynamicFieldValues => {
                TestDynamicField1 => undef,
                TestDynamicField2 => undef,
            },
        },
    },
    {
        Name => 'AdditionalDynamicFieldValuesStore (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            DynamicField       => $Param{DynamicFieldMultiselectNameInvokerSearch},
            Value              => 'Znuny3',
        },
        ExpectedResult => {
            Success                      => 1,
            AdditionalDynamicFieldValues => {
                TestDynamicField1 => 'Znuny3',
                TestDynamicField2 => 'Znuny3',
            },
        },
    },
    {
        Name => 'AdditionalDynamicFieldValuesStore (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            DynamicField       => $Param{DynamicFieldMultiselectNameInvokerSearch},
            Value              => 'NOTEXISTS',
        },
        ExpectedResult => {
            Success                      => 1,
            AdditionalDynamicFieldValues => {
                TestDynamicField1 => undef,
                TestDynamicField2 => undef,
            },
        },
    },
);

for my $Test (@AdditionalDynamicFieldValuesStoreTest) {

    $UnitTestWebserviceObject->Mock(
        %DefaultMock,
        %{ $Test->{Mock} },
    );

    my $TicketID = $HelperObject->TicketCreate();
    my $Success  = $HelperObject->DynamicFieldSet(
        Field    => $Test->{Data}->{DynamicField},
        ObjectID => $TicketID,
        Value    => $Test->{Data}->{Value},
    );

    $Self->True(
        scalar $Success,
        $Test->{Name} . ' - DynamicFieldSet',
    );

    $Success = $DynamicFieldWebserviceObject->AdditionalDynamicFieldValuesStore(
        DynamicFieldConfig => $Test->{Data}->{DynamicFieldConfig},
        TicketID           => $TicketID,
        UserID             => 1,
    );

    $Self->Is(
        $Success ? 1 : 0,
        $Test->{ExpectedResult}->{Success},
        $Test->{Name} . ' - AdditionalDynamicFieldValuesStore Success',
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Ticket       = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => 1,
    );

    for my $DynamicField ( sort keys %{ $Test->{ExpectedResult}->{AdditionalDynamicFieldValues} } ) {
        my $AdditionalDynamicFieldValue = $Test->{ExpectedResult}->{AdditionalDynamicFieldValues}->{$DynamicField};
        my $AdditionalDynamicFieldValueString = $AdditionalDynamicFieldValue // 'undef';

        $Self->Is(
            $Ticket{ 'DynamicField_' . $DynamicField },
            $AdditionalDynamicFieldValue,
            $Test->{Name}
                . " - $Test->{Data}->{DynamicField} - Additional DynamicField Values - $AdditionalDynamicFieldValueString",
        );
    }
}

# DisplayValueGet

my @DisplayValueGetTest = (
    {
        Name => 'DisplayValueGet - Text (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            Value              => 'Znuny3',
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
    {
        Name => 'DisplayValueGet - Text (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            Value              => 'Znuny3',
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
    {
        Name => 'DisplayValueGet - Multiselect (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            Value              => 'Znuny3',
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
    {
        Name => 'DisplayValueGet - Multiselect (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            Value              => 'Znuny3',
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
);

for my $Test (@DisplayValueGetTest) {
    my $DisplayValue = $DynamicFieldWebserviceObject->DisplayValueGet(
        DynamicFieldConfig => $Test->{Data}->{DynamicFieldConfig},
        Value              => $Test->{Data}->{Value},
    );

    $Self->IsDeeply(
        $DisplayValue,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# _DisplayValueAssemble
my @DisplayValueAssembleTest = (
    {
        Name => '_DisplayValueAssemble - Text (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            Result             => {
                Key   => 'SomeKey',
                Value => 'SomeValue',
            },
        },
        ExpectedResult => 'SomeKey|SomeValue',
    },
    {
        Name => '_DisplayValueAssemble - Text (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
            Result             => {
                Key   => 'Znuny3',
                Value => 'Znuny3',
            },
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
    {
        Name => '_DisplayValueAssemble - Multiselect (succeeding)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            Result             => {
                Key   => 'SomeKey',
                Value => 'SomeValue',
            },
        },
        ExpectedResult => 'SomeKey|SomeValue',
    },
    {
        Name => '_DisplayValueAssemble - Multiselect (failing)',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
            Result             => {
                Key   => 'Znuny3',
                Value => 'Znuny3',
            },
        },
        ExpectedResult => 'Znuny3|Znuny3',
    },
);

for my $Test (@DisplayValueAssembleTest) {
    my $DisplayValue = $DynamicFieldWebserviceObject->_DisplayValueAssemble(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $DisplayValue,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# _DisplaySeparatorGet
my @DisplaySeparatorGetTest = (
    {
        Name => '_DisplaySeparatorGet (succeeding)',
        Data => {
            DisplaySeparator => '|'
        },
        ExpectedResult => '|',
    },
    {
        Name           => '_DisplaySeparatorGet (succeeding) - empty space',
        Data           => {},
        ExpectedResult => ' ',
    },
);

for my $Test (@DisplaySeparatorGetTest) {
    my $DisplaySeparator = $DynamicFieldWebserviceObject->_DisplaySeparatorGet(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $DisplaySeparator,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# BackendList
my %BackendList = $DynamicFieldWebserviceObject->BackendList();

$Self->IsDeeply(
    \%BackendList,
    {
        'DirectRequest'  => 'DirectRequest',
        'ResponseValues' => 'ResponseValues'
    },
    'BackendList',
);

# BackendListGet
my %BackendListGet = $DynamicFieldWebserviceObject->BackendListGet();

$Self->IsDeeply(
    \%BackendListGet,
    {
        'DirectRequest' => {
            'Documentation' => "Executes a direct request without any checks before or after.
Example response:
{
    Key   => 'Znuny',
    Value => 'Rocks'
}
",
            'Module' => '/Kernel/System/DynamicField/Webservice/DirectRequest.pm',
            'Name'   => 'DirectRequest'
        },
        'ResponseValues' => {
            'Documentation' => "Runs a request with return code and return message handling.

Example response:
{
    response => {
        returncode    => '200',
        returnmessage => 'Success'
    },
    values => [
        {
            ID    => '1',
            Name  => 'Znuny',
            Value => 'Rocks',
        }
    ],
}

Returns:
[
    {
        ID    => '1',
        Name  => 'Znuny',
        Value => 'Rocks',
    }
]

",
            'Module' => '/Kernel/System/DynamicField/Webservice/ResponseValues.pm',
            'Name'   => 'ResponseValues'
        }
    },
    'BackendListGet',
);

# Autocomplete
my @AutocompleteTest = (
    {
        Name => 'Autocomplete - Text (succeeding) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigTextInvokerSearch,
        },
        ExpectedResult => [
            {
                'DisplayValue' => 'Znuny3|Znuny3',
                'StoredValue'  => 'Znuny3'
            },
            {
                'DisplayValue' => 'Rocks4|Rocks4',
                'StoredValue'  => 'Rocks4'
            }
        ],
    },
    {
        Name => 'Autocomplete - Multiselect (succeeding) - Name or Value LIKE Znuny',
        Data => {
            DynamicFieldConfig => $DynamicFieldConfigMultiselectInvokerSearch,
        },
        ExpectedResult => [
            {
                'DisplayValue' => 'Znuny3|Znuny3',
                'StoredValue'  => 'Znuny3'
            },
            {
                'DisplayValue' => 'Rocks4|Rocks4',
                'StoredValue'  => 'Rocks4'
            }
        ],
    },
);

for my $Test (@AutocompleteTest) {

    my $Autocomplete = $DynamicFieldWebserviceObject->Autocomplete(
        DynamicFieldConfig => $Test->{Data}->{DynamicFieldConfig},
        SearchTerms        => '***',
        UserID             => 1,
    );

    $Self->IsDeeply(
        $Autocomplete,
        $Test->{ExpectedResult},
        "$Test->{Name},",
    );
}

# Template

@Tests = (
    {
        Name => 'default template - value string',
        Data => {
            DynamicFieldConfig => {
                Name       => 'Multiselect',
                Label      => 'Multiselect',
                ObjectType => 'Ticket',
                FieldType  => 'WebserviceMultiselect',
                Config     => {
                    DefaultValue => "",
                },
            },
            Value => 'UnitTest ticket',
        },
        Expected => {
            Value => "UnitTest ticket",
        },
    },
    {
        Name => 'default template - value array HTML',
        Data => {
            DynamicFieldConfig => {
                Name       => 'Multiselect',
                Label      => 'Multiselect',
                ObjectType => 'Ticket',
                FieldType  => 'WebserviceMultiselect',
                Config     => {
                    DefaultValue => "",
                },
            },
            Value => [ 'first', 'second', 'third' ],
        },
        Expected => {
            Value => "first, second, third",
        },
    },
    {
        Name => 'default template - DisplayedValuesSeparator separator HTML',
        Data => {
            DynamicFieldConfig => {
                Name       => 'Multiselect',
                Label      => 'Multiselect',
                ObjectType => 'Ticket',
                FieldType  => 'WebserviceMultiselect',
                Config     => {
                    DefaultValue             => "",
                    DisplayedValuesSeparator => '<space>-<space>',
                    TemplateType             => 'separator',
                },
            },
            Value => [ 'first', 'second', 'third' ],
        },
        Expected => {
            Value => "first - second - third",
        },
    },
    {
        Name => 'default template - wordwrap HTML',
        Data => {
            DynamicFieldConfig => {
                Name       => 'Multiselect',
                Label      => 'Multiselect',
                ObjectType => 'Ticket',
                FieldType  => 'WebserviceMultiselect',
                Config     => {
                    DefaultValue => "",
                    TemplateType => 'wordwrap',
                },
            },
            Value => [ 'first', 'second', 'third' ],
        },
        Expected => {
            Value => "first<br>second<br>third",
        },
    },
    {
        Name => 'default template - list HTML',
        Data => {
            DynamicFieldConfig => {
                Name       => 'Multiselect',
                Label      => 'Multiselect',
                ObjectType => 'Ticket',
                FieldType  => 'WebserviceMultiselect',
                Config     => {
                    DefaultValue => "",
                    TemplateType => 'list',
                },
            },
            Value => [ 'first', 'second', 'third' ],
        },
        Expected => {
            Value => "<ul><li>first</li><li>second</li><li>third</li></ul>",
        },
    },
);

for my $Test (@Tests) {

    my $Value = $DynamicFieldWebserviceObject->Template(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $Value,
        $Test->{Expected}->{Value},
        "$Test->{Name} - Template",
    );
}

# AdditionalRequestDataGet
my %Data = $DynamicFieldWebserviceObject->AdditionalRequestDataGet(
    UserID   => 1,
    UserType => 'Agent',
);

$Self->Is(
    $Data{UserLogin},
    'root@localhost',
    'AdditionalRequestDataGet - UserID 1',
);

my $RandomID     = $HelperObject->GetRandomNumber();
my $CustomerUser = $HelperObject->TestCustomerUserCreate(
    Language  => 'de',
    UserLogin => $RandomID,
);
%Data = $DynamicFieldWebserviceObject->AdditionalRequestDataGet(
    UserID   => $CustomerUser,
    UserType => 'Customer',
);

$Self->Is(
    $Data{UserLogin},
    $RandomID,
    "AdditionalRequestDataGet - UserID $RandomID",
);

1;
