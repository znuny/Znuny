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

my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestParamObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Param');
my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
my $WebserviceObject          = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $UnitTestWebserviceObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

$LayoutObject->{Action} = 'AgentTicketSearch';
$LayoutObject->{UserID} = 1;

my $DynamicField   = 'WebserviceCustomSearchFormTest';
my $WebserviceName = 'DynamicFieldWebservice';

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
                    {
                        Key   => 'Znuny2',
                        Value => 'Znuny2',
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

my @Tests = (

    # WebserviceDropdown
    {
        Name                              => 'WebserviceDropdown - CustomSearchForm (nothing)',
        DynamicFieldName                  => $DynamicField . 'Dropdown',
        Param                             => {},
        ExpectedGetParamResult            => {},
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Dropdown" => [],
        },
    },
    {
        Name             => 'WebserviceDropdown - CustomSearchForm (succeeding)',
        DynamicFieldName => $DynamicField . 'Dropdown',
        Param            => {
            DynamicFieldWebserviceCustomSearchForm              => '1',
            "Search_DynamicField_" . $DynamicField . "Dropdown" => 'Znuny2',
        },
        ExpectedGetParamResult => {
            "Search_DynamicField_" . $DynamicField . "Dropdown" => [
                'Znuny2'
            ],
        },
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Dropdown" => [
                'Znuny2'
            ],
        },
    },
    {
        Name             => 'WebserviceDropdown - CustomSearchForm (succeeding)',
        DynamicFieldName => $DynamicField . 'Dropdown',
        Param            => {
            DynamicFieldWebserviceCustomSearchForm              => '1',
            "Search_DynamicField_" . $DynamicField . "Dropdown" => 'Znuny*',
        },
        ExpectedGetParamResult => {
            "Search_DynamicField_" . $DynamicField . "Dropdown" => [
                'Znuny',
                'Znuny2',
            ],
        },
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Dropdown" => [
                'Znuny',
                'Znuny2',
            ],
        },
    },

    # WebserviceMultiselect
    {
        Name                              => 'WebserviceMultiselect - CustomSearchForm (nothing)',
        DynamicFieldName                  => $DynamicField . 'Multiselect',
        Param                             => {},
        ExpectedGetParamResult            => {},
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Multiselect" => [],
        },
    },
    {
        Name             => 'WebserviceMultiselect - CustomSearchForm (succeeding)',
        DynamicFieldName => $DynamicField . 'Multiselect',
        Param            => {
            DynamicFieldWebserviceCustomSearchForm                 => '1',
            "Search_DynamicField_" . $DynamicField . "Multiselect" => 'Znuny2',
        },
        ExpectedGetParamResult => {
            "Search_DynamicField_" . $DynamicField . "Multiselect" => [
                'Znuny2',
            ],
        },
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Multiselect" => [
                'Znuny2',
            ],
        },
    },
    {
        Name             => 'WebserviceMultiselect - CustomSearchForm (succeeding)',
        DynamicFieldName => $DynamicField . 'Multiselect',
        Param            => {
            DynamicFieldWebserviceCustomSearchForm                 => '1',
            "Search_DynamicField_" . $DynamicField . "Multiselect" => 'Znuny*',
        },
        ExpectedGetParamResult => {
            "Search_DynamicField_" . $DynamicField . "Multiselect" => [
                'Znuny',
                'Znuny2',
            ],
        },
        ExpectedSearchFieldValueGetResult => {
            "Search_DynamicField_" . $DynamicField . "Multiselect" => [
                'Znuny',
                'Znuny2',
            ],
        },
    },
);

for my $Test (@Tests) {
    for my $Param ( sort keys %{ $Test->{Param} } ) {
        my $Value = $Test->{Param}->{$Param};
        $UnitTestParamObject->ParamSet(
            Name  => $Param,
            Value => $Value,
        );
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Test->{DynamicFieldName},
    );

    my $SearchFieldValues = $DynamicFieldBackendObject->SearchFieldValueGet(
        DynamicFieldConfig     => $DynamicFieldConfig,
        ParamObject            => $ParamObject,
        ReturnProfileStructure => 1,
        LayoutObject           => $LayoutObject,
    );

    # Test return value of SearchFieldValueGet()
    $Self->IsDeeply(
        $SearchFieldValues,
        $Test->{ExpectedSearchFieldValueGetResult},
        $Test->{Name},
    );

    # Test manipulated request parameters
    for my $Param ( sort keys %{ $Test->{ExpectedGetParamResult} } ) {
        my @SearchValues = $ParamObject->GetArray( Param => $Param );

        $Self->IsDeeply(
            \@SearchValues,
            $Test->{ExpectedGetParamResult}->{$Param},
            $Test->{Name},
        );
    }
}

1;
