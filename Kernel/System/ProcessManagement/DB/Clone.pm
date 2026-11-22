# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::DB::Clone;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::ProcessManagement::DB::Activity',
    'Kernel::System::ProcessManagement::DB::ActivityDialog',
    'Kernel::System::ProcessManagement::DB::Entity',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::ProcessManagement::DB::Transition',
    'Kernel::System::ProcessManagement::DB::TransitionAction',
    'Kernel::System::VirtualFS',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::ProcessManagement::DB::Clone - clone processes and process elements

=head1 DESCRIPTION

Full process clone creates an independent inactive copy. Every contained activity, activity
dialog, transition and transition action receives a new EntityID. References inside the process,
including path, layout, start activity and process scope, point at the cloned entities.

Copy of a process only duplicates the process container and keeps the original element EntityIDs.
Clone does not do that.

Dynamic fields referenced by dialogs or transition actions are reused, not duplicated.
Process icons and other file preferences are stored again under the new process EntityID.
ACLs, ticket history and statistics are not copied.
Dialog order and the process path are preserved.

Partial clone duplicates one element. Cloning an activity also clones its activity dialogs.
Those dialogs assume the scope of the activity being cloned.
The original element stays unchanged. Nothing is written until a name is supplied.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CloneObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Clone');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessClone()

Create an independent inactive copy of a process.

    my $Result = $CloneObject->ProcessClone(
        ID     => 123,                              # ID or EntityID required
        EntityID => 'Process-9690ae9ae455d8614d570149b8ab1199',
        Name   => 'Incident Management (Clone)',    # required, chosen by the user
        UserID => 1,
    );

Returns:

    $Result = {
        Success   => 1,
        ProcessID => 456,
        EntityID  => 'Process-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    };

Nothing is created when Name is missing or the clone fails. A failed clone is rolled back.

=cut

sub ProcessClone {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $EntityObject  = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

    if ( !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return {
            Success => 0,
            Message => 'Need UserID!',
        };
    }

    if ( !$Param{ID} && !$Param{EntityID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID or EntityID!',
        );
        return {
            Success => 0,
            Message => 'Need ID or EntityID!',
        };
    }

    my $Name = $Param{Name} // '';
    $Name =~ s{\A\s+|\s+\z}{}xms;
    if ( !IsStringWithData($Name) ) {
        return {
            Success => 0,
            Message => 'Need Name!',
        };
    }
    if ( length $Name > 200 ) {
        return {
            Success => 0,
            Message => 'The name must not exceed 200 characters.',
        };
    }
    $Param{Name} = $Name;

    my $Process = $ProcessObject->ProcessGet(
        ID       => $Param{ID},
        EntityID => $Param{EntityID},
        UserID   => $Param{UserID},
    );
    if ( !IsHashRefWithData($Process) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Could not find the process to clone.',
        );
        return {
            Success => 0,
            Message => 'Could not find the process to clone.',
        };
    }

    my $Collected = $Self->_ProcessPartsCollect(
        Process => $Process,
        UserID  => $Param{UserID},
    );
    if ( !$Collected->{Success} ) {
        return {
            Success => 0,
            Message => $Collected->{Message},
        };
    }

    my $EntityMap = $Self->_EntityMapCreate(
        ProcessEntityID => $Process->{EntityID},
        EntityIDs       => $Collected->{EntityIDs},
        UserID          => $Param{UserID},
    );
    if ( !$EntityMap ) {
        return {
            Success => 0,
            Message => 'Could not generate EntityIDs for the cloned process.',
        };
    }

    my $Bundle = {
        Process => {
            EntityID      => $Process->{EntityID},
            Name          => $Process->{Name},
            StateEntityID => $Process->{StateEntityID},
            Layout        => $Process->{Layout} || {},
            Config        => $Process->{Config} || {},
        },
        Activities        => $Collected->{Activities},
        ActivityDialogs   => $Collected->{ActivityDialogs},
        Transitions       => $Collected->{Transitions},
        TransitionActions => $Collected->{TransitionActions},
    };

    my $ClonedBundle = $Self->_StructureClone($Bundle);
    if ( ref $ClonedBundle ne 'HASH' ) {
        return {
            Success => 0,
            Message => 'Could not copy the process configuration.',
        };
    }

    my $Remapped = $Self->_DataRemap( $ClonedBundle, $EntityMap );
    $Remapped->{Process}->{Name}          = $Param{Name};
    $Remapped->{Process}->{StateEntityID} = 'S2';
    $Remapped->{Process}->{EntityID}      = $EntityMap->{ $Process->{EntityID} };

    my %Added;

    my %PartList = (
        Activity         => 'Activities',
        ActivityDialog   => 'ActivityDialogs',
        Transition       => 'Transitions',
        TransitionAction => 'TransitionActions',
    );

    PART:
    for my $Part (qw(ActivityDialog Transition TransitionAction Activity)) {
        my $Items = $Remapped->{ $PartList{$Part} } || {};

        ENTITYID:
        for my $EntityID ( sort keys %{$Items} ) {
            next ENTITYID if !$EntityID;

            my $Item = $Items->{$EntityID};
            my $ID   = $Self->_PartAdd(
                EntityType => $Part,
                EntityID   => $Item->{EntityID},
                Name       => $Item->{Name},
                Config     => $Item->{Config},
                UserID     => $Param{UserID},
            );
            if ( !$ID ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => "Could not clone $Part.",
                );
            }

            $Added{$Part}->{ $Item->{EntityID} } = $ID;

            my $Synced = $EntityObject->EntitySyncStateSet(
                EntityType => $Part,
                EntityID   => $Item->{EntityID},
                SyncState  => 'not_sync',
                UserID     => $Param{UserID},
            );
            if ( !$Synced ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => "Could not set the sync state for cloned $Part.",
                );
            }
        }
    }

    my $ProcessID = $ProcessObject->ProcessAdd(
        EntityID      => $Remapped->{Process}->{EntityID},
        Name          => $Remapped->{Process}->{Name},
        StateEntityID => $Remapped->{Process}->{StateEntityID},
        Layout        => $Remapped->{Process}->{Layout} || {},
        Config        => $Remapped->{Process}->{Config} || {},
        UserID        => $Param{UserID},
    );
    if ( !$ProcessID ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            UserID  => $Param{UserID},
            Message => 'Could not create the cloned process.',
        );
    }
    $Added{Process}->{ $Remapped->{Process}->{EntityID} } = $ProcessID;

    my $ProcessSynced = $EntityObject->EntitySyncStateSet(
        EntityType => 'Process',
        EntityID   => $Remapped->{Process}->{EntityID},
        SyncState  => 'not_sync',
        UserID     => $Param{UserID},
    );
    if ( !$ProcessSynced ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            UserID  => $Param{UserID},
            Message => 'Could not set the sync state for the cloned process.',
        );
    }

    my $PreferenceResult = $Self->_ProcessPreferencesClone(
        ProcessEntityID    => $Process->{EntityID},
        NewProcessEntityID => $Remapped->{Process}->{EntityID},
        UserID             => $Param{UserID},
    );
    if ( !$PreferenceResult->{Success} ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            Files   => $PreferenceResult->{Files},
            UserID  => $Param{UserID},
            Message => $PreferenceResult->{Message},
        );
    }

    return {
        Success   => 1,
        ProcessID => $ProcessID,
        EntityID  => $Remapped->{Process}->{EntityID},
    };
}

