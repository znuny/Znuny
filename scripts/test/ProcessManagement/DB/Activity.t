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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $CacheObject          = $Kernel::OM->Get('Kernel::System::Cache');
my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
my $HelperObject         = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# set fixed time
$HelperObject->FixedTimeSet();

# define needed variables
my $RandomID                = $HelperObject->GetRandomID();
my $UserID                  = 1;
my $ActivityDialogEntityID1 = 'AD1-' . $RandomID;
my $ActivityDialogEntityID2 = 'AD2-' . $RandomID;
my $ActivityDialogEntityID3 = 'AD3-' . $RandomID;
my $ActivityDialogName1     = 'ActivityDialog1';
my $ActivityDialogName2     = 'ActivityDialog2';
my $ActivityDialogName3     = 'ActivityDialog3';

my $ProcessEntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'Process',
    UserID     => 1,
);

my $EntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'Activity',
    UserID     => 1,
);

my $ActivityEntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'Activity',
    UserID     => 1,
);

my %ActivityDialogLookup = (
    $ActivityDialogEntityID1 => $ActivityDialogName1,
    $ActivityDialogEntityID2 => $ActivityDialogName2,
    $ActivityDialogEntityID3 => $ActivityDialogName3,
);

my $AcitivityDialogID1 = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $ActivityDialogEntityID1,
    Name     => $ActivityDialogName1,
    Config   => {
        DescriptionShort => 'a Description',
        Fields           => {},
        FieldOrder       => [],
    },
    UserID => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityDialogID1,
    undef,
    "ActivityDialogAdd Test1: EntityID '$ActivityDialogEntityID1', Name '$ActivityDialogName1' | Should not be undef",
);
my $AcitivityDialogID2 = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $ActivityDialogEntityID2,
    Name     => $ActivityDialogName2,
    Config   => {
        DescriptionShort => 'a Description',
        Fields           => {},
        FieldOrder       => [],
    },
    UserID => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityDialogID2,
    undef,
    "ActivityDialogAdd Test2: EntityID '$ActivityDialogEntityID2', Name '$ActivityDialogName2' | Should not be undef",
);
my $AcitivityDialogID3 = $ActivityDialogObject->ActivityDialogAdd(
    EntityID => $ActivityDialogEntityID3,
    Name     => $ActivityDialogName3,
    Config   => {
        DescriptionShort => 'a Description',
        Fields           => {},
        FieldOrder       => [],
    },
    UserID => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityDialogID3,
    undef,
    "ActivityDialogAdd Test3: EntityID '$ActivityDialogEntityID3', Name '$ActivityDialogName3' | Should not be undef",
);

my @AddedActivityDialogs = ( $AcitivityDialogID1, $AcitivityDialogID2, $AcitivityDialogID3 );
my $ActivityDialogList   = $ActivityDialogObject->ActivityDialogList(
    UseEntities => 1,
    UserID      => $UserID,
);

# get original activity list
my $OriginalActivityList = $ActivityObject->ActivityList( UserID => $UserID ) || {};

