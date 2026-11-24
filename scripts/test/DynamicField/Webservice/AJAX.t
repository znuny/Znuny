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

my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

my ( $AgentUserLogin, $AgentUserID ) = $HelperObject->TestUserCreate();

# Subaction Test must only be available for agents with permission on AdminDynamicFieldWebservice.
my %TestSubactionParams = (
    Subaction               => 'Test',
    DynamicFieldName        => 'TestSubaction',
    FieldType               => 'WebserviceDropdown',
    'Config[Backend]'       => '../../../../NotExisting',
    'Config[Webservice]'    => $WebserviceName,
    'Config[InvokerSearch]' => 'TestSearch',
    'Config[InvokerGet]'    => 'TestGet',
    'Config[StoredValue]'   => 'Key',
);
for my $Param ( sort keys %TestSubactionParams ) {
    $UnitTestParamObject->ParamSet(
        Name  => $Param,
        Value => $TestSubactionParams{$Param},
    );
}

my $AdminModuleGroupName = 'AdminDFWebservice' . $HelperObject->GetRandomID();
my $AdminModuleGroupID   = $GroupObject->GroupAdd(
    Name    => $AdminModuleGroupName,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $AdminModuleGroupID,
    "GroupAdd() - $AdminModuleGroupName",
);

my ( $AdminModuleUserLogin, $AdminModuleUserID ) = $HelperObject->TestUserCreate(
    Groups => [$AdminModuleGroupName],
);

my $OriginalAdminModuleReg = $ConfigObject->Get('Frontend::Module')->{AdminDynamicFieldWebservice};

my @TestSubactionTests = (
    {
        Name          => 'Subaction Test - customer interface is denied',
        SessionSource => 'CustomerInterface',
        UserID        => 1,
        Allowed       => 0,
    },
    {
        Name          => 'Subaction Test - agent without admin permission is denied',
        SessionSource => 'AgentInterface',
        UserID        => $AgentUserID,
        Allowed       => 0,
    },
    {
        Name          => 'Subaction Test - admin agent is allowed, invalid backend is reported',
        SessionSource => 'AgentInterface',
        UserID        => 1,
        Allowed       => 1,
    },
    {
        Name          => 'Subaction Test - agent of a group without module permission is denied',
        SessionSource => 'AgentInterface',
        UserID        => $AdminModuleUserID,
        Allowed       => 0,
    },
    {
        Name          => 'Subaction Test - agent of the group configured in module registration is allowed',
        SessionSource => 'AgentInterface',
        UserID        => $AdminModuleUserID,
        ModuleGroups  => [$AdminModuleGroupName],
        Allowed       => 1,
    },
    {
        Name          => 'Subaction Test - admin agent is denied if module registration uses another group',
        SessionSource => 'AgentInterface',
        UserID        => 1,
        ModuleGroups  => [$AdminModuleGroupName],
        Allowed       => 0,
    },
);

for my $Test (@TestSubactionTests) {
    my %ModuleReg = %{$OriginalAdminModuleReg};
    if ( $Test->{ModuleGroups} ) {
        $ModuleReg{Group}   = $Test->{ModuleGroups};
        $ModuleReg{GroupRo} = [];
    }
    $ConfigObject->Set(
        Key   => 'Frontend::Module###AdminDynamicFieldWebservice',
        Value => \%ModuleReg,
    );

    $LayoutObject->{SessionSource} = $Test->{SessionSource};
    $LayoutObject->{UserID}        = $Test->{UserID};

    my $Result = $AJAXDynamicFieldWebserviceObject->Run();

    if ( $Test->{Allowed} ) {
        $Self->True(
            (
                $Result =~ m{"Success":0}ms
                    && $Result =~ m{"ErrorMessage":"Invalid web service backend configuration\."}ms
                )
            ? 1
            : 0,
            $Test->{Name},
        );
    }
    else {
        $Self->False(
            ( $Result =~ m{"Success"}ms ? 1 : 0 ),
            $Test->{Name},
        );
    }
}

