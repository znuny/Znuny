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

use Kernel::System::VariableCheck qw(:all);

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::DynamicFieldSet');

# define variables
my $UserID            = 1;
my $ModuleName        = 'DynamicFieldSet';
my $RandomID          = $HelperObject->GetRandomID();
my $DFName1           = 'Test1' . $RandomID;
my $DFName2           = 'Test2' . $RandomID;
my $DFName3           = 'Test3' . $RandomID;
my $DFName4           = 'Test4' . $RandomID;
my $DFForeignTicketID = 'UnitTestForeignTicketID' . $RandomID;
my $DFForeignField    = 'UnitTestForeignField' . $RandomID;

# set user details
my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();

# Create the dynamic fields for testing

my @NewDynamicFieldConfig = (
    {
        Name       => $DFName1,
        Label      => $DFName1,
        FieldType  => 'Dropdown',
        ObjectType => 'Ticket',
        Config     => {
            TranslatableValues => '0',
            PossibleValues     => {
                1 => 'A',
                2 => 'B',
                3 => 'C',
            },
        },
    },
    {
        Name       => $DFName2,
        Label      => $DFName2,
        FieldType  => 'Checkbox',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => $DFName3,
        Label      => $DFName3,
        FieldType  => 'Text',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => $DFName4,
        Label      => $DFName4,
        FieldType  => 'Multiselect',
        ObjectType => 'Ticket',
        Config     => {
            TranslatableValues => '0',
            PossibleValues     => {
                'a' => 'A',
                'b' => 'B',
                'c' => 'C',
            },
        },
    },
    {
        Name       => $DFForeignTicketID,
        Label      => $DFForeignTicketID,
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
    {
        Name       => $DFForeignField,
        Label      => $DFForeignField,
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
);

my @AddedDynamicFields;
for my $DynamicFieldConfig (@NewDynamicFieldConfig) {

    # add the new dynamic field
    my $ID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldAdd(
        %{$DynamicFieldConfig},
        FieldOrder => 99999,
        ValidID    => 1,
        UserID     => 1,
    );

    push @AddedDynamicFields, $ID;

    # sanity check
    $Self->True(
        $ID,
        "DynamicFieldAdd() - DynamicField: $ID for DynamicFieldSet"
            . " checks with True",
    );
}

# Create customer.
$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'CheckEmailAddresses',
    Value => '0',
);

my $CustomerUserFirstName = 'FirstName' . $RandomID;
my $CustomerUserID        = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => $CustomerUserFirstName,
    UserLastname   => 'Doe',
    UserCustomerID => "Customer#$RandomID",
    UserLogin      => "CustomerLogin#$RandomID",
    UserEmail      => "customer$RandomID\@example.com",
    UserPassword   => 'some_pass',
    ValidID        => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserID,
    "CustomerUser $CustomerUserID created."
);

# get ticket object
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

# Create a test ticket
my $TicketID = $TicketObject->TicketCreate(
    Title         => 'test',
    QueueID       => 1,
    Lock          => 'unlock',
    Priority      => '3 normal',
    StateID       => 1,
    TypeID        => 1,
    OwnerID       => 1,
    ResponsibleID => 1,
    CustomerUser  => $CustomerUserID,
    UserID        => $UserID,
);

# sanity checks
$Self->True(
    $TicketID,
    "TicketCreate() - $TicketID",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    UserID   => $UserID,
);
$Self->True(
    IsHashRefWithData( \%Ticket ),
    "TicketGet() - Get Ticket with ID $TicketID.",
);

