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
my $TicketAttributeRelationsObject = $Kernel::OM->Get('Kernel::System::TicketAttributeRelations');
my $ZnunyHelperObject              = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $DynamicFieldObject             = $Kernel::OM->Get('Kernel::System::DynamicField');

my $UserID = 1;

my $Home                 = $ConfigObject->Get('Home');
my $UnitTestBaseFilePath = $Home . '/scripts/test/TicketAttributeRelations/Excel/TestFiles/ImportCommand/';

my @DynamicFields = (
    {
        Name       => 'UnitTestDropdown1',
        Label      => "UnitTestDropdown1",
        ObjectType => 'Ticket',
        FieldType  => 'Dropdown',
        Config     => {
            PossibleValues     => { Test => 'Test' },
            DefaultValue       => "Key",
            TreeView           => '0',
            PossibleNone       => '0',
            TranslatableValues => '0',
            Link               => '',
        },
    },
    {
        Name       => 'UnitTestDropdown2',
        Label      => "UnitTestDropdown2",
        ObjectType => 'Ticket',
        FieldType  => 'Dropdown',
        Config     => {
            PossibleValues     => { Test => 'Test' },
            DefaultValue       => "Key",
            TreeView           => '0',
            PossibleNone       => '0',
            TranslatableValues => '0',
            Link               => '',
        },
    },
);

my $DynamicFieldsCreated = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    scalar $DynamicFieldsCreated,
    "Creation of dynamic fields must succeed.",
);

#
# Import new file
#

my $UnitTestFilename = 'ImportCommand1.xlsx';

my $FilePath = $UnitTestBaseFilePath . $UnitTestFilename;

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

my $TicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
    UserID => $UserID,
);

my @ImportedTicketAttributeRelations;
if ( IsArrayRefWithData($TicketAttributeRelations) ) {
    @ImportedTicketAttributeRelations = grep { $_->{Filename} eq $UnitTestFilename } @{$TicketAttributeRelations};
}

$Self->Is(
    scalar @ImportedTicketAttributeRelations,
    1,
    'There must be exactly one entry with the name of the imported file.',
);

my $ImportedTicketAttributeRelations = shift @ImportedTicketAttributeRelations;

my %ExpectedImportedTicketAttributeRelations = (
    ID         => $ImportedTicketAttributeRelations->{ID},
    Filename   => $UnitTestFilename,
    Priority   => $ImportedTicketAttributeRelations->{Priority},
    Attribute1 => 'DynamicField_UnitTestDropdown1',
    Attribute2 => 'DynamicField_UnitTestDropdown2',
    RawData    => $ImportedTicketAttributeRelations->{RawData},    # Don't mess around with Excel file content here
    Data       => [
        {
            DynamicField_UnitTestDropdown1 => 'a',
            DynamicField_UnitTestDropdown2 => '1',
        },
        {
            DynamicField_UnitTestDropdown1 => 'b',
            DynamicField_UnitTestDropdown2 => '2',
        },
        {
            DynamicField_UnitTestDropdown1 => 'c',
            DynamicField_UnitTestDropdown2 => '3',
        },
    ],
    CreatedTime => $ImportedTicketAttributeRelations->{CreatedTime},
    CreatedBy   => $UserID,
    ChangeTime  => $ImportedTicketAttributeRelations->{ChangeTime},
    ChangedBy   => $UserID,
);

$Self->IsDeeply(
    $ImportedTicketAttributeRelations,
    \%ExpectedImportedTicketAttributeRelations,
    'Imported ticket attribute relations must match expected one.',
);

#
# Update imported ticket attribute relations
#

$FilePath = $UnitTestBaseFilePath . 'Update1/' . $UnitTestFilename;

$ImportCommandResult = $HelperObject->ConsoleCommand(
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

$TicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
    UserID => $UserID,
);

my @UpdatedTicketAttributeRelations;
if ( IsArrayRefWithData($TicketAttributeRelations) ) {
    @UpdatedTicketAttributeRelations = grep { $_->{Filename} eq $UnitTestFilename } @{$TicketAttributeRelations};
}

