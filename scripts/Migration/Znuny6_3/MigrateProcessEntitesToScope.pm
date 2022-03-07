# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateProcessEntitesToScope;    ## no critic

use strict;
use warnings;
use Kernel::System::VariableCheck qw(:all);

use parent qw(scripts::Migration::Base);
use File::Copy;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::ProcessManagement::DB::Activity',
    'Kernel::System::ProcessManagement::DB::ActivityDialog',
    'Kernel::System::ProcessManagement::DB::Entity',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::ProcessManagement::DB::Transition',
    'Kernel::System::ProcessManagement::DB::TransitionAction',
);

=head1 SYNOPSIS

Add the default global scope for existing process entity.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $MainObject             = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
    my $LogObject              = $Kernel::OM->Get('Kernel::System::Log');
    my $CacheObject            = $Kernel::OM->Get('Kernel::System::Cache');
    my $ProcessObject          = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $ActivityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
    my $ActivityDialogObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
    my $TransitionObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');
    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');
    my $EntityObject           = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');

    # Loop over every entity and update the scope
    my $ActivityList = $ActivityObject->ActivityListGet(
        UserID => 1,
    ) // [];

    ACTIVITY:
    for my $ActivityData ( @{$ActivityList} ) {
        next ACTIVITY if !IsHashRefWithData($ActivityData);

        $ActivityObject->ActivityUpdate(
            ID       => $ActivityData->{ID},
            Name     => $ActivityData->{Name},
            EntityID => $ActivityData->{EntityID},
            Config   => {
                %{ $ActivityData->{Config} },
                Scope => 'Global',
            },
            UserID => 1,
        );
    }

    my $ActivityDialogList = $ActivityDialogObject->ActivityDialogListGet(
        UserID => 1
    ) // [];

    ACTIVITYDIALOG:
    for my $ActivityDialogData ( @{$ActivityDialogList} ) {
        next ACTIVITYDIALOG if !IsHashRefWithData($ActivityDialogData);

        $ActivityDialogObject->ActivityDialogUpdate(
            ID       => $ActivityDialogData->{ID},
            Name     => $ActivityDialogData->{Name},
            EntityID => $ActivityDialogData->{EntityID},
            Config   => {
                %{ $ActivityDialogData->{Config} },
                Scope => 'Global',
            },
            UserID => 1,
        );
    }

    my $TransitionList = $TransitionObject->TransitionListGet(
        UserID => 1,
    ) // [];

    TRANSITION:
    for my $TransitionData ( @{$TransitionList} ) {
        next TRANSITION if !IsHashRefWithData($TransitionData);

        $TransitionObject->TransitionUpdate(
            ID       => $TransitionData->{ID},
            EntityID => $TransitionData->{EntityID},
            Name     => $TransitionData->{Name},
            Config   => {
                %{ $TransitionData->{Config} },
                Scope => 'Global',
            },
            UserID => 1,
        );

    }

    my $TransitionActionList = $TransitionActionObject->TransitionActionListGet(
        UserID => 1,
    ) // [];

    TRANSITIONACTION:
    for my $TransitionActionData ( @{$TransitionActionList} ) {
        next TRANSITIONACTION if !IsHashRefWithData($TransitionActionData);

        $TransitionActionObject->TransitionActionUpdate(
            ID       => $TransitionActionData->{ID},
            EntityID => $TransitionActionData->{EntityID},
            Name     => $TransitionActionData->{Name},
            Module   => $TransitionActionData->{Module},
            Config   => {
                %{ $TransitionActionData->{Config} },
                Scope => 'Global',
            },
            UserID => 1,
        );
    }

    # Deploy process
    my $Location = $ConfigObject->Get('Home') . '/Kernel/Config/Files/ZZZProcessManagement.pm';

    my $ProcessDump = $ProcessObject->ProcessDump(
        ResultType => 'FILE',
        Location   => $Location,
        UserID     => 1,
    );

    if ($ProcessDump) {
        my $Success = $EntityObject->EntitySyncStatePurge(
            UserID => 1,
        );
    }
    $CacheObject->CleanUp(
        Type => 'ProcessManagement_Process',
    );

    return 1;
}

1;
