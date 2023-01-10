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

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject      = $Kernel::OM->Get('Kernel::System::SysConfig');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $DBObject             = $Kernel::OM->Get('Kernel::System::DB');

my $Value = 'test';
if ( $DBObject->{Backend}->{'DB::CaseSensitive'} ) {
    $Value = 'Test';
}

# Tests for _ItemReverseListGet function
my $ResultItemReverseListGet = $ZnunyHelperObject->_ItemReverseListGet(
    $Value, ( 'Test' => 1 )
);

$Self->True(
    $ResultItemReverseListGet,
    'Test basic function call of _ItemReverseListGet()',
);

# Tests for _EventAdd function
my $ResultEventAdd = $ZnunyHelperObject->_EventAdd(
    Object => 'Ticket',
    Event  => [
        'ZnunyEvent1',
        'ZnunyEvent2',
    ],
);

$Self->True(
    $ResultEventAdd,
    'Test basic function call of _EventAdd()',
);

# Tests for _EventRemove function
my $ResultEventRemove = $ZnunyHelperObject->_EventRemove(
    Object => 'Ticket',
    Event  => [
        'ZnunyEvent1',
        'ZnunyEvent2',
    ],
);

$Self->True(
    $ResultEventRemove,
    'Test basic function call of _EventRemove()',
);

my $Success;
my %DefaultColumns = (
    Title                     => 1,
    CustomerUserID            => 1,
    DynamicField_DropdownTest => 1,
    DynamicField_Anotherone   => 1,
);

my %DefaultColumnsConfigs = (
    'Ticket::Frontend::AgentTicketStatusView###DefaultColumns'      => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketQueue###DefaultColumns'           => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns' => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketWatchView###DefaultColumns'       => \%DefaultColumns,

    'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'     => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns' => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketSearch###DefaultColumns'         => \%DefaultColumns,
    'Ticket::Frontend::AgentTicketService###DefaultColumns'        => \%DefaultColumns,

    'DashboardBackend###0100-TicketPendingReminder' => \%DefaultColumns,
    'DashboardBackend###0110-TicketEscalation'      => \%DefaultColumns,
    'DashboardBackend###0120-TicketNew'             => \%DefaultColumns,
    'DashboardBackend###0130-TicketOpen'            => \%DefaultColumns,
    'DashboardBackend###0140-RunningTicketProcess'  => \%DefaultColumns,

    'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => \%DefaultColumns,
    'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation'      => \%DefaultColumns,
    'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => \%DefaultColumns,
    'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen'            => \%DefaultColumns,
);

# Tests for _DefaultColumnsEnable function
$Success = $ZnunyHelperObject->_DefaultColumnsEnable(%DefaultColumnsConfigs);

$Self->True(
    $Success,
    'Test basic function call of _DefaultColumnsEnable()',
);

# Tests for _DefaultColumnsDisable function
$Success = $ZnunyHelperObject->_DefaultColumnsDisable(%DefaultColumnsConfigs);

$Self->True(
    $Success,
    'Test basic function call of _DefaultColumnsDisable()',
);

my %DynamicFieldsScreen = (
    'TestDynamicField1' => 1,
    'TestDynamicField2' => 1,
);

# Tests for _DynamicFieldsScreenEnable function
my $ResultDynamicFieldsScreenEnable = $ZnunyHelperObject->_DynamicFieldsScreenEnable(
    'AgentTicketFreeText' => \%DynamicFieldsScreen
);

$Self->True(
    $ResultDynamicFieldsScreenEnable,
    'Test basic function call of _DynamicFieldsScreenEnable()',
);

$ZnunyHelperObject->_RebuildConfig();
$SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
$ConfigObject    = $Kernel::OM->Get('Kernel::Config');

my $AgentTicketFreeTextFrontendConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketFreeText');

for my $DynamicFieldScreen ( sort keys %DynamicFieldsScreen ) {
    $Self->Is(
        $AgentTicketFreeTextFrontendConfig->{DynamicField}->{$DynamicFieldScreen},
        $DynamicFieldsScreen{$DynamicFieldScreen},
        "_DynamicFieldsScreenEnable() for $DynamicFieldScreen in AgentTicketFreeText",
    );
}

# Tests for _DynamicFieldsScreenDisable function
my $ResultDynamicFieldsScreenDisable = $ZnunyHelperObject->_DynamicFieldsScreenDisable(
    'AgentTicketFreeText' => \%DynamicFieldsScreen,
);

$Self->True(
    $ResultDynamicFieldsScreenDisable,
    'Test basic function call of _DynamicFieldsScreenDisable()',
);

$ZnunyHelperObject->_RebuildConfig();
$SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
$ConfigObject    = $Kernel::OM->Get('Kernel::Config');

$AgentTicketFreeTextFrontendConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketFreeText');

for my $DynamicFieldScreen ( sort keys %DynamicFieldsScreen ) {
    $Self->False(
        $AgentTicketFreeTextFrontendConfig->{DynamicField}->{$DynamicFieldScreen},
        "_DynamicFieldsScreenDisable() for $DynamicFieldScreen in AgentTicketFreeText",
    );
}

# Tests for _DynamicFieldsCreateIfNotExists function
my $ResultDynamicFieldsCreateIfNotExists = $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
    {
        Name       => 'TestDynamicField1',
        Label      => "TestDynamicField1",
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
);

