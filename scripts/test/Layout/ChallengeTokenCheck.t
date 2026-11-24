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

use CGI ();

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'SessionCSRFProtection',
    Value => 1,
);

my ( $AgentLogin, $AgentUserID ) = $HelperObject->TestUserCreate(
    Groups => ['users'],
);
$Self->True(
    $AgentUserID,
    'TestUserCreate()',
);

my %SessionIDs;
$SessionIDs{Agent} = $SessionObject->CreateSessionID(
    UserType  => 'User',
    UserLogin => $AgentLogin,
    UserID    => $AgentUserID,
);
$SessionIDs{AgentSecond} = $SessionObject->CreateSessionID(
    UserType  => 'User',
    UserLogin => $AgentLogin,
    UserID    => $AgentUserID,
);

# Customer sessions use the login as UserID, so a customer login equal to the agent's numeric ID
#   results in a session with the same UserID.
$SessionIDs{Customer} = $SessionObject->CreateSessionID(
    UserType  => 'Customer',
    UserLogin => $AgentUserID,
    UserID    => $AgentUserID,
);

my %ChallengeTokens;
for my $Session ( sort keys %SessionIDs ) {
    $Self->True(
        $SessionIDs{$Session},
        "CreateSessionID() $Session",
    );

    my %SessionData = $SessionObject->GetSessionIDData(
        SessionID => $SessionIDs{$Session},
    );
    $ChallengeTokens{$Session} = $SessionData{UserChallengeToken};
}

my @Tests = (
    {
        Name           => 'Token of the current agent session is accepted',
        ChallengeToken => $ChallengeTokens{Agent},
        Success        => 1,
    },
    {
        Name           => 'Token of another session of the same agent is accepted',
        ChallengeToken => $ChallengeTokens{AgentSecond},
        Success        => 1,
    },
    {
        Name           => 'Token of a customer session with the same UserID is rejected',
        ChallengeToken => $ChallengeTokens{Customer},
        Success        => 0,
    },
    {
        Name           => 'Random token is rejected',
        ChallengeToken => $HelperObject->GetRandomID(),
        Success        => 0,
    },
);

for my $Test (@Tests) {
    CGI::initialize_globals();
    $Kernel::OM->ObjectsDiscard(
        Objects => [ 'Kernel::System::Web::Request', 'Kernel::Output::HTML::Layout' ],
    );
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::Web::Request' => {
            WebRequest => CGI->new("ChallengeToken=$Test->{ChallengeToken}"),
        },
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    $LayoutObject->{UserID}             = $AgentUserID;
    $LayoutObject->{UserType}           = 'User';
    $LayoutObject->{UserChallengeToken} = $ChallengeTokens{Agent};

    my $FatalErrorCalled = 0;
    my $Success;
    {
        no warnings 'redefine';    ## no critic

        local *Kernel::Output::HTML::Layout::FatalError = sub {
            $FatalErrorCalled = 1;
            return;
        };

        $Success = $LayoutObject->ChallengeTokenCheck();
    }

    if ( $Test->{Success} ) {
        $Self->True(
            $Success,
            "ChallengeTokenCheck() - $Test->{Name}",
        );
        $Self->False(
            $FatalErrorCalled,
            "ChallengeTokenCheck() - $Test->{Name} - no FatalError",
        );
    }
    else {
        $Self->False(
            $Success,
            "ChallengeTokenCheck() - $Test->{Name}",
        );
        $Self->True(
            $FatalErrorCalled,
            "ChallengeTokenCheck() - $Test->{Name} - FatalError",
        );
    }
}

for my $Session ( sort keys %SessionIDs ) {
    $SessionObject->RemoveSessionID(
        SessionID => $SessionIDs{$Session},
    );
}

# Cleanup is done by RestoreDatabase.

1;
