# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
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

my $ActivityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
my $ActivityDialogObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
my $CloneObject            = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Clone');
my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $EntityObject           = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ProcessObject          = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');
my $TransitionObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');
my $VirtualFSObject        = $Kernel::OM->Get('Kernel::System::VirtualFS');

my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;

my $MissingName = $CloneObject->ProcessClone(
    ID     => 1,
    Name   => '   ',
    UserID => $UserID,
);
$Self->False(
    $MissingName->{Success},
    'ProcessClone() without a name must not succeed.',
);

my $InvalidElement = $CloneObject->EntityClone(
    EntityType => 'Process',
    EntityID   => 'Process-1',
    Name       => 'Ignored',
    UserID     => $UserID,
);
$Self->False(
    $InvalidElement->{Success},
    'EntityClone() must reject an unsupported element type.',
);

my $ProcessEntityID = $EntityObject->EntityIDGenerate(
    EntityType => 'Process',
    UserID     => $UserID,
);
my $ActivityEntityID1 = $EntityObject->EntityIDGenerate(
    EntityType => 'Activity',
    UserID     => $UserID,
);
my $ActivityEntityID2 = $EntityObject->EntityIDGenerate(
    EntityType => 'Activity',
    UserID     => $UserID,
);
my $DialogEntityID1 = $EntityObject->EntityIDGenerate(
    EntityType => 'ActivityDialog',
    UserID     => $UserID,
);
my $DialogEntityID2 = $EntityObject->EntityIDGenerate(
    EntityType => 'ActivityDialog',
    UserID     => $UserID,
);
my $TransitionEntityID = $EntityObject->EntityIDGenerate(
    EntityType => 'Transition',
    UserID     => $UserID,
);
my $TransitionActionEntityID = $EntityObject->EntityIDGenerate(
    EntityType => 'TransitionAction',
    UserID     => $UserID,
);

my $DialogConfig = {
    DescriptionShort => 'Short',
    DescriptionLong  => 'Long text',
    FieldOrder       => [ 'DynamicField_ProcessCloneUnit', 'Title' ],
    Fields           => {
        DynamicField_ProcessCloneUnit => {
            Display      => 1,
            DefaultValue => 'keep-me',
        },
        Title => {
            Display => 2,
        },
    },
    Interface => ['AgentInterface'],
    Scope     => 'Global',
};

my $DialogID1 = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $DialogEntityID1,
    Name     => 'RequestDialog',
    Config   => $DialogConfig,
    UserID   => $UserID,
);
my $DialogID2 = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $DialogEntityID2,
    Name     => 'Second Dialog',
    Config   => {
        %{$DialogConfig},
        DescriptionShort => 'Second',
    },
    UserID => $UserID,
);

$Self->True( $DialogID1 && $DialogID2, 'Activity dialogs for the clone test must be created.' );

my $ActivityID1 = $ActivityObject->ActivityAdd(
    EntityID => $ActivityEntityID1,
    Name     => 'File Request',
    Config   => {
        Scope          => 'Process',
        ScopeEntityID  => $ProcessEntityID,
        ActivityDialog => {
            1 => $DialogEntityID1,
            2 => $DialogEntityID2,
        },
    },
    UserID => $UserID,
);
my $ActivityID2 = $ActivityObject->ActivityAdd(
    EntityID => $ActivityEntityID2,
    Name     => 'Approval',
    Config   => {
        Scope          => 'Global',
        ActivityDialog => {
            1 => $DialogEntityID1,
        },
    },
    UserID => $UserID,
);

$Self->True( $ActivityID1 && $ActivityID2, 'Activities for the clone test must be created.' );

my $TransitionID = $TransitionObject->TransitionAdd(
    EntityID => $TransitionEntityID,
    Name     => 'Approved',
    Config   => {
        Scope     => 'Global',
        Condition => {
            1 => {
                Type   => 'and',
                Fields => {
                    Queue => {
                        Type  => 'String',
                        Match => 'Raw',
                    },
                },
            },
        },
        ConditionLinking => 'and',
    },
    UserID => $UserID,
);
my $TransitionActionID = $TransitionActionObject->TransitionActionAdd(
    EntityID => $TransitionActionEntityID,
    Name     => 'Set state',
    Config   => {
        Scope  => 'Global',
        Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
        Config => {
            State                     => 'open',
            DynamicField_ProcessClone => 'reused',
        },
    },
    UserID => $UserID,
);