$ConfigObject->Set(
    Key   => 'Frontend::Module###AdminDynamicFieldWebservice',
    Value => $OriginalAdminModuleReg,
);

# Subactions Autocomplete and AutoFill must check ticket permission and,
# in the customer interface, the activation of the dynamic field on a customer screen.
my $CustomerUserLogin      = $HelperObject->TestCustomerUserCreate();
my $OtherCustomerUserLogin = $HelperObject->TestCustomerUserCreate();

my %TicketIDs;
for my $CustomerUser ( $CustomerUserLogin, $OtherCustomerUserLogin ) {
    $TicketIDs{$CustomerUser} = $TicketObject->TicketCreate(
        Title        => 'AJAXDynamicFieldWebservice permission test',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => $CustomerUser,
        CustomerUser => $CustomerUser,
        OwnerID      => 1,
        UserID       => 1,
    );
    $Self->True(
        $TicketIDs{$CustomerUser},
        "TicketCreate() - ticket for customer user $CustomerUser",
    );
}

my $PermissionDynamicFieldName = $DynamicField . 'Dropdown';

my $OriginalCustomerTicketMessageConfig = $ConfigObject->Get('Ticket::Frontend::CustomerTicketMessage')->{DynamicField}
    // {};
my $OriginalActivityDialogConfig = $ConfigObject->Get('Process::ActivityDialog');

my %CustomerScreenSetups = (
    None => sub {
        $ConfigObject->Set(
            Key   => 'Ticket::Frontend::CustomerTicketMessage###DynamicField',
            Value => $OriginalCustomerTicketMessageConfig,
        );
        $ConfigObject->Set(
            Key   => 'Process::ActivityDialog',
            Value => $OriginalActivityDialogConfig,
        );
    },
    CustomerTicketMessage => sub {
        $ConfigObject->Set(
            Key   => 'Ticket::Frontend::CustomerTicketMessage###DynamicField',
            Value => {
                %{$OriginalCustomerTicketMessageConfig},
                $PermissionDynamicFieldName => 1,
            },
        );
        $ConfigObject->Set(
            Key   => 'Process::ActivityDialog',
            Value => $OriginalActivityDialogConfig,
        );
    },
    CustomerProcess => sub {
        $ConfigObject->Set(
            Key   => 'Ticket::Frontend::CustomerTicketMessage###DynamicField',
            Value => $OriginalCustomerTicketMessageConfig,
        );
        $ConfigObject->Set(
            Key   => 'Process::ActivityDialog',
            Value => {
                'ActivityDialog-UnitTestAJAX' => {
                    Interface => ['CustomerInterface'],
                    Fields    => {
                        "DynamicField_$PermissionDynamicFieldName" => {
                            Display => 1,
                        },
                    },
                },
            },
        );
    },
    AgentProcess => sub {
        $ConfigObject->Set(
            Key   => 'Ticket::Frontend::CustomerTicketMessage###DynamicField',
            Value => $OriginalCustomerTicketMessageConfig,
        );
        $ConfigObject->Set(
            Key   => 'Process::ActivityDialog',
            Value => {
                'ActivityDialog-UnitTestAJAX' => {
                    Interface => ['AgentInterface'],
                    Fields    => {
                        "DynamicField_$PermissionDynamicFieldName" => {
                            Display => 1,
                        },
                    },
                },
            },
        );
    },
);

