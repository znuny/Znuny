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

use Kernel::System::VariableCheck qw(:all);

my %ChangeConfigs = (
    CheckEmailAddresses     => 0,
    CheckMXRecord           => 0,
    'Frontend::RichText'    => 0,
    SendmailModule          => 'Kernel::System::Email::Test',
    DefaultLanguage         => 'en',
    AgentSelfNotifyOnAction => 1,
);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

for my $CfgKey ( sort keys %ChangeConfigs ) {
    $HelperObject->ConfigSettingChange(
        Key   => $CfgKey,
        Value => $ChangeConfigs{$CfgKey},
    );
}

my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
$TestEmailObject->CleanUp();

my $MailQueueObject = $Kernel::OM->Get('Kernel::System::MailQueue');
$MailQueueObject->Delete();

my $UserLogin = $HelperObject->TestUserCreate(
    Groups => ['users'],
);
my $UserObject = $Kernel::OM->Get('Kernel::System::User');
my %UserData   = $UserObject->GetUserData(
    User => $UserLogin,
);
my $UserID = $UserData{UserID};

my $CustomerUserLogin = $HelperObject->TestCustomerUserCreate();

my $TicketObject            = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject           = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');
my $RandomID                = $HelperObject->GetRandomID();
my $NotificationBodyMarker  = "AgentCreateByNotificationNewTicket-$RandomID";

# Disable existing ticket-create notifications so only the test notification is asserted.
my %ExistingNotifications = $NotificationEventObject->NotificationList(
    Details => 1,
);

NOTIFICATION:
for my $NotificationID ( sort keys %ExistingNotifications ) {
    my $Notification = $ExistingNotifications{$NotificationID};
    next NOTIFICATION if !IsArrayRefWithData( $Notification->{Data}->{Events} );
    next NOTIFICATION if !grep { $_ eq 'NotificationNewTicket' } @{ $Notification->{Data}->{Events} };

    my $Success = $NotificationEventObject->NotificationUpdate(
        %$Notification,
        ValidID => 2,
        UserID  => 1,
    );
    $Self->True(
        $Success,
        "Disabled existing NotificationNewTicket notification ID $NotificationID",
    );
}

my $TestNotificationID = $NotificationEventObject->NotificationAdd(
    Name    => "AgentCreateBy-$RandomID",
    Comment => 'Unit test notification for AgentCreateBy via NotificationNewTicket',
    Data    => {
        Events     => ['NotificationNewTicket'],
        Recipients => ['AgentCreateBy'],
        Transports => ['Email'],
    },
    Message => {
        en => {
            Subject     => "AgentCreateBy $RandomID",
            Body        => "$NotificationBodyMarker <OTRS_TICKET_TicketID>",
            ContentType => 'text/plain',
        },
    },
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $TestNotificationID,
    "Test NotificationNewTicket notification created - ID $TestNotificationID",
);

my $ProcessDynamicFieldName = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID')
    // 'ProcessManagementProcessID';

my $EmailsForTestNotification = sub {
    my $Emails = $TestEmailObject->EmailsGet();

    my @Matching;
    EMAIL:
    for my $Email ( @{$Emails} ) {
        my $Body = ref $Email->{Body} ? ${ $Email->{Body} } : $Email->{Body};
        next EMAIL if $Body !~ m{\Q$NotificationBodyMarker\E};

        push @Matching, {
            ToArray => $Email->{ToArray},
            Body    => $Body,
        };
    }

    return @Matching;
};