=head2 EntityClone()

Clone one process element. Activity clone also clones the activity dialogs of that activity.
The caller must pass the name. No data is written when the name is missing.

    my $Result = $CloneObject->EntityClone(
        EntityType => 'Activity',          # Activity, ActivityDialog, Transition, TransitionAction
        EntityID   => 'Activity-9690ae9ae455d8614d570149b8ab1199',
        Name       => 'Approval (Clone)',
        UserID     => 1,
    );

=cut

sub EntityClone {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return {
            Success => 0,
            Message => 'Need UserID!',
        };
    }

    my %AllowedEntityType = (
        Activity         => 1,
        ActivityDialog   => 1,
        Transition       => 1,
        TransitionAction => 1,
    );
    if ( !$Param{EntityType} || !$AllowedEntityType{ $Param{EntityType} } ) {
        return {
            Success => 0,
            Message => 'Invalid process element type.',
        };
    }
    if ( !IsStringWithData( $Param{EntityID} ) ) {
        return {
            Success => 0,
            Message => 'Need EntityID!',
        };
    }

    my $Name = $Param{Name} // '';
    $Name =~ s{\A\s+|\s+\z}{}xms;
    if ( !IsStringWithData($Name) ) {
        return {
            Success => 0,
            Message => 'Need Name!',
        };
    }
    if ( length $Name > 200 ) {
        return {
            Success => 0,
            Message => 'The name must not exceed 200 characters.',
        };
    }
    $Param{Name} = $Name;

    if ( $Param{EntityType} eq 'Activity' ) {
        return $Self->_ActivityClone(%Param);
    }
    if ( $Param{EntityType} eq 'ActivityDialog' ) {
        return $Self->_ActivityDialogClone(%Param);
    }
    if ( $Param{EntityType} eq 'Transition' ) {
        return $Self->_TransitionClone(%Param);
    }

    return $Self->_TransitionActionClone(%Param);
}

