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
);

my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $UserObject      = $Kernel::OM->Get('Kernel::System::User');
my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransportObject = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::Webservice');

# Preload classes that will be locally overridden in this test.
my $RequesterObject  = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

# Keep recipient payload behavior deterministic for assertions.
$ConfigObject->Set(
    Key   => 'WebserviceNotifications::RecipientInformation',
    Value => {
        Agent                      => [ 'UserEmail', 'UserPw', 'Password', 'SearchUserPw' ],
        Customer                   => [ 'UserEmail', 'UserPw', 'Password', 'SearchUserPw' ],
        AdditionalRecipientKeyName => 'UserLogin',
    },
);

my $UserLogin = $HelperObject->TestUserCreate(
    Groups => ['users'],
);

my %UserData = $UserObject->GetUserData(
    User => $UserLogin,
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Webservice transport sanitization test',
    QueueID      => 1,
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerID   => 'example.com',
    CustomerUser => $UserData{UserLogin},
    OwnerID      => $UserData{UserID},
    UserID       => $UserData{UserID},
);

$Self->True(
    $TicketID,
    "TicketCreate() successful for TicketID $TicketID",
);

my %CapturedRequesterParams;

{
    no warnings 'redefine';    ## no critic

    local *Kernel::System::GenericInterface::Webservice::WebserviceList = sub {
        return {
            1 => 'UnitTest Webservice',
        };
    };

    local *Kernel::GenericInterface::Requester::Run = sub {
        my ( $RequesterSelf, %Param ) = @_;

        %CapturedRequesterParams = %Param;

        return {
            Success => 1,
        };
    };

    my $Success = $TransportObject->SendNotification(
        TicketID     => $TicketID,
        UserID       => $UserData{UserID},
        Event        => 'TicketCreate',
        Attachments  => [],
        Notification => {
            Name        => 'Webservice Transport Sanitization',
            Subject     => 'Test subject',
            Body        => 'Test body',
            ContentType => 'text/plain',
            Data        => {
                TransportWebserviceAsynchronous => [0],
                TransportWebserviceID           => [1],
                TransportWebserviceInvokerName  => ['InvokerName'],
            },
        },
        Recipient => {
            Type         => 'Customer',
            UserEmail    => 'customer@example.com',
            UserPw       => 'top-level-secret',
            Password     => 'top-level-db-secret',
            SearchUserPw => 'top-level-ldap-secret',
            Config       => {
                Params => {
                    UserPw       => 'nested-secret',
                    UserPassword => 'nested-password',
                    Password     => 'db-password',
                    Host         => 'ldaps://example.test',
                },
            },
            CompanyConfig => {
                Params => {
                    Password => 'company-db-password',
                    DSN      => 'DBI:mysql:database=customer_company',
                },
            },
            BackendConfigs => [
                {
                    Module => 'Kernel::System::CustomerUser::LDAP',
                    Params => {
                        UserPw => 'array-ldap-secret',
                    },
                },
                {
                    Module => 'Kernel::System::CustomerUser::DB',
                    Params => {
                        Password => 'array-db-secret',
                    },
                },
            ],
        },
    );

    $Self->True(
        $Success,
        'SendNotification() successful',
    );
}

$Self->Is(
    ref $CapturedRequesterParams{Data},
    'HASH',
    'Requester got data payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{UserEmail},
    'customer@example.com',
    'Whitelisted recipient information remains available',
);

$Self->False(
    exists $CapturedRequesterParams{Data}->{UserPw},
    'Whitelisted UserPw recipient information is omitted from request data',
);

$Self->False(
    exists $CapturedRequesterParams{Data}->{Password},
    'Whitelisted Password recipient information is omitted from request data',
);

$Self->False(
    exists $CapturedRequesterParams{Data}->{SearchUserPw},
    'Whitelisted SearchUserPw recipient information is omitted from request data',
);

$Self->Is(
    ref $CapturedRequesterParams{Data}->{Recipient},
    'HASH',
    'Requester payload contains recipient hash',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{UserPw},
    undef,
    'Top-level UserPw was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{UserPassword},
    undef,
    'Top-level UserPassword was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{Config}->{Params}->{UserPw},
    undef,
    'Nested Config->Params->UserPw was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{Config}->{Params}->{UserPassword},
    undef,
    'Nested Config->Params->UserPassword was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{Config}->{Params}->{Password},
    undef,
    'Nested DB Config->Params->Password was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{CompanyConfig}->{Params}->{Password},
    undef,
    'Nested DB CompanyConfig->Params->Password was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{BackendConfigs}->[0]->{Params}->{UserPw},
    undef,
    'Nested LDAP array Config->Params->UserPw was removed from recipient payload',
);

$Self->Is(
    $CapturedRequesterParams{Data}->{Recipient}->{BackendConfigs}->[1]->{Params}->{Password},
    undef,
    'Nested DB array Config->Params->Password was removed from recipient payload',
);

1;
