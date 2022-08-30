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
my $CacheObject    = $Kernel::OM->Get('Kernel::System::Cache');
my $ActivityObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
my $ProcessObject  = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

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
my $RandomID          = $HelperObject->GetRandomID();
my $UserID            = 1;
my $ActivityEntityID1 = 'A1-' . $RandomID;
my $ActivityEntityID2 = 'A2-' . $RandomID;
my $ActivityEntityID3 = 'A3-' . $RandomID;
my $ActivityName1     = 'Activity1';
my $ActivityName2     = 'Activity2';
my $ActivityName3     = 'Activity3';

my $EntityID = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity')->EntityIDGenerate(
    EntityType => 'Process',
    UserID     => 1,
);

my %ActivityLookup = (
    $ActivityEntityID1 => $ActivityName1,
    $ActivityEntityID2 => $ActivityName2,
    $ActivityEntityID3 => $ActivityName3,
);

my $AcitivityID1 = $ActivityObject->ActivityAdd(
    EntityID => $ActivityEntityID1,
    Name     => $ActivityName1,
    Config   => {},
    UserID   => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityID1,
    undef,
    "ActivityAdd Test1: EntityID '$ActivityEntityID1', Name '$ActivityName1' | Should not be undef",
);
my $AcitivityID2 = $ActivityObject->ActivityAdd(
    EntityID => $ActivityEntityID2,
    Name     => $ActivityName2,
    Config   => {},
    UserID   => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityID2,
    undef,
    "ActivityAdd Test2: EntityID '$ActivityEntityID2', Name '$ActivityName2' | Should not be undef",
);
my $AcitivityID3 = $ActivityObject->ActivityAdd(
    EntityID => $ActivityEntityID3,
    Name     => $ActivityName3,
    Config   => {},
    UserID   => $UserID,
);

# sanity test
$Self->IsNot(
    $AcitivityID3,
    undef,
    "ActivityAdd Test3: EntityID '$ActivityEntityID3', Name '$ActivityName3' | Should not be undef",
);

my @AddedActivities = ( $AcitivityID1, $AcitivityID2, $AcitivityID3 );
my $ActivityList    = $ActivityObject->ActivityList(
    UseEntities => 1,
    UserID      => $UserID,
);

# get original process list
my $OriginalProcessList = $ProcessObject->ProcessList( UserID => $UserID ) || {};