# Run() tests
my @Tests = (
    {
        Name    => 'No Params',
        Config  => undef,
        Success => 0,
    },
    {
        Name   => 'No UserID',
        Config => {
            UserID => undef,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => 1,
            },
        },
        Success => 0,
    },
    {
        Name   => 'No Ticket',
        Config => {
            UserID => $UserID,
            Ticket => undef,
            Config => {
                $DFName1 => 1,
            },
        },
        Success => 0,
    },
    {
        Name   => 'No Config',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {},
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                NoAgentNotify => 0,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Ticket Format',
        Config => {
            UserID => $UserID,
            Ticket => 1,
            Config => {
                $DFName1 => '1',
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config Format',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => 1,
        },
        Success => 0,
    },
    {
        Name   => 'Correct ASCII Dropdown',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => 'TestString',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct ASCII Checkbox',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName2 => 1,
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct ASCII Dropdown && Checkbox',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => 1,
                $DFName2 => 0,
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct UTF8 Dropdown',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 =>
                    'äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-カスタ-用迎使用-Язык',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct Ticket->Queue Dropdown',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => '<OTRS_TICKET_Queue>',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct Ticket->Queue + Ticket->QueueID Dropdown',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => '<OTRS_TICKET_Queue> <OTRS_TICKET_QueueID>',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct Ticket->NotExisting Dropdown',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => '<OTRS_TICKET_NotExisting>',
            },
        },
        NoValue => 1,
        Success => 1,
    },
    {
        Name   => 'Correct Using Different UserID',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName1 => 'Test',
                UserID   => $TestUserID,
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct multiple values set for Multiselect',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName4 => 'a, b',
            },
        },
        Multiselect    => 1,
        ExpectedResult => [ 'a', 'b' ],
        Success        => 1,
    },
    {
        Name   => 'Correct Using OTRS Customer Data tag',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                $DFName3 => '<OTRS_CUSTOMER_DATA_UserFirstname>',
            },
        },
        Success => 1,
    },
);

TEST:
for my $Test (@Tests) {

    # make a deep copy to avoid changing the definition
    my $OrigTest = Storable::dclone($Test);

    my $Success = $TransitionActionObject->Run(
        %{ $Test->{Config} },
        ProcessEntityID          => 'P1',
        ActivityEntityID         => 'A1',
        TransitionEntityID       => 'T1',
        TransitionActionEntityID => 'TA1',
    );

    if ( !$Test->{Success} ) {
        $Self->False(
            $Success,
            "$ModuleName Run() - Test:'$Test->{Name}' | executed with False"
        );
        next TEST;
    }

    $Self->True(
        $Success,
        "$ModuleName Run() - Test:'$Test->{Name}' | executed with True"
    );

    # get ticket
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => 1,
    );

    ATTRIBUTE:
    for my $Attribute ( sort keys %{ $Test->{Config}->{Config} } ) {

        if ( $Test->{NoValue} ) {
            $Self->False(
                defined $Ticket{ 'DynamicField_' . $Attribute },
                "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_" . $Attribute
                    . " for TicketID: $TicketID exists with True",
            );
            next TEST;
        }

        # Check set value for multiple selected values of multiselect dynamic field (see bug#14900).
        if ( $Test->{Multiselect} ) {
            $Self->IsDeeply(
                $Ticket{ 'DynamicField_' . $Attribute },
                $Test->{ExpectedResult},
                "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_" . $Attribute
                    . " for TicketID: $TicketID match expected value",
            );
            next TEST;
        }

        $Self->True(
            defined $Ticket{ 'DynamicField_' . $Attribute },
            "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_" . $Attribute
                . " for TicketID: $TicketID exists with True",
        );

        my $ExpectedValue = $Test->{Config}->{Config}->{$Attribute};
        if (
            $OrigTest->{Config}->{Config}->{$Attribute}
            =~ m{\A<OTRS_TICKET_([A-Za-z0-9_]+)>\z}msx
            )
        {
            $ExpectedValue = $Ticket{$1} // '';
            $Self->IsNot(
                $Test->{Config}->{Config}->{$Attribute},
                $OrigTest->{Config}->{Config}->{$Attribute},
                "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_$Attribute value: $OrigTest->{Config}->{Config}->{$Attribute} should been replaced",
            );
        }
        elsif (
            $OrigTest->{Config}->{Config}->{$Attribute}
            =~ m{\A<OTRS_TICKET_([A-Za-z0-9_]+)> [ ] <OTRS_TICKET_([A-Za-z0-9_]+)>\z}msx
            )
        {
            $ExpectedValue = ( $Ticket{$1} // '' ) . ' ' . ( $Ticket{$2} // '' );
            $Self->IsNot(
                $Test->{Config}->{Config}->{$Attribute},
                $OrigTest->{Config}->{Config}->{$Attribute},
                "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_$Attribute value: $OrigTest->{Config}->{Config}->{$Attribute} should been replaced",
            );
        }

        $Self->Is(
            $Ticket{ 'DynamicField_' . $Attribute },
            $ExpectedValue,
            "$ModuleName - Test:'$Test->{Name}' | Attribute: DynamicField_" . $Attribute
                . " for TicketID: $TicketID match expected value",
        );
    }

    if ( $OrigTest->{Config}->{Config}->{UserID} ) {
        $Self->Is(
            $Test->{Config}->{Config}->{UserID},
            undef,
            "$ModuleName - Test:'$Test->{Name}' | Attribute: UserID for TicketID:"
                . " $TicketID should be removed (as it was used)",
        );
    }
}

