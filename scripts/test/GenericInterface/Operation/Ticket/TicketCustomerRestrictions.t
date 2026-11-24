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

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation::Ticket::TicketCreate;
use Kernel::GenericInterface::Operation::Ticket::TicketUpdate;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $RandomID     = $HelperObject->GetRandomID();

my $UserLogin = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
);
my $Password = $UserLogin;

my $CustomerUserLogin = $HelperObject->TestCustomerUserCreate();
my $CustomerPassword  = $CustomerUserLogin;

my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => 1,
    CommunicationType => 'Provider',
);

my $RunOperation = sub {
    my (%Param) = @_;

    my $OperationObject = "Kernel::GenericInterface::Operation::Ticket::$Param{Operation}"->new(
        DebuggerObject => $DebuggerObject,
        WebserviceID   => 1,
    );

    return $OperationObject->Run(
        Data => $Param{Data},
    );
};

my $ArticleDataGet = sub {
    my (%Param) = @_;

    my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleBackendObject = $ArticleObject->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID},
    );

    return $ArticleBackendObject->ArticleGet(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID},
    );
};

my $Type = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type::Default') || 'Unclassified';

my %Ticket = (
    Title        => 'Customer restriction ' . $RandomID,
    Queue        => 'Raw',
    Type         => $Type,
    State        => 'new',
    Priority     => '3 normal',
    CustomerUser => $CustomerUserLogin,
);

my %ForgedArticle = (
    Subject              => 'Article subject',
    Body                 => 'Article body',
    ContentType          => 'text/plain; charset=UTF8',
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'IT Support <helpdesk@example.com>',
);

my $CustomerCreate = $RunOperation->(
    Operation => 'TicketCreate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        Ticket            => {%Ticket},
        Article           => {%ForgedArticle},
    },
);

$Self->True(
    $CustomerCreate->{Data}->{TicketID},
    'Customer create returns a ticket',
);

my %CustomerArticle = $ArticleDataGet->(
    TicketID  => $CustomerCreate->{Data}->{TicketID},
    ArticleID => $CustomerCreate->{Data}->{ArticleID},
);

$Self->Is(
    $CustomerArticle{SenderType},
    'customer',
    'Customer SenderType is forced to customer',
);
$Self->Is(
    $CustomerArticle{IsVisibleForCustomer},
    1,
    'Customer IsVisibleForCustomer is forced to 1',
);
$Self->Is(
    $CustomerArticle{From},
    "\"$CustomerUserLogin $CustomerUserLogin\" <$CustomerUserLogin\@localunittest.com>",
    'Customer From is taken from the authenticated customer',
);

my $OtherCustomerLogin = $HelperObject->TestCustomerUserCreate();

my $CustomerIdentity = $RunOperation->(
    Operation => 'TicketCreate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        Ticket            => {
            %Ticket,
            Title        => 'Other customer ' . $RandomID,
            CustomerUser => $OtherCustomerLogin,
            CustomerID   => 'someone-else',
        },
        Article => {
            %ForgedArticle,
            ArticleSend => 1,
            To          => 'someone@example.com',
            Cc          => 'cc@example.com',
            Bcc         => 'bcc@example.com',
        },
    },
);

$Self->True(
    $CustomerIdentity->{Data}->{TicketID},
    'Customer create ignores supplied customer and article addressing',
);

my %IdentityTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
    TicketID => $CustomerIdentity->{Data}->{TicketID},
    UserID   => 1,
);
$Self->Is(
    $IdentityTicket{CustomerUserID},
    $CustomerUserLogin,
    'CustomerUser is the authenticated customer',
);
$Self->Is(
    $IdentityTicket{CustomerID},
    $CustomerUserLogin,
    'CustomerID is taken from the authenticated customer',
);

my %IdentityArticle = $ArticleDataGet->(
    TicketID  => $CustomerIdentity->{Data}->{TicketID},
    ArticleID => $CustomerIdentity->{Data}->{ArticleID},
);
$Self->Is(
    $IdentityArticle{CommunicationChannel},
    'Internal',
    'Customer ArticleSend is ignored',
);
$Self->Is(
    $IdentityArticle{Cc} || '',
    '',
    'Customer Cc is ignored',
);
$Self->Is(
    $IdentityArticle{Bcc} || '',
    '',
    'Customer Bcc is ignored',
);