#
# Tests for ProcessAdd
#
my @Tests = (
    {
        Name    => 'ProcessAdd Test 1: No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 2: No EntityID',
        Config => {
            EntityID      => undef,
            Name          => 'Process-$RandomID',
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'ProcessAdd Test 3: No Name',
        Config => {
            EntityID      => $RandomID,
            Name          => undef,
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,

    },
    {
        Name   => 'ProcessAdd Test 4: No StateEntityID',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => undef,
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 5: No Layout',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => undef,
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 6: No Config',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => undef,
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 7: No Config Description',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Data => 1,
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 8: No UserID',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 9: Wrong Config format',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {},
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 10: Wrong Config format 2',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => 'Config',
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 11: Correct ASCII',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
                Path        => {
                    $ActivityEntityID1 => {},
                }
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessAdd Test 12: Duplicated EntityID',
        Config => {
            EntityID      => $RandomID,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessAdd Test 13: Correct UTF8',
        Config => {
            EntityID      => "$RandomID-1",
            Name          => "Process-$RandomID-!Â§\$%&/()=?Ã*ÃÃL:L@,.-",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description Â§$%&/()=?Ã*ÃÃL:L@,.-',
                Path        => {
                    $ActivityEntityID1 => {},
                    $ActivityEntityID2 => {},
                }
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessAdd Test 14: Correct UTF8 2',
        Config => {
            EntityID      => "$RandomID-2",
            Name          => "Process-$RandomID-äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Path        => {
                    $ActivityEntityID1 => {},
                    $ActivityEntityID2 => {},
                    $ActivityEntityID3 => {},
                }
            },
            UserID => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessAdd Test 15: EntityID Full Length',
        Config => {
            EntityID      => $EntityID,
            Name          => $EntityID,
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ',
                Path        => {
                    $ActivityEntityID1 => {},
                    $ActivityEntityID2 => {},
                    $ActivityEntityID3 => {},
                }
            },
            UserID => $UserID,
        },
        Success => 1,
    },
);

my %AddedProcess;
for my $Test (@Tests) {
    my $ProcessID = $ProcessObject->ProcessAdd( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $ProcessID,
            0,
            "$Test->{Name} | ProcessID should not be 0",
        );
        $AddedProcess{$ProcessID} = $Test->{Config};
    }
    else {
        $Self->Is(
            $ProcessID,
            undef,
            "$Test->{Name} | ProcessID should be undef",
        );
    }
}

my @AddedProcessList = map {$_} sort keys %AddedProcess;

#
# ProcessSearch() tests
#

@Tests = (
    {
        Name        => "ProcessSearch Test1 - Correct ASCII",
        ProcessName => $RandomID,
        Result      => [
            $RandomID,
            "$RandomID-1",
            "$RandomID-2",
        ],
        Count => 3,
    },
    {
        Name        => "ProcessSearch Test1 - Correct ASCII with asterisk",
        ProcessName => $RandomID,
        Result      => [
            $RandomID,
            "$RandomID-1",
            "$RandomID-2",
        ],
        Count => 3,
    },
    {
        Name        => "ProcessSearch Test2 - Correct UTF8 1",
        ProcessName => "Process-$RandomID-!Â§\$%&/()=?Ã*ÃÃL:L@,.-",
        Result      => ["$RandomID-1"],
        Count       => 1,
    },
    {
        Name        => "ProcessSearch Test3 - - Correct UTF8 1",
        ProcessName => "Process-$RandomID-äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ",
        Result      => ["$RandomID-2"],
        Count       => 1,
    },
    {
        Name        => "ProcessSearch Test4 - EntityID Full Length",
        ProcessName => $EntityID,
        Result      => [$EntityID],
        Count       => 1,
    },
);

for my $Test (@Tests) {

    my $ProcessList = $ProcessObject->ProcessSearch( ProcessName => $Test->{ProcessName} );

    $Self->Is(
        scalar keys @{$ProcessList},
        $Test->{Count},
        "$Test->{Name} | Number of processes List is as expected: $Test->{Count}.",
    );

    $Self->IsDeeply(
        $ProcessList,
        $Test->{Result},
        "$Test->{Name} | Result of process search is as expected.",
    );

}

#
# ProcessGet()
#

@Tests = (
    {
        Name    => 'ProcessGet Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ProcessGet Test 2: No ID and EntityID',
        Config => {
            ID            => undef,
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessGet Test 3: No UserID',
        Config => {
            ID            => 1,
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessGet Test 4: Wrong ID',
        Config => {
            ID            => '9999999',
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessGet Test 5: Wrong EntityID',
        Config => {
            ID            => undef,
            EntityID      => '9999999',
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessGet Test 6: Correct ASCII, W/ID, WO/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[0],
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 7: Correct ASCII, W/ID, W/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[0],
            EntityID      => undef,
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 8: Correct UTF8, W/ID, WO/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[1],
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 9: Correct UTF8, W/ID, W/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[1],
            EntityID      => undef,
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 11: Correct UTF82, W/ID, WO/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[2],
            EntityID      => undef,
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 12: Correct UTF82, W/ID, W/ActivityNames ',
        Config => {
            ID            => $AddedProcessList[2],
            EntityID      => undef,
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 13: Correct ASCII, W/EntityID, WO/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[0] }->{EntityID},
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 14: Correct ASCII, W/EntityID, W/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[0] }->{EntityID},
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 15: Correct UTF8, W/EntityID, WO/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[1] }->{EntityID},
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 16: Correct UTF8, W/EntityID, W/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[1] }->{EntityID},
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 17: Correct UTF82, W/EntityID, WO/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[2] }->{EntityID},
            ActivityNames => 0,
            UserID        => $UserID,
        },
        Success => 1,
    },
    {
        Name   => 'ProcessGet Test 18: Correct UTF82, W/EntityID, W/ActivityNames ',
        Config => {
            ID            => undef,
            EntityID      => $AddedProcess{ $AddedProcessList[2] }->{EntityID},
            ActivityNames => 1,
            UserID        => $UserID,
        },
        Success => 1,
    },
);

