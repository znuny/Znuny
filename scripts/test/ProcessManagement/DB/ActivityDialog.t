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
my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
my $HelperObject         = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# set fixed time
$HelperObject->FixedTimeSet();

# define needed variables
my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;

my $ProcessEntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'Process',
    UserID     => 1,
);

my $EntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'ActivityDialog',
    UserID     => 1,
);

my $ActivityDialogEntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'ActivityDialog',
    UserID     => 1,
);

# get original ActivityDialog list
my $OriginalActivityDialogList = $ActivityDialogObject->ActivityDialogList( UserID => $UserID )
    || {};

#
# Tests for ActivityDialogAdd
#
my @Tests = (
    {
        Name    => 'ActivityDialogAdd Test 1: No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 2: No EntityID',
        Config => {
            EntityID => undef,
            Name     => 'ActivityDialog-$RandomID',
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {},
                FieldOrder       => [],
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'ActivityDialogAdd Test 3: No Name',
        Config => {
            EntityID => $RandomID,
            Name     => undef,
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {},
                FieldOrder       => [],
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'ActivityDialogAdd Test 4: No Config',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 5: No Config DescriptionShort',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                Data       => 1,
                Fields     => {},
                FieldOrder => [],
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 6: No Config Fields',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => undef,
                FieldOrder       => [],
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 7: No Config FieldOrder',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {},
                FieldOrder       => undef,
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 8: No UserID',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {},
                FieldOrder       => undef,
            },
            UserID => undef,

        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 9: Wrong Config format',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {},
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 10: Wrong Config format 2',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => 'Config',
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 11: Wrong Config Fields format',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => 'fields',
                FieldOrder       => [],
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 12: Wrong Config FieldOrder format',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {},
                FieldOrder       => 'fieldorder',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 13: Correct ASCII',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => ['PriotityID'],
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogAdd Test 14: Duplicated EntityID',
        Config => {
            EntityID => $RandomID,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                DescriptionShort => 'a Description',
                Fields           => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => ['PriotityID'],
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogAdd Test 15: Correct UTF8',
        Config => {
            EntityID => "$RandomID-1",
            Name     => "ActivityDialog-$RandomID-!Â§$%&/()=?Ã*ÃÃL:L@,.-",
            Config   => {
                DescriptionShort => 'a Description !Â§$%&/()=?Ã*ÃÃL:L@,.-',
                Fields           => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => [ 'PriotityID', 'StateID' ],
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogAdd Test 15: Correct UTF8 2',
        Config => {
            EntityID => "$RandomID-2",
            Name     => "ActivityDialog-$RandomID--äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
            Config   => {
                DescriptionShort =>
                    'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Fields => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    QueueID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => [ 'PriotityID', 'StateID', 'QueueID' ],
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogAdd Test 15: EntityID Full Length',
        Config => {
            EntityID => $EntityID,
            Name     => $EntityID,
            Config   => {
                DescriptionShort =>
                    'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Fields => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    QueueID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => [ 'PriotityID', 'StateID', 'QueueID' ],
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogAdd Test 16: Scope Global',
        Config => {
            EntityID => "$ActivityDialogEntityID-1",
            Name     => "$ActivityDialogEntityID-1",
            Config   => {
                DescriptionShort =>
                    'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Fields => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    QueueID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder    => [ 'PriotityID', 'StateID', 'QueueID' ],
                Scope         => 'Global',
                ScopeEntityID => undef,
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogAdd Test 17: Scope Process',
        Config => {
            EntityID => "$ActivityDialogEntityID-2",
            Name     => "$ActivityDialogEntityID-2",
            Config   => {
                DescriptionShort =>
                    'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Fields => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    QueueID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder    => [ 'PriotityID', 'StateID', 'QueueID' ],
                Scope         => 'Global',
                ScopeEntityID => $ProcessEntityID,
            },
            UserID => $UserID,
        },
        Success => 1,
    },
);

my %AddedActivityDialogs;
for my $Test (@Tests) {
    my $ActivityDialogID = $ActivityDialogObject->ActivityDialogAdd( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $ActivityDialogID,
            0,
            "$Test->{Name} | ActivityDialogID should not be 0",
        );
        $AddedActivityDialogs{$ActivityDialogID} = $Test->{Config};
    }
    else {
        $Self->Is(
            $ActivityDialogID,
            undef,
            "$Test->{Name} | ActivityDialogID should be undef",
        );
    }
}

#
# ActivityDialogGet()
#

my @AddedActivityDialogsList = map {$_} sort { $a <=> $b } keys %AddedActivityDialogs;
@Tests = (
    {
        Name    => 'ActivityDialogGet Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityDialogGet Test 2: No ID and EntityID',
        Config => {
            ID       => undef,
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogGet Test 3: No UserID',
        Config => {
            ID       => 1,
            EntityID => undef,
            UserID   => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogGet Test 4: Wrong ID',
        Config => {
            ID       => '9999999',
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogGet Test 5: Wrong EntityID',
        Config => {
            ID       => undef,
            EntityID => '9999999',
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogGet Test 6: Correct ASCII, W/ID',
        Config => {
            ID       => $AddedActivityDialogsList[0],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 7: Correct UTF8, W/ID',
        Config => {
            ID       => $AddedActivityDialogsList[1],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 8: Correct UTF82, W/ID',
        Config => {
            ID       => $AddedActivityDialogsList[2],
            EntityID => undef,
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 9: Correct ASCII, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedActivityDialogs{ $AddedActivityDialogsList[0] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 10: Correct UTF8, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedActivityDialogs{ $AddedActivityDialogsList[1] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 11: Correct UTF82, W/EntityID,',
        Config => {
            ID       => undef,
            EntityID => $AddedActivityDialogs{ $AddedActivityDialogsList[2] }->{EntityID},
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 12: Scope Global',
        Config => {
            ID       => undef,
            EntityID => "$ActivityDialogEntityID-1",
            UserID   => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ActivityDialogGet Test 13: Scope Process',
        Config => {
            ID       => undef,
            EntityID => "$ActivityDialogEntityID-2",
            UserID   => $UserID,
        },
        Success => 1,
    },
);

for my $Test (@Tests) {
    my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->Is(
            ref $ActivityDialog,
            'HASH',
            "$Test->{Name} | ActivityDialog structure is HASH",
        );
        $Self->True(
            IsHashRefWithData($ActivityDialog),
            "$Test->{Name} | ActivityDialog structure is non empty HASH",
        );

        # check cache
        my $CacheKey;
        if ( $Test->{Config}->{ID} ) {
            $CacheKey = 'ActivityDialogGet::ID::' . $Test->{Config}->{ID};
        }
        else {
            $CacheKey = 'ActivityDialogGet::EntityID::' . $Test->{Config}->{EntityID};
        }

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_ActivityDialog',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $ActivityDialog,
            "$Test->{Name} | ActivityDialog cache"
        );

        # remove not need parameters
        my %ExpectedActivityDialog = %{ $AddedActivityDialogs{ $ActivityDialog->{ID} } };
        delete $ExpectedActivityDialog{UserID};

        # create a variable copy otherwise the cache will be altered
        my %ActivityDialogCopy = %{$ActivityDialog};

        for my $Attribute (qw(ID CreateTime ChangeTime)) {
            $Self->IsNot(
                $ActivityDialogCopy{$Attribute},
                undef,
                "$Test->{Name} | ActivityDialog{$Attribute} should not be undef",
            );
            delete $ActivityDialogCopy{$Attribute};
        }

        $Self->IsDeeply(
            \%ActivityDialogCopy,
            \%ExpectedActivityDialog,
            "$Test->{Name} | ActivityDialog"
        );
    }
    else {
        $Self->False(
            ref $ActivityDialog eq 'HASH',
            "$Test->{Name} | ActivityDialog structure is not HASH",
        );
        $Self->Is(
            $ActivityDialog,
            undef,
            "$Test->{Name} | ActivityDialog should be undefined",
        );
    }
}

#
# ActivityDialogUpdate() tests
#
@Tests = (
    {
        Name    => 'ActivityDialogUpdate Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 2: No ID',
        Config => {
            ID       => undef,
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 3: No EntityID',
        Config => {
            ID       => 1,
            EntityID => undef,
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 4: No Name',
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
        Name   => 'ActivityDialogUpdate Test 5: No Config',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID",
            Config   => undef,
            UserID   => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 6: No UserID',
        Config => {
            ID       => 1,
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID",
            Config   => {
                Description => 'a Description',
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 7: Correct ASCII',
        Config => {
            ID       => $AddedActivityDialogsList[0],
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID -U",
            Config   => {
                DescriptionShort => 'a Description-u',
                Fields           => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => ['PriotityID'],
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ActivityDialogUpdate Test 8: Correct UTF8',
        Config => {
            ID       => $AddedActivityDialogsList[1],
            EntityID => $RandomID . '-1-U',
            Name     => "ActivityDialog-$RandomID -!Â§$%&/()=?Ã*ÃÃL:L@,.--U",
            Config   => {
                DescriptionShort => 'a Description !Â§$%&/()=?Ã*ÃÃL:L@,.--U',
                Fields           => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => [ 'PriotityID', 'StateID' ],
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ActivityDialogUpdate Test 9: Correct UTF8 2',
        Config => {
            ID       => $AddedActivityDialogsList[1],
            EntityID => $RandomID . '-2-U',
            Name     => "ActivityDialog-$RandomID--äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U",
            Config   => {
                DescriptionShort =>
                    'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ--U',
                Fields => {
                    PriorityID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    StateID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                    QueueID => {
                        DescriptionShort => 'Short description',
                        DescriptionLong  => 'Longer description',
                        Display          => 0,
                        DefaultValue     => 1,
                    },
                },
                FieldOrder => [ 'PriotityID', 'StateID', 'QueueID' ],
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ActivityDialogUpdate Test 10: Correct ASCII No DBUpdate',
        Config => {
            ID       => $AddedActivityDialogsList[0],
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID -U",
            Config   => {
                Description => 'a Description-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 11: Scope Global',
        Config => {
            ID       => $AddedActivityDialogsList[0],
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID -U",
            Config   => {
                Description => 'a Description-U',
                Scope       => 'Global',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
    {
        Name   => 'ActivityDialogUpdate Test 12: Scope Process',
        Config => {
            ID       => $AddedActivityDialogsList[0],
            EntityID => $RandomID . '-U',
            Name     => "ActivityDialog-$RandomID -U",
            Config   => {
                Description   => 'a Description-U',
                Scope         => 'Process',
                ScopeEntityID => 'Process-9690ae9ae455d8614d570149b8ab1199',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
);

for my $Test (@Tests) {

    # get the old ActivityDialog (if any)
    my $OldActivityDialog = $ActivityDialogObject->ActivityDialogGet(
        ID     => $Test->{Config}->{ID} || 0,
        UserID => $Test->{Config}->{UserID},
    );

    if ( $Test->{Success} ) {

        # try to update the ActivityDialog
        print "Force a gap between create and update ActivityDialog, Waiting 2s\n";

        # wait 2 seconds
        $HelperObject->FixedTimeAddSeconds(2);

        my $Success = $ActivityDialogObject->ActivityDialogUpdate( %{ $Test->{Config} } );

        $Self->IsNot(
            $Success,
            0,
            "$Test->{Name} | Result should be 1"
        );

        # check cache
        my $CacheKey = 'ActivityDialogGet::ID::' . $Test->{Config}->{ID};

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_ActivityDialog',
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

        # get the new ActivityDialog
        my $NewActivityDialog = $ActivityDialogObject->ActivityDialogGet(
            ID     => $Test->{Config}->{ID},
            UserID => $Test->{Config}->{UserID},
        );

        # check cache
        $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_ActivityDialog',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $NewActivityDialog,
            "$Test->{Name} | Cache is equal to updated ActivityDialog",
        );

        if ( $Test->{UpdateDB} ) {
            $Self->IsNotDeeply(
                $NewActivityDialog,
                $OldActivityDialog,
                "$Test->{Name} | Updated ActivityDialog is different than original",
            );

            # check create and change times
            $Self->Is(
                $NewActivityDialog->{CreateTime},
                $OldActivityDialog->{CreateTime},
                "$Test->{Name} | Updated ActivityDialog create time should not change",
            );
            $Self->IsNot(
                $NewActivityDialog->{ChangeTime},
                $OldActivityDialog->{ChangeTime},
                "$Test->{Name} | Updated ActivityDialog change time should be different",
            );

            # remove not need parameters
            my %ExpectedActivityDialog = %{ $Test->{Config} };
            delete $ExpectedActivityDialog{UserID};

            # create a variable copy otherwise the cache will be altered
            my %NewActivityDialogCopy = %{$NewActivityDialog};

            for my $Attribute (qw( Activities CreateTime ChangeTime State)) {
                delete $NewActivityDialogCopy{$Attribute};
            }

            $Self->IsDeeply(
                \%NewActivityDialogCopy,
                \%ExpectedActivityDialog,
                "$Test->{Name} | ActivityDialog"
            );
        }
        else {
            $Self->IsDeeply(
                $NewActivityDialog,
                $OldActivityDialog,
                "$Test->{Name} | Updated ActivityDialog is equal than original",
            );
        }
    }
    else {
        my $Success = $ActivityDialogObject->ActivityDialogUpdate( %{ $Test->{Config} } );

        $Self->False(
            $Success,
            "$Test->{Name} | Result should fail",
        );
    }
}

#
# ActivityDialogList() tests
#

# no params
my $TestActivityDialogList = $ActivityDialogObject->ActivityDialogList();

$Self->Is(
    $TestActivityDialogList,
    undef,
    "ActivityDialogList Test 1: No Params | Should be undef",
);

# normal ActivityDialog list
$TestActivityDialogList = $ActivityDialogObject->ActivityDialogList( UserID => $UserID );

$Self->Is(
    ref $TestActivityDialogList,
    'HASH',
    "ActivityDialogList Test 2: All | Should be a HASH",
);

$Self->True(
    IsHashRefWithData($TestActivityDialogList),
    "ActivityDialogList Test 2: All | Should be not empty HASH",
);

$Self->IsNotDeeply(
    $TestActivityDialogList,
    $OriginalActivityDialogList,
    "ActivityDialogList Test 2: All | Should be different than the original",
);

# create a variable copy otherwise the cache will be altered
my %TestActivityDialogListCopy = %{$TestActivityDialogList};

# delete original ActivityDialogs
for my $ActivityDialogID ( sort keys %{$OriginalActivityDialogList} ) {
    delete $TestActivityDialogListCopy{$ActivityDialogID};
}

$Self->Is(
    scalar keys %TestActivityDialogListCopy,
    scalar @AddedActivityDialogsList,
    "ActivityDialogList Test 2: All ActivityDialog | Number of ActivityDialogs match added ActivityDialogs",
);

my $Counter = 0;
for my $ActivityDialogID ( sort { int $a <=> int $b } keys %TestActivityDialogListCopy ) {
    $Self->Is(
        $ActivityDialogID,
        $AddedActivityDialogsList[$Counter],
        "ActivityDialogList Test 2: All | ActivityDialogID match AddedActivityDialogID",
    );
    $Counter++;
}

#
# ActivityDialogDelete() (test for fail, test for success are done by removing activity dialogs
# at the end)
#
@Tests = (
    {
        Name    => 'ActivityDialogDelete Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ActivityDialogDelete Test 2: No ActivityDialog ID',
        Config => {
            ID     => undef,
            UserID => $RandomID,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogDelete Test 3: No UserID',
        Config => {
            ID     => $RandomID,
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ActivityDialogDelete Test 4: Wrong ActivityDialog ID',
        Config => {
            ID     => '9999999',
            UserID => $UserID,
        },
        Success => 0,
    },
);

for my $Test (@Tests) {
    my $Success = $ActivityDialogObject->ActivityDialogDelete( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->True(
            $Success,
            "$Test->{Name} | ActivityDialog deleted with true",
        );
    }
    else {
        $Self->False(
            $Success,
            "$Test->{Name} | ActivityDialog delete with false",
        );
    }
}

#
# ActivityDialogListGet() tests
#

my $FullList = $ActivityDialogObject->ActivityDialogListGet(
    UserID => undef,
);

$Self->IsNot(
    ref $FullList,
    'ARRAY',
    "ActivityDialogListGet Test 1: No UserID | List Should not be an array",
);

# get the List of activity dialogs with all details
$FullList = $ActivityDialogObject->ActivityDialogListGet(
    UserID => $UserID,
);

# get simple list of activity dialogs
my $List = $ActivityDialogObject->ActivityDialogList(
    UserID => $UserID,
);

# create the list of activity dialogs with details manually
my $ExpectedActivityDialogList;
for my $ActivityDialogID ( sort { int $a <=> int $b } keys %{$List} ) {

    my $ActivityDialogData = $ActivityDialogObject->ActivityDialogGet(
        ID     => $ActivityDialogID,
        UserID => $UserID,
    );
    push @{$ExpectedActivityDialogList}, $ActivityDialogData;
}

$Self->Is(
    ref $FullList,
    'ARRAY',
    "ActivityDialogListGet Test 2: Correct List | Should be an array",
);

$Self->True(
    IsArrayRefWithData($FullList),
    "ActivityDialogListGet Test 2: Correct List | The list is not empty",
);

$Self->IsDeeply(
    $FullList,
    $ExpectedActivityDialogList,
    "ActivityDialogListGet Test 2: Correct List | Activity List",
);

# check cache
my $CacheKey = 'ActivityDialogListGet';

my $Cache = $CacheObject->Get(
    Type => 'ProcessManagement_ActivityDialog',
    Key  => $CacheKey,
);

$Self->IsDeeply(
    $Cache,
    $FullList,
    "ActivityDialogListGet Test 2: Correct List | Cache",
);

# cleanup is done by RestoreDatabase

1;
