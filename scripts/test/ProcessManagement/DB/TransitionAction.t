# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

# get needed objects
my $CacheObject            = $Kernel::OM->Get('Kernel::System::Cache');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# set fixed time
$HelperObject->FixedTimeSet();

# define needed variables
my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;

my $EntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'TransitionAction',
    UserID     => 1,
);

# get original TransitionAction list
my $OriginalTransitionActionList = $TransitionActionObject->TransitionActionList( UserID => $UserID ) || {};

#
# Tests for TransitionActionAdd
#

my @Tests = (
    {
        Name    => 'TransitionActionAdd Test 1: No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 2: No EntityID',
        Config => {
            EntityID => undef,
            Name     => 'TransitionAction-$RandomID',
            Config   => {
                Condition => {},
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'TransitionActionAdd Test 3: No Name',
        Config => {
            EntityID => $RandomID,
            Name     => undef,
            Config   => {
                Condition => {},
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'TransitionActionAdd Test 4: No Config',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 5: No Config Module',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 6: No Config Config',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Config => {
                    Key1 => 'String',
                    Key2 => 2,
                },

            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 7: No UserID',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => 'String',
                    Key2 => 2,
                },
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 8: Wrong Config format',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => 'Config',
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 9: Wrong Config->Module format',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => {
                    String => 'Kernel::System::Process::Transition::Action::QueueMove',
                },
                Config => {
                    Key1 => 'String',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 0,
        Name    => 'TransitionActionAdd Test 10: Wrong Config->Config format',
        Config  => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => 'Config',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 11: Correct ASCII',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => 'String',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionAdd Test 12: Duplicated EntityID',
        Config => {
            EntityID => $RandomID,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => 'String',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionAdd Test 13: Correct UTF8',
        Config => {
            EntityID => "$RandomID-1",
            Name     => "TransitionAction-$RandomID--äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => '-äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionAdd Test 14: Correct UTF8 2',
        Config => {
            EntityID => "$RandomID-2",
            Name     => "TransitionAction-$RandomID--!Â§$%&/()=?Ã*ÃÃL:L@,.",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => '-!Â§$%&/()=?Ã*ÃÃL:L@,.',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionAdd Test 15: EntityID Full Length',
        Config => {
            EntityID => $EntityID,
            Name     => $EntityID,
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove',
                Config => {
                    Key1 => '-!Â§$%&/()=?Ã*ÃÃL:L@,.',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },

);

my %AddedTransitionActions;
for my $Test (@Tests) {
    my $TransitionActionID = $TransitionActionObject->TransitionActionAdd( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $TransitionActionID,
            undef,
            "$Test->{Name} | TransitionActionID should not be undef",
        );
        $AddedTransitionActions{$TransitionActionID} = $Test->{Config};
    }
    else {
        $Self->Is(
            $TransitionActionID,
            undef,
            "$Test->{Name} | TransitionActionID should be undef",
        );
    }
}

#
# TransitionActionGet()
#

my @AddedTransitionActionsList = map {$_} sort keys %AddedTransitionActions;
@Tests = (
    {
        Name    => 'TransitionActionGet Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'TransitionActionGet Test 2: No ID and EntityID',
        Config => {
            ID       => undef,
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionGet Test 3: No UserID',
        Config => {
            ID       => 1,
            EntityID => undef,
            UserID   => undef,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionGet Test 4: Wrong ID',
        Config => {
            ID       => '9999999',
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionGet Test 5: Wrong EntityID',
        Config => {
            ID       => undef,
            EntityID => '9999999',
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionGet Test 6: Correct ASCII, W/ID',
        Config => {
            ID       => $AddedTransitionActionsList[0],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionGet Test 7: Correct UTF8, W/ID',
        Config => {
            ID       => $AddedTransitionActionsList[1],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionGet Test 8: Correct UTF82, W/ID',
        Config => {
            ID       => $AddedTransitionActionsList[2],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionGet Test 9: Correct ASCII, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedTransitionActions{ $AddedTransitionActionsList[0] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionGet Test 10: Correct UTF8, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedTransitionActions{ $AddedTransitionActionsList[1] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'TransitionActionGet Test 11: Correct UTF82, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedTransitionActions{ $AddedTransitionActionsList[2] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
);

for my $Test (@Tests) {
    my $TransitionAction = $TransitionActionObject->TransitionActionGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->Is(
            ref $TransitionAction,
            'HASH',
            "$Test->{Name} | TransitionAction structure is HASH",
        );
        $Self->True(
            IsHashRefWithData($TransitionAction),
            "$Test->{Name} | TransitionAction structure is non empty HASH",
        );

        # check cache
        my $CacheKey;
        if ( $Test->{Config}->{ID} ) {
            $CacheKey = 'TransitionActionGet::ID::' . $Test->{Config}->{ID};
        }
        else {
            $CacheKey = 'TransitionActionGet::EntityID::' . $Test->{Config}->{EntityID};
        }

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_TransitionAction',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $TransitionAction,
            "$Test->{Name} | TransitionAction cache"
        );

        # remove not need parameters
        my %ExpectedTransitionAction = %{ $AddedTransitionActions{ $TransitionAction->{ID} } };
        delete $ExpectedTransitionAction{UserID};

        # create a variable copy otherwise the cache will be altered
        my %TransitionActionCopy = %{$TransitionAction};

        for my $Attribute (qw(ID CreateTime ChangeTime)) {
            $Self->IsNot(
                $TransitionActionCopy{$Attribute},
                undef,
                "$Test->{Name} | TransitionActionCopy{$Attribute} should not be undef",
            );
            delete $TransitionActionCopy{$Attribute};
        }

        $Self->IsDeeply(
            \%TransitionActionCopy,
            \%ExpectedTransitionAction,
            "$Test->{Name} | TransitionAction"
        );
    }
    else {
        $Self->False(
            ref $TransitionAction eq 'HASH',
            "$Test->{Name} | TransitionAction structure is not HASH",
        );
        $Self->Is(
            $TransitionAction,
            undef,
            "$Test->{Name} | TransitionAction should be undefined",
        );
    }
}

#
# TransitionActionUpdate() tests
#
@Tests = (
    {
        Name    => 'TransitionActionUpdate Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 2: No ID',
        Config => {
            ID       => undef,
            EntityID => $RandomID . '-U',
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 3: No EntityID',
        Config => {
            ID       => 1,
            EntityID => undef,
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 4: No Name',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => undef,
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 5: No Config',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "TransitionAction-$RandomID",
            Config   => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 6: No UserID',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "TransitionAction-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionUpdate Test 7: Correct ASCII',
        Config => {
            ID       => $AddedTransitionActionsList[0],
            EntityID => $RandomID . '-U',
            Name     => "TransitionAction-$RandomID -U",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove-U',
                Config => {
                    Key1 => 'String-U',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'TransitionActionUpdate Test 8: Correct UTF8',
        Config => {
            ID       => $AddedTransitionActionsList[1],
            EntityID => $RandomID . '-1-U',
            Name     => "TransitionAction-$RandomID -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove-U',
                Config => {
                    Key1 => '-äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1,
    },
    {
        Name   => 'TransitionActionUpdate Test 9: Correct UTF8 2',
        Config => {
            ID       => $AddedTransitionActionsList[1],
            EntityID => $RandomID . '-2-U',
            Name     => "TransitionAction-$RandomID--!Â§$%&/()=?Ã*ÃÃL:L@,.-U",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove-U',
                Config => {
                    Key1 => '-!Â§$%&/()=?Ã*ÃÃL:L@,.-U',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1,
    },
    {
        Name   => 'TransitionActionUpdate Test 10: Correct ASCII No DBUpdate',
        Config => {
            ID       => $AddedTransitionActionsList[0],
            EntityID => $RandomID . '-U',
            Name     => "TransitionAction-$RandomID -U",
            Config   => {
                Module => 'Kernel::System::Process::Transition::Action::QueueMove-U',
                Config => {
                    Key1 => 'String-U',
                    Key2 => 2,
                },
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
);

for my $Test (@Tests) {

    # get the old TransitionAction (if any)
    my $OldTransitionAction = $TransitionActionObject->TransitionActionGet(
        ID     => $Test->{Config}->{ID} || 0,
        UserID => $Test->{Config}->{UserID},
    );

    if ( $Test->{Success} ) {

        # try to update the TransitionAction
        print "Force a gap between create and update TransitionAction, Waiting 2s\n";

        # wait 2 seconds
        $HelperObject->FixedTimeAddSeconds(2);

        my $Success = $TransitionActionObject->TransitionActionUpdate( %{ $Test->{Config} } );

        $Self->IsNot(
            $Success,
            0,
            "$Test->{Name} | Result should be 1"
        );

        # check cache
        my $CacheKey = 'TransitionActionGet::ID::' . $Test->{Config}->{ID};

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_TransitionAction',
            Key  => $CacheKey,
        );

        if ( $Test->{UpdateDB} ) {
            $Self->Is(
                $Cache,
                undef,
                "$Test->{Name} | Cache should be deleted after update, should be undef",
            );
        }
        else {
            $Self->IsNot(
                $Cache,
                undef,
                "$Test->{Name} | Cache should not be deleted after update, since no update needed",
            );
        }

        # get the new TransitionAction
        my $NewTransitionAction = $TransitionActionObject->TransitionActionGet(
            ID     => $Test->{Config}->{ID},
            UserID => $Test->{Config}->{UserID},
        );

        # check cache
        $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_TransitionAction',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $NewTransitionAction,
            "$Test->{Name} | Cache is equal to updated TransitionAction",
        );

        if ( $Test->{UpdateDB} ) {
            $Self->IsNotDeeply(
                $NewTransitionAction,
                $OldTransitionAction,
                "$Test->{Name} | Updated TransitionAction is different than original",
            );

            # check create and change times
            $Self->Is(
                $NewTransitionAction->{CreateTime},
                $OldTransitionAction->{CreateTime},
                "$Test->{Name} | Updated TransitionAction create time should not change",
            );
            $Self->IsNot(
                $NewTransitionAction->{ChangeTime},
                $OldTransitionAction->{ChangeTime},
                "$Test->{Name} | Updated TransitionAction change time should be different",
            );

            # remove not need parameters
            my %ExpectedTransitionAction = %{ $Test->{Config} };
            delete $ExpectedTransitionAction{UserID};

            # create a variable copy otherwise the cache will be altered
            my %NewTransitionActionCopy = %{$NewTransitionAction};

            for my $Attribute (qw(CreateTime ChangeTime)) {
                delete $NewTransitionActionCopy{$Attribute};
            }

            $Self->IsDeeply(
                \%NewTransitionActionCopy,
                \%ExpectedTransitionAction,
                "$Test->{Name} | TransitionAction"
            );
        }
        else {
            $Self->IsDeeply(
                $NewTransitionAction,
                $OldTransitionAction,
                "$Test->{Name} | Updated TransitionAction is equal than original",
            );
        }
    }
    else {
        my $Success = $TransitionActionObject->TransitionActionUpdate( %{ $Test->{Config} } );

        $Self->False(
            $Success,
            "$Test->{Name} | Result should fail",
        );
    }
}

#
# TransitionActionList() tests
#

# no params
my $TestTransitionActionList = $TransitionActionObject->TransitionActionList();

$Self->Is(
    $TestTransitionActionList,
    undef,
    "TransitionActionList Test 1: No Params | Should be undef",
);

# normal TransitionAction list
$TestTransitionActionList = $TransitionActionObject->TransitionActionList( UserID => $UserID );

$Self->Is(
    ref $TestTransitionActionList,
    'HASH',
    "TransitionActionList Test 2: All | Should be a HASH",
);

$Self->True(
    IsHashRefWithData($TestTransitionActionList),
    "TransitionActionList Test 2: All | Should be not empty HASH",
);

$Self->IsNotDeeply(
    $TestTransitionActionList,
    $OriginalTransitionActionList,
    "TransitionActionList Test 2: All | Should be different than the original",
);

# create a variable copy otherwise the cache will be altered
my %TestTransitionActionListCopy = %{$TestTransitionActionList};

# delete original TransitionActions
for my $TransitionActionID ( sort keys %{$OriginalTransitionActionList} ) {
    delete $TestTransitionActionListCopy{$TransitionActionID};
}

$Self->Is(
    scalar keys %TestTransitionActionListCopy,
    scalar @AddedTransitionActionsList,
    "TransitionActionList Test 2: All TransitionAction | Number of TransitionActions match added TransitionActions",
);

my %AddedTransitionActionsListSort = map { $_ => 1 } @AddedTransitionActionsList;
for my $TransitionActionID ( sort keys %TestTransitionActionListCopy ) {
    $Self->True(
        $AddedTransitionActionsListSort{$TransitionActionID},
        "TransitionActionList Test 2: All | TransitionActionID match AddedTransitionActionID",
    );
}

#
# TransitionActionDelete() (test for fail, test for success are done by removing TransitionActions
# at the end)
#
@Tests = (
    {
        Name    => 'TransitionActionDelete Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'TransitionActionDelete Test 2: No TransitionAction ID',
        Config => {
            ID     => undef,
            UserID => $RandomID,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionDelete Test 3: No UserID',
        Config => {
            ID     => $RandomID,
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'TransitionActionDelete Test 4: Wrong TransitionAction ID',
        Config => {
            ID     => '9999999',
            UserID => $UserID,
        },
        Success => 0,
    },
);

for my $Test (@Tests) {
    my $Success = $TransitionActionObject->TransitionActionDelete( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->True(
            $Success,
            "$Test->{Name} | TransitionAction deleted with true",
        );
    }
    else {
        $Self->False(
            $Success,
            "$Test->{Name} | TransitionAction delete with false",
        );
    }
}

#
# TransitionActionListGet() tests
#

my $FullList = $TransitionActionObject->TransitionActionListGet(
    UserID => undef,
);

$Self->IsNot(
    ref $FullList,
    'ARRAY',
    "TransitionActionListGet Test 1: No UserID | List Should not be an array",
);

# get the List of TransitionActions with all details
$FullList = $TransitionActionObject->TransitionActionListGet(
    UserID => $UserID,
);

# get simple list of TransitionActions
my $List = $TransitionActionObject->TransitionActionList(
    UserID => $UserID,
);

# create the list of TransitionActions with details manually
my $ExpectedTransitionActionList;
for my $TransitionActionID ( sort { int $a <=> int $b } keys %{$List} ) {

    my $TransitionActionData = $TransitionActionObject->TransitionActionGet(
        ID     => $TransitionActionID,
        UserID => $UserID,
    );
    push @{$ExpectedTransitionActionList}, $TransitionActionData;
}

$Self->Is(
    ref $FullList,
    'ARRAY',
    "TransitionActionListGet Test 2: Correct List | Should be an array",
);

$Self->True(
    IsArrayRefWithData($FullList),
    "TransitionActionListGet Test 2: Correct List | The list is not empty",
);

$Self->IsDeeply(
    $FullList,
    $ExpectedTransitionActionList,
    "TransitionActionListGet Test 2: Correct List | TransitionAction List",
);

# check cache
my $CacheKey = 'TransitionActionListGet';

my $Cache = $CacheObject->Get(
    Type => 'ProcessManagement_TransitionAction',
    Key  => $CacheKey,
);

$Self->IsDeeply(
    $Cache,
    $FullList,
    "TransitionActionListGet Test 2: Correct List | Cache",
);

# cleanup is done by RestoreDatabase

1;
