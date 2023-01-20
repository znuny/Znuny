# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
my $BackendObject        = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
my $ServiceObject        = $Kernel::OM->Get('Kernel::System::Service');

my $IsITSMInstalled = $Kernel::OM->Get('Kernel::System::Util')->IsITSMInstalled();
my %ITSMCoreSLA;
my %ITSMCoreService;

if ($IsITSMInstalled) {

    # get the list of service types from general catalog
    my $ServiceTypeList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::Service::Type',
    );

    # build a lookup hash
    my %ServiceTypeName2ID = reverse %{$ServiceTypeList};

    # get the list of sla types from general catalog
    my $SLATypeList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::SLA::Type',
    );

    # build a lookup hash
    my %SLATypeName2ID = reverse %{$SLATypeList};

    %ITSMCoreSLA = (
        TypeID => $SLATypeName2ID{Other},
    );

    %ITSMCoreService = (
        TypeID      => $ServiceTypeName2ID{Training},
        Criticality => '3 normal',
    );

}

# Enable Service.
$HelperObject->ConfigSettingChange(
    Key   => 'Ticket::Service',
    Value => 1,
);

# Use a calendar with the same business hours for every day so that the UT runs correctly
#   on every day of the week and outside usual business hours.
$HelperObject->ConfigSettingChange(
    Key   => 'TimeWorkingHours::Calendar1',
    Value => {
        map { $_ => [ 0 .. 23 ] } qw( Mon Tue Wed Thu Fri Sat Sun ),
    },
);

# Disable default Vacation days.
$HelperObject->ConfigSettingChange(
    Key   => 'TimeVacationDays::Calendar1',
    Value => {},
);

# Set fixed time.
$HelperObject->FixedTimeSet();

my $RandomID = $HelperObject->GetRandomNumber();

# Create a test customer.
my $TestUserCustomer = $HelperObject->TestCustomerUserCreate();

# Create a dynamic field.
my $DynamicFieldName = "TestDF$RandomID";
my $FieldID          = $DynamicFieldObject->DynamicFieldAdd(
    Name       => $DynamicFieldName,
    FieldOrder => 9992,
    FieldType  => 'Dropdown',
    Config     => {
        DefaultValue   => 'Default',
        PossibleValues => {
            Item1 => 'Value1',
            item2 => 'Value2',
        },
    },
    Label      => $DynamicFieldName,
    ObjectType => 'Ticket',
    ValidID    => 1,
    UserID     => 1,
    Reorder    => 0,
);
$Self->True(
    $FieldID,
    "DynamicFieldAdd() successful for Field ID $FieldID",
);

# Add test Service.
my $ServiceID = $ServiceObject->ServiceAdd(
    Name    => "TestService - " . $HelperObject->GetRandomID(),
    ValidID => 1,
    UserID  => 1,
    %ITSMCoreService,
);
$Self->True(
    $ServiceID,
    "Service $ServiceID has been created.",
);

# Add service for the test customer.
$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $TestUserCustomer,
    ServiceID         => $ServiceID,
    Active            => 1,
    UserID            => 1,
);

# Add test SLA.
my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLAAdd(
    Name                => "TestSLA - " . $HelperObject->GetRandomID(),
    ServiceIDs          => [$ServiceID],
    FirstResponseTime   => 5,
    FirstResponseNotify => 60,
    UpdateTime          => 10,
    UpdateNotify        => 80,
    SolutionTime        => 15,
    SolutionNotify      => 80,
    Calendar            => 1,
    ValidID             => 1,
    UserID              => 1,
    %ITSMCoreSLA,
);
$Self->True(
    $SLAID,
    "SLA $SLAID has been created.",
);

