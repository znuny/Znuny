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

use Kernel::System::VariableCheck qw(:all);
use vars (qw($Self));

my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

if ( !$SeleniumObject->{SeleniumTestsActive} ) {
    $Self->True( 1, 'Selenium testing is not active, skipping tests.' );
    return 1;
}

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

$ZnunyHelperObject->_RebuildConfig();

my $Success;

my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
my $CacheObject        = $Kernel::OM->Get('Kernel::System::Cache');

my %UserData = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de',
);

$Self->True(
    scalar keys %UserData,
    "Test User created successfully.",
);
my $QueueID = $ZnunyHelperObject->_QueueCreateIfNotExists(
    Name    => 'UT' . $HelperObject->GetRandomNumber(),
    GroupID => 1,
);

$Self->True(
    $QueueID,
    "Test Queue created successfully.",
);
my $CustomerUserLogin = 'test-customer-user-' . $HelperObject->GetRandomNumber();

$HelperObject->TestCustomerUserCreate(
    UserLogin      => $CustomerUserLogin,
    UserFirstname  => 'Test user firstname',
    UserLastname   => 'Test user lastname',
    UserCustomerID => 'Customer',
    UserEmail      => $CustomerUserLogin . '@example.com',
);

my $DynamicFields = $HelperObject->ActivateDefaultDynamicFields();

my @TicketIDs;
push @TicketIDs, $HelperObject->TicketCreate(
    QueueID => $QueueID,
);
push @TicketIDs, $HelperObject->TicketCreate(
    QueueID => $QueueID,
);

my $DateTime = $TimeObject->CurrentTimestamp();
my ($Date) = split /\ /, $DateTime;
$Date .= ' 00:00:00';

my %DynamicFieldValues = (
    Text        => 'Test Text',
    Checkbox    => '1',
    Dropdown    => 'Key1',
    TextArea    => 'Example Text Area',
    Multiselect => [ 'Key1', 'Key2', 'Key3' ],
    Date        => $Date,
    DateTime    => $DateTime,
);
my $SystemTimePlusOneDayAndHour = $TimeObject->SystemTime() + 90000;

my ( $Second, $Minute, $Hour, $Day, $Month, $Year ) = $TimeObject->SystemTime2Date(
    SystemTime => $SystemTimePlusOneDayAndHour,
);

$Second = 0;

my $DateTimeChanged = $TimeObject->Date2SystemTime(
    Year   => $Year,
    Month  => $Month,
    Day    => $Day,
    Hour   => $Hour,
    Minute => $Minute,
    Second => $Second,
);

$DateTimeChanged = $TimeObject->SystemTime2TimeStamp(
    SystemTime => $DateTimeChanged,
);

( $Second, $Minute, $Hour, $Day, $Month, $Year )
    = map { /^0(.*)/ ? $1 : $_ } ( $Second, $Minute, $Hour, $Day, $Month, $Year );
$Second = 0;

my %DynamicFieldValuesChanged = (
    Text        => 'Test Text1',
    Checkbox    => undef,
    Dropdown    => 'Key2',
    TextArea    => 'Example Text Area1',
    Multiselect => [ 'Key1', 'Key3' ],
    Date        => {
        Year   => $Year,
        Month  => $Month,
        Day    => $Day,
        Hour   => '00',
        Minute => '00',
        Second => '00',
        Used   => 1,
    },
    DateTime => {
        Year   => $Year,
        Month  => $Month,
        Day    => $Day,
        Hour   => $Hour,
        Minute => $Minute,
        Second => $Second,
        Used   => 1,
    },
);
for my $TicketID (@TicketIDs) {

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID => $TicketID,
    );
}

for my $DynamicField ( @{$DynamicFields} ) {
    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicField->{Name},
    );

    for my $TicketID (@TicketIDs) {

        $Success = $BackendObject->ValueSet(
            DynamicFieldConfig => $DynamicField,
            ObjectID           => $TicketID,
            Value              => $DynamicFieldValues{ $DynamicField->{FieldType} },
            UserID             => $UserData{UserID},
        );

        $Self->True(
            $Success,
            "TicketID: $TicketID, DynamicFieldType: $DynamicField->{FieldType} ValueSet successfully.",
        );
    }
}
my %DynamicFieldsForEnabling = map { $_->{Name} => 1 } @{$DynamicFields};

# AgentTicketBulk normally can't handle dynamic fields,
# that's why _DynamicFieldsScreenEnable doesn't enable it for AgentTicketBulk
my %Screens = (
    AgentTicketBulk => \%DynamicFieldsForEnabling,
);

$Success = $ZnunyHelperObject->_DynamicFieldsScreenEnable(%Screens);

$Self->True(
    $Success,
    "DynamicFields enabled for AgentTicketBulk successfully.",
);