my @Tests = (
    {
        Name    => 'Agent email ticket (EmailAgent) - sent',
        Article => {
            ChannelName => 'Email',
            SenderType  => 'agent',
            HistoryType => 'EmailAgent',
        },
        ExpectedToCreator => 1,
    },
    {
        Name    => 'Phone ticket (PhoneCallCustomer) - sent',
        Article => {
            ChannelName => 'Phone',
            SenderType  => 'customer',
            HistoryType => 'PhoneCallCustomer',
        },
        ExpectedToCreator => 1,
    },
    {
        Name    => 'Customer email ticket (EmailCustomer) - not sent',
        Article => {
            ChannelName => 'Email',
            SenderType  => 'customer',
            HistoryType => 'EmailCustomer',
        },
        ExpectedToCreator => 0,
    },
    {
        Name              => 'Process ticket without articles - sent',
        Process           => 1,
        ExpectedToCreator => 1,
    },
    {
        Name    => 'Process ticket with Internal article (AddNote, as AgentTicketProcess) - sent',
        Process => 1,
        Article => {
            ChannelName => 'Internal',
            SenderType  => 'agent',
            HistoryType => 'AddNote',
        },
        ExpectedToCreator => 1,
    },
    {
        Name    => 'Process ticket with Phone article (PhoneCallAgent, as AgentTicketProcess) - sent',
        Process => 1,
        Article => {
            ChannelName => 'Phone',
            SenderType  => 'agent',
            HistoryType => 'PhoneCallAgent',
        },
        ExpectedToCreator => 1,
    },
);

TEST:
for my $Test (@Tests) {
    $TestEmailObject->CleanUp();
    $MailQueueObject->Delete();

    my $TicketID = $TicketObject->TicketCreate(
        Title        => $Test->{Name},
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'example.com',
        CustomerUser => $CustomerUserLogin,
        OwnerID      => $UserID,
        UserID       => $UserID,
    );
    $Self->True(
        $TicketID,
        "$Test->{Name} - ticket created",
    );
    next TEST if !$TicketID;

    if ( $Test->{Process} ) {
        $HelperObject->DynamicFieldSet(
            Field    => $ProcessDynamicFieldName,
            ObjectID => $TicketID,
            Value    => 'UnitTestProcess-' . $RandomID,
            UserID   => $UserID,
        );
    }

    my $ArticleBackendObject;
    if ( $Test->{Article} ) {
        $ArticleBackendObject = $ArticleObject->BackendForChannel(
            ChannelName => $Test->{Article}->{ChannelName},
        );

        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            SenderType           => $Test->{Article}->{SenderType},
            HistoryType          => $Test->{Article}->{HistoryType},
            HistoryComment       => '%%',
            IsVisibleForCustomer => 1,
            From                 => "\"$UserData{UserFullname}\" <$UserData{UserEmail}>",
            Subject              => $Test->{Name},
            Body                 => $Test->{Name},
            Charset              => 'UTF-8',
            MimeType             => 'text/plain',
            UserID               => $UserID,
        );
        $Self->True(
            $ArticleID,
            "$Test->{Name} - article created",
        );
        next TEST if !$ArticleID;
    }

    # TicketCreate is a transaction event (NotifyOnEmptyProcessTickets).
    $TicketObject->EventHandlerTransaction();

    # ArticleCreate queues NotificationNewTicket on the article backend.
    if ($ArticleBackendObject) {
        $ArticleBackendObject->EventHandlerTransaction();
    }

    # Empty process tickets get NotificationNewTicket from NotifyOnEmptyProcessTickets,
    # which is the production fallback when the start dialog has no article.
    if ( $Test->{Process} && !$Test->{Article} ) {
        my $NotifyOnEmptyProcessTicketsObject
            = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotifyOnEmptyProcessTickets');
        $NotifyOnEmptyProcessTicketsObject->Run(
            Event  => 'TicketCreate',
            UserID => $UserID,
            Data   => {
                TicketID => $TicketID,
            },
            Config => {
                NotRelevantForTest => 1,
            },
        );
    }

    my $Items = $MailQueueObject->List();
    for my $Item (@$Items) {
        $MailQueueObject->Send( %{$Item} );
    }
    $MailQueueObject->Delete();

    my @MatchingEmails = $EmailsForTestNotification->();

    my $CreatorNotified = 0;
    EMAIL:
    for my $Email (@MatchingEmails) {
        next EMAIL if !grep { $_ eq $UserData{UserEmail} } @{ $Email->{ToArray} || [] };
        $CreatorNotified = 1;
        last EMAIL;
    }

    $Self->Is(
        $CreatorNotified,
        $Test->{ExpectedToCreator} ? 1 : 0,
        $Test->{ExpectedToCreator}
        ? "$Test->{Name} - creator received NotificationNewTicket"
        : "$Test->{Name} - creator did not receive NotificationNewTicket",
    );
}

1;
