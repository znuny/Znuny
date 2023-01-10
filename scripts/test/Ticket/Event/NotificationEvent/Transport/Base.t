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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
    'Kernel::System::MailQueue' => {
        CheckEmailAddresses => 0,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $NotificationEventTransportEmailObject
    = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::Email');
my $UserObject                = $Kernel::OM->Get('Kernel::System::User');
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $RandomID = $HelperObject->GetRandomNumber();

my $DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String => '2016-01-02 03:04:05'
    },
);
$HelperObject->FixedTimeSet($DateTimeObject);

# create a new user for current test
my $UserLogin = $HelperObject->TestUserCreate(
    Groups => ['users'],
);
my %UserData = $UserObject->GetUserData(
    User => $UserLogin,
);
my $UserID = $UserData{UserID};

my @FieldValue = ( 'aaatest@znuny.com', 'bbbtest@znuny.com', 'ccctest@znuny.com' );

my @DynamicFields = (
    {
        Name       => 'TestText' . $RandomID,
        Label      => 'TestText' . $RandomID,
        FieldOrder => 9990,
        FieldType  => 'Text',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => '',
            Link         => '',
        },
        Reorder => 0,
        ValidID => 1,
        UserID  => $UserID,
    },
    {
        Name       => 'TestDropdown' . $RandomID,
        Label      => 'TestDropdown' . $RandomID,
        FieldOrder => 9990,
        FieldType  => 'Dropdown',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue   => '',
            Link           => '',
            PossibleNone   => 0,
            PossibleValues => {
                $FieldValue[0] => 'a',
                $FieldValue[1] => 'b',
                $FieldValue[2] => 'c',
            },
        },
        Reorder => 0,
        ValidID => 1,
        UserID  => $UserID,
    },
    {
        Name       => 'TestMultiselect' . $RandomID,
        Label      => 'TestMultiselect' . $RandomID,
        FieldOrder => 9990,
        FieldType  => 'Multiselect',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue   => '',
            Link           => '',
            PossibleNone   => 0,
            PossibleValues => {
                $FieldValue[0] => 'a',
                $FieldValue[1] => 'b',
                $FieldValue[2] => 'c',
            },
        },
        Reorder => 0,
        ValidID => 1,
        UserID  => $UserID,
    },
);

# Create test dynamic fields.
for my $DynamicField (@DynamicFields) {
    my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
        %{$DynamicField},
    );

    $Self->True(
        $FieldID,
        "Dynamic field $DynamicField->{Name} - ID $FieldID - created",
    );

    my $FieldIDConfig = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );

    my $FieldValueSet = $FieldValue[0];
    if ( $DynamicField->{FieldType} eq 'Multiselect' ) {
        $FieldValueSet = \@FieldValue;
    }
}

