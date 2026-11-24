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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SessionObject      = $Kernel::OM->Get('Kernel::System::AuthSession');
my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');
my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);
$ConfigObject->Set(
    Key   => 'SessionCSRFProtection',
    Value => 0,
);

my $InvalidID = $ValidObject->ValidLookup(
    Valid => 'invalid',
);
$Self->True(
    $InvalidID,
    'ValidID for invalid exists',
);

# Agent password change removes every session of that login, including GenericInterface.
my ( $AgentLogin,      $AgentUserID )      = $HelperObject->TestUserCreate();
my ( $OtherAgentLogin, $OtherAgentUserID ) = $HelperObject->TestUserCreate();

my %AgentData = $UserObject->GetUserData(
    UserID        => $AgentUserID,
    NoOutOfOffice => 1,
);
my %OtherAgentData = $UserObject->GetUserData(
    UserID        => $OtherAgentUserID,
    NoOutOfOffice => 1,
);

my $AgentSessionID = $SessionObject->CreateSessionID(
    %AgentData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'AgentInterface',
);
my $GISessionID = $SessionObject->CreateSessionID(
    %AgentData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'GenericInterface',
);
my $OtherAgentSessionID = $SessionObject->CreateSessionID(
    %OtherAgentData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'AgentInterface',
);

$Self->True( $AgentSessionID,      "Agent session created for '$AgentLogin'" );
$Self->True( $GISessionID,         "GenericInterface session created for '$AgentLogin'" );
$Self->True( $OtherAgentSessionID, "Agent session created for '$OtherAgentLogin'" );
$Self->Is(
    SessionCountForLogin( UserLogin => $AgentLogin ),
    2,
    "Two sessions exist for '$AgentLogin'",
);

my $AgentPasswordSet = $UserObject->SetPassword(
    UserLogin => $AgentLogin,
    PW        => 'New-pass-1',
);
$Self->True( $AgentPasswordSet, "SetPassword() for agent '$AgentLogin'" );
$Self->Is(
    SessionCountForLogin( UserLogin => $AgentLogin ),
    0,
    "Sessions for '$AgentLogin' were removed",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $AgentSessionID ),
    "Agent session for '$AgentLogin' is no longer valid",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $GISessionID ),
    "GenericInterface session for '$AgentLogin' is no longer valid",
);
$Self->True(
    $SessionObject->CheckSessionID( SessionID => $OtherAgentSessionID ),
    "Session for '$OtherAgentLogin' is still valid",
);

# Customer password change removes that customer user's sessions only.
my $CustomerLogin      = $HelperObject->TestCustomerUserCreate();
my $OtherCustomerLogin = $HelperObject->TestCustomerUserCreate();

my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
    User => $CustomerLogin,
);
my %OtherCustomerData = $CustomerUserObject->CustomerUserDataGet(
    User => $OtherCustomerLogin,
);

my $CustomerSessionID = $SessionObject->CreateSessionID(
    %CustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);
my $OtherCustomerSessionID = $SessionObject->CreateSessionID(
    %OtherCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);

$Self->True( $CustomerSessionID,      "Customer session created for '$CustomerLogin'" );
$Self->True( $OtherCustomerSessionID, "Customer session created for '$OtherCustomerLogin'" );

my $CustomerPasswordSet = $CustomerUserObject->SetPassword(
    UserLogin => $CustomerLogin,
    PW        => 'New-pass-2',
);
$Self->True( $CustomerPasswordSet, "SetPassword() for customer '$CustomerLogin'" );
$Self->Is(
    SessionCountForLogin( UserLogin => $CustomerLogin ),
    0,
    "Sessions for customer '$CustomerLogin' were removed",
);
$Self->True(
    $SessionObject->CheckSessionID( SessionID => $OtherCustomerSessionID ),
    "Session for customer '$OtherCustomerLogin' is still valid",
);

# A self-service password change keeps the session that submitted it.
my ( $KeepAgentLogin, $KeepAgentUserID ) = $HelperObject->TestUserCreate();
my %KeepAgentData = $UserObject->GetUserData(
    UserID        => $KeepAgentUserID,
    NoOutOfOffice => 1,
);
my $KeepAgentSessionID = $SessionObject->CreateSessionID(
    %KeepAgentData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'AgentInterface',
);
my $DropAgentSessionID = $SessionObject->CreateSessionID(
    %KeepAgentData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'GenericInterface',
);
$Self->True( $KeepAgentSessionID, "Session to keep created for '$KeepAgentLogin'" );
$Self->True( $DropAgentSessionID, "Session to drop created for '$KeepAgentLogin'" );

my $KeepAgentPasswordSet = $UserObject->SetPassword(
    UserLogin     => $KeepAgentLogin,
    PW            => 'New-pass-3',
    KeepSessionID => $KeepAgentSessionID,
);
$Self->True( $KeepAgentPasswordSet, "SetPassword() for agent '$KeepAgentLogin' keeps one session" );
$Self->True(
    scalar $SessionObject->CheckSessionID( SessionID => $KeepAgentSessionID ),
    "Session '$KeepAgentSessionID' for '$KeepAgentLogin' is still valid",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $DropAgentSessionID ),
    "Other session for '$KeepAgentLogin' was removed",
);

my $KeepCustomerLogin = $HelperObject->TestCustomerUserCreate();
my %KeepCustomerData  = $CustomerUserObject->CustomerUserDataGet(
    User => $KeepCustomerLogin,
);
my $KeepCustomerSessionID = $SessionObject->CreateSessionID(
    %KeepCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);
