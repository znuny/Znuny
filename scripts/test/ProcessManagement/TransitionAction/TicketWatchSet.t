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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketWatchSet');
my $ZnunyHelperObject      = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

$ConfigObject->{'Ticket::Watcher'} = 1;

my $TicketID = $HelperObject->TicketCreate();
my %Ticket   = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my %User1 = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);
my %User2 = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);
my %User3 = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);

#
# subscribe users by user login
#

my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action    => 'Subscribe',
        UserLogin => join( ', ', $User1{UserLogin}, $User2{UserLogin}, $User3{UserLogin} ),
        UserID    => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

my %Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->True(
        $UserFound,
        "user id on watch list",
    );
}

#
# unsubscribe users by user login
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action    => 'Unsubscribe',
        UserLogin => join( ', ', $User1{UserLogin}, $User2{UserLogin}, $User3{UserLogin} ),
        UserID    => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->False(
        $UserFound,
        "user id is not on watch list",
    );
}

#
# subscribe users by postmaster search
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action           => 'Subscribe',
        PostMasterSearch => join( ', ', $User1{UserEmail}, $User2{UserEmail}, $User3{UserEmail} ),
        UserID           => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->True(
        $UserFound,
        "user id is on watch list",
    );
}

#
# unsubscribe users by postmaster search
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action           => 'Unsubscribe',
        PostMasterSearch => join( ', ', $User1{UserEmail}, $User2{UserEmail}, $User3{UserEmail} ),
        UserID           => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->False(
        $UserFound,
        "user id is not on watch list",
    );
}

#
# subscribe users by user ids
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action  => 'Subscribe',
        UserIDs => join( ', ', $User1{UserID}, $User2{UserID}, $User3{UserID} ),
        UserID  => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->True(
        $UserFound,
        "user id is on watch list",
    );
}

#
# unsubscribe users by user ids
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action  => 'Unsubscribe',
        UserIDs => join( ', ', $User1{UserID}, $User2{UserID}, $User3{UserID} ),
        UserID  => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->False(
        $UserFound,
        "user id is not on watch list",
    );
}

#
# subscribe users by user ids
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action  => 'Subscribe',
        UserIDs => join( ', ', $User1{UserID}, $User2{UserID}, $User3{UserID} ),
        UserID  => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

for my $UserID ( ( $User1{UserID}, $User2{UserID}, $User3{UserID} ) ) {
    my $UserFound = grep { $_ eq $UserID } sort keys %Watch;

    $Self->True(
        $UserFound,
        "user id is on watch list",
    );
}

#
# unsubscribe ALL users
#

$TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        Action => 'UnsubscribeAll',
        UserID => 1,
    },
);

$Self->True(
    $TransitionActionResult,
    "TransitionActionObject->Run()",
);

%Watch = $TicketObject->TicketWatchGet(
    TicketID => $TicketID,
);

$Self->False(
    %Watch ? 1 : 0,
    'ticket watch list is empty',
);

1;
