# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## nofilter(TidyAll::Plugin::Znuny4OTRS::Legal::AGPLValidator)

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');
my $DynamicFieldObject    = $Kernel::OM->Get('Kernel::System::DynamicField');
my $CustomerUserObject    = $Kernel::OM->Get('Kernel::System::CustomerUser');
my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $Helper->GetRandomID();

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);
$ConfigObject->Set(
    Key   => 'DynamicFieldFromCustomerCompany::Mapping',
    Value => {
        CustomerCompanyURL  => 'CustomerCompanyURL' . $RandomID,
        CustomerCompanyName => 'CustomerCompanyName' . $RandomID,
        CustomerID          => 'CustomerID' . $RandomID,
    },
);
$ConfigObject->Set(
    Key   => 'Ticket::EventModulePost###4100-DynamicFieldFromCustomerCompany',
    Value => {
        Module => 'Kernel::System::Ticket::Event::DynamicFieldFromCustomerCompany',
        Event  => '(TicketCreate|TicketCustomerUpdate)',
    },
);

my @DynamicFields = (
    {
        Name       => 'CustomerCompanyURL' . $RandomID,
        Label      => 'CustomerCompanyURL',
        FieldOrder => 9993,
    },
    {
        Name       => 'CustomerCompanyName' . $RandomID,
        Label      => 'CustomerCompanyName',
        FieldOrder => 9994,
    },
    {
        Name       => 'CustomerID' . $RandomID,
        Label      => 'CustomerID',
        FieldOrder => 9995,
    },
);

my @AddedDynamicFieldNames;
for my $DynamicFieldConfig (@DynamicFields) {
    my $ID = $DynamicFieldObject->DynamicFieldAdd(
        %{$DynamicFieldConfig},
        Config => {
            DefaultValue => '',
        },
        FieldType     => 'Text',
        ObjectType    => 'Ticket',
        InternalField => 0,
        Reorder       => 0,
        ValidID       => 1,
        UserID        => 1,
    );

    $Self->IsNot(
        $ID,
        undef,
        "DynamicFieldAdd() for '$DynamicFieldConfig->{Label}' Field ID should be defined",
    );

    push @AddedDynamicFieldNames, $DynamicFieldConfig->{Name};
}

my $TestCustomerID = $CustomerCompanyObject->CustomerCompanyAdd(
    CustomerID             => 'CustomerID' . $RandomID,
    CustomerCompanyName    => 'CustomerCompanyName' . $RandomID,
    CustomerCompanyStreet  => 'Some Street',
    CustomerCompanyZIP     => '12345',
    CustomerCompanyCity    => 'Some city',
    CustomerCompanyCountry => 'USA',
    CustomerCompanyURL     => 'http://example.com' . $RandomID,
    CustomerCompanyComment => 'some comment',
    ValidID                => 1,
    UserID                 => 1,
);

my %TestCustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
    CustomerID => $TestCustomerID,
);

my $TestUserLogin = $CustomerUserObject->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => 'UserFirstName',
    UserLastname   => 'UserLastName',
    UserCustomerID => $TestCustomerID,
    UserLogin      => 'UserLogin',
    UserEmail      => 'email@example.com',
    ValidID        => 1,
    UserID         => 1,
);

my %TestUserData = $CustomerUserObject->CustomerUserDataGet(
    User => $TestUserLogin,
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Some Ticket Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => $TestUserData{CustomerID},
    CustomerUser => $TestUserLogin,
    OwnerID      => 1,
    UserID       => 1,
);

# At this point the information should be already stored in the dynamic fields
# get ticket data (with dynamic fields).
my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
    Silent        => 0,
);

for my $DynamicFieldName (@AddedDynamicFieldNames) {
    $Self->IsNot(
        $Ticket{ 'DynamicField_' . $DynamicFieldName },
        undef,
        "Dynamic field $DynamicFieldName for ticket with ID $TicketID should not be undef.",
    );
}

$Self->Is(
    $Ticket{ 'DynamicField_CustomerID' . $RandomID },
    $TestCustomerCompany{CustomerID},
    "Dynamic field 'CustomerID$RandomID' for ticket with ID $TicketID must match test company ID.",
);
$Self->Is(
    $Ticket{ 'DynamicField_CustomerCompanyName' . $RandomID },
    $TestCustomerCompany{CustomerCompanyName},
    "Dynamic field 'CustomerCompanyName$RandomID' for ticket with ID $TicketID must match test company name.",
);

$Self->Is(
    $Ticket{ 'DynamicField_CustomerCompanyURL' . $RandomID },
    $TestCustomerCompany{CustomerCompanyURL},
    "Dynamic field 'CustomerCompanyURL$RandomID' for ticket with ID $TicketID must match test company URL.",
);

1;