$Self->True( $TransitionID && $TransitionActionID, 'Transition and transition action must be created.' );

my $ProcessConfig = {
    Description         => 'Clone me',
    StartActivity       => $ActivityEntityID1,
    StartActivityDialog => $DialogEntityID1,
    Path                => {
        $ActivityEntityID1 => {
            $TransitionEntityID => {
                ActivityEntityID => $ActivityEntityID2,
                TransitionAction => [$TransitionActionEntityID],
            },
        },
        $ActivityEntityID2 => {},
    },
};
my $ProcessLayout = {
    $ActivityEntityID1 => {
        left => 10,
        top  => 20,
    },
    $ActivityEntityID2 => {
        left => 220,
        top  => 20,
    },
};

my $ProcessID = $ProcessObject->ProcessAdd(
    EntityID      => $ProcessEntityID,
    Name          => 'Incident Management',
    StateEntityID => 'S1',
    Layout        => $ProcessLayout,
    Config        => $ProcessConfig,
    UserID        => $UserID,
);
$Self->True( $ProcessID, 'ProcessAdd() must create the source process.' );

my $PrefKey = 'UnitTestIcon' . $RandomID;
$ConfigObject->Set(
    Key   => 'ProcessPreferences###ZZZ-UnitTest-Clone-Icon',
    Value => {
        Module      => 'Kernel::Output::HTML::ProcessPreferences::Generic',
        Label       => 'Icon',
        Desc        => 'Process icon.',
        PrefKey     => $PrefKey,
        ClusterName => 'Category',
        Block       => 'File',
        MaxFiles    => 1,
        FileTypes   => 'png,jpg,jpeg,gif',
    },
);

my $IconContent  = "\x89PNG\r\n\x1a\nClone" . $RandomID;
my $IconFilename = 'VirtualFS::' . $ProcessEntityID . '::' . $PrefKey . '::unittest.png';
my $IconWritten  = $VirtualFSObject->Write(
    Content     => \$IconContent,
    Filename    => $IconFilename,
    Mode        => 'binary',
    Preferences => {
        ContentType => 'image/png',
        Filename    => 'unittest.png',
        Filesize    => length $IconContent,
        FilesizeRaw => length $IconContent,
    },
);
$Self->True( $IconWritten, 'VirtualFS must store the process icon.' );

my $PreferenceSet = $ProcessObject->ProcessPreferencesSet(
    ProcessEntityID => $ProcessEntityID,
    Key             => $PrefKey,
    Value           => $IconFilename,
);
$Self->True( $PreferenceSet, 'ProcessPreferencesSet() must store the process icon.' );

my $ActivityCountBefore = scalar keys %{ $ActivityObject->ActivityList( UserID => $UserID ) };

my $CloneResult = $CloneObject->ProcessClone(
    ID     => $ProcessID,
    Name   => 'Incident Management (Copy)',
    UserID => $UserID,
);
$Self->True( $CloneResult->{Success}, 'ProcessClone() must succeed: ' . ( $CloneResult->{Message} || '' ) );

my $ClonedProcess = $ProcessObject->ProcessGet(
    ID     => $CloneResult->{ProcessID},
    UserID => $UserID,
);
$Self->Is( $ClonedProcess->{Name}, 'Incident Management (Copy)', 'Cloned process must use the submitted name.' );
$Self->Is( $ClonedProcess->{StateEntityID}, 'S2',                'Cloned process must be inactive.' );
$Self->IsNot( $ClonedProcess->{EntityID}, $ProcessEntityID, 'Cloned process must receive a new EntityID.' );