my @PermissionTests = (
    {
        Name           => 'Customer - Autocomplete - field not active on any customer screen is denied',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        CustomerScreen => 'None',
        Allowed        => 0,
    },
    {
        Name           => 'Customer - AutoFill - field not active on any customer screen is denied',
        Subaction      => 'AutoFill',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        CustomerScreen => 'None',
        Allowed        => 0,
    },
    {
        Name           => 'Customer - Autocomplete - field active on CustomerTicketMessage without TicketID is allowed',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        CustomerScreen => 'CustomerTicketMessage',
        Allowed        => 1,
    },
    {
        Name           => 'Customer - Autocomplete - ticket of another customer is denied',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        TicketID       => $TicketIDs{$OtherCustomerUserLogin},
        CustomerScreen => 'CustomerTicketMessage',
        Allowed        => 0,
    },
    {
        Name           => 'Customer - AutoFill - ticket of another customer is denied',
        Subaction      => 'AutoFill',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        TicketID       => $TicketIDs{$OtherCustomerUserLogin},
        CustomerScreen => 'CustomerTicketMessage',
        Allowed        => 0,
    },
    {
        Name           => 'Customer - Autocomplete - own ticket is allowed',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        TicketID       => $TicketIDs{$CustomerUserLogin},
        CustomerScreen => 'CustomerTicketMessage',
        Allowed        => 1,
    },
    {
        Name           => 'Customer - Autocomplete - field active in customer process activity dialog is allowed',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        CustomerScreen => 'CustomerProcess',
        Allowed        => 1,
    },
    {
        Name           => 'Customer - Autocomplete - field active in agent process activity dialog only is denied',
        Subaction      => 'Autocomplete',
        SessionSource  => 'CustomerInterface',
        UserID         => $CustomerUserLogin,
        CustomerScreen => 'AgentProcess',
        Allowed        => 0,
    },
    {
        Name           => 'Agent - Autocomplete - agent without permission on ticket is denied',
        Subaction      => 'Autocomplete',
        SessionSource  => 'AgentInterface',
        UserID         => $AgentUserID,
        TicketID       => $TicketIDs{$OtherCustomerUserLogin},
        CustomerScreen => 'None',
        Allowed        => 0,
    },
    {
        Name           => 'Agent - Autocomplete - agent with permission on ticket is allowed',
        Subaction      => 'Autocomplete',
        SessionSource  => 'AgentInterface',
        UserID         => 1,
        TicketID       => $TicketIDs{$OtherCustomerUserLogin},
        CustomerScreen => 'None',
        Allowed        => 1,
    },
);

for my $Test (@PermissionTests) {
    $CustomerScreenSetups{ $Test->{CustomerScreen} }->();

    my %Param = (
        Subaction        => $Test->{Subaction},
        SearchTerms      => 'Znuny',
        FieldType        => 'WebserviceDropdown',
        DynamicFieldName => $PermissionDynamicFieldName,
        TicketID         => $Test->{TicketID} // '',
    );
    for my $Param ( sort keys %Param ) {
        $UnitTestParamObject->ParamSet(
            Name  => $Param,
            Value => $Param{$Param},
        );
    }

    $LayoutObject->{SessionSource} = $Test->{SessionSource};
    $LayoutObject->{UserID}        = $Test->{UserID};

    my $Result = $AJAXDynamicFieldWebserviceObject->Run();

    if ( $Test->{Allowed} ) {
        $UnitTestWebserviceObject->ValidateResult(
            UnitTestObject => $Self,
        );

        my $ExpectedResult = $Test->{Subaction} eq 'AutoFill' ? '"Field1":"Znuny"' : '"StoredValue":"Znuny"';
        $Self->True(
            ( $Result =~ m{\Q$ExpectedResult\E}ms ? 1 : 0 ),
            $Test->{Name},
        );
    }
    else {
        my $WebserviceResults = $UnitTestWebserviceObject->Result();

        $Self->False(
            ( IsArrayRefWithData($WebserviceResults) ? 1 : 0 ),
            "$Test->{Name} - web service was not called",
        );
        $Self->True(
            ( $Result =~ m{\{\}\s*\z}ms ? 1 : 0 ),
            $Test->{Name},
        );
    }
}

$CustomerScreenSetups{None}->();

1;