sub _ActivityClone {
    my ( $Self, %Param ) = @_;

    my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
    my $EntityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');

    my $Activity = $ActivityObject->ActivityGet(
        EntityID => $Param{EntityID},
        UserID   => $Param{UserID},
    );
    if ( !IsHashRefWithData($Activity) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not find Activity $Param{EntityID} to clone.",
        );
        return {
            Success => 0,
            Message => 'Could not find the process element to clone.',
        };
    }

    my $Config = $Self->_StructureClone( $Activity->{Config} || {} );
    if ( ref $Config ne 'HASH' ) {
        $Config = {};
    }
    $Config->{ActivityDialog} ||= {};

    my %DialogBySource;
    my @CreatedDialogs;
    my %Added;

    ORDER:
    for my $Order ( sort { $a <=> $b } keys %{ $Config->{ActivityDialog} } ) {
        my $SourceEntityID = $Config->{ActivityDialog}->{$Order};
        next ORDER if !$SourceEntityID;

        if ( !$DialogBySource{$SourceEntityID} ) {
            my $Dialog = $ActivityDialogObject->ActivityDialogGet(
                EntityID => $SourceEntityID,
                UserID   => $Param{UserID},
            );
            if ( !IsHashRefWithData($Dialog) ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => 'Could not find an activity dialog of the activity to clone.',
                );
            }

            my $DialogConfig = $Self->_StructureClone( $Dialog->{Config} || {} );
            $Self->_ScopeApply(
                Config        => $DialogConfig,
                Scope         => $Config->{Scope},
                ScopeEntityID => $Config->{ScopeEntityID},
            );
            my $NewEntityID = $EntityObject->EntityIDGenerate(
                EntityType => 'ActivityDialog',
                UserID     => $Param{UserID},
            );
            if ( !$NewEntityID ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => 'Could not generate an EntityID for the cloned activity dialog.',
                );
            }

            my $DialogName = $Self->_CloneName( $Dialog->{Name} );
            my $DialogID   = $ActivityDialogObject->ActivityDialogAdd(
                EntityID => $NewEntityID,
                Name     => $DialogName,
                Config   => $DialogConfig,
                UserID   => $Param{UserID},
            );
            if ( !$DialogID ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => 'Could not clone an activity dialog.',
                );
            }

            $Added{ActivityDialog}->{$NewEntityID} = $DialogID;
            my $Synced = $EntityObject->EntitySyncStateSet(
                EntityType => 'ActivityDialog',
                EntityID   => $NewEntityID,
                SyncState  => 'not_sync',
                UserID     => $Param{UserID},
            );
            if ( !$Synced ) {
                return $Self->_CloneRollBack(
                    Added   => \%Added,
                    UserID  => $Param{UserID},
                    Message => 'Could not set the sync state for the cloned activity dialog.',
                );
            }

            $DialogBySource{$SourceEntityID} = $NewEntityID;
            push @CreatedDialogs, $NewEntityID;
        }

        $Config->{ActivityDialog}->{$Order} = $DialogBySource{$SourceEntityID};
    }

    my $NewEntityID = $EntityObject->EntityIDGenerate(
        EntityType => 'Activity',
        UserID     => $Param{UserID},
    );
    if ( !$NewEntityID ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            UserID  => $Param{UserID},
            Message => 'Could not generate an EntityID for the cloned activity.',
        );
    }

    my $ActivityID = $ActivityObject->ActivityAdd(
        EntityID => $NewEntityID,
        Name     => $Param{Name},
        Config   => $Config,
        UserID   => $Param{UserID},
    );
    if ( !$ActivityID ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            UserID  => $Param{UserID},
            Message => 'Could not clone the activity.',
        );
    }
    $Added{Activity}->{$NewEntityID} = $ActivityID;

    my $Synced = $EntityObject->EntitySyncStateSet(
        EntityType => 'Activity',
        EntityID   => $NewEntityID,
        SyncState  => 'not_sync',
        UserID     => $Param{UserID},
    );
    if ( !$Synced ) {
        return $Self->_CloneRollBack(
            Added   => \%Added,
            UserID  => $Param{UserID},
            Message => 'Could not set the sync state for the cloned activity.',
        );
    }

    my @CanvasEntities = (
        {
            EntityType => 'Activity',
            EntityID   => $NewEntityID,
        },
    );
    for my $DialogEntityID (@CreatedDialogs) {
        push @CanvasEntities, {
            EntityType => 'ActivityDialog',
            EntityID   => $DialogEntityID,
        };
    }

    return {
        Success    => 1,
        ID         => $ActivityID,
        EntityID   => $NewEntityID,
        EntityType => 'Activity',
        Config     => $Self->_CanvasConfig(
            Entities => \@CanvasEntities,
            UserID   => $Param{UserID},
        ),
    };
}

