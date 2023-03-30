# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use CGI;

use vars (qw($Self));

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();

# Create new entities
my $DynamicFieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldAdd(
    Name       => 'DynamicField' . $RandomID,
    Label      => 'DynamicField' . $RandomID,
    FieldOrder => 1,
    FieldType  => 'Text',
    ObjectType => 'Ticket',
    Config     => {},
    ValidID    => 1,
    UserID     => 1,
);

$Self->IsNot(
    $DynamicFieldID,
    undef,
    "DynamicFieldAdd() for dynamic field DynamicField$RandomID - ID $DynamicFieldID",
);

my $PriorityID = $Kernel::OM->Get('Kernel::System::Priority')->PriorityAdd(
    Name    => $RandomID,
    ValidID => 1,
    UserID  => 1,
);
$Self->IsNot(
    $PriorityID,
    undef,
    "PriorityAdd() for priority $RandomID - ID $PriorityID",
);

my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
    Name            => $RandomID,
    ValidID         => 1,
    GroupID         => 1,
    SystemAddressID => 1,
    SalutationID    => 1,
    SignatureID     => 1,
    Comment         => 'Some comment',
    UserID          => 1,
);
$Self->IsNot(
    $QueueID,
    undef,
    "QueueAdd() for queue $RandomID - ID $QueueID",
);

my $StateID = $Kernel::OM->Get('Kernel::System::State')->StateAdd(
    Name    => $RandomID,
    Comment => 'some comment',
    ValidID => 1,
    TypeID  => 1,
    UserID  => 1,
);
$Self->IsNot(
    $StateID,
    undef,
    "StateAdd() for state $RandomID - ID $StateID",
);

my $TypeID = $Kernel::OM->Get('Kernel::System::Type')->TypeAdd(
    Name    => $RandomID,
    ValidID => 1,
    UserID  => 1,
);
$Self->IsNot(
    $TypeID,
    undef,
    "TypeAdd() for type $RandomID - ID $TypeID",
);

my $SystemAddressID = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressAdd(
    Name     => $RandomID,
    Realname => $RandomID . '@znuny.com',
    ValidID  => 1,
    QueueID  => 1,
    Comment  => $RandomID,
    UserID   => 1,
);

$Self->IsNot(
    $SystemAddressID,
    undef,
    "SystemAddressAdd() for system address ID $RandomID \@znuny.com - ID $SystemAddressID",
);

my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserAdd(
    UserFirstname => 'Mr',
    UserLastname  => 'Znuny',
    UserLogin     => $RandomID . 'znuny',
    UserEmail     => $RandomID . '@znuny.com',
    ValidID       => 1,
    ChangeUserID  => 1,
);

$Self->IsNot(
    $UserID,
    undef,
    "UserAdd() for user $RandomID znuny - ID $UserID",
);

my $ServiceID = $Kernel::OM->Get('Kernel::System::Service')->ServiceAdd(
    Name    => $RandomID,
    ValidID => 1,
    UserID  => 1,
);

$Self->IsNot(
    $ServiceID,
    undef,
    "ServiceAdd() for service $RandomID - ID $ServiceID",
);

my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLAAdd(
    Name    => $RandomID,
    ValidID => 1,
    UserID  => 1,
);

$Self->IsNot(
    $SLAID,
    undef,
    "SLAAdd() for SLA $RandomID - ID $SLAID",
);