my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $AgentTicketBulkConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketBulk');

$Self->IsDeeply(
    $AgentTicketBulkConfig->{DynamicField},
    {
        'UnitTestCheckbox'    => '1',
        'UnitTestDate'        => '1',
        'UnitTestDateTime'    => '1',
        'UnitTestDropdown'    => '1',
        'UnitTestMultiSelect' => '1',
        'UnitTestText'        => '1',
        'UnitTestTextArea'    => '1',
    },
    "Lookup: DynamicFields enabled for AgentTicketBulk successfully.",
);

my @Tickets;

for my $TicketID (@TicketIDs) {
    push @Tickets, {
        $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        ),
    };
}

my $SeleniumTest = sub {

    # initialize Znuny4OTRS Helpers and other needed objects
    my $UserObject        = $Kernel::OM->Get('Kernel::System::User');
    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    #     # setup a full featured test environment
    #     my $TestEnvironmentData = $HelperObject->SetupTestEnvironment();

    # create test user and login
    my %UserData = $SeleniumObject->AgentLogin(
        Groups   => [ 'admin', 'users' ],
        Language => 'de'
    );

    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketBulk',
        TicketID    => \@TicketIDs,
        WaitForAJAX => 0,
    );

    DF:
    for my $DynamicField ( @{$DynamicFields} ) {

        $Success = $SeleniumObject->InputSet(
            Attribute   => 'DynamicField_' . $DynamicField->{Name},
            Content     => $DynamicFieldValuesChanged{ $DynamicField->{FieldType} },
            WaitForAJAX => 0,
            Options     => {
                TriggerChange => 1,
            },
        );

        next DF if ( $DynamicField->{FieldType} eq 'Date' || $DynamicField->{FieldType} eq 'DateTime' );

        $Success = $SeleniumObject->InputSet(
            Attribute   => 'DynamicField_' . $DynamicField->{Name} . 'Used',
            Content     => '1',
            WaitForAJAX => 0,
            Options     => {
                TriggerChange => 1,
            },
        );
    }

    $SeleniumObject->find_element( '#Subject', 'css' )->VerifiedSubmit();
};

$SeleniumObject->RunTest($SeleniumTest);

# Date and DateTime needs whole numbers for setting via InputJS
# so 1.1.2016 not 01.01.2016
# result is formatted as 01.01.2016
# so reformatting for checking is required
$DynamicFieldValuesChanged{DateTime} = $DateTimeChanged;
( $DynamicFieldValuesChanged{Date} ) = split /\ /, $DateTimeChanged;
$DynamicFieldValuesChanged{Date} .= ' 00:00:00';

# Checkbox needs "undef" for setting via InputJS, results in 0 in storage
$DynamicFieldValuesChanged{Checkbox} = 0;

my @TicketsChanged;

my $Counter = 0;
for my $TicketID (@TicketIDs) {

    $CacheObject->Delete(
        Type => 'DynamicFieldValue',
        Key  => "ValueGet::ObjectID::$TicketID",
    );

    $TicketObject->_TicketCacheClear( TicketID => $TicketID );

    push @TicketsChanged, {
        $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        ),
    };

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFields} ) {

        if ( $DynamicField->{FieldType} eq 'Multiselect' ) {
            $Self->IsDeeply(
                $TicketsChanged[$Counter]->{"DynamicField_$DynamicField->{Name}"},
                $DynamicFieldValuesChanged{ $DynamicField->{FieldType} },
                "TicketID: $TicketID DynamicField: $DynamicField->{Name} - no difference found between DynamicFieldValuesChanged and the Updated Ticket.",
            );

            $Self->IsNotDeeply(
                $Tickets[$Counter]->{"DynamicField_$DynamicField->{Name}"},
                $TicketsChanged[$Counter]->{"DynamicField_$DynamicField->{Name}"},
                "TicketID: $TicketID DynamicField: $DynamicField->{Name} - Ticket value is not equal to previous Ticket Value",
            );
            next DYNAMICFIELD;
        }

        $Self->Is(
            $TicketsChanged[$Counter]->{"DynamicField_$DynamicField->{Name}"},
            $DynamicFieldValuesChanged{ $DynamicField->{FieldType} },
            "TicketID: $TicketID DynamicField: $DynamicField->{Name} - no difference found between DynamicFieldValuesChanged and the Updated Ticket.",
        );
        $Self->IsNot(
            $Tickets[$Counter]->{"DynamicField_$DynamicField->{Name}"},
            $TicketsChanged[$Counter]->{"DynamicField_$DynamicField->{Name}"},
            "TicketID: $TicketID DynamicField: $DynamicField->{Name} - Ticket value is not equal to previous Ticket Value",
        );
    }

    $Counter++;
}

1;