sub _ActivityDialogClone {
    my ( $Self, %Param ) = @_;

    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
    my $EntityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');

    my $Dialog = $ActivityDialogObject->ActivityDialogGet(
        EntityID => $Param{EntityID},
        UserID   => $Param{UserID},
    );
    if ( !IsHashRefWithData($Dialog) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not find ActivityDialog $Param{EntityID} to clone.",
        );
        return {
            Success => 0,
            Message => 'Could not find the process element to clone.',
        };
    }

    my $Config      = $Self->_StructureClone( $Dialog->{Config} || {} );
    my $NewEntityID = $EntityObject->EntityIDGenerate(
        EntityType => 'ActivityDialog',
        UserID     => $Param{UserID},
    );
    if ( !$NewEntityID ) {
        return {
            Success => 0,
            Message => 'Could not generate an EntityID for the cloned activity dialog.',
        };
    }

    my $DialogID = $ActivityDialogObject->ActivityDialogAdd(
        EntityID => $NewEntityID,
        Name     => $Param{Name},
        Config   => $Config,
        UserID   => $Param{UserID},
    );
    if ( !$DialogID ) {
        return {
            Success => 0,
            Message => 'Could not clone the activity dialog.',
        };
    }

    my $Synced = $EntityObject->EntitySyncStateSet(
        EntityType => 'ActivityDialog',
        EntityID   => $NewEntityID,
        SyncState  => 'not_sync',
        UserID     => $Param{UserID},
    );
    if ( !$Synced ) {
        $ActivityDialogObject->ActivityDialogDelete(
            ID     => $DialogID,
            UserID => $Param{UserID},
        );
        return {
            Success => 0,
            Message => 'Could not set the sync state for the cloned activity dialog.',
        };
    }

    return {
        Success    => 1,
        ID         => $DialogID,
        EntityID   => $NewEntityID,
        EntityType => 'ActivityDialog',
        Config     => $Self->_CanvasConfig(
            Entities => [
                {
                    EntityType => 'ActivityDialog',
                    EntityID   => $NewEntityID,
                },
            ],
            UserID => $Param{UserID},
        ),
    };
}

sub _TransitionClone {
    my ( $Self, %Param ) = @_;

    my $EntityObject     = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $TransitionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');

    my $Transition = $TransitionObject->TransitionGet(
        EntityID => $Param{EntityID},
        UserID   => $Param{UserID},
    );
    if ( !IsHashRefWithData($Transition) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not find Transition $Param{EntityID} to clone.",
        );
        return {
            Success => 0,
            Message => 'Could not find the process element to clone.',
        };
    }

    my $Config      = $Self->_StructureClone( $Transition->{Config} || {} );
    my $NewEntityID = $EntityObject->EntityIDGenerate(
        EntityType => 'Transition',
        UserID     => $Param{UserID},
    );
    if ( !$NewEntityID ) {
        return {
            Success => 0,
            Message => 'Could not generate an EntityID for the cloned transition.',
        };
    }

    my $TransitionID = $TransitionObject->TransitionAdd(
        EntityID => $NewEntityID,
        Name     => $Param{Name},
        Config   => $Config,
        UserID   => $Param{UserID},
    );
    if ( !$TransitionID ) {
        return {
            Success => 0,
            Message => 'Could not clone the transition.',
        };
    }

    my $Synced = $EntityObject->EntitySyncStateSet(
        EntityType => 'Transition',
        EntityID   => $NewEntityID,
        SyncState  => 'not_sync',
        UserID     => $Param{UserID},
    );
    if ( !$Synced ) {
        $TransitionObject->TransitionDelete(
            ID     => $TransitionID,
            UserID => $Param{UserID},
        );
        return {
            Success => 0,
            Message => 'Could not set the sync state for the cloned transition.',
        };
    }

    return {
        Success    => 1,
        ID         => $TransitionID,
        EntityID   => $NewEntityID,
        EntityType => 'Transition',
        Config     => $Self->_CanvasConfig(
            Entities => [
                {
                    EntityType => 'Transition',
                    EntityID   => $NewEntityID,
                },
            ],
            UserID => $Param{UserID},
        ),
    };
}

sub _TransitionActionClone {
    my ( $Self, %Param ) = @_;

    my $EntityObject           = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject              = $Kernel::OM->Get('Kernel::System::Log');
    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');

    my $TransitionAction = $TransitionActionObject->TransitionActionGet(
        EntityID => $Param{EntityID},
        UserID   => $Param{UserID},
    );
    if ( !IsHashRefWithData($TransitionAction) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not find TransitionAction $Param{EntityID} to clone.",
        );
        return {
            Success => 0,
            Message => 'Could not find the process element to clone.',
        };
    }

    my $Config      = $Self->_StructureClone( $TransitionAction->{Config} || {} );
    my $NewEntityID = $EntityObject->EntityIDGenerate(
        EntityType => 'TransitionAction',
        UserID     => $Param{UserID},
    );
    if ( !$NewEntityID ) {
        return {
            Success => 0,
            Message => 'Could not generate an EntityID for the cloned transition action.',
        };
    }

    my $TransitionActionID = $TransitionActionObject->TransitionActionAdd(
        EntityID => $NewEntityID,
        Name     => $Param{Name},
        Config   => $Config,
        UserID   => $Param{UserID},
    );
    if ( !$TransitionActionID ) {
        return {
            Success => 0,
            Message => 'Could not clone the transition action.',
        };
    }

    my $Synced = $EntityObject->EntitySyncStateSet(
        EntityType => 'TransitionAction',
        EntityID   => $NewEntityID,
        SyncState  => 'not_sync',
        UserID     => $Param{UserID},
    );
    if ( !$Synced ) {
        $TransitionActionObject->TransitionActionDelete(
            ID     => $TransitionActionID,
            UserID => $Param{UserID},
        );
        return {
            Success => 0,
            Message => 'Could not set the sync state for the cloned transition action.',
        };
    }

    return {
        Success    => 1,
        ID         => $TransitionActionID,
        EntityID   => $NewEntityID,
        EntityType => 'TransitionAction',
        Config     => $Self->_CanvasConfig(
            Entities => [
                {
                    EntityType => 'TransitionAction',
                    EntityID   => $NewEntityID,
                },
            ],
            UserID => $Param{UserID},
        ),
    };
}