my $OriginalAfter = $ProcessObject->ProcessGet(
    ID     => $ProcessID,
    UserID => $UserID,
);
$Self->Is( $OriginalAfter->{Name},          'Incident Management', 'Original process name must stay unchanged.' );
$Self->Is( $OriginalAfter->{StateEntityID}, 'S1',                  'Original process must stay active.' );
$Self->Is( $OriginalAfter->{Config}->{Description}, 'Clone me', 'Original process description must stay unchanged.' );
$Self->IsDeeply(
    $OriginalAfter->{Config}->{Path},
    $ProcessConfig->{Path},
    'Original process path must stay unchanged.',
);
$Self->Is(
    $OriginalAfter->{Config}->{StartActivity},
    $ActivityEntityID1,
    'Original start activity must stay unchanged.',
);
$Self->Is(
    $OriginalAfter->{Config}->{StartActivityDialog},
    $DialogEntityID1,
    'Original start activity dialog must stay unchanged.',
);

my $SyncState = $EntityObject->EntitySyncStateGet(
    EntityType => 'Process',
    EntityID   => $ClonedProcess->{EntityID},
    UserID     => $UserID,
);
$Self->Is( $SyncState->{SyncState}, 'not_sync', 'Cloned process must be marked as not synchronized.' );

my $ClonedStartActivity = $ClonedProcess->{Config}->{StartActivity};
$Self->True( $ClonedStartActivity, 'Cloned process must keep a start activity.' );
$Self->IsNot( $ClonedStartActivity, $ActivityEntityID1, 'Start activity must point at the cloned activity.' );

my $ClonedActivity1 = $ActivityObject->ActivityGet(
    EntityID => $ClonedStartActivity,
    UserID   => $UserID,
);
$Self->Is( $ClonedActivity1->{Name}, 'File Request', 'Full clone must keep the activity name.' );
$Self->Is(
    $ClonedActivity1->{Config}->{ScopeEntityID},
    $ClonedProcess->{EntityID},
    'Process-scoped activity must point at the cloned process.',
);
$Self->Is(
    $ClonedActivity1->{Config}->{ActivityDialog}->{1},
    $ClonedProcess->{Config}->{StartActivityDialog},
    'Dialog order 1 must stay the start activity dialog.',
);
$Self->IsNot(
    $ClonedActivity1->{Config}->{ActivityDialog}->{1},
    $DialogEntityID1,
    'Cloned activity must not reference the original dialog.',
);
$Self->IsNot(
    $ClonedActivity1->{Config}->{ActivityDialog}->{2},
    $ClonedActivity1->{Config}->{ActivityDialog}->{1},
    'The second dialog must stay a separate clone.',
);

my $ClonedPath                 = $ClonedProcess->{Config}->{Path};
my ($ClonedTransitionEntityID) = sort keys %{ $ClonedPath->{$ClonedStartActivity} };
my $ClonedEdge                 = $ClonedPath->{$ClonedStartActivity}->{$ClonedTransitionEntityID};
$Self->IsNot( $ClonedTransitionEntityID, $TransitionEntityID, 'Path must use the cloned transition.' );
$Self->IsNot(
    $ClonedEdge->{ActivityEntityID},
    $ActivityEntityID2,
    'Path destination must be the cloned activity.',
);
$Self->IsNot(
    $ClonedEdge->{TransitionAction}->[0],
    $TransitionActionEntityID,
    'Path must use the cloned transition action.',
);
$Self->Is(
    scalar @{ $ClonedEdge->{TransitionAction} },
    1,
    'Transition action order must be preserved.',
);

my $SharedDialogUsers = 0;
for my $ActivityEntityID ( sort keys %{$ClonedPath} ) {
    my $Activity = $ActivityObject->ActivityGet(
        EntityID => $ActivityEntityID,
        UserID   => $UserID,
    );
    my $Dialogs = $Activity->{Config}->{ActivityDialog} || {};
    for my $Order ( sort keys %{$Dialogs} ) {
        if ( $Dialogs->{$Order} eq $ClonedActivity1->{Config}->{ActivityDialog}->{1} ) {
            $SharedDialogUsers++;
        }
    }
}
$Self->Is( $SharedDialogUsers, 2, 'A dialog used by two activities must be cloned once and shared by both clones.' );

