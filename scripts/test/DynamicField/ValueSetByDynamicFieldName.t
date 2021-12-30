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

my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my @DynamicFields = (
    {
        Name          => 'DynamicFieldValueSetTest',
        Label         => "DynamicFieldValueSetTest",
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        InternalField => 0,
        Config        => {
            DefaultValue => '',
            Link         => '',
        },
    },
);

$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

my $TicketID = $HelperObject->TicketCreate();

#
# Test for Kernel::System::DynamicField::Backend::ValueSet with optional parameter DynamicFieldName.
#
my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'DynamicFieldValueSetTest',
);

# First, set field via config (standard OTRS).
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => '456',
    UserID             => 1,
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_DynamicFieldValueSetTest},
    456,
    'Ticket has the correct value saved for dynamic field DynamicFieldValueSetTest via dynamic field backend ValueSet with dynamic field config param.',
);

# Set field via dynamic field name (new optional parameter).
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldName => 'DynamicFieldValueSetTest',
    ObjectID         => $TicketID,
    Value            => '789',
    UserID           => 1,
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_DynamicFieldValueSetTest},
    789,
    'Ticket has the correct value saved for dynamic field DynamicFieldValueSetTest via dynamic field backend ValueSet with dynamic field name param.',
);

1;
