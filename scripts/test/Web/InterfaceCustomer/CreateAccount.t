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

use CGI;

use Kernel::System::Web::InterfaceCustomer;

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
my $CacheObject        = $Kernel::OM->Get('Kernel::System::Cache');

my %ChangeConfigs = (
    CheckEmailAddresses                                       => 0,
    CheckMXRecord                                             => 0,
    HTTPSForceRedirect                                        => 0,
    SendmailModule                                            => 'Kernel::System::Email::Test',
    CustomerPanelCreateAccount                                => 1,
    'CustomerPanelCreateAccount::RateLimitMaxAttempts'        => 0,
    'CustomerPanelCreateAccount::RateLimitWindow'             => 600,
    'CustomerPanelCreateAccount::MailRestrictions::Whitelist' => [],
    'CustomerPanelCreateAccount::MailRestrictions::Blacklist' => [],
);

for my $ConfigKey ( sort keys %ChangeConfigs ) {
    $HelperObject->ConfigSettingChange(
        Key   => $ConfigKey,
        Value => $ChangeConfigs{$ConfigKey},
    );
}

my $RandomID            = $HelperObject->GetRandomID();
my $Email               = "create-account-$RandomID\@example.com";
my $AttackerLogin       = "attacker-$RandomID";
my $AttackerCustomerID  = "VictimCorp-$RandomID";
my $AttackerCustomerIDs = 'VictimA,VictimB';
my $AttackerPhone       = '555-0100';

my $Output = CreateAccountRun(
    Action          => 'CustomerCreateAccount',
    UserTitle       => 'Dr',
    UserFirstname   => 'Ada',
    UserLastname    => 'Lovelace',
    UserEmail       => $Email,
    UserLogin       => $AttackerLogin,
    UserCustomerID  => $AttackerCustomerID,
    UserCustomerIDs => $AttackerCustomerIDs,
    UserPhone       => $AttackerPhone,
    RemoteAddr      => '203.0.113.20',
);

my %UserData = $CustomerUserObject->CustomerUserDataGet(
    User => $Email,
);

$Self->True(
    $UserData{UserID},
    "Customer user $Email was created",
);

$Self->Is(
    $UserData{UserLogin},
    $Email,
    'UserLogin is derived from UserEmail',
);

$Self->Is(
    $UserData{UserCustomerID},
    $Email,
    'UserCustomerID is derived from UserEmail',
);

$Self->Is(
    $UserData{UserTitle} || '',
    'Dr',
    'UserTitle from the request is stored',
);

$Self->Is(
    $UserData{UserFirstname} || '',
    'Ada',
    'UserFirstname from the request is stored',
);

$Self->Is(
    $UserData{UserLastname} || '',
    'Lovelace',
    'UserLastname from the request is stored',
);

$Self->Is(
    $UserData{UserPhone} || '',
    '',
    'UserPhone from the request is ignored',
);

$Self->Is(
    $UserData{UserCustomerIDs} || '',
    '',
    'UserCustomerIDs from the request is ignored',
);

my %AttackerData = $CustomerUserObject->CustomerUserDataGet(
    User => $AttackerLogin,
);

$Self->False(
    $AttackerData{UserID},
    'Supplied UserLogin was not created',
);

$HelperObject->ConfigSettingChange(
    Key   => 'CustomerPanelCreateAccount::AllowedFields',
    Value => [ 'UserTitle', 'UserFirstname', 'UserLastname', 'UserEmail', 'UserCustomerID', 'UserPhone' ],
);

my $BypassEmail = "create-account-bypass-$RandomID\@example.com";

CreateAccountRun(
    Action          => 'CustomerCreateAccount',
    UserTitle       => 'Dr',
    UserFirstname   => 'Grace',
    UserLastname    => 'Hopper',
    UserEmail       => $BypassEmail,
    UserLogin       => "bypass-$RandomID",
    UserCustomerID  => $AttackerCustomerID,
    UserCustomerIDs => $AttackerCustomerIDs,
    UserPhone       => $AttackerPhone,
    RemoteAddr      => '203.0.113.21',
);