sub _ProcessPartsCollect {
    my ( $Self, %Param ) = @_;

    my $ActivityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
    my $ActivityDialogObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
    my $LogObject              = $Kernel::OM->Get('Kernel::System::Log');
    my $TransitionObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');
    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');

    my $Process   = $Param{Process};
    my %EntityIDs = (
        Activity         => {},
        ActivityDialog   => {},
        Transition       => {},
        TransitionAction => {},
    );

    my $Path = $Process->{Config}->{Path} || {};
    ACTIVITY:
    for my $ActivityEntityID ( sort keys %{$Path} ) {
        $EntityIDs{Activity}->{$ActivityEntityID} = 1;
        my $Transitions = $Path->{$ActivityEntityID} || {};

        TRANSITION:
        for my $TransitionEntityID ( sort keys %{$Transitions} ) {
            $EntityIDs{Transition}->{$TransitionEntityID} = 1;
            my $Edge = $Transitions->{$TransitionEntityID} || {};
            if ( $Edge->{ActivityEntityID} ) {
                $EntityIDs{Activity}->{ $Edge->{ActivityEntityID} } = 1;
            }

            my $TransitionActions = $Edge->{TransitionAction} || [];
            TRANSITIONACTION:
            for my $TransitionActionEntityID ( @{$TransitionActions} ) {
                next TRANSITIONACTION if !$TransitionActionEntityID;
                $EntityIDs{TransitionAction}->{$TransitionActionEntityID} = 1;
            }
        }
    }

    my $Layout = $Process->{Layout} || {};
    LAYOUTACTIVITY:
    for my $ActivityEntityID ( sort keys %{$Layout} ) {
        $EntityIDs{Activity}->{$ActivityEntityID} = 1;
    }

    if ( $Process->{Config}->{StartActivity} ) {
        $EntityIDs{Activity}->{ $Process->{Config}->{StartActivity} } = 1;
    }
    if ( $Process->{Config}->{StartActivityDialog} ) {
        $EntityIDs{ActivityDialog}->{ $Process->{Config}->{StartActivityDialog} } = 1;
    }

    my %Activities;
    ACTIVITYLOAD:
    for my $ActivityEntityID ( sort keys %{ $EntityIDs{Activity} } ) {
        my $Activity = $ActivityObject->ActivityGet(
            EntityID => $ActivityEntityID,
            UserID   => $Param{UserID},
        );
        if ( !IsHashRefWithData($Activity) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not get Activity $ActivityEntityID for process clone.",
            );
            return {
                Success => 0,
                Message => 'Could not load an activity of the process to clone.',
            };
        }
        $Activities{$ActivityEntityID} = $Activity;

        my $ActivityDialogs = $Activity->{Config}->{ActivityDialog} || {};
        ORDER:
        for my $Order ( sort keys %{$ActivityDialogs} ) {
            my $ActivityDialogEntityID = $ActivityDialogs->{$Order};
            next ORDER if !$ActivityDialogEntityID;
            $EntityIDs{ActivityDialog}->{$ActivityDialogEntityID} = 1;
        }
    }

    my %ActivityDialogs;
    DIALOGLOAD:
    for my $ActivityDialogEntityID ( sort keys %{ $EntityIDs{ActivityDialog} } ) {
        my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
            EntityID => $ActivityDialogEntityID,
            UserID   => $Param{UserID},
        );
        if ( !IsHashRefWithData($ActivityDialog) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not get ActivityDialog $ActivityDialogEntityID for process clone.",
            );
            return {
                Success => 0,
                Message => 'Could not load an activity dialog of the process to clone.',
            };
        }
        $ActivityDialogs{$ActivityDialogEntityID} = $ActivityDialog;
    }

    my %Transitions;
    TRANSITIONLOAD:
    for my $TransitionEntityID ( sort keys %{ $EntityIDs{Transition} } ) {
        my $Transition = $TransitionObject->TransitionGet(
            EntityID => $TransitionEntityID,
            UserID   => $Param{UserID},
        );
        if ( !IsHashRefWithData($Transition) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not get Transition $TransitionEntityID for process clone.",
            );
            return {
                Success => 0,
                Message => 'Could not load a transition of the process to clone.',
            };
        }
        $Transitions{$TransitionEntityID} = $Transition;
    }

    my %TransitionActions;
    TRANSITIONACTIONLOAD:
    for my $TransitionActionEntityID ( sort keys %{ $EntityIDs{TransitionAction} } ) {
        my $TransitionAction = $TransitionActionObject->TransitionActionGet(
            EntityID => $TransitionActionEntityID,
            UserID   => $Param{UserID},
        );
        if ( !IsHashRefWithData($TransitionAction) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not get TransitionAction $TransitionActionEntityID for process clone.",
            );
            return {
                Success => 0,
                Message => 'Could not load a transition action of the process to clone.',
            };
        }
        $TransitionActions{$TransitionActionEntityID} = $TransitionAction;
    }

    return {
        Success           => 1,
        EntityIDs         => \%EntityIDs,
        Activities        => \%Activities,
        ActivityDialogs   => \%ActivityDialogs,
        Transitions       => \%Transitions,
        TransitionActions => \%TransitionActions,
    };
}