my $ClonedDialog = $ActivityDialogObject->ActivityDialogGet(
    EntityID => $ClonedActivity1->{Config}->{ActivityDialog}->{1},
    UserID   => $UserID,
);
$Self->Is( $ClonedDialog->{Name}, 'RequestDialog', 'Full clone must keep the dialog name.' );
$Self->Is(
    $ClonedDialog->{Config}->{Fields}->{DynamicField_ProcessCloneUnit}->{DefaultValue},
    'keep-me',
    'Dynamic field reference must be reused, not renamed.',
);
$Self->IsDeeply(
    $ClonedDialog->{Config}->{FieldOrder},
    $DialogConfig->{FieldOrder},
    'Activity dialog field order must be preserved.',
);

my $ClonedTransition = $TransitionObject->TransitionGet(
    EntityID => $ClonedTransitionEntityID,
    UserID   => $UserID,
);
$Self->Is(
    $ClonedTransition->{Config}->{Condition}->{1}->{Fields}->{Queue}->{Match},
    'Raw', 'Transition condition must be preserved.'
);

my $ClonedTransitionAction = $TransitionActionObject->TransitionActionGet(
    EntityID => $ClonedEdge->{TransitionAction}->[0],
    UserID   => $UserID,
);
$Self->Is(
    $ClonedTransitionAction->{Config}->{Config}->{State},
    'open', 'Transition action configuration must be preserved.'
);
$Self->Is(
    $ClonedTransitionAction->{Config}->{Config}->{DynamicField_ProcessClone},
    'reused',
    'Transition action dynamic field reference must be reused.',
);

$Self->Is( $ClonedProcess->{Layout}->{$ClonedStartActivity}->{left}, 10, 'Layout left position must be preserved.' );
$Self->Is( $ClonedProcess->{Layout}->{$ClonedStartActivity}->{top},  20, 'Layout top position must be preserved.' );

my $YAMLObject       = $Kernel::OM->Get('Kernel::System::YAML');
my $ClonedConfigYAML = $YAMLObject->Dump(
    Data => {
        Config => $ClonedProcess->{Config},
        Layout => $ClonedProcess->{Layout},
    },
);
for my $OldEntityID (
    $ProcessEntityID, $ActivityEntityID1, $ActivityEntityID2,
    $DialogEntityID1, $DialogEntityID2,   $TransitionEntityID, $TransitionActionEntityID
    )
{
    $Self->False(
        index( $ClonedConfigYAML, $OldEntityID ) >= 0 ? 1 : 0,
        "Cloned process must not reference original EntityID $OldEntityID.",
    );
}

my %ClonedPreferences = $ProcessObject->ProcessPreferencesGet(
    ProcessEntityID => $ClonedProcess->{EntityID},
);
my $ClonedIcon = $ClonedPreferences{$PrefKey}->[0]->{Content};
$Self->Is(
    ref $ClonedIcon eq 'SCALAR' ? ${$ClonedIcon} : undef,
    $IconContent,
    'Process icon must be copied to the cloned process.',
);
$Self->False(
    ( $ClonedPreferences{$PrefKey}->[0]->{Preferences}->{Filename} || '' ) eq '' ? 1 : 0,
    'Cloned icon must keep its file name.',
);

my %OriginalPreferences = $ProcessObject->ProcessPreferencesGet(
    ProcessEntityID => $ProcessEntityID,
);
$Self->Is(
    $OriginalPreferences{$PrefKey}->[0]->{Preferences}->{Filename} ? 1 : 0,
    1,
    'Original process icon must still exist.',
);

my $ElementBefore = $CloneObject->EntityClone(
    EntityType => 'Activity',
    EntityID   => $ActivityEntityID1,
    Name       => '',
    UserID     => $UserID,
);
$Self->False( $ElementBefore->{Success}, 'EntityClone() without a name must not succeed.' );
$Self->Is(
    scalar keys %{ $ActivityObject->ActivityList( UserID => $UserID ) },
    $ActivityCountBefore + 2,
    'A cancelled element clone must not create another activity. Full clone created two activities.',
);