my $CustomerPendingTime = $RunOperation->(
    Operation => 'TicketUpdate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        TicketID          => $CustomerCreate->{Data}->{TicketID},
        Ticket            => {
            PendingTime => {
                Diff => 60,
            },
        },
    },
);

$Self->True(
    $CustomerPendingTime->{Data}->{TicketID},
    'Customer PendingTime update is accepted',
);

my $CustomerReassign = $RunOperation->(
    Operation => 'TicketUpdate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        TicketID          => $CustomerCreate->{Data}->{TicketID},
        Ticket            => {
            CustomerUser => $OtherCustomerLogin,
            CustomerID   => 'someone-else',
        },
    },
);

$Self->True(
    $CustomerReassign->{Data}->{TicketID},
    'Customer update ignores CustomerUser and CustomerID',
);

my %ReassignTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
    TicketID => $CustomerCreate->{Data}->{TicketID},
    UserID   => 1,
);
$Self->Is(
    $ReassignTicket{CustomerUserID},
    $CustomerUserLogin,
    'Ticket customer user is unchanged',
);
$Self->Is(
    $ReassignTicket{CustomerID},
    $CustomerUserLogin,
    'Ticket customer ID is unchanged',
);

my $CustomerOwner = $RunOperation->(
    Operation => 'TicketCreate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        Ticket            => {
            %Ticket,
            Title => 'Customer owner ' . $RandomID,
            Owner => $UserLogin,
        },
        Article => {%ForgedArticle},
    },
);

$Self->Is(
    $CustomerOwner->{Data}->{Error}->{ErrorCode},
    'TicketCreate.InvalidParameter',
    'Customer Owner is rejected',
);

my $CustomerUpdateOwner = $RunOperation->(
    Operation => 'TicketUpdate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        TicketID          => $CustomerCreate->{Data}->{TicketID},
        Ticket            => {
            Owner => $UserLogin,
        },
    },
);

$Self->Is(
    $CustomerUpdateOwner->{Data}->{Error}->{ErrorCode},
    'TicketUpdate.InvalidParameter',
    'Customer Owner update is rejected',
);

my $CustomerUpdateArticle = $RunOperation->(
    Operation => 'TicketUpdate',
    Data      => {
        CustomerUserLogin => $CustomerUserLogin,
        Password          => $CustomerPassword,
        TicketID          => $CustomerCreate->{Data}->{TicketID},
        Article           => {%ForgedArticle},
    },
);

$Self->True(
    $CustomerUpdateArticle->{Data}->{ArticleID},
    'Customer update article returns an article',
);

my %CustomerUpdateArticleData = $ArticleDataGet->(
    TicketID  => $CustomerCreate->{Data}->{TicketID},
    ArticleID => $CustomerUpdateArticle->{Data}->{ArticleID},
);

$Self->Is(
    $CustomerUpdateArticleData{SenderType},
    'customer',
    'Customer update SenderType is forced to customer',
);
$Self->Is(
    $CustomerUpdateArticleData{IsVisibleForCustomer},
    1,
    'Customer update IsVisibleForCustomer is forced to 1',
);
$Self->Is(
    $CustomerUpdateArticleData{From},
    "\"$CustomerUserLogin $CustomerUserLogin\" <$CustomerUserLogin\@localunittest.com>",
    'Customer update From is taken from the authenticated customer',
);

my $AgentCreate = $RunOperation->(
    Operation => 'TicketCreate',
    Data      => {
        UserLogin => $UserLogin,
        Password  => $Password,
        Ticket    => {
            %Ticket,
            Title => 'Agent article ' . $RandomID,
        },
        Article => {%ForgedArticle},
    },
);

$Self->True(
    $AgentCreate->{Data}->{TicketID},
    'Agent create returns a ticket',
);

my %AgentArticle = $ArticleDataGet->(
    TicketID  => $AgentCreate->{Data}->{TicketID},
    ArticleID => $AgentCreate->{Data}->{ArticleID},
);

$Self->Is(
    $AgentArticle{SenderType},
    'agent',
    'Agent SenderType is kept',
);
$Self->Is(
    $AgentArticle{IsVisibleForCustomer},
    0,
    'Agent IsVisibleForCustomer is kept',
);

1;