#
# Tests for ActivityAdd
#
my @Tests = (
    {
        Name    => 'ActivityAdd Test 1: No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityAdd Test 2: No EntityID',
        Config => {
            EntityID => undef,
            Name     => 'Activity-$RandomID',
            Config   => {},
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityAdd Test 3: No Name',
        Config => {
            EntityID => $RandomID,
            Name     => undef,
            Config   => {},
            UserID   => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'ActivityAdd Test 4: No UserID',
        Config => {
            EntityID => $RandomID,
            Name     => "Activity-$RandomID",
            Config   => {},
            UserID   => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityAdd Test 5: Wrong Config format',
        Config => {
            EntityID => $RandomID,
            Name     => "Activity-$RandomID",
            Config   => 'Config',
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityAdd Test 6: Correct ASCII',
        Config => {
            EntityID => $RandomID,
            Name     => "Activity-$RandomID",
            Config   => {
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityAdd Test 7: Duplicated EntityID',
        Config => {
            EntityID => $RandomID,
            Name     => "Activity-$RandomID",
            Config   => {
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                },
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityAdd Test 8: Correct UTF8',
        Config => {
            EntityID => "$RandomID-1",
            Name     => "Activity-$RandomID-!Â§$%&/()=?Ã*ÃÃL:L@,.-",
            Config   => {
                Description    => 'a Description !Â§$%&/()=?Ã*ÃÃL:L@,.-',
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                    2 => $ActivityDialogEntityID2,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityAdd Test 9: Correct UTF8 2',
        Config => {
            EntityID => "$RandomID-2",
            Name     => "Activity-$RandomID--äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
            Config   => {
                Description    => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                    2 => $ActivityDialogEntityID2,
                    3 => $ActivityDialogEntityID3,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityAdd Test 10: EntityID Full Length',
        Config => {
            EntityID => $EntityID,
            Name     => $EntityID,
            Config   => {
                Description    => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                    2 => $ActivityDialogEntityID2,
                    3 => $ActivityDialogEntityID3,
                },
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityAdd Test 11: Scope Global',
        Config => {
            EntityID => "$ActivityEntityID-1",
            Name     => "$ActivityEntityID-1",
            Config   => {
                Description    => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                    2 => $ActivityDialogEntityID2,
                    3 => $ActivityDialogEntityID3,
                },
                Scope         => 'Global',
                ScopeEntityID => undef,
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityAdd Test 12: Scope Process',
        Config => {
            EntityID => "$ActivityEntityID-2",
            Name     => "$ActivityEntityID-2",
            Config   => {
                Description    => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                ActivityDialog => {
                    1 => $ActivityDialogEntityID1,
                    2 => $ActivityDialogEntityID2,
                    3 => $ActivityDialogEntityID3,
                },
                Scope         => 'Process',
                ScopeEntityID => $ProcessEntityID,
            },
            UserID => $UserID,
        },
        Success => 1,
    },
);

my %AddedActivities;
for my $Test (@Tests) {
    my $ActivityID = $ActivityObject->ActivityAdd( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $ActivityID,
            0,
            "$Test->{Name} | ActivityID should not be 0",
        );
        $AddedActivities{$ActivityID} = $Test->{Config};
    }
    else {
        $Self->Is(
            $ActivityID,
            undef,
            "$Test->{Name} | ActivityID should be undef",
        );
    }
}

#
# ActivitySearch() tests
#

@Tests = (
    {
        Name         => "ActivitySearch Test1 - Correct ASCII",
        ActivityName => $RandomID,
        Result       => [
            $RandomID,
            "$RandomID-1",
            "$RandomID-2",
        ],
        Count => 3,
    },
    {
        Name         => "ActivitySearch Test1 - Correct ASCII with asterisk",
        ActivityName => '*' . $RandomID . '*',
        Result       => [
            $RandomID,
            "$RandomID-1",
            "$RandomID-2",
        ],
        Count => 3,
    },
    {
        Name         => "ActivitySearch Test2 - Correct UTF8 1",
        ActivityName => "Activity-$RandomID-!Â§$%&/()=?Ã*ÃÃL:L@,.-",
        ,
        Result => ["$RandomID-1"],
        Count  => 1,
    },
    {
        Name         => "ActivitySearch Test3 - - Correct UTF8 1",
        ActivityName => "Activity-$RandomID--äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
        Result       => ["$RandomID-2"],
        Count        => 1,
    },
    {
        Name         => "ActivitySearch Test4 - EntityID Full Length",
        ActivityName => $EntityID,
        Result       => [$EntityID],
        Count        => 1,
    },
);

for my $Test (@Tests) {

    my $ActivityList = $ActivityObject->ActivitySearch( ActivityName => $Test->{ActivityName} );

    $Self->Is(
        scalar keys @{$ActivityList},
        $Test->{Count},
        "$Test->{Name} | Number of activities is as expected: $Test->{Count}.",
    );

    $Self->IsDeeply(
        $ActivityList,
        $Test->{Result},
        "$Test->{Name} | Result of activity search is as expected.",
    );
}

#
# ActivityGet()
#
my @AddedActivityList = map {$_} sort keys %AddedActivities;
@Tests = (
    {
        Name    => 'ActivityGet Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityGet Test 2: No ID and EntityID',
        Config => {
            ID                  => undef,
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityGet Test 3: No UserID',
        Config => {
            ID                  => 1,
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityGet Test 4: Wrong ID',
        Config => {
            ID                  => '9999999',
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityGet Test 5: Wrong EntityID',
        Config => {
            ID                  => undef,
            EntityID            => '9999999',
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityGet Test 6: Correct ASCII, W/ID, WO/ActivityDialogNames ',
        Config => {
            ID                  => $AddedActivityList[0],
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 7: Correct ASCII, W/ID, W/ActivityNames ',
        Config => {
            ID                  => $AddedActivityList[0],
            EntityID            => undef,
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 8: Correct UTF8, W/ID, WO/ActivityDialogNames ',
        Config => {
            ID                  => $AddedActivityList[1],
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 9: Correct UTF8, W/ID, W/ActivityDialogNames ',
        Config => {
            ID                  => $AddedActivityList[1],
            EntityID            => undef,
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 11: Correct UTF82, W/ID, WO/ActivityDialogNames ',
        Config => {
            ID                  => $AddedActivityList[2],
            EntityID            => undef,
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 12: Correct UTF82, W/ID, W/ActivityDialogNames ',
        Config => {
            ID                  => $AddedActivityList[2],
            EntityID            => undef,
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 13: Correct ASCII, W/EntityID, WO/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[0] }->{EntityID},
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 14: Correct ASCII, W/EntityID, W/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[0] }->{EntityID},
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 15: Correct UTF8, W/EntityID, WO/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[1] }->{EntityID},
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 16: Correct UTF8, W/EntityID, W/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[1] }->{EntityID},
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 17: Correct UTF82, W/EntityID, WO/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[2] }->{EntityID},
            ActivityDialogNames => 0,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 18: Correct UTF82, W/EntityID, W/ActivityDialogNames ',
        Config => {
            ID                  => undef,
            EntityID            => $AddedActivities{ $AddedActivityList[2] }->{EntityID},
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 19: Scope Global',
        Config => {
            ID                  => undef,
            EntityID            => "$ActivityEntityID-1",
            ActivityDialogNames => 1,
            UserID              => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityGet Test 20: Scope Process',
        Config => {
            ID                  => undef,
            EntityID            => "$ActivityEntityID-2",
            ActivityDialogNames => 1,
            UserID              => $UserID,
            Scope               => 'Global',
        },
        Success => 1,
    },
);

for my $Test (@Tests) {
    my $Activity = $ActivityObject->ActivityGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {

        $Self->Is(
            ref $Activity,
            'HASH',
            "$Test->{Name} | Activity structure is HASH",
        );
        $Self->True(
            IsHashRefWithData($Activity),
            "$Test->{Name} | Activity structure is non empty HASH",
        );
        if ( $Test->{Config}->{ActivityDialogNames} ) {
            $Self->Is(
                ref $Activity->{ActivityDialogs},
                'HASH',
                "$Test->{Name} | Activity ActivityDialogs structure is HASH",
            );

            my $ActivityDialog = $AddedActivities{ $Activity->{ID} }->{Config}->{ActivityDialog};
            my %ExpectedActivityDialogs
                = map { $ActivityDialog->{$_} => $ActivityDialogLookup{ $ActivityDialog->{$_} } }
                sort keys %{$ActivityDialog};

            $Self->IsDeeply(
                $Activity->{ActivityDialogs},
                \%ExpectedActivityDialogs,
                "$Test->{Name} | Activity ActivityDialogs"
            );
        }
        else {
            $Self->Is(
                ref $Activity->{ActivityDialogs},
                'ARRAY',
                "$Test->{Name} | Activity Activities structure is ARRAY",
            );

            my @ExpectedActivityDialogs = map { $AddedActivities{ $Activity->{ID} }->{Config}->{ActivityDialog}->{$_} }
                sort { $a <=> $b }
                keys %{ $AddedActivities{ $Activity->{ID} }->{Config}->{ActivityDialog} };
            $Self->IsDeeply(
                $Activity->{ActivityDialogs},
                \@ExpectedActivityDialogs,
                "$Test->{Name} | Activity ActivityDialogs"
            );
        }

        my $ActivityDialogNames = 0;
        if (
            defined $Test->{Config}->{ActivityDialogNames}
            && $Test->{Config}->{ActivityDialogNames} == 1
            )
        {
            $ActivityDialogNames = 1;
        }

        # check cache
        my $CacheKey;
        if ( $Test->{Config}->{ID} ) {
            $CacheKey = 'ActivityGet::ID::' . $Test->{Config}->{ID} . '::ActivityDialogNames::'
                . $ActivityDialogNames;
        }
        else {
            $CacheKey = 'ActivityGet::EntityID::'
                . $Test->{Config}->{EntityID}
                . '::ActivityDialogNames::'
                . $ActivityDialogNames;
        }

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Activity',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $Activity,
            "$Test->{Name} | Activity cache"
        );

        # remove not need parameters
        my %ExpectedActivity = %{ $AddedActivities{ $Activity->{ID} } };
        delete $ExpectedActivity{UserID};

        # create a variable copy otherwise the cache will be altered
        my %ActivityCopy = %{$Activity};
        for my $Attribute (qw(ID ActivityDialogs CreateTime ChangeTime)) {
            $Self->IsNot(
                $ActivityCopy{$Attribute},
                undef,
                "$Test->{Name} | ActivityCopy{$Attribute} should not be undef",
            );
            delete $ActivityCopy{$Attribute};
        }

        $Self->IsDeeply(
            \%ActivityCopy,
            \%ExpectedActivity,
            "$Test->{Name} | Activity"
        );
    }
    else {
        $Self->False(
            ref $Activity eq 'HASH',
            "$Test->{Name} | Activity structure is not HASH",
        );
        $Self->Is(
            $Activity,
            undef,
            "$Test->{Name} | Activity should be undefined",
        );
    }
}

#
# ActivityUpdate() tests
#
@Tests = (
    {
        Name    => 'ActivityUpdate Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityUpdate Test 2: No ID',
        Config => {
            ID       => undef,
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityUpdate Test 3: No EntityID',
        Config => {
            ID       => 1,
            EntityID => undef,
            Name     => "Activity-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityUpdate Test 4: No Name',
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
        Name   => 'ActivityUpdate Test 5: No Config',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID",
            Config   => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityUpdate Test 6: No UserID',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityUpdate Test 7: Correct ASCII',
        Config => {
            ID       => $AddedActivityList[0],
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID -U",
            Config   => {
                Description => 'a Description-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1,
    },
    {
        Name   => 'ActivityUpdate Test 8: Correct UTF8',
        Config => {
            ID       => $AddedActivityList[1],
            EntityID => $RandomID . '-1-U',
            Name     => "Activity-$RandomID -!Â§$%&/()=?Ã*ÃÃL:L@,.--U",
            Config   => {
                Description => 'a Description !Â§$%&/()=?Ã*ÃÃL:L@,.--U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ActivityUpdate Test 9: Correct UTF8 2',
        Config => {
            ID       => $AddedActivityList[1],
            EntityID => $RandomID . '-2-U',
            Name     => "Activity-$RandomID -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U",
            Config   => {
                Description => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ActivityUpdate Test 10: Correct ASCII No DBUpdate',
        Config => {
            ID       => $AddedActivityList[0],
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID -U",
            Config   => {
                Description => 'a Description-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
    {
        Name   => 'ActivityUpdate Test 11: Scope Global',
        Config => {
            ID       => $AddedActivityList[0],
            EntityID => $RandomID . '-U',
            Name     => "Activity-$RandomID -U",
            Config   => {
                Description => 'a Description-U',
                Scope       => 'Global'
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
);

for my $Test (@Tests) {

    # get the old activity (if any)
    my $OldActivity = $ActivityObject->ActivityGet(
        ID     => $Test->{Config}->{ID} || 0,
        UserID => $Test->{Config}->{UserID},
    );

    if ( $Test->{Success} ) {

        # try to update the Activity
        print "Force a gap between create and update activity, Waiting 2s\n";

        # wait 2 seconds
        $HelperObject->FixedTimeAddSeconds(2);

        my $Success = $ActivityObject->ActivityUpdate( %{ $Test->{Config} } );

        $Self->IsNot(
            $Success,
            0,
            "$Test->{Name} | Result should be 1"
        );

        # check cache
        my $CacheKey = 'ActivityGet::ID::' . $Test->{Config}->{ID} . '::ActivityDialogNames::0';

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Activity',
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

        # get the new process
        my $NewActivity = $ActivityObject->ActivityGet(
            ID     => $Test->{Config}->{ID},
            UserID => $Test->{Config}->{UserID},
        );

        # check cache
        $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Activity',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $NewActivity,
            "$Test->{Name} | Cache is equal to updated activity",
        );

        if ( $Test->{UpdateDB} ) {
            $Self->IsNotDeeply(
                $NewActivity,
                $OldActivity,
                "$Test->{Name} | Updated activity is different than original",
            );

            # check create and change times
            $Self->Is(
                $NewActivity->{CreateTime},
                $OldActivity->{CreateTime},
                "$Test->{Name} | Updated activity create time should not change",
            );
            $Self->IsNot(
                $NewActivity->{ChangeTime},
                $OldActivity->{ChangeTime},
                "$Test->{Name} | Updated activity change time should be different",
            );

            # remove not need parameters
            my %ExpectedActivity = %{ $Test->{Config} };
            delete $ExpectedActivity{UserID};

            # create a variable copy otherwise the cache will be altered
            my %NewActivityCopy = %{$NewActivity};
            for my $Attribute (qw( ActivityDialogs CreateTime ChangeTime )) {
                delete $NewActivityCopy{$Attribute};
            }

            $Self->IsDeeply(
                \%NewActivityCopy,
                \%ExpectedActivity,
                "$Test->{Name} | Activity"
            );
        }
        else {
            $Self->IsDeeply(
                $NewActivity,
                $OldActivity,
                "$Test->{Name} | Updated activity is equal than original",
            );
        }
    }
    else {
        my $Success = $ActivityObject->ActivityUpdate( %{ $Test->{Config} } );

        $Self->False(
            $Success,
            "$Test->{Name} | Result should fail",
        );
    }
}

#
# ActivityList() tests
#

# no params
my $TestActivityList = $ActivityObject->ActivityList();

$Self->Is(
    $TestActivityList,
    undef,
    "ActivityList Test 1: No Params | Should be undef",
);

# normal Activity list
$TestActivityList = $ActivityObject->ActivityList( UserID => $UserID );

$Self->Is(
    ref $TestActivityList,
    'HASH',
    "ActivityList Test 2: | Should be a HASH",
);

$Self->True(
    IsHashRefWithData($TestActivityList),
    "ActivityList Test 2: | Should be not empty HASH",
);

$Self->IsNotDeeply(
    $TestActivityList,
    $OriginalActivityList,
    "ActivityList Test 2: | Should be different than the original",
);

# create a variable copy otherwise the cache will be altered
my %TestActivityListCopy = %{$TestActivityList};

# delete original activities
for my $ActivityID ( sort keys %{$OriginalActivityList} ) {
    delete $TestActivityListCopy{$ActivityID};
}

$Self->Is(
    scalar keys %TestActivityListCopy,
    scalar @AddedActivityList,
    "ActivityList Test 2: | Number of activities match added activities",
);

my $Counter = 0;
for my $ActivityID ( sort { $a cmp $b } keys %TestActivityListCopy ) {
    $Self->Is(
        $ActivityID,
        $AddedActivityList[$Counter],
        "ActivityList Test 2: | ActivityID match AddedActivityID",
    );
    $Counter++;
}

#
# ActivityDelete() (test for fail, test for success are done by removing activities at the end)
#
@Tests = (
    {
        Name    => 'ActivityDelete Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityDelete Test 2: No Activity ID',
        Config => {
            ID     => undef,
            UserID => $RandomID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDelete Test 3: No UserID',
        Config => {
            ID     => $RandomID,
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDelete Test 4: Wrong Activity ID',
        Config => {
            ID     => '9999999',
            UserID => $UserID,
        },
        Success => 0,
    },
);

for my $Test (@Tests) {
    my $Success = $ActivityObject->ActivityDelete( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->True(
            $Success,
            "$Test->{Name} | Activity deleted with true",
        );
    }
    else {
        $Self->False(
            $Success,
            "$Test->{Name} | Activity delete with false",
        );
    }
}

#
# ActivityListGet() tests
#

my $FullList = $ActivityObject->ActivityListGet(
    UserID => undef,
);

$Self->IsNot(
    ref $FullList,
    'ARRAY',
    "ActivityListGet Test 1: No UserID | List Should not be an array",
);

# get the List of activities with all details
$FullList = $ActivityObject->ActivityListGet(
    UserID => $UserID,
);

# get simple list of activities
my $List = $ActivityObject->ActivityList(
    UserID => $UserID,
);

# create the list of activities with details manually
my $ExpectedActivityList;
for my $ActivityID ( sort { int $a <=> int $b } keys %{$List} ) {

    my $ActivityData = $ActivityObject->ActivityGet(
        ID     => $ActivityID,
        UserID => $UserID,
    );
    push @{$ExpectedActivityList}, $ActivityData;
}

$Self->Is(
    ref $FullList,
    'ARRAY',
    "ActivityListGet Test 2: Correct List | Should be an array",
);

$Self->True(
    IsArrayRefWithData($FullList),
    "ActivityListGet Test 2: Correct List | The list is not empty",
);

$Self->IsDeeply(
    $FullList,
    $ExpectedActivityList,
    "ActivityListGet Test 2: Correct List | Activity List",
);

# check cache
my $CacheKey = 'ActivityListGet';

my $Cache = $CacheObject->Get(
    Type => 'ProcessManagement_Activity',
    Key  => $CacheKey,
);

$Self->IsDeeply(
    $Cache,
    $FullList,
    "ActivityListGet Test 2: Correct List | Cache",
);

# cleanup is done by RestoreDatabase

1;