sub _EntityMapCreate {
    my ( $Self, %Param ) = @_;

    my $EntityObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my %EntityMap;

    my $NewProcessEntityID = $EntityObject->EntityIDGenerate(
        EntityType => 'Process',
        UserID     => $Param{UserID},
    );
    if ( !$NewProcessEntityID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Could not generate a process EntityID.',
        );
        return;
    }
    $EntityMap{ $Param{ProcessEntityID} } = $NewProcessEntityID;

    my %EntityType = (
        Activity         => 1,
        ActivityDialog   => 1,
        Transition       => 1,
        TransitionAction => 1,
    );

    ENTITYTYPE:
    for my $EntityType ( sort keys %EntityType ) {
        my $EntityIDs = $Param{EntityIDs}->{$EntityType} || {};

        ENTITYID:
        for my $EntityID ( sort keys %{$EntityIDs} ) {
            my $NewEntityID = $EntityObject->EntityIDGenerate(
                EntityType => $EntityType,
                UserID     => $Param{UserID},
            );
            if ( !$NewEntityID ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Could not generate an EntityID for $EntityType.",
                );
                return;
            }
            $EntityMap{$EntityID} = $NewEntityID;
        }
    }

    return \%EntityMap;
}

sub _PartAdd {
    my ( $Self, %Param ) = @_;

    my %ObjectName = (
        Activity         => 'Kernel::System::ProcessManagement::DB::Activity',
        ActivityDialog   => 'Kernel::System::ProcessManagement::DB::ActivityDialog',
        Transition       => 'Kernel::System::ProcessManagement::DB::Transition',
        TransitionAction => 'Kernel::System::ProcessManagement::DB::TransitionAction',
    );

    my $Object = $Kernel::OM->Get( $ObjectName{ $Param{EntityType} } );
    my $Add    = $Param{EntityType} . 'Add';

    return $Object->$Add(
        EntityID => $Param{EntityID},
        Name     => $Param{Name},
        Config   => $Param{Config},
        UserID   => $Param{UserID},
    );
}

sub _ProcessPreferencesClone {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $ProcessObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my @Files;
    my $PreferencesConfig = $ConfigObject->Get('ProcessPreferences');
    if ( !IsHashRefWithData($PreferencesConfig) ) {
        return {
            Success => 1,
            Files   => \@Files,
        };
    }

    my %Preferences = $ProcessObject->ProcessPreferencesGet(
        ProcessEntityID => $Param{ProcessEntityID},
    );
    if ( !%Preferences ) {
        return {
            Success => 1,
            Files   => \@Files,
        };
    }

    my %PreferenceBlock;
    SETTING:
    for my $Setting ( sort keys %{$PreferencesConfig} ) {
        my $PrefKey = $PreferencesConfig->{$Setting}->{PrefKey};
        next SETTING if !$PrefKey;
        $PreferenceBlock{$PrefKey} = $PreferencesConfig->{$Setting}->{Block} || '';
    }

    PREFERENCEKEY:
    for my $PreferenceKey ( sort keys %Preferences ) {
        next PREFERENCEKEY if !defined $Preferences{$PreferenceKey};

        my @PreferenceValues;
        if ( IsStringWithData( $Preferences{$PreferenceKey} ) ) {
            @PreferenceValues = ( $Preferences{$PreferenceKey} );
        }
        elsif ( IsArrayRefWithData( $Preferences{$PreferenceKey} ) ) {
            @PreferenceValues = @{ $Preferences{$PreferenceKey} };
        }
        else {
            next PREFERENCEKEY;
        }

        VALUE:
        for my $Value (@PreferenceValues) {
            if ( ( $PreferenceBlock{$PreferenceKey} || '' ) eq 'File' ) {
                my $SourceFilename = '';
                if ( ref $Value eq 'HASH' && $Value->{Preferences} ) {
                    $SourceFilename = $Value->{Preferences}->{Filename} || '';
                }
                my $ContentRef = '';
                if ( ref $Value eq 'HASH' ) {
                    $ContentRef = $Value->{Content};
                }
                if ( !$SourceFilename || ref $ContentRef ne 'SCALAR' ) {
                    return {
                        Success => 0,
                        Message => 'Could not clone a process file preference.',
                        Files   => \@Files,
                    };
                }

                my $Filename = 'VirtualFS::'
                    . $Param{NewProcessEntityID} . '::'
                    . $PreferenceKey . '::'
                    . $SourceFilename;

                my $Written = $VirtualFSObject->Write(
                    Content     => $ContentRef,
                    Filename    => $Filename,
                    Mode        => 'binary',
                    Preferences => $Value->{Preferences},
                );
                if ( !$Written ) {
                    return {
                        Success => 0,
                        Message => 'Could not store a cloned process file preference.',
                        Files   => \@Files,
                    };
                }

                push @Files, $Filename;
                $Value = $Filename;
            }

            my $Set = $ProcessObject->ProcessPreferencesSet(
                ProcessEntityID => $Param{NewProcessEntityID},
                Key             => $PreferenceKey,
                Value           => $Value,
            );
            if ( !$Set ) {
                return {
                    Success => 0,
                    Message => 'Could not store a cloned process preference.',
                    Files   => \@Files,
                };
            }
        }
    }

    return {
        Success => 1,
        Files   => \@Files,
    };
}

