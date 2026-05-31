# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (RequireExplicitPackage)
use strict;
use warnings;
use utf8;
use vars (qw($Self));

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$HelperObject->SetupTestEnvironment();

my $DateTimeObject = $Kernel::OM->Create(
    'Kernel::System::DateTime',
    ObjectParams => {
        String => '2020-01-10 16:00:00',
    },
);
$HelperObject->FixedTimeSet($DateTimeObject);

# Do not check email addresses.
$HelperObject->ConfigSettingChange(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

# Set DefaultLanguage to UTC.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'DefaultLanguage',
    Value => 'en',
);

# Set OTRSTimeZone to UTC.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'OTRSTimeZone',
    Value => 'UTC',
);

my $CustomerUserLogin = $HelperObject->TestCustomerUserCreate();
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject     = $Kernel::OM->Get('Kernel::System::Ticket::Article');

# Create test ticket.
my $TicketNumber = $TicketObject->TicketCreateNumber();
my $TicketID     = $TicketObject->TicketCreate(
    TN           => $TicketNumber,
    Title        => 'UnitTest ticket',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerID   => '12345',
    CustomerUser => "$CustomerUserLogin\@localunittest.com",
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $TicketID,
    "TicketID $TicketID is created",
);

my $ArticleBackendObject = $ArticleObject->BackendForChannel(
    ChannelName => 'Phone',
);

# Define internal and display values for each DynamicField type. Keys are the
# names of DynamicFields created by SetupTestEnvironment(), without the
# "UnitTest" prefix. If value is scalar, both are identical, otherwise it's an
# arrayref of [internal, display].
my %DynamicFieldTests = (
    Text        => 'UnitTest-foo',         # Internal value = display value
    TextArea    => 'some longer text',
    Checkbox    => [qw( 1 Checked )],
    Dropdown    => [qw( Key2 Value2 )],    # Internally called "Key2", displayed "Value2"
    MultiSelect => [qw( Key1 Value1 )],

    # Internally international format with seconds, displayed murrican mdY w/o seconds
    Date     => [ $DateTimeObject->Format( Format => '%Y-%m-%d' ), $DateTimeObject->Format( Format => '%m/%d/%Y' ) ],
    DateTime => [
        $DateTimeObject->Format( Format => '%Y-%m-%d %H:%M:%S' ),
        $DateTimeObject->Format( Format => '%m/%d/%Y %H:%M' )
    ],
);

my $DynamicFieldTemplate = "Test: " . join(
    '  ',
    map {"<OTRS_TICKET_DYNAMICFIELD_UnitTest$_>=><OTRS_TICKET_DYNAMICFIELD_UnitTest${_}_VALUE>"}
        sort keys %DynamicFieldTests
);

# Original:
# Test: 1=>Checked  2024-11-06=>11/06/2024  2024-11-06 00:12:13=>11/06/2024 00:12    Key2=>Value2  Key1=>Value1  UnitTest-foo=>UnitTest-foo  some longer text=>some longer text
my $DynamicFieldExpect = "Test: " . join(
    '  ',
    map {
        ref $DynamicFieldTests{$_}
            ?
            "$DynamicFieldTests{$_}[0]=>$DynamicFieldTests{$_}[1]"
            :
            "$DynamicFieldTests{$_}=>$DynamicFieldTests{$_}"
        }
        sort keys %DynamicFieldTests
);

#STDERR->say("TEMPLATE: $DynamicFieldTemplate\nEXPECT:   $DynamicFieldExpect");

# Attach a dynamic field of each type to the ticket
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
for my $Type ( sort keys %DynamicFieldTests ) {
    my $StoredValue = ref $DynamicFieldTests{$Type} ? $DynamicFieldTests{$Type}[0] : $DynamicFieldTests{$Type};
    $DynamicFieldBackendObject->ValueSet(
        DynamicFieldName => "UnitTest$Type",
        ObjectID         => $TicketID,
        Value            => $StoredValue,
        UserID           => 1,
    );
}

