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

my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
my $UserObject    = $Kernel::OM->Get('Kernel::System::User');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Create test users and a session for every one.
my @TestUserLogins;
for my $Count ( 1 .. 3 ) {
    my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();
    push @TestUserLogins, $TestUserLogin;

    my %UserData = $UserObject->GetUserData(
        UserID        => $TestUserID,
        NoOutOfOffice => 1,
    );

    my $NewSessionID = $SessionObject->CreateSessionID(
        %UserData,
        UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
        UserType        => 'User',
        SessionSource   => 'AgentInterface',
    );
    $Self->True(
        $NewSessionID,
        "SessionID '$NewSessionID' is created for user '$TestUserLogin'",
    );
}

# Check if all sessions exist.
my @SessionIDs = $SessionObject->GetAllSessionIDs();
my %SessionDataLoginBefore;

for my $SessionID (@SessionIDs) {
    my %SessionData = $SessionObject->GetSessionIDData(
        SessionID => $SessionID,
    );
    $SessionDataLoginBefore{ $SessionData{UserLogin} } = 1;
}

for my $TestUserLogin (@TestUserLogins) {
    $Self->True(
        $SessionDataLoginBefore{$TestUserLogin},
        "User '$TestUserLogin' is found",
    );
}

my $TestUserLoginRemoveSession = $TestUserLogins[0];

# Remove session from one test user.
my $Success = $SessionObject->RemoveSessionByUser(
    UserLogin => $TestUserLoginRemoveSession,
);
$Self->True(
    $Success,
    "Session from user '$TestUserLoginRemoveSession' is deleted",
);

# Check if only appropriate session is removed.
@SessionIDs = $SessionObject->GetAllSessionIDs();
my %SessionDataLoginAfter;

for my $SessionID (@SessionIDs) {
    my %SessionData = $SessionObject->GetSessionIDData(
        SessionID => $SessionID,
    );
    $SessionDataLoginAfter{ $SessionData{UserLogin} } = 1;
}

for my $TestUserLogin (@TestUserLogins) {
    if ( $TestUserLogin eq $TestUserLoginRemoveSession ) {
        $Self->False(
            $SessionDataLoginAfter{$TestUserLogin},
            "User '$TestUserLogin' is not found",
        );
    }
    else {
        $Self->True(
            $SessionDataLoginAfter{$TestUserLogin},
            "User '$TestUserLogin' is found",
        );
    }
}

# Restore to the previous state is done by RestoreDatabase.

my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

# Same login, both types. Omitting UserType still removes every matching session.
my ( $SharedLogin, $SharedUserID ) = $HelperObject->TestUserCreate();
$HelperObject->TestCustomerUserCreate(
    UserLogin => $SharedLogin,
);

my %SharedUserData = $UserObject->GetUserData(
    UserID        => $SharedUserID,
    NoOutOfOffice => 1,
);
my %SharedCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
    User => $SharedLogin,
);

my $SharedAgentSessionID = $SessionObject->CreateSessionID(
    %SharedUserData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
    SessionSource   => 'AgentInterface',
);
my $SharedCustomerSessionID = $SessionObject->CreateSessionID(
    %SharedCustomerUserData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'Customer',
    SessionSource   => 'CustomerInterface',
);
$Self->True(
    $SharedAgentSessionID && $SharedCustomerSessionID,
    "Sessions for shared login '$SharedLogin' are created",
);

$Success = $SessionObject->RemoveSessionByUser(
    UserLogin => $SharedLogin,
    UserType  => 'Agent',
);
$Self->False(
    $Success,
    'RemoveSessionByUser() rejects an invalid UserType',
);
$Self->True(
    _SessionExists(
        UserLogin => $SharedLogin,
        UserType  => 'User',
    ),
    "Agent session for '$SharedLogin' is kept after an invalid UserType",
);
$Self->True(
    _SessionExists(
        UserLogin => $SharedLogin,
        UserType  => 'Customer',
    ),
    "Customer session for '$SharedLogin' is kept after an invalid UserType",
);

$Success = $SessionObject->RemoveSessionByUser(
    UserLogin => $SharedLogin,
);
$Self->True(
    $Success,
    "Sessions for shared login '$SharedLogin' are deleted without UserType",
);
$Self->False(
    _SessionExists(
        UserLogin => $SharedLogin,
        UserType  => 'User',
    ),
    "Agent session for '$SharedLogin' is not found",
);
$Self->False(
    _SessionExists(
        UserLogin => $SharedLogin,
        UserType  => 'Customer',
    ),
    "Customer session for '$SharedLogin' is not found",
);

# Same login again. UserType removes only the given type.
my ( $TypedLogin, $TypedUserID ) = $HelperObject->TestUserCreate();
$HelperObject->TestCustomerUserCreate(
    UserLogin => $TypedLogin,
);

my %TypedUserData = $UserObject->GetUserData(
    UserID        => $TypedUserID,
    NoOutOfOffice => 1,
);
my %TypedCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
    User => $TypedLogin,
);

$Self->True(
    $SessionObject->CreateSessionID(
        %TypedUserData,
        UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
        UserType        => 'User',
        SessionSource   => 'AgentInterface',
    ),
    "Agent session for '$TypedLogin' is created",
);
$Self->True(
    $SessionObject->CreateSessionID(
        %TypedCustomerUserData,
        UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
        UserType        => 'Customer',
        SessionSource   => 'CustomerInterface',
    ),
    "Customer session for '$TypedLogin' is created",
);

$Success = $SessionObject->RemoveSessionByUser(
    UserLogin => $TypedLogin,
    UserType  => 'User',
);
$Self->True(
    $Success,
    "Agent session for '$TypedLogin' is deleted",
);
$Self->False(
    _SessionExists(
        UserLogin => $TypedLogin,
        UserType  => 'User',
    ),
    "Agent session for '$TypedLogin' is not found",
);
$Self->True(
    _SessionExists(
        UserLogin => $TypedLogin,
        UserType  => 'Customer',
    ),
    "Customer session for '$TypedLogin' is kept",
);

$Success = $SessionObject->RemoveSessionByUser(
    UserLogin => $TypedLogin,
    UserType  => 'Customer',
);
$Self->True(
    $Success,
    "Customer session for '$TypedLogin' is deleted",
);
$Self->False(
    _SessionExists(
        UserLogin => $TypedLogin,
        UserType  => 'Customer',
    ),
    "Customer session for '$TypedLogin' is not found",
);

sub _SessionExists {
    my (%Param) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    SESSIONID:
    for my $SessionID ( $SessionObject->GetAllSessionIDs() ) {
        my %SessionData = $SessionObject->GetSessionIDData(
            SessionID => $SessionID,
        );

        next SESSIONID if ( $SessionData{UserLogin} // '' ) ne $Param{UserLogin};
        next SESSIONID if ( $SessionData{UserType}  // '' ) ne $Param{UserType};

        return 1;
    }

    return 0;
}

1;
