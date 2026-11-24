# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
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
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

my $RandomID = $HelperObject->GetRandomID();

my $ScreenConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketNoteToLinkedTicket');
my $Permission   = $ScreenConfig->{Permission} || 'note';

my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();

my $AllowedGroupID = $GroupObject->GroupAdd(
    Name    => 'Allowed-' . $RandomID,
    ValidID => 1,
    UserID  => 1,
);
my $HiddenGroupID = $GroupObject->GroupAdd(
    Name    => 'Hidden-' . $RandomID,
    ValidID => 1,
    UserID  => 1,
);

$Self->True( $AllowedGroupID, "Group Allowed-$RandomID is created" );
$Self->True( $HiddenGroupID,  "Group Hidden-$RandomID is created" );

my %GroupPermission = (
    ro => 1,
);
$GroupPermission{$Permission} = 1;

my $PermissionSet = $GroupObject->PermissionGroupUserAdd(
    GID        => $AllowedGroupID,
    UID        => $TestUserID,
    Permission => \%GroupPermission,
    UserID     => 1,
);
$Self->True( $PermissionSet, "User $TestUserLogin can use the allowed group" );

my $AllowedQueueID = $QueueObject->QueueAdd(
    Name            => 'Allowed-' . $RandomID,
    ValidID         => 1,
    GroupID         => $AllowedGroupID,
    SystemAddressID => 1,
    SalutationID    => 1,
    SignatureID     => 1,
    Comment         => 'Allowed queue',
    UserID          => 1,
);
my $HiddenQueueID = $QueueObject->QueueAdd(
    Name            => 'Hidden-' . $RandomID,
    ValidID         => 1,
    GroupID         => $HiddenGroupID,
    SystemAddressID => 1,
    SalutationID    => 1,
    SignatureID     => 1,
    Comment         => 'Hidden queue',
    UserID          => 1,
);

$Self->True( $AllowedQueueID, "Queue Allowed-$RandomID is created" );
$Self->True( $HiddenQueueID,  "Queue Hidden-$RandomID is created" );

my %Title = (
    Source            => 'Source-' . $RandomID,
    Allowed           => 'AllowedLink-' . $RandomID,
    Hidden            => 'HiddenLink-' . $RandomID,
    Unlinked          => 'UnlinkedNote-' . $RandomID,
    MergeShellHidden  => 'MergeShellHidden-' . $RandomID,
    MergeTargetHidden => 'HiddenMergeTarget-' . $RandomID,
    MergeShellShown   => 'MergeShellShown-' . $RandomID,
    MergeTargetShown  => 'ShownMergeTarget-' . $RandomID,
);

my %QueueID = (
    Source            => $AllowedQueueID,
    Allowed           => $AllowedQueueID,
    Hidden            => $HiddenQueueID,
    Unlinked          => $AllowedQueueID,
    MergeShellHidden  => $AllowedQueueID,
    MergeTargetHidden => $HiddenQueueID,
    MergeShellShown   => $AllowedQueueID,
    MergeTargetShown  => $AllowedQueueID,
);

my %TicketID;
for my $Name ( sort keys %Title ) {
    $TicketID{$Name} = $TicketObject->TicketCreate(
        Title        => $Title{$Name},
        QueueID      => $QueueID{$Name},
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => '123465',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );
    $Self->True( $TicketID{$Name}, "Ticket $Name is created" );
}

for my $TargetName (qw(Allowed Hidden MergeShellHidden MergeShellShown)) {
    my $LinkAdded = $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $TicketID{Source},
        TargetObject => 'Ticket',
        TargetKey    => $TicketID{$TargetName},
        Type         => 'ParentChild',
        State        => 'Valid',
        UserID       => 1,
    );
    $Self->True( $LinkAdded, "Source is linked to $TargetName" );
}

my $HiddenMerged = $TicketObject->TicketMerge(
    MainTicketID  => $TicketID{MergeTargetHidden},
    MergeTicketID => $TicketID{MergeShellHidden},
    UserID        => 1,
);
my $ShownMerged = $TicketObject->TicketMerge(
    MainTicketID  => $TicketID{MergeTargetShown},
    MergeTicketID => $TicketID{MergeShellShown},
    UserID        => 1,
);

$Self->True( $HiddenMerged, 'Merged shell into a hidden target' );
$Self->True( $ShownMerged,  'Merged shell into a permitted target' );

my $ModuleLoaded = $MainObject->Require('Kernel::Modules::AgentTicketNoteToLinkedTicket');
$Self->True( $ModuleLoaded, 'AgentTicketNoteToLinkedTicket is loaded' );

my $ModuleObject = bless {
    Action   => 'AgentTicketNoteToLinkedTicket',
    TicketID => $TicketID{Source},
    UserID   => $TestUserID,
    },
    'Kernel::Modules::AgentTicketNoteToLinkedTicket';

my $LinkedTickets = $ModuleObject->_GetLinkedTickets() || {};

my %AllowedTicket = $TicketObject->TicketGet(
    TicketID      => $TicketID{Allowed},
    DynamicFields => 0,
    UserID        => 1,
);
my %ShownMergeTarget = $TicketObject->TicketGet(
    TicketID      => $TicketID{MergeTargetShown},
    DynamicFields => 0,
    UserID        => 1,
);

$Self->Is(
    $LinkedTickets->{ $TicketID{Allowed} },
    $AllowedTicket{TicketNumber} . ' - ' . $AllowedTicket{Title},
    'Permitted linked ticket is listed with number and title',
);
$Self->Is(
    $LinkedTickets->{ $TicketID{MergeTargetShown} },
    $ShownMergeTarget{TicketNumber} . ' - ' . $ShownMergeTarget{Title},
    'Permitted merge target is listed with number and title',
);

for my $Name (qw(Hidden Unlinked MergeShellHidden MergeTargetHidden MergeShellShown)) {
    $Self->False(
        $LinkedTickets->{ $TicketID{$Name} },
        "Ticket $Name is not offered",
    );
}

my $ListedText = join ' ', values %{$LinkedTickets};
for my $Name (qw(Hidden Unlinked MergeTargetHidden)) {
    $Self->True(
        ( index( $ListedText, $Title{$Name} ) == -1 ),
        "Title of $Name is not shown",
    );
}

$Self->True(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{Allowed}, $TicketID{MergeTargetShown} ],
    ),
    'Permitted linked tickets are accepted',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{Unlinked} ],
    ),
    'Unlinked ticket is rejected',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{Hidden} ],
    ),
    'Linked ticket without permission is rejected',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{Allowed}, $TicketID{Unlinked} ],
    ),
    'One unlinked ticket rejects the whole selection',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{MergeTargetHidden} ],
    ),
    'Merge target without permission is rejected',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [ $TicketID{MergeShellShown} ],
    ),
    'Merged ticket shell is rejected',
);
$Self->True(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => [],
    ),
    'Empty selection is accepted',
);
$Self->False(
    $ModuleObject->_LinkedTicketWritePermitted(
        LinkedTicketIDs => ['abc'],
    ),
    'Non-numeric ticket ID is rejected',
);

1;
