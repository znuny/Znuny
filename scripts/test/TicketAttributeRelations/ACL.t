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

my $HelperObject                   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject                   = $Kernel::OM->Get('Kernel::Config');
my $MainObject                     = $Kernel::OM->Get('Kernel::System::Main');
my $UserObject                     = $Kernel::OM->Get('Kernel::System::User');
my $ZnunyHelperObject              = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $TicketAttributeRelationsObject = $Kernel::OM->Get('Kernel::System::TicketAttributeRelations');

my $Home                 = $ConfigObject->Get('Home');
my $UnitTestBaseFilePath = $Home . '/scripts/test/TicketAttributeRelations/Excel/TestFiles/ImportCommand/';
my $UnitTestFilename     = 'ImportCommand2.xlsx';
my $FilePath             = $UnitTestBaseFilePath . $UnitTestFilename;

my $UserID = 1;

my $TestUserLogin = $HelperObject->TestUserCreate(
    Groups   => ['users'],
    Language => 'de'
);

my $TestUserID = $UserObject->UserLookup(
    UserLogin => $TestUserLogin,
);

#
# Import ticket attribute relations with the following data:
#
# DynamicField_UnitTestDropdown1; DynamicField_UnitTestDropdown2
# d; 10
# e; 11
# f; 12
#
my $ImportCommandResult = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::TicketAttributeRelations::Import',
    Parameter     => [
        $FilePath,
    ],
);

$Self->Is(
    scalar $ImportCommandResult->{ExitCode},
    0,
    'Execution of command Admin::TicketAttributeRelations::Import must be successful.',
);

#
# Create test dynamic fields.
#
my @DynamicFieldConfigs = (
    {
        Name          => 'UnitTestDropdown1',
        Label         => "UnitTestDropdown1",
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Dropdown',
        Config        => {
            DefaultValue   => "",
            PossibleValues => {
                a => 'a',
                b => 'b',
                c => 'c',
                d => 'd',
                e => 'e',
                f => 'f',
                w => 'w',
                x => 'x',
                y => 'y',
                z => 'z',
            },
        },
    },
    {
        Name          => 'UnitTestDropdown2',
        Label         => "UnitTestDropdown2",
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Multiselect',
        Config        => {
            DefaultValue   => "",
            PossibleValues => {
                1  => 1,
                2  => 2,
                9  => 9,
                10 => 10,
                11 => 11,
                12 => 12,
                26 => 26,
                50 => 50,
                85 => 85,
            },
        },
    },
);

$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFieldConfigs);

#
# Execute tests for ACL module Kernel::System::Ticket::Acl::TicketAttributeRelations.
# Just use one of the combinations stored in the imported Excel file:
# UnitTestDropdown1 = e => UnitTestDropdown2 = 12
#
my %ACLValues = $HelperObject->ACLValuesGet(
    Check        => 'DynamicField_UnitTestDropdown2',
    Action       => 'AgentTicketNote',
    DynamicField => {
        DynamicField_UnitTestDropdown1 => 'e',
    },
    UserID => $TestUserID,
);

my %ExpectedACLValues = (
    11 => 11,
);

$Self->IsDeeply(
    \%ACLValues,
    \%ExpectedACLValues,
    'ACL values must match expected ones.',
);

# Also test for a value combination not stored in the Excel file.
%ACLValues = $HelperObject->ACLValuesGet(
    Check        => 'DynamicField_UnitTestDropdown2',
    Action       => 'AgentTicketNote',
    DynamicField => {
        DynamicField_UnitTestDropdown1 => 'Some value',
    },
    UserID => $TestUserID,
);

%ExpectedACLValues = %{ $DynamicFieldConfigs[1]->{Config}->{PossibleValues} };

$Self->IsDeeply(
    \%ACLValues,
    \%ExpectedACLValues,
    'ACL values must match expected ones.',
);

1;