sub _CanvasConfig {
    my ( $Self, %Param ) = @_;

    my %ObjectName = (
        Activity         => 'Kernel::System::ProcessManagement::DB::Activity',
        ActivityDialog   => 'Kernel::System::ProcessManagement::DB::ActivityDialog',
        Transition       => 'Kernel::System::ProcessManagement::DB::Transition',
        TransitionAction => 'Kernel::System::ProcessManagement::DB::TransitionAction',
    );
    my %DumpKey = (
        Activity         => 'Activity',
        ActivityDialog   => 'ActivityDialog',
        Transition       => 'Transition',
        TransitionAction => 'TransitionAction',
    );

    my %Config;
    ENTITY:
    for my $Entity ( @{ $Param{Entities} || [] } ) {
        next ENTITY if !$ObjectName{ $Entity->{EntityType} };

        my $Object = $Kernel::OM->Get( $ObjectName{ $Entity->{EntityType} } );
        my $Get    = $Entity->{EntityType} . 'Get';
        my $Data   = $Object->$Get(
            EntityID => $Entity->{EntityID},
            UserID   => $Param{UserID},
        );
        next ENTITY if !IsHashRefWithData($Data);

        $Config{ $DumpKey{ $Entity->{EntityType} } }->{ $Entity->{EntityID} } = $Self->_CanvasEntry(
            EntityType => $Entity->{EntityType},
            Data       => $Data,
        );
    }

    return \%Config;
}

sub _CanvasEntry {
    my ( $Self, %Param ) = @_;

    my $Data = $Param{Data};

    if ( $Param{EntityType} eq 'Activity' ) {
        return {
            ID             => $Data->{ID},
            Name           => $Data->{Name},
            CreateTime     => $Data->{CreateTime},
            ChangeTime     => $Data->{ChangeTime},
            ActivityDialog => $Data->{Config}->{ActivityDialog} || '',
        };
    }
    if ( $Param{EntityType} eq 'ActivityDialog' ) {
        return {
            Name             => $Data->{Name},
            CreateTime       => $Data->{CreateTime},
            ChangeTime       => $Data->{ChangeTime},
            Interface        => $Data->{Config}->{Interface}        || '',
            DescriptionShort => $Data->{Config}->{DescriptionShort} || '',
            DescriptionLong  => $Data->{Config}->{DescriptionLong}  || '',
            Fields           => $Data->{Config}->{Fields}           || {},
            FieldOrder       => $Data->{Config}->{FieldOrder}       || [],
            Permission       => $Data->{Config}->{Permission}       || '',
            RequiredLock     => $Data->{Config}->{RequiredLock}     || '',
            SubmitAdviceText => $Data->{Config}->{SubmitAdviceText} || '',
            SubmitButtonText => $Data->{Config}->{SubmitButtonText} || '',
        };
    }
    if ( $Param{EntityType} eq 'Transition' ) {
        return {
            Name             => $Data->{Name},
            CreateTime       => $Data->{CreateTime},
            ChangeTime       => $Data->{ChangeTime},
            Condition        => $Data->{Config}->{Condition}        || {},
            ConditionLinking => $Data->{Config}->{ConditionLinking} || '',
        };
    }

    return {
        Name       => $Data->{Name},
        CreateTime => $Data->{CreateTime},
        ChangeTime => $Data->{ChangeTime},
        Module     => $Data->{Config}->{Module} || '',
        Config     => $Data->{Config}->{Config} || {},
    };
}

