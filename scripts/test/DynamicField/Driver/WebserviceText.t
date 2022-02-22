# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
my $UnitTestWebserviceObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $WebserviceObject          = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $WebserviceName = 'DynamicFieldWebservice';
my $DynamicField   = $WebserviceName . 'Driver';

$ZnunyHelperObject->_WebserviceCreate(
    Webservices => {
        $WebserviceName => 'scripts/test/sample/Webservice/' . $WebserviceName . '.yml',
    }
);
my $Webservice = $WebserviceObject->WebserviceGet(
    Name => $WebserviceName,
);

$Self->True(
    $Webservice,
    "WebserviceGet() - $WebserviceName",
);

$UnitTestWebserviceObject->Mock(
    TestSearch => [
        {
            Data   => {},
            Result => {
                Success => 1,
                Data    => [
                    {
                        Key   => 'Znuny',
                        Value => 'Znuny',
                    },
                    {
                        Key   => 'Rocks',
                        Value => 'Rocks',
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
                    Key   => 'Znuny',
                    Value => 'Znuny',
                },
            },
        },
    ],
);

my @DynamicFields = (
    {
        Name       => $DynamicField . 'Text',
        Label      => $DynamicField . 'Text',
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceText',
        Config     => {
            Webservice               => $WebserviceName,
            InvokerSearch            => 'TestSearch',
            InvokerGet               => 'TestGet',
            Backend                  => 'DirectRequest',
            SearchKeys               => 'key',
            StoredValue              => 'key',
            DisplayedValues          => 'key',
            DisplayedValuesSeparator => '-',
            Limit                    => 100,
            AutocompleteMinLength    => 3,
            InputFieldWidth          => 50,
            QueryDelay               => 1,
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

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $DynamicField . 'Text',
);

# EditFieldRender
my $TicketID = $HelperObject->TicketCreate();
$LayoutObject->{TicketID} = $TicketID;

my $DynamicFieldHTML = $DynamicFieldBackendObject->EditFieldRender(
    DynamicFieldConfig => $DynamicFieldConfig,
    LayoutObject       => $LayoutObject,
    ParamObject        => $ParamObject,
    AJAXUpdate         => 1,
);

$Self->IsDeeply(
    $DynamicFieldHTML,
    {
        'Label' =>
            '<label id="LabelDynamicField_DynamicFieldWebserviceDriverText" for="DynamicField_DynamicFieldWebserviceDriverText">
DynamicFieldWebserviceDriverText:
</label>
',
        'Field' =>
            '<input type="hidden" class="Hidden" id="DynamicField_DynamicFieldWebserviceDriverText" name="DynamicField_DynamicFieldWebserviceDriverText" value="" data-dynamic-field-name="DynamicFieldWebserviceDriverText" data-dynamic-field-type="WebserviceText" data-selected-value-field-name="DynamicField_DynamicFieldWebserviceDriverText" data-autocomplete-field-name="DynamicField_DynamicFieldWebserviceDriverTextAutocomplete" data-autocomplete-min-length="3" data-ticket-id="'
            . $TicketID . '" />
<input type="text" class="DynamicFieldText W50pc" id="DynamicField_DynamicFieldWebserviceDriverTextAutocomplete" name="DynamicField_DynamicFieldWebserviceDriverTextAutocomplete" title="DynamicFieldWebserviceDriverText" value="" data-selected-autocomplete-display-value="" />
'
    },
    'EditFieldRender',
);

# ValueSet
$Success = $DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => 'UNKNOWN',
    UserID             => 1,
);

$Self->True(
    $Success,
    'ValueSet - UNKNOWN',
);

# ValueGet
my $ValueGet = $DynamicFieldBackendObject->ValueGet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
);

$Self->Is(
    $ValueGet,
    'UNKNOWN',
    'ValueGet',
);

1;