for my $Test (@Tests) {
    my $Process = $ProcessObject->ProcessGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->Is(
            ref $Process,
            'HASH',
            "$Test->{Name} | Process structure is HASH",
        );
        $Self->True(
            IsHashRefWithData($Process),
            "$Test->{Name} | Process structure is non empty HASH",
        );
        if ( $Test->{Config}->{ActivityNames} ) {
            $Self->Is(
                ref $Process->{Activities},
                'HASH',
                "$Test->{Name} | Process Activities structure is HASH",
            );

            my %ExpectedActivities = map { $_ => $ActivityLookup{$_} }
                sort keys %{ $AddedProcess{ $Process->{ID} }->{Config}->{Path} };
            $Self->IsDeeply(
                $Process->{Activities},
                \%ExpectedActivities,
                "$Test->{Name} | Process Activities"
            );
        }
        else {
            $Self->Is(
                ref $Process->{Activities},
                'ARRAY',
                "$Test->{Name} | Process Activities structure is ARRAY",
            );

            my @ExpectedActivities = map {$_} sort keys %{ $AddedProcess{ $Process->{ID} }->{Config}->{Path} };
            $Self->IsDeeply(
                $Process->{Activities},
                \@ExpectedActivities,
                "$Test->{Name} | Process Activities"
            );
        }

        my $ActivityNames = 0;
        if ( defined $Test->{Config}->{ActivityNames} && $Test->{Config}->{ActivityNames} == 1 ) {
            $ActivityNames = 1;
        }

        my $TransitionNames = 0;
        if ( defined $Test->{Config}->{TransitionNames} && $Test->{Config}->{TransitionNames} == 1 )
        {
            $TransitionNames = 1;
        }

        my $TransitionActionNames = 0;
        if (
            defined $Test->{Config}->{TransitionActionNames}
            && $Test->{Config}->{TransitionActionNames} == 1
            )
        {
            $TransitionActionNames = 1;
        }

        # check cache
        my $CacheKey;
        if ( $Test->{Config}->{ID} ) {
            $CacheKey = join '::', 'ProcessGet::ID', $Test->{Config}->{ID}, 'ActivityNames',
                $ActivityNames,
                'TransitionNames',
                $TransitionNames,
                'TransitionActionNames',
                $TransitionActionNames;
        }
        else {
            $CacheKey = join '::', 'ProcessGet::EntityID', $Test->{Config}->{EntityID},
                'ActivityNames',
                $ActivityNames,
                'TransitionNames',
                $TransitionNames,
                'TransitionActionNames',
                $TransitionActionNames;
        }

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Process',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $Process,
            "$Test->{Name} | Process cache"
        );

        # remove not need parameters
        my %ExpectedProcess = %{ $AddedProcess{ $Process->{ID} } };
        delete $ExpectedProcess{UserID};

        # create a variable copy otherwise the cache will be altered
        my %ProcessCopy = %{$Process};

        for my $Attribute (
            qw(ID Activities Transitions TransitionActions CreateTime ChangeTime State)
            )
        {
            $Self->IsNot(
                $ProcessCopy{$Attribute},
                undef,
                "$Test->{Name} | Process->{$Attribute} should not be undef",
            );
            delete $ProcessCopy{$Attribute};
        }

        $Self->IsDeeply(
            \%ProcessCopy,
            \%ExpectedProcess,
            "$Test->{Name} | Process"
        );
    }
    else {
        $Self->False(
            ref $Process eq 'HASH',
            "$Test->{Name} | Process structure is not HASH",
        );
        $Self->Is(
            $Process,
            undef,
            "$Test->{Name} | Process should be undefined",
        );
    }
}