sub _CloneName {
    my ( $Self, $Name ) = @_;

    my $Suffix = ' (Clone)';

    my $CloneName = ( $Name // '' ) . $Suffix;
    if ( length $CloneName > 200 ) {
        my $MaxLength = 200 - length $Suffix;
        if ( $MaxLength < 1 ) {
            $MaxLength = 1;
        }
        $CloneName = substr( $Name, 0, $MaxLength ) . $Suffix;
    }

    return $CloneName;
}

sub _ScopeApply {
    my ( $Self, %Param ) = @_;

    return if ref $Param{Config} ne 'HASH';

    my $Scope = $Param{Scope} || 'Global';
    $Param{Config}->{Scope} = $Scope;

    if ( $Scope eq 'Global' ) {
        delete $Param{Config}->{ScopeEntityID};
        return 1;
    }

    $Param{Config}->{ScopeEntityID} = $Param{ScopeEntityID};
    return 1;
}

sub _StructureClone {
    my ( $Self, $Data ) = @_;

    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');

    return $YAMLObject->Load(
        Data => $YAMLObject->Dump(
            Data => $Data,
        ),
    );
}

sub _DataRemap {
    my ( $Self, $Data, $EntityMap ) = @_;

    return $Data if !defined $Data;

    if ( !ref $Data ) {
        if ( exists $EntityMap->{$Data} ) {
            return $EntityMap->{$Data};
        }

        my $Remapped = $Data;
        ENTITYID:
        for my $EntityID ( sort { length $b <=> length $a } keys %{$EntityMap} ) {
            next ENTITYID if $EntityID !~ m{
                \A
                (?:Process|ActivityDialog|Activity|TransitionAction|Transition)
                -
                [0-9a-f]{32}
                \z
            }xms;
            next ENTITYID if index( $Remapped, $EntityID ) == -1;

            my $NewEntityID = $EntityMap->{$EntityID};
            $Remapped =~ s{\Q$EntityID\E}{$NewEntityID}xmsg;
        }
        return $Remapped;
    }

    if ( ref $Data eq 'ARRAY' ) {
        my @Remapped;
        for my $Item ( @{$Data} ) {
            push @Remapped, $Self->_DataRemap( $Item, $EntityMap );
        }
        return \@Remapped;
    }

    if ( ref $Data eq 'HASH' ) {
        my %Remapped;
        for my $Key ( sort keys %{$Data} ) {
            my $NewKey = $Self->_DataRemap( $Key, $EntityMap );
            $Remapped{$NewKey} = $Self->_DataRemap( $Data->{$Key}, $EntityMap );
        }
        return \%Remapped;
    }

    return $Data;
}

sub _CloneRollBack {
    my ( $Self, %Param ) = @_;

    my $EntityObject    = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $ProcessObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my $Added   = $Param{Added}   || {};
    my $Message = $Param{Message} || 'Could not clone the process.';

    $LogObject->Log(
        Priority => 'error',
        Message  => $Message,
    );

    if ( $Added->{Process} ) {
        PROCESS:
        for my $ProcessEntityID ( sort keys %{ $Added->{Process} } ) {
            $ProcessObject->ProcessDelete(
                ID     => $Added->{Process}->{$ProcessEntityID},
                UserID => $Param{UserID},
            );
            $EntityObject->EntitySyncStateDelete(
                EntityType => 'Process',
                EntityID   => $ProcessEntityID,
                UserID     => $Param{UserID},
            );
        }
    }

    my %ObjectName = (
        Activity         => 'Kernel::System::ProcessManagement::DB::Activity',
        ActivityDialog   => 'Kernel::System::ProcessManagement::DB::ActivityDialog',
        Transition       => 'Kernel::System::ProcessManagement::DB::Transition',
        TransitionAction => 'Kernel::System::ProcessManagement::DB::TransitionAction',
    );

    PART:
    for my $Part (qw(Activity ActivityDialog Transition TransitionAction)) {
        next PART if !$Added->{$Part};

        my $Object = $Kernel::OM->Get( $ObjectName{$Part} );
        my $Delete = $Part . 'Delete';

        ENTITY:
        for my $EntityID ( sort keys %{ $Added->{$Part} } ) {
            my $Deleted = $Object->$Delete(
                ID     => $Added->{$Part}->{$EntityID},
                UserID => $Param{UserID},
            );
            if ( !$Deleted ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Could not roll back cloned $Part $EntityID.",
                );
            }
            $EntityObject->EntitySyncStateDelete(
                EntityType => $Part,
                EntityID   => $EntityID,
                UserID     => $Param{UserID},
            );
        }
    }

    FILE:
    for my $Filename ( @{ $Param{Files} || [] } ) {
        $VirtualFSObject->Delete(
            Filename        => $Filename,
            DisableWarnings => 1,
        );
    }

    return {
        Success => 0,
        Message => $Message,
    };
}

1;