$Self->True(
    $ResultDynamicFieldsCreateIfNotExists,
    'Test basic function call of _DynamicFieldsCreateIfNotExists()',
);

# Tests for _DynamicFieldsDisable function
my $ResultDynamicFieldsDisable = $ZnunyHelperObject->_DynamicFieldsDisable(
    'TestDynamicField1',
);

$Self->True(
    $ResultDynamicFieldsDisable,
    'Test basic function call of _DynamicFieldsDisable()',
);

# Tests for _DynamicFieldsDelete function
my $ResultDynamicFieldsDelete = $ZnunyHelperObject->_DynamicFieldsDelete(
    'TestDynamicField1',
);

$Self->True(
    $ResultDynamicFieldsDelete,
    'Test basic function call of _DynamicFieldsDelete()',
);

# Tests for _GroupCreateIfNotExists function
my $ResultGroupCreateIfNotExists = $ZnunyHelperObject->_GroupCreateIfNotExists(
    Name => 'Some Group Name',
);

$Self->True(
    $ResultGroupCreateIfNotExists,
    'Test basic function call of _GroupCreateIfNotExists()',
);

# Tests for _RoleCreateIfNotExists function
my $ResultRoleCreateIfNotExists = $ZnunyHelperObject->_RoleCreateIfNotExists(
    Name => 'Some Role Name',
);

$Self->True(
    $ResultRoleCreateIfNotExists,
    'Test basic function call of _RoleCreateIfNotExists()',
);

# Tests for _TypeCreateIfNotExists function
my $ResultTypeCreateIfNotExists = $ZnunyHelperObject->_TypeCreateIfNotExists(
    Name => 'Some Type Name',
);

$Self->True(
    $ResultTypeCreateIfNotExists,
    'Test basic function call of _TypeCreateIfNotExists()',
);

# Tests for _StateCreateIfNotExists function
my $ResultStateCreateIfNotExists = $ZnunyHelperObject->_StateCreateIfNotExists(
    Name   => 'Some State Name',
    TypeID => 1,
);

$Self->True(
    $ResultStateCreateIfNotExists,
    'Test basic function call of _StateCreateIfNotExists()',
);

# Tests for _StateDisable function
my $ResultStateDisable = $ZnunyHelperObject->_StateDisable(
    'Some State Name',
);

$Self->True(
    $ResultStateDisable,
    'Test basic function call of _StateDisable()',
);

# Tests for _ServiceCreateIfNotExists function
my $ResultServiceCreateIfNotExists = $ZnunyHelperObject->_ServiceCreateIfNotExists(
    Name => 'Some ServiceName',
);

$Self->True(
    $ResultServiceCreateIfNotExists,
    'Test basic function call of _ServiceCreateIfNotExists()',
);

# Tests for _SLACreateIfNotExists function
my $ResultSLACreateIfNotExists = $ZnunyHelperObject->_SLACreateIfNotExists(
    Name => 'Some SLAName',
);

$Self->True(
    $ResultSLACreateIfNotExists,
    'Test basic function call of _SLACreateIfNotExists()',
);

# Tests for _QueueCreateIfNotExists function
my $ResultQueueCreateIfNotExists = $ZnunyHelperObject->_QueueCreateIfNotExists(
    Name    => 'Some Queue Name',
    GroupID => 1,
);

$Self->True(
    $ResultQueueCreateIfNotExists,
    'Test basic function call of _QueueCreateIfNotExists()',
);

# Tests for _WebserviceCreateIfNotExists function
my $ResultWebserviceCreateIfNotExists = $ZnunyHelperObject->_WebserviceCreateIfNotExists(
    SubDir => 'Znuny',
);

$Self->True(
    $ResultWebserviceCreateIfNotExists,
    'Test basic function call of _WebserviceCreateIfNotExists()',
);

# Tests for _WebservicesGet function
my $ResultWebservicesGet = $ZnunyHelperObject->_WebservicesGet(
    SubDir => 'Znuny',
);

$Self->True(
    $ResultWebservicesGet,
    'Test basic function call of _WebservicesGet()',
);

# Tests for _WebserviceDelete function
my $ResultWebserviceDelete = $ZnunyHelperObject->_WebserviceDelete(
    SubDir => 'Znuny',
);

$Self->True(
    $ResultWebserviceDelete,
    'Test basic function call of _WebserviceDelete()',
);

# Tests for _GenericAgentCreate and _GenericAgentCreateIfNotExists function
my @GenericAgents = (
    {
        Name => 'UnitTestJob',
        Data => {
            Valid => '1'
            ,

            # Event based execution (single ticket)
            EventValues => [
                'TicketCreate'
            ],

            # Select Tickets
            LockIDs => [
                '1'
            ],

            # Update/Add Ticket Attributes
            NewLockID => '2',
        },
        UserID => 1,
    },
);

my $ResultGenericAgentCreate = $ZnunyHelperObject->_GenericAgentCreate(@GenericAgents);
$Self->True(
    $ResultGenericAgentCreate,
    'Test basic function call of _GenericAgentCreate()',
);

my $ResultGenericAgentCreateIfNotExists = $ZnunyHelperObject->_GenericAgentCreateIfNotExists(@GenericAgents);
$Self->True(
    $ResultGenericAgentCreateIfNotExists,
    'Test basic function call of _GenericAgentCreateIfNotExists()',
);

1;