my $DropCustomerSessionID = $SessionObject->CreateSessionID(
    %KeepCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'GenericInterface',
);
$Self->True( $KeepCustomerSessionID, "Session to keep created for '$KeepCustomerLogin'" );
$Self->True( $DropCustomerSessionID, "Session to drop created for '$KeepCustomerLogin'" );

my $KeepCustomerPasswordSet = $CustomerUserObject->SetPassword(
    UserLogin     => $KeepCustomerLogin,
    PW            => 'New-pass-4',
    KeepSessionID => $KeepCustomerSessionID,
);
$Self->True(
    $KeepCustomerPasswordSet,
    "SetPassword() for customer '$KeepCustomerLogin' keeps one session",
);
$Self->True(
    scalar $SessionObject->CheckSessionID( SessionID => $KeepCustomerSessionID ),
    "Session '$KeepCustomerSessionID' for '$KeepCustomerLogin' is still valid",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $DropCustomerSessionID ),
    "Other session for '$KeepCustomerLogin' was removed",
);

# AdminCustomerUser invalidation and login change.
my $InvalidCustomerLogin = $HelperObject->TestCustomerUserCreate();
my %InvalidCustomerData  = $CustomerUserObject->CustomerUserDataGet(
    User => $InvalidCustomerLogin,
);
my $InvalidCustomerSessionID = $SessionObject->CreateSessionID(
    %InvalidCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);
my $InvalidCustomerGISessionID = $SessionObject->CreateSessionID(
    %InvalidCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'GenericInterface',
);
$Self->True(
    $InvalidCustomerSessionID,
    "Customer session created for '$InvalidCustomerLogin'",
);
$Self->True(
    $InvalidCustomerGISessionID,
    "GenericInterface session created for '$InvalidCustomerLogin'",
);

AdminCustomerUserChange(
    %InvalidCustomerData,
    ID      => $InvalidCustomerLogin,
    ValidID => $InvalidID,
);

$Self->Is(
    SessionCountForLogin( UserLogin => $InvalidCustomerLogin ),
    0,
    "Sessions for invalidated customer '$InvalidCustomerLogin' were removed",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $InvalidCustomerGISessionID ),
    "GenericInterface session for invalidated customer '$InvalidCustomerLogin' is no longer valid",
);

my $RenameCustomerLogin = $HelperObject->TestCustomerUserCreate();
my $RenamedLogin        = $HelperObject->GetRandomID();
my %RenameCustomerData  = $CustomerUserObject->CustomerUserDataGet(
    User => $RenameCustomerLogin,
);
my $RenameCustomerSessionID = $SessionObject->CreateSessionID(
    %RenameCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);
my $RenameCustomerGISessionID = $SessionObject->CreateSessionID(
    %RenameCustomerData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'GenericInterface',
);
$Self->True(
    $RenameCustomerSessionID,
    "Customer session created for '$RenameCustomerLogin'",
);
$Self->True(
    $RenameCustomerGISessionID,
    "GenericInterface session created for '$RenameCustomerLogin'",
);

AdminCustomerUserChange(
    %RenameCustomerData,
    ID        => $RenameCustomerLogin,
    UserLogin => $RenamedLogin,
    ValidID   => 1,
);

$Self->Is(
    SessionCountForLogin( UserLogin => $RenameCustomerLogin ),
    0,
    "Sessions for renamed customer '$RenameCustomerLogin' were removed",
);
$Self->False(
    scalar $SessionObject->CheckSessionID( SessionID => $RenameCustomerGISessionID ),
    "GenericInterface session for renamed customer '$RenameCustomerLogin' is no longer valid",
);
$Self->Is(
    SessionCountForLogin( UserLogin => $RenamedLogin ),
    0,
    "Renamed customer '$RenamedLogin' has no session yet",
);

$Self->True(
    $SessionObject->CheckSessionID( SessionID => $OtherCustomerSessionID ),
    "Unrelated customer session is still valid",
);

sub SessionCountForLogin {
    my (%Param) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $Count         = 0;

    SESSIONID:
    for my $SessionID ( $SessionObject->GetAllSessionIDs() ) {
        my %SessionData = $SessionObject->GetSessionIDData(
            SessionID => $SessionID,
        );
        next SESSIONID if ( $SessionData{UserLogin} // '' ) ne $Param{UserLogin};
        $Count++;
    }

    return $Count;
}

sub AdminCustomerUserChange {
    my (%Param) = @_;

    my %CGIParam = (
        Nav    => 'None',
        Source => 'CustomerUser',
    );

    FIELD:
    for my $Field (
        qw(ID UserTitle UserFirstname UserLastname UserLogin UserEmail UserCustomerID UserPhone UserFax UserMobile UserStreet UserZip UserCity UserCountry UserComment ValidID)
        )
    {
        next FIELD if !defined $Param{$Field};
        $CGIParam{$Field} = $Param{$Field};
    }

    CGI->initialize_globals();
    my $CGI = CGI->new( \%CGIParam );

    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::System::Web::Request',
            'Kernel::Output::HTML::Layout',
        ],
    );
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::Web::Request' => {
            WebRequest => $CGI,
        },
        'Kernel::Output::HTML::Layout' => {
            UserID   => 1,
            UserType => '',
        },
    );

    my $Loaded = $MainObject->Require('Kernel::Modules::AdminCustomerUser');
    $Self->True( $Loaded, 'Loaded Kernel::Modules::AdminCustomerUser' );
    return if !$Loaded;

    my $Module = Kernel::Modules::AdminCustomerUser->new(
        Action    => 'AdminCustomerUser',
        Subaction => 'ChangeAction',
        UserID    => 1,
    );

    my $Output = eval {
        $Module->Run();
    };
    $Self->True(
        $Output,
        'AdminCustomerUser ChangeAction returned output',
    );

    return $Output;
}

1;