my $LastAgentSubject      = 'Article#3-agent';
my $LastAgentSubject9     = 'Article#3 [...]';
my $LastAgentBody         = "agent-Article#3-Line1\nagent-Article#3-Line2\nagentArticle#3-Line3";
my $LastAgentBody2        = "> agent-Article#3-Line1\n> agent-Article#3-Line2";
my $LastCustomerSubject   = 'Article#6-customer';
my $LastCustomerSubject12 = 'Article#6-cu [...]';
my $LastCustomerBody
    = "customer-Article#6-Line1\ncustomer-Article#6-Line2\ncustomerArticle#6-Line3\nCircular: <OTRS_CUSTOMER_BODY[10]>";
my $LastCustomerBody1 = "> customer-Article#6-Line1";

my @Configs = (
    {
        SenderType => 'agent',
        Subject    => 'Article#1-agent',
        Body       => "agent-Article#1-Line1\nagent-Article#1-Line2\nagentArticle#1-Line3",
    },
    {
        SenderType => 'agent',
        Subject    => 'Article#2-agent',
        Body       => "agent-Article#2-Line1\nagent-Article#2-Line2\nagentArticle#2-Line3",
    },
    {
        SenderType => 'agent',
        Subject    => $LastAgentSubject,
        Body       => $LastAgentBody,
    },
    {
        SenderType => 'customer',
        Subject    => 'Article#4-customer',
        Body       => "customer-Article#4-Line1\ncustomer-Article#4-Line2\ncustomerArticle#4-Line3",
    },
    {
        SenderType => 'customer',
        Subject    => 'Article#5-customer',
        Body       => "customer-Article#5-Line1\ncustomer-Article#5-Line2\ncustomerArticle#5-Line3",
    },
    {
        SenderType => 'customer',
        Subject    => $LastCustomerSubject,
        Body       => $LastCustomerBody,
    },
);

my @Articles;

for my $Config (@Configs) {
    my $ArticleID = $ArticleBackendObject->ArticleCreate(
        %{$Config},
        TicketID             => $TicketID,
        IsVisibleForCustomer => 0,
        From                 => 'Some Agent <otrs@example.com>',
        To                   => 'Supplier <supplier@example.com>',
        Charset              => 'utf8',
        MimeType             => 'text/plain',
        HistoryType          => 'OwnerUpdate',
        HistoryComment       => 'Some free text!',
        UserID               => 1,
    );
    $Self->True(
        $ArticleID,
        "ArticleID $ArticleID is created"
    );
    my %ArticleData = $ArticleBackendObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $ArticleID,
    );
    push @Articles, \%ArticleData;
}

# Get ticket and article data for tests.
my %TicketData = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
);

# Define for which template types certain tags are supported.
my %Supported = (
    Answer           => 1,
    Forward          => 1,
    Note             => 1,
    'Answer,Forward' => 1,
);