my @Tests = (
    {
        Name => 'No value set',
        Data => {
            DynamicField   => {},
            RecipientEmail => '',
        },
        Expected => {
            RecipientEmail => undef,
        },
    },
    {
        Name => 'No RecipientEmail set',
        Data => {
            DynamicField => {
                'TestText' . $RandomID        => 'aaatest@znuny.com',
                'TestDropdown' . $RandomID    => 'bbbtest@znuny.com',
                'TestMultiselect' . $RandomID => 'ccctest@znuny.com',
            },
            RecipientEmail => '',
        },
        Expected => {
            RecipientEmail => undef,
        },
    },
    {
        Name => 'RecipientEmail set',
        Data => {
            DynamicField => {
                'TestText' . $RandomID        => 'aaatest@znuny.com',
                'TestDropdown' . $RandomID    => 'bbbtest@znuny.com',
                'TestMultiselect' . $RandomID => 'ccctest@znuny.com',
            },
            RecipientEmail => 'info@znuny.com',
        },
        Expected => {
            RecipientEmail => 'info@znuny.com',
        },
    },
    {
        Name => 'RecipientEmail with text field',
        Data => {
            DynamicField => {
                'TestText' . $RandomID => 'aaatest@znuny.com',
            },
            RecipientEmail => 'info@znuny.com, <OTRS_TICKET_DynamicField_TestText' . $RandomID . '>',
        },
        Expected => {
            RecipientEmail => 'info@znuny.com, aaatest@znuny.com',
        },
    },
    {
        Name => 'RecipientEmail with dropdown field',
        Data => {
            DynamicField => {
                'TestDropdown' . $RandomID => 'bbbtest@znuny.com',
            },
            RecipientEmail => 'info@znuny.com, <OTRS_TICKET_DynamicField_TestDropdown' . $RandomID . '>',
        },
        Expected => {
            RecipientEmail => 'info@znuny.com, bbbtest@znuny.com',
        },
    },
    {
        Name => 'RecipientEmail with multiselect field',
        Data => {
            DynamicField => {
                'TestMultiselect' . $RandomID => 'ccctest@znuny.com',
            },
            RecipientEmail => 'info@znuny.com, <OTRS_TICKET_DynamicField_TestMultiselect' . $RandomID . '>',
        },
        Expected => {
            RecipientEmail => 'info@znuny.com, ccctest@znuny.com',
        },
    },
    {
        Name => 'RecipientEmail with multiple values in multiselect field',
        Data => {
            DynamicField => {
                'TestMultiselect' . $RandomID => [
                    'aaatest@znuny.com',
                    'bbbtest@znuny.com',
                    'ccctest@znuny.com',
                ]
            },
            RecipientEmail => 'info@znuny.com, <OTRS_TICKET_DynamicField_TestMultiselect' . $RandomID . '>',
        },
        Expected => {
            RecipientEmail => 'info@znuny.com, aaatest@znuny.com, bbbtest@znuny.com, ccctest@znuny.com',
        },
    },
    {
        Name => 'RecipientEmail with multiple values in multiselect field in other order',
        Data => {
            DynamicField => {
                'TestMultiselect' . $RandomID => [
                    'aaatest@znuny.com',
                    'bbbtest@znuny.com',
                    'ccctest@znuny.com',
                ]
            },
            RecipientEmail => '<OTRS_TICKET_DynamicField_TestMultiselect' . $RandomID . '>, info@znuny.com',
        },
        Expected => {
            RecipientEmail => 'aaatest@znuny.com, bbbtest@znuny.com, ccctest@znuny.com, info@znuny.com',
        },
    },
);

my $Count = 0;
for my $Test (@Tests) {
    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Ticket One Title',
        QueueID      => 1,
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'example.com',
        CustomerUser => $UserData{UserLogin},
        OwnerID      => $UserID,
        UserID       => $UserID,
    );

    $Self->True(
        $TicketID,
        "TicketCreate() successful for Ticket ID $TicketID",
    );

    my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
        TicketID             => $TicketID,
        IsVisibleForCustomer => 1,
        SenderType           => 'customer',
        From                 => 'customerOne@example.com, customerTwo@example.com',
        To                   => 'Some Agent A <agent-a@example.com>',
        Subject              => 'some short description',
        Body                 => 'the message text',
        Charset              => 'utf8',
        MimeType             => 'text/plain',
        HistoryType          => 'OwnerUpdate',
        HistoryComment       => 'Some free text!',
        UserID               => $UserID,
    );

    $Self->True(
        $ArticleID,
        "ArticleCreate() successful for Article ID $ArticleID",
    );

    # Set DF value to ticket - test OTRS tags in RecipientEmail.
    for my $DynamicField ( sort keys %{ $Test->{Data}->{DynamicField} } ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicField,
        );
        my $Value    = $Test->{Data}->{DynamicField}->{$DynamicField};
        my $ValueSet = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $TicketID,
            Value              => $Value,
            UserID             => $UserID,
        );
        $Self->True(
            $ValueSet,
            "DynamicField ValueSet() successful for DynamicField $DynamicField.",
        );
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    my $RecipientEmail = $NotificationEventTransportEmailObject->_ReplaceTicketAttributes(
        Ticket => \%Ticket,
        Field  => $Test->{Data}->{RecipientEmail},
    );

    $Self->Is(
        $RecipientEmail,
        $Test->{Expected}->{RecipientEmail},
        $Test->{Name} . ' - _ReplaceTicketAttributes',
    );
}

1;