$Self->Is(
    scalar @UpdatedTicketAttributeRelations,
    1,
    'There must be exactly one entry with the name of the imported file after importing the file again.',
);

my $UpdatedTicketAttributeRelations = shift @UpdatedTicketAttributeRelations;

my %ExpectedUpdatedTicketAttributeRelations = (
    ID         => $ImportedTicketAttributeRelations->{ID},       # yes, the one from the imported one before the update.
    Filename   => $UnitTestFilename,
    Priority   => $ImportedTicketAttributeRelations->{Priority}, # yes, the one from the imported one before the update.
    Attribute1 => 'DynamicField_UnitTestDropdown1',
    Attribute2 => 'DynamicField_UnitTestDropdown2',
    RawData    => $UpdatedTicketAttributeRelations->{RawData},   # Don't mess around with Excel file content here
    Data       => [
        {
            DynamicField_UnitTestDropdown1 => 'a',
            DynamicField_UnitTestDropdown2 => '4',
        },
        {
            DynamicField_UnitTestDropdown1 => 'b',
            DynamicField_UnitTestDropdown2 => '5',
        },
        {
            DynamicField_UnitTestDropdown1 => 'c',
            DynamicField_UnitTestDropdown2 => '6',
        },
    ],
    CreatedTime => $ImportedTicketAttributeRelations->{CreatedTime}
    ,    # yes, the one from the imported one before the update.
    CreatedBy  => $UserID,
    ChangeTime => $UpdatedTicketAttributeRelations->{ChangeTime},
    ChangedBy  => $UserID,
);

$Self->IsDeeply(
    $UpdatedTicketAttributeRelations,
    \%ExpectedUpdatedTicketAttributeRelations,
    'Imported ticket attribute relations must match expected one after update.',
);

#
# Check that dynamic field configs still have the original possible values configured.
#
my %ExpectedDynamicFieldPossibleValues = (
    UnitTestDropdown1 => {
        Test => 'Test',
    },
    UnitTestDropdown2 => {
        Test => 'Test',
    },
);

for my $DynamicFieldName ( sort keys %ExpectedDynamicFieldPossibleValues ) {
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    );

    $Self->IsDeeply(
        $DynamicFieldConfig->{Config}->{PossibleValues},
        $ExpectedDynamicFieldPossibleValues{$DynamicFieldName},
        "Possible values of dynamic field $DynamicFieldName must match expected ones.",
    );
}

#
# Update with dynamic field config update
#

$FilePath = $UnitTestBaseFilePath . 'Update2/' . $UnitTestFilename;

$ImportCommandResult = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::TicketAttributeRelations::Import',
    Parameter     => [
        $FilePath,
        '--dynamic-field-config-update',
    ],
);

$Self->Is(
    scalar $ImportCommandResult->{ExitCode},
    0,
    'Execution of command Admin::TicketAttributeRelations::Import must be successful.',
);

$TicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
    UserID => $UserID,
);

if ( IsArrayRefWithData($TicketAttributeRelations) ) {
    @UpdatedTicketAttributeRelations = grep { $_->{Filename} eq $UnitTestFilename } @{$TicketAttributeRelations};
}

$Self->Is(
    scalar @UpdatedTicketAttributeRelations,
    1,
    'There must be exactly one entry with the name of the imported file after importing the file again.',
);

$UpdatedTicketAttributeRelations = shift @UpdatedTicketAttributeRelations;