# DynamicField value set with <OTRS_CUSTOMER_DATA_*> tag.
%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{ 'DynamicField_' . $DFName3 },
    $CustomerUserFirstName,
    "DynamicField $DFName3 value is correctly set."
);

# Regression test: <OTRS_FIRST_ARTICLE_Body>/<OTRS_LAST_ARTICLE_Body> tags used in a
# DynamicFieldSet config value used to leak Attachment/ContentType keys into $Param{Config},
# which made DynamicFieldSet::Run() treat them as (missing) dynamic field names and fail
my $ArticleBodyContent = 'ArticleTagRegressionTest' . $RandomID;

$HelperObject->ArticleCreate(
    TicketID => $TicketID,
    Body     => $ArticleBodyContent,
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $DynamicFieldSetArticleTagResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P1',
    ActivityEntityID         => 'A1',
    TransitionEntityID       => 'T1',
    TransitionActionEntityID => 'TA1',
    Config                   => {
        $DFName3 => '<OTRS_FIRST_ARTICLE_Body>',
    },
);

$Self->True(
    $DynamicFieldSetArticleTagResult,
    "$ModuleName Run() with <OTRS_FIRST_ARTICLE_Body> in a DynamicField value does not fail "
        . '(Attachment/ContentType must not leak into Config as if they were dynamic field names)',
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    ( index( $Ticket{ 'DynamicField_' . $DFName3 } // '', $ArticleBodyContent ) > -1 ) ? 1 : 0,
    "$ModuleName - DynamicField $DFName3 contains the resolved <OTRS_FIRST_ARTICLE_Body> content",
);

# Regression test: same as above, but with a dynamic field literally named 'Body'. Relying only
# on the config attribute name (instead of also checking which transition action module is
# calling) would still leak Attachment/ContentType into Config in this case and break
# DynamicFieldSet::Run(), since 'Attachment' sorts before 'Body' and would be looked up first.
my $BodyDynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
    Name       => 'Body',
    Label      => 'Body',
    FieldType  => 'Text',
    ObjectType => 'Ticket',
    Config     => {
        DefaultValue => '',
    },
    FieldOrder => 99999,
    ValidID    => 1,
    UserID     => 1,
);

$Self->True(
    $BodyDynamicFieldID,
    "DynamicFieldAdd() - DynamicField literally named 'Body' for $ModuleName regression test",
);

push @AddedDynamicFields, $BodyDynamicFieldID;

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $DynamicFieldSetBodyNamedFieldResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P1',
    ActivityEntityID         => 'A1',
    TransitionEntityID       => 'T1',
    TransitionActionEntityID => 'TA1',
    Config                   => {
        Body => '<OTRS_FIRST_ARTICLE_Body>',
    },
);

$Self->True(
    $DynamicFieldSetBodyNamedFieldResult,
    "$ModuleName Run() with a dynamic field literally named 'Body' does not fail "
        . '(Attachment/ContentType must not leak in just because the config key is named Body)',
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->True(
    ( index( $Ticket{DynamicField_Body} // '', $ArticleBodyContent ) > -1 ) ? 1 : 0,
    "$ModuleName - DynamicField 'Body' contains the resolved <OTRS_FIRST_ARTICLE_Body> content",
);

# Run TransitionAction with ForeignTicketID
my $ForeignTicketID = $HelperObject->TicketCreate();

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $DFForeignTicketID,
);

my $ValueSet = $DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $ForeignTicketID,
    UserID             => 1,
);

$Self->True(
    $ValueSet,
    "ValueSet()",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $DynamicFieldSetResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P1',
    ActivityEntityID         => 'A1',
    TransitionEntityID       => 'T1',
    TransitionActionEntityID => 'TA1',
    Config                   => {
        ForeignTicketID => '<OTRS_Ticket_DynamicField_' . $DFForeignTicketID . '>',
        $DFForeignField => 'blub',
    }
);

$Self->True(
    $DynamicFieldSetResult,
    "TransitionActionObject->Run()",
);

my %ForeignTicket = $TicketObject->TicketGet(
    TicketID      => $ForeignTicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $ForeignTicket{ 'DynamicField_' . $DFForeignField },
    'blub',
    'Value in foreign ticket got set',
);

1;