my @TicketIDs;
for my $Item ( 1 .. 6 ) {

    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Ticket One Title',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        ServiceID    => $ServiceID,
        SLAID        => $SLAID,
        CustomerID   => $TestUserCustomer,
        CustomerUser => $TestUserCustomer,
        OwnerID      => 1,
        UserID       => 1,
    );
    $Self->True(
        $TicketID,
        "TicketCreate() successful for Ticket ID $TicketID",
    );
    push @TicketIDs, $TicketID;

    my $TestFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );

    $BackendObject->ValueSet(
        DynamicFieldConfig => $TestFieldConfig,
        ObjectID           => $TicketID,
        Value              => 'Item1',
        UserID             => 1,
    );

    $HelperObject->FixedTimeAddSeconds( 2 * $Item * 60 );

    my $Success = $TicketObject->TicketStateSet(
        StateID            => 4,
        TicketID           => $TicketID,
        SendNoNotification => 0,
        UserID             => 1,
    );
    $Self->True(
        $Success,
        "TicketStateSet() successful set state 'open' for ticket $TicketID",
    );

    my $ArticleID = $ArticleBackendObject->ArticleCreate(
        TicketID             => $TicketID,
        IsVisibleForCustomer => 1,
        SenderType           => 'agent',
        From                 => 'Agent Some Agent Some Agent <email@example.com>',
        To                   => 'Customer A <customer-a@example.com>',
        Cc                   => 'Customer B <customer-b@example.com>',
        ReplyTo              => 'Customer B <customer-b@example.com>',
        Subject              => 'some short description',
        Body                 => 'the message text Perl modules provide a range of',
        ContentType          => 'text/plain; charset=ISO-8859-15',
        HistoryType          => 'OwnerUpdate',
        HistoryComment       => 'Some free text!',
        UserID               => 1,
        NoAgentNotify        => 1,
    );
    $Self->True( $ArticleID, "ArticleCreate() Created article $ArticleID" );

    $HelperObject->FixedTimeAddSeconds( $Item * 60 );

    # Close all ticket's except the last one.
    if ( $Item != 6 ) {
        $Success = $TicketObject->TicketStateSet(
            StateID            => 2,
            TicketID           => $TicketID,
            SendNoNotification => 0,
            UserID             => 1,
        );
        $Self->True(
            $Success,
            "TicketStateSet() successful set state 'close successful' for ticket $TicketID",
        );
    }
}

# Merge two last created test tickets.
my $MergeSuccess = $TicketObject->TicketMerge(
    MainTicketID  => $TicketIDs[4],
    MergeTicketID => $TicketIDs[5],
    UserID        => 1,
);
$Self->True(
    $MergeSuccess,
    "TicketMerge() successful merged TicketID $TicketIDs[4] with TicketID $TicketIDs[5]"
);

my @Tests = (
    {
        KindsOfReporting => 'SolutionAverageAllOver',
        ExpectedResult   => '8 m',
    },
    {
        KindsOfReporting => 'SolutionMinTimeAllOver',
        ExpectedResult   => '3 m',
    },
    {
        KindsOfReporting => 'SolutionMaxTimeAllOver',
        ExpectedResult   => '15 m',
    },
    {
        KindsOfReporting => 'SolutionAverage',
        ExpectedResult   => '9 m',
    },
    {
        KindsOfReporting => 'SolutionMinTime',
        ExpectedResult   => '3 m',
    },
    {
        KindsOfReporting => 'SolutionMaxTime',
        ExpectedResult   => '15 m',
    },
    {
        KindsOfReporting => 'SolutionWorkingTimeAverage',
        ExpectedResult   => '9 m',
    },
    {
        KindsOfReporting => 'SolutionMinWorkingTime',
        ExpectedResult   => '3 m',
    },
    {
        KindsOfReporting => 'SolutionMaxWorkingTime',
        ExpectedResult   => '15 m',
    },
    {
        KindsOfReporting => 'NumberOfTickets',
        ExpectedResult   => '5',
    },
    {
        KindsOfReporting => 'ResponseAverage',
        ExpectedResult   => '6 m',
    },
    {
        KindsOfReporting => 'ResponseMinTime',
        ExpectedResult   => '2 m',
    },
    {
        KindsOfReporting => 'ResponseWorkingTimeAverage',
        ExpectedResult   => '6 m',
    },
    {
        KindsOfReporting => 'ResponseMinWorkingTime',
        ExpectedResult   => '2 m',
    },
    {
        KindsOfReporting => 'ResponseMaxWorkingTime',
        ExpectedResult   => '10 m',
    },
);

my $TicketSolutionResponseTimeObject = $Kernel::OM->Get('Kernel::System::Stats::Dynamic::TicketSolutionResponseTime');

# Check GetStatElement().
for my $Test (@Tests) {
    for my $Item (qw(Item1 Item2)) {

        my $Result = $TicketSolutionResponseTimeObject->GetStatElement(
            ServiceIDs                       => [$ServiceID],
            KindsOfReporting                 => [ $Test->{KindsOfReporting} ],
            "DynamicField_$DynamicFieldName" => [$Item],
        );

        my $ExpectedResult;
        if ( $Item eq 'Item2' ) {
            $ExpectedResult = 0;
        }
        else {
            $ExpectedResult = $Test->{ExpectedResult};
        }

        $Self->Is(
            $Result,
            $ExpectedResult,
            "$Test->{KindsOfReporting} is calculated well - $Result",
        );
    }

}

# Cleanup cache.
$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