my %BypassData = $CustomerUserObject->CustomerUserDataGet(
    User => $BypassEmail,
);

$Self->True(
    $BypassData{UserID},
    "Customer user $BypassEmail was created",
);

$Self->Is(
    $BypassData{UserLogin},
    $BypassEmail,
    'UserLogin stays derived from UserEmail when UserCustomerID is allowlisted',
);

$Self->Is(
    $BypassData{UserCustomerID},
    $BypassEmail,
    'UserCustomerID stays derived from UserEmail when it is allowlisted',
);

$Self->Is(
    $BypassData{UserPhone} || '',
    $AttackerPhone,
    'Allowlisted UserPhone from the request is stored',
);

$CacheObject->CleanUp(
    Type => 'CustomerCreateAccount',
);

$HelperObject->ConfigSettingChange(
    Key   => 'CustomerPanelCreateAccount::RateLimitMaxAttempts',
    Value => 2,
);

my @RateLimitEmails;
for my $Attempt ( 1 .. 3 ) {
    my $RateLimitEmail = "create-account-limit-$Attempt-$RandomID\@example.com";
    push @RateLimitEmails, $RateLimitEmail;

    $Output = CreateAccountRun(
        Action         => 'CustomerCreateAccount',
        UserTitle      => 'Dr',
        UserFirstname  => 'Rate',
        UserLastname   => "Limit$Attempt",
        UserEmail      => $RateLimitEmail,
        UserLogin      => "limit-$Attempt-$RandomID",
        UserCustomerID => $AttackerCustomerID,
        RemoteAddr     => '203.0.113.50',
        ForwardedFor   => "198.51.100.$Attempt",
    );
}

my %FirstLimitedUser = $CustomerUserObject->CustomerUserDataGet(
    User => $RateLimitEmails[0],
);
my %SecondLimitedUser = $CustomerUserObject->CustomerUserDataGet(
    User => $RateLimitEmails[1],
);
my %BlockedUser = $CustomerUserObject->CustomerUserDataGet(
    User => $RateLimitEmails[2],
);

$Self->True(
    $FirstLimitedUser{UserID},
    'First registration inside the rate limit is created',
);

$Self->True(
    $SecondLimitedUser{UserID},
    'Second registration inside the rate limit is created',
);

$Self->False(
    $BlockedUser{UserID},
    'Registration past the rate limit is not created when X-Forwarded-For changes',
);

my $RateLimitMessageFound = $Output =~ m{Could not create account[.] Please try again later[.]} ? 1 : 0;

$Self->True(
    $RateLimitMessageFound,
    'Rate limit response is a generic error',
);

$CacheObject->CleanUp(
    Type => 'CustomerCreateAccount',
);

sub CreateAccountRun {
    my (%Param) = @_;

    my $RemoteAddr = delete $Param{RemoteAddr};
    if ( !$RemoteAddr ) {
        $RemoteAddr = '203.0.113.20';
    }

    my $ForwardedFor = delete $Param{ForwardedFor};
    if ( !defined $ForwardedFor ) {
        $ForwardedFor = '';
    }

    local $ENV{REMOTE_ADDR}          = $RemoteAddr;
    local $ENV{HTTP_X_FORWARDED_FOR} = $ForwardedFor;
    local $ENV{QUERY_STRING}         = '';
    local $ENV{REQUEST_METHOD}       = 'GET';

    if ( !$Param{Action} ) {
        $Param{Action} = 'CustomerCreateAccount';
    }

    CGI::initialize_globals();

    my $CGI = CGI->new( \%Param );

    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::Language',
            'Kernel::Output::HTML::Layout',
            'Kernel::System::Web::Request',
        ],
    );

    my $Output = '';
    local *STDOUT;
    if ( !open STDOUT, '>:utf8', \$Output ) {    ## no critic
        die "Cannot open STDOUT: $!";
    }

    my $InterfaceCustomer = Kernel::System::Web::InterfaceCustomer->new(
        WebRequest => $CGI,
    );
    $InterfaceCustomer->Run();

    return $Output;
}

1;
