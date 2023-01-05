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

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');

my @DynamicFields = (
    {
        Name          => 'DynamicFieldSetTest',
        Label         => "DynamicFieldSetTest",
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        InternalField => 0,
        Config        => {
            DefaultValue => '',
            Link         => '',
        },
    },
);

my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    '_DynamicFieldsCreate(DynamicFieldSetTest)',
);

my $TicketID = $HelperObject->TicketCreate();

$HelperObject->DynamicFieldSet(
    Field      => 'DynamicFieldSetTest',
    ObjectID   => $TicketID,
    ObjectType => 'Ticket',
    Value      => '123',
    UserID     => 1,
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_DynamicFieldSetTest},
    123,
    'Ticket has the correct value saved for dynamic field DynamicFieldSetTest',
);

1;