#
# ProcessUpdate() tests
#
@Tests = (
    {
        Name    => 'ProcessUpdate Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 2: No ID',
        Config => {
            ID            => undef,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 3: No EntityID',
        Config => {
            ID            => 1,
            EntityID      => undef,
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 5: No Name',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => undef,
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 6: No StateEntityID',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => undef,
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 7: No Layout',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => undef,
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 7: No Layout',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => undef,
            Config        => {
                Description => 'a Description',
            },
            UserID => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 9: No Config',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => undef,
            UserID        => $UserID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 10: No UserID',
        Config => {
            ID            => 1,
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description',
            },
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessUpdate Test 11: Correct ASCII',
        Config => {
            ID            => $AddedProcessList[0],
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID -U",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ProcessUpdate Test 12: Correct UTF8',
        Config => {
            ID            => $AddedProcessList[1],
            EntityID      => $RandomID . '-1-U',
            Name          => "Process-$RandomID -!Â§$%&/()=?Ã*ÃÃL:L@,.--U",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description Â§$%&/()=?Ã*ÃÃL:L@,.--U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ProcessUpdate Test 13: Correct UTF8 2',
        Config => {
            ID            => $AddedProcessList[1],
            EntityID      => $RandomID . '-2-U',
            Name          => "Process-$RandomID -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description -äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 1
    },
    {
        Name   => 'ProcessUpdate Test 14: Correct ASCII No DBUpdate',
        Config => {
            ID            => $AddedProcessList[0],
            EntityID      => $RandomID . '-U',
            Name          => "Process-$RandomID -U",
            StateEntityID => 'S1',
            Layout        => {},
            Config        => {
                Description => 'a Description-U',
            },
            UserID => $UserID,
        },
        Success  => 1,
        UpdateDB => 0,
    },
);

for my $Test (@Tests) {

    # get the old process (if any)
    my $OldProcess = $ProcessObject->ProcessGet(
        ID     => $Test->{Config}->{ID} || 0,
        UserID => $Test->{Config}->{UserID},
    );

    if ( $Test->{Success} ) {

        # try to update the process
        print "Force a gap between create and update process, Waiting 2s\n";

        # wait 2 seconds
        $HelperObject->FixedTimeAddSeconds(2);

        my $Success = $ProcessObject->ProcessUpdate( %{ $Test->{Config} } );

        $Self->IsNot(
            $Success,
            0,
            "$Test->{Name} | Result should be 1"
        );

        # check cache
        my $CacheKey = 'ProcessGet::ID::'
            . $Test->{Config}->{ID}
            . '::ActivityNames::0::TransitionNames::0::TransitionActionNames::0';

        my $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Process',
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
        my $NewProcess = $ProcessObject->ProcessGet(
            ID     => $Test->{Config}->{ID},
            UserID => $Test->{Config}->{UserID},
        );

        # check cache
        $Cache = $CacheObject->Get(
            Type => 'ProcessManagement_Process',
            Key  => $CacheKey,
        );

        $Self->IsDeeply(
            $Cache,
            $NewProcess,
            "$Test->{Name} | Cache is equal to updated process",
        );

        if ( $Test->{UpdateDB} ) {
            $Self->IsNotDeeply(
                $NewProcess,
                $OldProcess,
                "$Test->{Name} | Updated process is different than original",
            );

            # check create and change times
            $Self->Is(
                $NewProcess->{CreateTime},
                $OldProcess->{CreateTime},
                "$Test->{Name} | Updated process create time should not change",
            );
            $Self->IsNot(
                $NewProcess->{ChangeTime},
                $OldProcess->{ChangeTime},
                "$Test->{Name} | Updated process change time should be different",
            );

            # remove not need parameters
            my %ExpectedProcess = %{ $Test->{Config} };
            delete $ExpectedProcess{UserID};

            # create a variable copy otherwise the cache will be altered
            my %NewProcessCopy = %{$NewProcess};

            for my $Attribute (
                qw( Activities Transitions TransitionActions CreateTime ChangeTime State)
                )
            {
                delete $NewProcessCopy{$Attribute};
            }

            $Self->IsDeeply(
                \%NewProcessCopy,
                \%ExpectedProcess,
                "$Test->{Name} | Process"
            );
        }
        else {
            $Self->IsDeeply(
                $NewProcess,
                $OldProcess,
                "$Test->{Name} | Updated process is equal than original",
            );
        }
    }
    else {
        my $Success = $ProcessObject->ProcessUpdate( %{ $Test->{Config} } );

        $Self->False(
            $Success,
            "$Test->{Name} | Result should fail",
        );
    }
}

#
# ProcessList() tests
#

# no params
my $TestProcessList = $ProcessObject->ProcessList();

$Self->Is(
    $TestProcessList,
    undef,
    "ProcessList Test 1: No Params | Should be undef",
);

# normal process list
$TestProcessList = $ProcessObject->ProcessList( UserID => $UserID );

$Self->Is(
    ref $TestProcessList,
    'HASH',
    "ProcessList Test 2: All Process | Should be a HASH",
);

$Self->True(
    IsHashRefWithData($TestProcessList),
    "ProcessList Test 2: All Process | Should be not empty HASH",
);

$Self->IsNotDeeply(
    $TestProcessList,
    $OriginalProcessList,
    "ProcessList Test 2: All Process | Should be different than the original",
);

# create a variable copy otherwise the cache will be altered
my %TestProcessListCopy = %{$TestProcessList};

# delete original process
for my $ProcessID ( sort keys %{$OriginalProcessList} ) {
    delete $TestProcessListCopy{$ProcessID};
}

$Self->Is(
    scalar keys %TestProcessListCopy,
    scalar @AddedProcessList,
    "ProcessList Test 2: All Process | Number of processes match added processes",
);

my $Counter = 0;
for my $ProcessID ( sort { $a cmp $b } keys %TestProcessListCopy ) {
    $Self->Is(
        $ProcessID,
        $AddedProcessList[$Counter],
        "ProcessList Test 2: All Process | ProcessID match AddedProcessID",
    );
    $Counter++;
}

# prepare process for listing
my $Process = $ProcessObject->ProcessGet(
    ID     => $AddedProcessList[0],
    UserID => $UserID,
);
my $Success = $ProcessObject->ProcessUpdate(
    ID => $AddedProcessList[0],
    %{$Process},
    StateEntityID => 'S1',
    UserID        => 1,
);

$Self->IsNot(
    $Success,
    0,
    "ProcessList | Updated process for ProcessID:'$AddedProcessList[0]' result should be 1",
);

for my $Index ( 1, 2 ) {

    my $Process = $ProcessObject->ProcessGet(
        ID     => $AddedProcessList[$Index],
        UserID => $UserID,
    );
    my $Success = $ProcessObject->ProcessUpdate(
        ID => $AddedProcessList[$Index],
        %{$Process},
        StateEntityID => 'S2',
        UserID        => 1,
    );

    $Self->IsNot(
        $Success,
        0,
        "ProcessList | Updated process for ProcessID:'$AddedProcessList[$Index]' result should be 1",
    );
}

@Tests = (
    {
        Name   => 'ProcessList Test3: State S1',
        Config => {
            UseEntities    => 0,
            StateEntityIDs => ['S1'],
            UserID         => $UserID,
        },
    },
    {
        Name   => 'ProcessList Test3: State S2',
        Config => {
            UseEntities    => 0,
            StateEntityIDs => ['S2'],
            UserID         => $UserID,
        },
    },
    {
        Name   => 'ProcessList Test4: State S3',
        Config => {
            UseEntities    => 0,
            StateEntityIDs => ['S3'],
            UserID         => $UserID,
        },
    },
    {
        Name   => 'ProcessList Test5: State S1, State S2, State S3',
        Config => {
            UseEntities    => 0,
            StateEntityIDs => [ 'S1', 'S2', 'S3' ],
            UserID         => $UserID,
        },
        AllProcess => 1,
    },
    {
        Name   => 'ProcessList Test6: Empty list',
        Config => {
            UseEntities    => 0,
            StateEntityIDs => [$RandomID],
            UserID         => $UserID,
        },
        EmptyList => 1,
    },
);

for my $Test (@Tests) {
    my $ProcessList = $ProcessObject->ProcessList( %{ $Test->{Config} } );

    # create a variable copy otherwise the cache will be altered
    my %ProcessListCopy = %{$ProcessList};

    # remove original processes
    PROCESSID:
    for my $ProcessID ( sort keys %{$OriginalProcessList} ) {
        next PROCESSID if !$ProcessListCopy{$ProcessID};
        delete $ProcessListCopy{$ProcessID};
    }

    # special case for empty list
    if ( $Test->{EmptyList} ) {
        $Self->False(
            scalar keys %ProcessListCopy,
            "$Test->{Name} | List is empty",
        );
    }
    else {

        # special case for all process
        if ( $Test->{AllProcess} ) {
            $Self->IsDeeply(
                \%ProcessListCopy,
                \%TestProcessListCopy,
                "$Test->{Name} | List is identical as in no State filter",
            );
        }
        else {
            $Self->IsNotDeeply(
                \%ProcessListCopy,
                \%TestProcessListCopy,
                "$Test->{Name} | List is different as in no State filter",
            );

            $Self->IsNot(
                scalar keys %ProcessListCopy,
                scalar keys %TestProcessListCopy,
                "$Test->{Name} | Number of processes List is different as in no State filter",
            );
        }
    }
}

#
# ProcessDelete() (test for fail, test for success are done by removing processes at the end)
#
@Tests = (
    {
        Name    => 'ProcessDelete Test 1: No params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'ProcessDelete Test 2: No process ID',
        Config => {
            ID     => undef,
            UserID => $RandomID,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessDelete Test 3: No UserID',
        Config => {
            ID     => $RandomID,
            UserID => undef,
        },
        Success => 0,
    },
    {
        Name   => 'ProcessDelete Test 4: Wrong process ID',
        Config => {
            ID     => '9999999',
            UserID => $UserID,
        },
        Success => 0,
    },
);

for my $Test (@Tests) {
    my $Success = $ProcessObject->ProcessDelete( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->True(
            $Success,
            "$Test->{Name} | Process deleted with true",
        );
    }
    else {
        $Self->False(
            $Success,
            "$Test->{Name} | Process delete with false",
        );
    }
}

#
# ProcessListGet() tests
#

my $FullList = $ProcessObject->ProcessListGet(
    UserID => undef,
);

$Self->IsNot(
    ref $FullList,
    'ARRAY',
    "ProcessListGet Test 1: No UserID | List Should not be an array",
);

# get the List of processes with all details
$FullList = $ProcessObject->ProcessListGet(
    UserID => $UserID,
);

# get simple list of processes
my $List = $ProcessObject->ProcessList(
    UserID => $UserID,
);

# create the list of processes with details manually
my $ExpectedProcessList;
for my $ProcessID ( sort { int $a <=> int $b } keys %{$List} ) {

    my $ProcessData = $ProcessObject->ProcessGet(
        ID     => $ProcessID,
        UserID => $UserID,
    );
    push @{$ExpectedProcessList}, $ProcessData;
}

$Self->Is(
    ref $FullList,
    'ARRAY',
    "ProcessListGet Test 2: Correct List | Should be an array",
);

$Self->True(
    IsArrayRefWithData($FullList),
    "ProcessListGet Test 2: Correct List | The list is not empty",
);

$Self->IsDeeply(
    $FullList,
    $ExpectedProcessList,
    "ProcessListGet Test 2: Correct List | Process List",
);

# check cache
my $CacheKey = 'ProcessListGet';

my $Cache = $CacheObject->Get(
    Type => 'ProcessManagement_Process',
    Key  => $CacheKey,
);

$Self->IsDeeply(
    $Cache,
    $FullList,
    "ProcessListGet Test 2: Correct List | Cache",
);

# cleanup is done by RestoreDatabase

1;