my @Tests = (

    # false
    {
        Name        => 'Missing entity type',
        QueryString => "Action=AdminQueue;Subaction=Change;QueueID=$QueueID",
        EntityType  => undef,
        Success     => 0,
    },
    {
        Name          => 'Missing queue ID',
        QueryString   => "Action=AdminQueue;Subaction=Change",
        EntityType    => 'Queue',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong entity type',
        QueryString   => "Action=AdminQueue;Subaction=Change;QueueID=$QueueID",
        EntityType    => 'Type',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong dynamic field entity type',
        QueryString   => "Action=AdminDynamicField;Subaction=Change;ID=$DynamicFieldID" . '1',
        EntityType    => 'DynamicField',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong queue entity type',
        QueryString   => "Action=AdminQueue;Subaction=Change;QueueID=$QueueID" . '1',
        EntityType    => 'Queue',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong priority entity type',
        QueryString   => "Action=AdminPriority;Subaction=Change;PriorityID=$PriorityID" . '1',
        EntityType    => 'Priority',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong service entity type',
        QueryString   => "Action=AdminService;Subaction=Change;ID=$ServiceID" . '1',
        EntityType    => 'Service',
        Success       => 1,
        ExpectedValue => '',
    },
    {
        Name          => 'Wrong SLA entity type',
        QueryString   => "Action=AdminSLA;Subaction=Change;ID=$SLAID" . '1',
        EntityType    => 'SLA',
        Success       => 1,
        ExpectedValue => '',
    },
    {
        Name          => 'Wrong state entity type',
        QueryString   => "Action=AdminState;Subaction=Change;ID=$StateID" . '1',
        EntityType    => 'State',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong system address entity type',
        QueryString   => "Action=AdminSystemAddress;Subaction=Change;ID=$SystemAddressID" . '1',
        EntityType    => 'SystemAddress',
        Success       => 1,
        ExpectedValue => undef,
    },
    {
        Name          => 'Wrong type wntity type',
        QueryString   => "Action=AdminType;Subaction=Change;ID=$TypeID" . '1',
        EntityType    => 'Type',
        Success       => 1,
        ExpectedValue => undef,
    },

    # true
    {
        Name          => 'Correct dynamic field entity type',
        QueryString   => "Action=AdminDynamicField;Subaction=Change;ID=$DynamicFieldID",
        EntityType    => 'DynamicField',
        Success       => 1,
        ExpectedValue => 'DynamicField' . $RandomID,
    },
    {
        Name          => 'Correct queue entity type',
        QueryString   => "Action=AdminQueue;Subaction=Change;QueueID=$QueueID",
        EntityType    => 'Queue',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct priority entity type',
        QueryString   => "Action=AdminPriority;Subaction=Change;PriorityID=$PriorityID",
        EntityType    => 'Priority',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct service entity type',
        QueryString   => "Action=AdminService;Subaction=Change;ID=$ServiceID",
        EntityType    => 'Service',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct SLA entity type',
        QueryString   => "Action=AdminSLA;Subaction=SLASave;SLAID=$SLAID",
        EntityType    => 'SLA',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct state entity type',
        QueryString   => "Action=AdminState;Subaction=Change;ID=$StateID",
        EntityType    => 'State',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct system address entity type',
        QueryString   => "Action=AdminSystemAddress;Subaction=Change;ID=$SystemAddressID",
        EntityType    => 'SystemAddress',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
    {
        Name          => 'Correct user entity type',
        QueryString   => "Action=AdminUser;Subaction=Change;ID=$UserID",
        EntityType    => 'User',
        Success       => 1,
        ExpectedValue => $RandomID . 'znuny',
    },
    {
        Name          => 'Correct type entity type',
        QueryString   => "Action=AdminType;Subaction=Change;ID=$TypeID",
        EntityType    => 'Type',
        Success       => 1,
        ExpectedValue => $RandomID,
    },
);

TEST:
for my $Test (@Tests) {
    local %ENV = (
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => $Test->{QueryString} // '',
    );

    CGI->initialize_globals();
    my $Request = Kernel::System::Web::Request->new();

    my $EntityName = $Kernel::OM->Get('Kernel::System::SysConfig::ValueType::Entity')->EntityLookupFromWebRequest(
        EntityType => $Test->{EntityType} // '',
    );

    if ( !$Test->{Success} ) {
        $Self->Is(
            $EntityName,
            undef,
            "$Test->{Name} EntityLookupFromWebRequest() - EntityName (No Success)",
        );
        next TEST;
    }

    $Self->Is(
        $EntityName,
        $Test->{ExpectedValue},
        "$Test->{Name} EntityLookupFromWebRequest() - EntityName",
    );

    $Kernel::OM->ObjectsDiscard(
        Objects => [ 'Kernel::System::Web::Request', ],
    );
}

1;