my $ActivityClone = $CloneObject->EntityClone(
    EntityType => 'Activity',
    EntityID   => $ActivityEntityID1,
    Name       => 'File Request (Copy)',
    UserID     => $UserID,
);
$Self->True( $ActivityClone->{Success}, 'Activity clone must succeed: ' . ( $ActivityClone->{Message} || '' ) );

my $OriginalActivity = $ActivityObject->ActivityGet(
    EntityID => $ActivityEntityID1,
    UserID   => $UserID,
);
$Self->Is(
    $OriginalActivity->{Config}->{ActivityDialog}->{1},
    $DialogEntityID1,
    'Original activity must keep its original dialog.',
);

my $ActivityCopy = $ActivityObject->ActivityGet(
    ID     => $ActivityClone->{ID},
    UserID => $UserID,
);
$Self->Is( $ActivityCopy->{Name}, 'File Request (Copy)', 'Partial activity clone must use the submitted name.' );
$Self->IsNot( $ActivityCopy->{EntityID}, $ActivityEntityID1, 'Partial activity clone must receive a new EntityID.' );
$Self->Is(
    $ActivityCopy->{Config}->{ScopeEntityID},
    $ProcessEntityID,
    'Partial clone must keep the original process scope.',
);

my $CopiedDialog = $ActivityDialogObject->ActivityDialogGet(
    EntityID => $ActivityCopy->{Config}->{ActivityDialog}->{1},
    UserID   => $UserID,
);
$Self->Is( $CopiedDialog->{Name}, 'RequestDialog (Clone)', 'Related dialog must get the (Clone) suffix.' );
$Self->IsNot( $CopiedDialog->{EntityID}, $DialogEntityID1, 'Related dialog must receive a new EntityID.' );
$Self->Is(
    $CopiedDialog->{Config}->{Scope},
    'Process',
    'Related dialog must assume the scope of the cloned activity.',
);
$Self->Is(
    $CopiedDialog->{Config}->{ScopeEntityID},
    $ProcessEntityID,
    'Related dialog must assume the ScopeEntityID of the cloned activity.',
);

my $CopiedSecondDialog = $ActivityDialogObject->ActivityDialogGet(
    EntityID => $ActivityCopy->{Config}->{ActivityDialog}->{2},
    UserID   => $UserID,
);
$Self->Is(
    $CopiedSecondDialog->{Name},
    'Second Dialog (Clone)',
    'Related dialog with spaces must get the (Clone) suffix.'
);
$Self->Is(
    $CopiedSecondDialog->{Config}->{Scope},
    'Process',
    'Every related dialog must assume the scope of the cloned activity.',
);
$Self->Is(
    $CopiedSecondDialog->{Config}->{ScopeEntityID},
    $ProcessEntityID,
    'Every related dialog must assume the ScopeEntityID of the cloned activity.',
);

my $DialogClone = $CloneObject->EntityClone(
    EntityType => 'ActivityDialog',
    EntityID   => $DialogEntityID1,
    Name       => 'RequestDialog (Copy)',
    UserID     => $UserID,
);
$Self->True( $DialogClone->{Success}, 'Activity dialog clone must succeed.' );
my $DialogCopy = $ActivityDialogObject->ActivityDialogGet(
    ID     => $DialogClone->{ID},
    UserID => $UserID,
);
$Self->Is(
    $DialogCopy->{Config}->{Fields}->{DynamicField_ProcessCloneUnit}->{DefaultValue},
    'keep-me',
    'Cloned activity dialog must keep dynamic field values.',
);
$Self->Is(
    $DialogCopy->{Config}->{Scope},
    'Global',
    'A cloned activity dialog must keep its own scope.',
);
$Self->False(
    $DialogCopy->{Config}->{ScopeEntityID} ? 1 : 0,
    'A global activity dialog clone must not keep a ScopeEntityID.',
);