%ExpectedUpdatedTicketAttributeRelations = (
    ID         => $ImportedTicketAttributeRelations->{ID},       # yes, the one from the imported one before the update.
    Filename   => $UnitTestFilename,
    Priority   => $ImportedTicketAttributeRelations->{Priority}, # yes, the one from the imported one before the update.
    Attribute1 => 'DynamicField_UnitTestDropdown1',
    Attribute2 => 'DynamicField_UnitTestDropdown2',
    RawData    => $UpdatedTicketAttributeRelations->{RawData},   # Don't mess around with Excel file content here
    Data       => [
        {
            DynamicField_UnitTestDropdown1 => 'a',
            DynamicField_UnitTestDropdown2 => '7',
        },
        {
            DynamicField_UnitTestDropdown1 => 'b',
            DynamicField_UnitTestDropdown2 => '8',
        },
        {
            DynamicField_UnitTestDropdown1 => 'c',
            DynamicField_UnitTestDropdown2 => '9',
        },
    ],
    CreatedTime => $ImportedTicketAttributeRelations->{CreatedTime}
    ,    # yes, the one from the imported one before the update.
    CreatedBy  => $UserID,
    ChangeTime => $UpdatedTicketAttributeRelations->{ChangeTime},
    ChangedBy  => $UserID,
);

$Self->IsDeeply(
    $UpdatedTicketAttributeRelations,
    \%ExpectedUpdatedTicketAttributeRelations,
    'Imported ticket attribute relations must match expected one after update.',
);

#
# Check that dynamic field configs still have the original possible values configured.
#
%ExpectedDynamicFieldPossibleValues = (
    UnitTestDropdown1 => {
        Test => 'Test',
        a    => 'a',
        b    => 'b',
        c    => 'c',
    },
    UnitTestDropdown2 => {
        Test => 'Test',
        7    => 7,
        8    => 8,
        9    => 9,
    },
);

for my $DynamicFieldName ( sort keys %ExpectedDynamicFieldPossibleValues ) {
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    );

    $Self->IsDeeply(
        $DynamicFieldConfig->{Config}->{PossibleValues},
        $ExpectedDynamicFieldPossibleValues{$DynamicFieldName},
        "Possible values of dynamic field $DynamicFieldName must match expected ones.",
    );
}

#
# Add a new ticket attribute relations record and update the priority of the existing one to from 1 to 2.
#

my $SecondUnitTestFilename = 'ImportCommand2.xlsx';
my $SecondFilePath         = $UnitTestBaseFilePath . $SecondUnitTestFilename;

$ImportCommandResult = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::TicketAttributeRelations::Import',
    Parameter     => [
        $SecondFilePath,
    ],
);

$Self->Is(
    scalar $ImportCommandResult->{ExitCode},
    0,
    'Execution of command Admin::TicketAttributeRelations::Import must be successful.',
);

# Now update first ticket attribute relations record from priority 1 to 2.
$ImportCommandResult = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::TicketAttributeRelations::Import',
    Parameter     => [
        $FilePath,
        '--priority', 2,
    ],
);

$Self->Is(
    scalar $ImportCommandResult->{ExitCode},
    0,
    'Execution of command Admin::TicketAttributeRelations::Import must be successful.',
);

$TicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
    UserID => $UserID,
);

my @TicketAttributeRelationsToCheck;
if ( IsArrayRefWithData($TicketAttributeRelations) ) {
    @TicketAttributeRelationsToCheck = grep {
        $_->{Filename} eq $UnitTestFilename
            || $_->{Filename} eq $SecondUnitTestFilename
        }
        sort { $a->{Priority} <=> $b->{Priority} }
        @{$TicketAttributeRelations};
}

$Self->Is(
    scalar @TicketAttributeRelationsToCheck,
    2,
    'There must be two entries with the names of the imported files.',
);

# Verify priorities
$Self->True(
    $TicketAttributeRelationsToCheck[1]->{Filename} eq $UnitTestFilename
        && $TicketAttributeRelationsToCheck[1]->{Priority} == 2,
    'First imported ticket attribute relations record now must have priority 2.',
);

$Self->True(
    $TicketAttributeRelationsToCheck[0]->{Filename} eq $SecondUnitTestFilename
        && $TicketAttributeRelationsToCheck[0]->{Priority} == 1,
    'Second imported ticket attribute relations record now must have priority 1.',
);

1;