my @Tests = (
    {
        Name           => 'Supported tag - <OTRS_CONFIG_ScriptAlias>',
        TemplateText   => 'Thank you for your email. <OTRS_CONFIG_ScriptAlias>',
        ExpectedResult => 'Thank you for your email. ' . $ConfigObject->Get('ScriptAlias'),
    },
    {
        Name         => 'Supported tags - <OTRS_TICKET_*> without TicketID',
        TemplateText =>
            'Options of the ticket data (e. g. <OTRS_TICKET_TicketNumber>, <OTRS_TICKET_TicketID>, <OTRS_TICKET_Queue>)',
        ExpectedResult => 'Options of the ticket data (e. g. -, -, -)',
    },
    {
        Name         => 'Supported tags - <OTRS_TICKET_*>  with TicketID',
        TemplateText =>
            'Options of the ticket data (e. g. <OTRS_TICKET_TicketNumber>, <OTRS_TICKET_TicketID>, <OTRS_TICKET_Queue>, <OTRS_TICKET_State>)',
        ExpectedResult => "Options of the ticket data (e. g. $TicketNumber, $TicketID, Raw, open)",
        TicketID       => $TicketID,
    },
    {
        Name           => 'Tag <OTRS_AGENT_SUBJECT>',
        TemplateText   => 'Test: <OTRS_AGENT_SUBJECT>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastAgentSubject",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: $Articles[0]->{Subject}",
                $Articles[1]->{ArticleID} => "Test: $Articles[1]->{Subject}",
                $Articles[2]->{ArticleID} => "Test: $Articles[2]->{Subject}",
                $Articles[3]->{ArticleID} => 'Test: -',
                $Articles[4]->{ArticleID} => 'Test: -',
                $Articles[5]->{ArticleID} => 'Test: -',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_AGENT_SUBJECT[9]>',
        TemplateText   => 'Test: <OTRS_AGENT_SUBJECT[9]>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastAgentSubject9",
            Supported => {
                $Articles[0]->{ArticleID} => 'Test: Article#1 [...]',
                $Articles[1]->{ArticleID} => 'Test: Article#2 [...]',
                $Articles[2]->{ArticleID} => 'Test: Article#3 [...]',
                $Articles[3]->{ArticleID} => 'Test: -',
                $Articles[4]->{ArticleID} => 'Test: -',
                $Articles[5]->{ArticleID} => 'Test: -',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_AGENT_BODY>',
        TemplateText   => 'Test: <OTRS_AGENT_BODY>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastAgentBody",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: $Articles[0]->{Body}",
                $Articles[1]->{ArticleID} => "Test: $Articles[1]->{Body}",
                $Articles[2]->{ArticleID} => "Test: $Articles[2]->{Body}",
                $Articles[3]->{ArticleID} => 'Test: -',
                $Articles[4]->{ArticleID} => 'Test: -',
                $Articles[5]->{ArticleID} => 'Test: -',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_AGENT_BODY[2]>',
        TemplateText   => 'Test: <OTRS_AGENT_BODY[2]>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastAgentBody2",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: > agent-Article#1-Line1\n> agent-Article#1-Line2",
                $Articles[1]->{ArticleID} => "Test: > agent-Article#2-Line1\n> agent-Article#2-Line2",
                $Articles[2]->{ArticleID} => "Test: > agent-Article#3-Line1\n> agent-Article#3-Line2",
                $Articles[3]->{ArticleID} => 'Test: -',
                $Articles[4]->{ArticleID} => 'Test: -',
                $Articles[5]->{ArticleID} => 'Test: -',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_AGENT_BODY[2]>',
        TemplateText   => 'Test: <OTRS_AGENT_BODY[2]>',
        TicketID       => $TicketID,
        RichText       => 1,
        TemplateResult => {
            Note =>
                qq{Test: <div  type="cite" style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt"><p>agent-Article#3-Line1</p>\n<p>agent-Article#3-Line2</p></div>},
            Supported => {
                $Articles[0]->{ArticleID} =>
                    qq{Test: <div  type="cite" style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt"><p>agent-Article#1-Line1</p>\n<p>agent-Article#1-Line2</p></div>},
                $Articles[1]->{ArticleID} =>
                    qq{Test: <div  type="cite" style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt"><p>agent-Article#2-Line1</p>\n<p>agent-Article#2-Line2</p></div>},
                $Articles[2]->{ArticleID} =>
                    qq{Test: <div  type="cite" style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt"><p>agent-Article#3-Line1</p>\n<p>agent-Article#3-Line2</p></div>},
                $Articles[3]->{ArticleID} => 'Test: -',
                $Articles[4]->{ArticleID} => 'Test: -',
                $Articles[5]->{ArticleID} => 'Test: -',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_CUSTOMER_SUBJECT>',
        TemplateText   => 'Test: <OTRS_CUSTOMER_SUBJECT>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastCustomerSubject",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: $Articles[0]->{Subject}",
                $Articles[1]->{ArticleID} => "Test: $Articles[1]->{Subject}",
                $Articles[2]->{ArticleID} => "Test: $Articles[2]->{Subject}",
                $Articles[3]->{ArticleID} => "Test: $Articles[3]->{Subject}",
                $Articles[4]->{ArticleID} => "Test: $Articles[4]->{Subject}",
                $Articles[5]->{ArticleID} => "Test: $Articles[5]->{Subject}",
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_CUSTOMER_SUBJECT[12]>',
        TemplateText   => 'Test: <OTRS_CUSTOMER_SUBJECT[12]>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastCustomerSubject12",
            Supported => {
                $Articles[0]->{ArticleID} => 'Test: Article#1-ag [...]',
                $Articles[1]->{ArticleID} => 'Test: Article#2-ag [...]',
                $Articles[2]->{ArticleID} => 'Test: Article#3-ag [...]',
                $Articles[3]->{ArticleID} => 'Test: Article#4-cu [...]',
                $Articles[4]->{ArticleID} => 'Test: Article#5-cu [...]',
                $Articles[5]->{ArticleID} => 'Test: Article#6-cu [...]',
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_CUSTOMER_BODY>',
        TemplateText   => 'Test: <OTRS_CUSTOMER_BODY>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastCustomerBody",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: $Articles[0]->{Body}",
                $Articles[1]->{ArticleID} => "Test: $Articles[1]->{Body}",
                $Articles[2]->{ArticleID} => "Test: $Articles[2]->{Body}",
                $Articles[3]->{ArticleID} => "Test: $Articles[3]->{Body}",
                $Articles[4]->{ArticleID} => "Test: $Articles[4]->{Body}",
                $Articles[5]->{ArticleID} => "Test: $Articles[5]->{Body}",
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_CUSTOMER_BODY[1]>',
        TemplateText   => 'Test: <OTRS_CUSTOMER_BODY[1]>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $LastCustomerBody1",
            Supported => {
                $Articles[0]->{ArticleID} => "Test: > agent-Article#1-Line1",
                $Articles[1]->{ArticleID} => "Test: > agent-Article#2-Line1",
                $Articles[2]->{ArticleID} => "Test: > agent-Article#3-Line1",
                $Articles[3]->{ArticleID} => "Test: > customer-Article#4-Line1",
                $Articles[4]->{ArticleID} => "Test: > customer-Article#5-Line1",
                $Articles[5]->{ArticleID} => "Test: > customer-Article#6-Line1",
            },
            Unsupported => 'Test: -',
        }
    },
    {
        Name           => 'Tag <OTRS_TICKET_ID>',
        TemplateText   => 'Test: <OTRS_TICKET_ID>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $TicketID",
            Supported => {
                map { $Articles[$_]->{ArticleID} => "Test: $TicketID" } 0 .. 5
            },
            Unsupported => "Test: $TicketID",
        }
    },
    {
        Name           => 'Tag <OTRS_TICKET_NUMBER>',
        TemplateText   => 'Test: <OTRS_TICKET_NUMBER>',
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => "Test: $TicketData{TicketNumber}",
            Supported => {
                map { $Articles[$_]->{ArticleID} => "Test: $TicketData{TicketNumber}" } 0 .. 5
            },
            Unsupported => "Test: $TicketData{TicketNumber}",
        }
    },
    {
        Name           => 'Tag <OTRS_CUSTOMER_REALNAME>',
        TemplateText   => 'Test: <OTRS_CUSTOMER_REALNAME>',
        TemplateResult => {
            Note      => "Test: Supplier",
            Supported => {
                map { $Articles[$_]->{ArticleID} => "Test: Supplier" } 0 .. 5
            },
            Unsupported => "Test: Supplier",
        }
    },
    {
        Name           => 'Tag <OTRS_TICKET_DynamicField_*>',
        TemplateText   => $DynamicFieldTemplate,
        TicketID       => $TicketID,
        TemplateResult => {
            Note      => $DynamicFieldExpect,
            Supported => {
                map { $Articles[$_]->{ArticleID} => $DynamicFieldExpect } 0 .. 5
            },
            Unsupported => $DynamicFieldExpect,
        }
    },
    {
        Name         => 'Test supported tag - <OTRS_EMAIL_DATE[*]> with time zones',
        TemplateText =>
            'Belgrade: <OTRS_EMAIL_DATE[Europe/Belgrade]>; Denver: <OTRS_EMAIL_DATE[America/Denver]>; Tokyo: <OTRS_EMAIL_DATE[Asia/Tokyo]>',
        ExpectedResult =>
            "Belgrade: Friday, January 10, 2020 at 17:00:00 (Europe/Belgrade); Denver: Friday, January 10, 2020 at 09:00:00 (America/Denver); Tokyo: Saturday, January 11, 2020 at 01:00:00 (Asia/Tokyo)",
        Data     => \%TicketData,
        TicketID => $TicketID,
    },
    {
        Name         => 'Test supported tag - <OTRS_EMAIL_DATE> without time zone',
        TemplateText =>
            'No TimeZone specified (UTC): <OTRS_EMAIL_DATE>',
        ExpectedResult => 'No TimeZone specified (UTC): Friday, January 10, 2020 at 16:00:00 (UTC)',
        Data           => \%TicketData,
        TicketID       => $TicketID,
    },
);

my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

my @Types = qw( Answer Forward Create Note Email PhoneCall );
push @Types, ( 'Email,PhoneCall', 'Answer,Forward', );

TEST:
my $OldRichTextSetting = 42;    # random non-boolean value
for my $Test (@Tests) {

    # Get a $TemplateGeneratorObject with appropriate RichText setting
    # Only change the settings if different from last time through the loop
    $Test->{RichText} //= 0;    # Make sure it's defined
    if ( $OldRichTextSetting != $Test->{RichText} ) {
        $Kernel::OM->ObjectsDiscard(
            Objects => ['Kernel::System::TemplateGenerator']
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => $Test->{RichText} ? 1 : 0,
        );
        $OldRichTextSetting = $Test->{RichText};
    }
    my $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

    for my $TemplateType (@Types) {

        # Create standard template.
        my $TemplateID = $StandardTemplateObject->StandardTemplateAdd(
            Name         => $HelperObject->GetRandomID() . '-StandardTemplate',
            Template     => $Test->{TemplateText},
            ContentType  => 'text/plain; charset=utf-8',
            TemplateType => $TemplateType,
            ValidID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TemplateID,
            "'$TemplateType' type - TemplateID $TemplateID is created",
        );

        # Check template text.
        if ( $Test->{ExpectedResult} ) {
            my $Template = $TemplateGeneratorObject->Template(
                TemplateID => $TemplateID,
                TicketID   => $Test->{TicketID},
                Data       => $Test->{Data}       // {},
                TicketData => $Test->{TicketData} // {},
                UserID     => 1,
            );
            $Self->Is(
                $Template,
                $Test->{ExpectedResult},
                "'$TemplateType' type - $Test->{Name}",
            );
        }
        elsif ( $Test->{TemplateResult} ) {

            # Test for all agent and customer articles.
            for my $Article (@Articles) {
                my $Template = $TemplateGeneratorObject->Template(
                    TemplateID => $TemplateID,
                    TicketID   => $Test->{TicketID},
                    Data       => { %TicketData, %{$Article} },
                    TicketData => $Test->{TicketData} // {},
                    UserID     => 1,
                );

                if ( $Supported{$TemplateType} ) {
                    my $ExpectedResult = $Test->{TemplateResult}->{Supported}->{ $Article->{ArticleID} } // '';

                    # For Note template, there is last article data.
                    if ( $TemplateType eq 'Note' ) {
                        $ExpectedResult = $Test->{TemplateResult}->{Note};
                    }

                    $Self->Is(
                        $Template,
                        $ExpectedResult,
                        "'$TemplateType' type - $Article->{Subject} - $Test->{Name}",
                    );
                }
                else {
                    $Self->Is(
                        $Template,
                        $Test->{TemplateResult}->{Unsupported},
                        "'$TemplateType' type - $Article->{Subject} - $Test->{Name}",
                    );
                }
            }
        }
    }
}

# Cleanup is done by RestoreDatabase.

1;