my $TransitionClone = $CloneObject->EntityClone(
    EntityType => 'Transition',
    EntityID   => $TransitionEntityID,
    Name       => 'Approved_Copy',
    UserID     => $UserID,
);
$Self->True( $TransitionClone->{Success}, 'Transition clone must succeed.' );
my $TransitionCopy = $TransitionObject->TransitionGet(
    ID     => $TransitionClone->{ID},
    UserID => $UserID,
);
$Self->Is(
    $TransitionCopy->{Config}->{Condition}->{1}->{Fields}->{Queue}->{Match},
    'Raw', 'Cloned transition must keep its condition.'
);
$Self->Is(
    $TransitionCopy->{Config}->{Scope},
    'Global',
    'A cloned transition must keep its own scope.',
);

my $ActionClone = $CloneObject->EntityClone(
    EntityType => 'TransitionAction',
    EntityID   => $TransitionActionEntityID,
    Name       => 'Set state (Copy)',
    UserID     => $UserID,
);
$Self->True( $ActionClone->{Success}, 'Transition action clone must succeed.' );
my $ActionCopy = $TransitionActionObject->TransitionActionGet(
    ID     => $ActionClone->{ID},
    UserID => $UserID,
);
$Self->Is( $ActionCopy->{Config}->{Config}->{State}, 'open', 'Cloned transition action must keep its configuration.' );
$Self->True(
    $ActionClone->{Config}->{TransitionAction}->{ $ActionCopy->{EntityID} },
    'Canvas config must contain the cloned transition action.'
);
$Self->Is(
    $ActionCopy->{Config}->{Scope},
    'Global',
    'A cloned transition action must keep its own scope.',
);

my $ScopedDialogEntityID = $EntityObject->EntityIDGenerate(
    EntityType => 'ActivityDialog',
    UserID     => $UserID,
);
my $GlobalActivityEntityID = $EntityObject->EntityIDGenerate(
    EntityType => 'Activity',
    UserID     => $UserID,
);
my $ScopedDialogID = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $ScopedDialogEntityID,
    Name     => 'Process only dialog',
    Config   => {
        DescriptionShort => 'Scoped',
        DescriptionLong  => 'Scoped dialog',
        Fields           => {
            Title => {
                Display => 1,
            },
        },
        FieldOrder    => ['Title'],
        Scope         => 'Process',
        ScopeEntityID => $ProcessEntityID,
        Interface     => ['AgentInterface'],
    },
    UserID => $UserID,
);
my $GlobalActivityID = $ActivityObject->ActivityAdd(
    EntityID => $GlobalActivityEntityID,
    Name     => 'Global activity',
    Config   => {
        Scope          => 'Global',
        ActivityDialog => {
            1 => $ScopedDialogEntityID,
        },
    },
    UserID => $UserID,
);
$Self->True( $ScopedDialogID && $GlobalActivityID, 'Global activity with a process-scoped dialog must be created.' );

my $GlobalActivityClone = $CloneObject->EntityClone(
    EntityType => 'Activity',
    EntityID   => $GlobalActivityEntityID,
    Name       => 'Global activity (Clone)',
    UserID     => $UserID,
);
$Self->True(
    $GlobalActivityClone->{Success},
    'Global activity clone must succeed: ' . ( $GlobalActivityClone->{Message} || '' ),
);
my $GlobalActivityCopy = $ActivityObject->ActivityGet(
    ID     => $GlobalActivityClone->{ID},
    UserID => $UserID,
);
$Self->Is( $GlobalActivityCopy->{Config}->{Scope}, 'Global', 'Cloned global activity must stay global.' );
$Self->False(
    $GlobalActivityCopy->{Config}->{ScopeEntityID} ? 1 : 0,
    'Cloned global activity must not keep a ScopeEntityID.',
);
my $ScopedDialogCopy = $ActivityDialogObject->ActivityDialogGet(
    EntityID => $GlobalActivityCopy->{Config}->{ActivityDialog}->{1},
    UserID   => $UserID,
);
$Self->Is(
    $ScopedDialogCopy->{Config}->{Scope},
    'Global',
    'Related dialog must assume the global scope of the cloned activity.',
);
$Self->False(
    $ScopedDialogCopy->{Config}->{ScopeEntityID} ? 1 : 0,
    'Related dialog must drop the process ScopeEntityID of the source dialog.',
);

1;
