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

use Kernel::Modules::AJAXDynamicFieldWebservice;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestParamObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Param');
my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $ZnunyHelperObject        = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $WebserviceObject         = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

my $AJAXDynamicFieldWebserviceObject = Kernel::Modules::AJAXDynamicFieldWebservice->new( %{$Self} );

$LayoutObject->{UserID} = 1;

my $Result         = $UnitTestWebserviceObject->Result();
my $WebserviceName = 'DynamicFieldWebservice';
my $DynamicField   = $WebserviceName . 'AJAX';

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

my @DynamicFields = (
    {
        Name       => 'Field1',
        Label      => 'Field1',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => 'Field2',
        Label      => 'Field2',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => $DynamicField . 'Dropdown',
        Label      => $DynamicField . 'Dropdown',
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceDropdown',
        Config     => {
            DefaultValue        => '',
            Link                => '',
            InvokerSearch       => 'TestSearch',
            InvokerGet          => 'TestGet',
            Webservice          => $WebserviceName,
            SearchKeys          => 'Key',
            AdditionalDFStorage => [
                {
                    DynamicField => 'Field1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend'
                },
                {
                    DynamicField => 'Field2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend'
                },
            ],
        },
    },
    {
        Name       => $DynamicField . 'Multiselect',
        Label      => $DynamicField . 'Multiselect',
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceMultiselect',
        Config     => {
            DefaultValue        => '',
            Link                => '',
            InvokerSearch       => 'TestSearch',
            InvokerGet          => 'TestGet',
            Webservice          => $WebserviceName,
            SearchKeys          => 'Key',
            AdditionalDFStorage => [
                {
                    DynamicField => 'Field1',
                    Key          => 'Key',
                    Type         => 'FrontendBackend'
                },
                {
                    DynamicField => 'Field2',
                    Key          => 'Value',
                    Type         => 'FrontendBackend'
                },
            ],
        },
    },
);

$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

my @Tests = (

    # WebserviceDropdown
    {
        Name  => 'WebserviceDropdown - Autocomplete (nothing)',
        Param => {
            Subaction        => 'Autocomplete',
            SearchTerms      => 'xxx',
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $DynamicField . 'Dropdown',
        },
        ExpectedResult => '\[\]',
    },
    {
        Name  => 'WebserviceDropdown - Autocomplete (succeeding)',
        Param => {
            Subaction        => 'Autocomplete',
            SearchTerms      => 'Znuny',
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $DynamicField . 'Dropdown',
        },
        ExpectedResult => '[{"StoredValue":"Znuny","DisplayValue":"Znuny"}]',
    },
    {
        Name  => 'WebserviceDropdown - AutoFill (nothing)',
        Param => {
            Subaction        => 'AutoFill',
            SearchTerms      => 'xxx',
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $DynamicField . 'Dropdown',
        },
        ExpectedResult => '"Field1":null',
    },
    {
        Name  => 'WebserviceDropdown - AutoFill (succeeding)',
        Param => {
            Subaction        => 'AutoFill',
            SearchTerms      => 'Znuny',
            FieldType        => 'WebserviceDropdown',
            DynamicFieldName => $DynamicField . 'Dropdown',
        },
        ExpectedResult => '"Field1":"Znuny"',
    },

    # WebserviceMultiselect
    {
        Name  => 'WebserviceMultiselect - Autocomplete (nothing)',
        Param => {
            Subaction        => 'Autocomplete',
            SearchTerms      => 'xxx',
            FieldType        => 'WebserviceMultiselect',
            DynamicFieldName => $DynamicField . 'Multiselect',
        },
        ExpectedResult => '\[\]',
    },
    {
        Name  => 'WebserviceMultiselect - Autocomplete (succeeding)',
        Param => {
            Subaction        => 'Autocomplete',
            SearchTerms      => 'Rocks',
            FieldType        => 'WebserviceMultiselect',
            DynamicFieldName => $DynamicField . 'Multiselect',
        },
        ExpectedResult => '[{"StoredValue":"Rocks","DisplayValue":"Rocks"}]',
    },
    {
        Name  => 'WebserviceMultiselect - AutoFill (nothing)',
        Param => {
            Subaction        => 'AutoFill',
            SearchTerms      => 'xxx',
            FieldType        => 'WebserviceMultiselect',
            DynamicFieldName => $DynamicField . 'Multiselect',
        },
        ExpectedResult => '"Field1":null',
    },
    {
        Name  => 'WebserviceMultiselect - AutoFill (succeeding)',
        Param => {
            Subaction        => 'AutoFill',
            SearchTerms      => 'Znuny',
            FieldType        => 'WebserviceMultiselect',
            DynamicFieldName => $DynamicField . 'Multiselect',
        },
        ExpectedResult => '"Field1":"Znuny"',
    },
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

for my $Test (@Tests) {
    for my $Param ( sort keys %{ $Test->{Param} } ) {
        my $Value = $Test->{Param}->{$Param};
        $UnitTestParamObject->ParamSet(
            Name  => $Param,
            Value => $Value,
        );
    }

    my $Result         = $AJAXDynamicFieldWebserviceObject->Run();
    my $ValidateResult = $UnitTestWebserviceObject->ValidateResult(
        UnitTestObject => $Self,
    );

    $Self->True(
        ( $Result =~ m{$Test->{ExpectedResult}}msi ? 1 : 0 ),
        $Test->{Name} . " - ExpectedResult: $Test->{ExpectedResult}",
    );
}

1;
