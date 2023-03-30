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

my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SysConfigObject          = $Kernel::OM->Get('Kernel::System::SysConfig');
my $SysConfigMigrationObject = $Kernel::OM->Get('Kernel::System::SysConfig::Migration');
my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');

# So the test works in transaction in order to avoid crash the system if tests is failed.
my $StartedTransaction = $HelperObject->BeginWork();
$Self->True(
    $StartedTransaction,
    'Started database transaction.',
);

# Load sample XML file.
my $Directory = $ConfigObject->Get('Home') . '/scripts/test/sample/SysConfig/Migration';
my $XMLLoaded = $SysConfigObject->ConfigurationXML2DB(
    UserID    => 1,
    Directory => $Directory,
    Force     => 1,
    CleanUp   => 0,
);

$Self->True(
    $XMLLoaded,
    "Example XML loaded.",
);

my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
    Comments           => "MigrateSysConfigSettings deployment",
    UserID             => 1,
    Force              => 1,
    AllSettings        => 1,
    OverriddenFileName => 1,
);

$Self->True(
    $DeploymentResult{Success},
    "Deployment successful.",
);

my @Tests = (
    {
        Name         => 'String - AddEffectiveValue',
        OriginalData => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
            IsValid        => 1,
        },
        Data => {
            'EmptyString' => {
                AddEffectiveValue => 'Ticket#',
            }
        },
        Expected => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
        }
    },
    {
        Name         => 'String - UpdateEffectiveValue',
        OriginalData => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
            IsValid        => 1,
        },
        Data => {
            'EmptyString' => {
                UpdateEffectiveValue => {
                    'Ticket#' => 'Znuny###',
                },
            }
        },
        Expected => {
            Name           => 'EmptyString',
            EffectiveValue => 'Znuny###'
        }
    },
    {
        Name         => 'String - DeleteEffectiveValue',
        OriginalData => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
            IsValid        => 1,
        },
        Data => {
            'EmptyString' => {
                DeleteEffectiveValue => 'Ticket#',
            }
        },
        Expected => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
        }
    },
    {
        Name         => 'String - EffectiveValue',
        OriginalData => {
            Name           => 'EmptyString',
            EffectiveValue => 'Ticket#',
            IsValid        => 1,
        },
        Data => {
            'EmptyString' => {
                EffectiveValue => 'Znuny###',
            }
        },
        Expected => {
            Name           => 'EmptyString',
            EffectiveValue => 'Znuny###',
        }
    },

    {
        Name         => 'Array - AddEffectiveValue',
        OriginalData => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
            ],
            IsValid => 1,
        },
        Data => {
            'EmptyArray' => {
                AddEffectiveValue => [
                    'thirdparty/canvg-1.4/canvg.js',
                ]
            }
        },
        Expected => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
                'thirdparty/canvg-1.4/canvg.js',
            ]
        }
    },
    {
        Name         => 'Array - UpdateEffectiveValue',
        OriginalData => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
            ],
            IsValid => 1,
        },
        Data => {
            'EmptyArray' => {
                UpdateEffectiveValue => {
                    'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js' =>
                        'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
                    'thirdparty/jquery-3.5.1/jquery.js' => 'thirdparty/jquery-3.6.0/jquery.js',
                },
            }
        },
        Expected => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
                'thirdparty/jquery-3.6.0/jquery.js',
            ]
        }
    },
    {
        Name         => 'Array - DeleteEffectiveValue',
        OriginalData => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
                'thirdparty/jquery-3.4.1/jquery.js',
            ],
            IsValid => 1,
        },
        Data => {
            'EmptyArray' => {
                DeleteEffectiveValue => [
                    'thirdparty/jquery-3.4.1/jquery.js',
                ]
            }
        },
        Expected => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
            ]
        }
    },
    {
        Name         => 'Array - EffectiveValue',
        OriginalData => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.0/jquery.js',
            ],
            IsValid => 1,
        },
        Data => {
            'EmptyArray' => {
                EffectiveValue => [
                    'thirdparty/jquery-3.5.1/jquery.js',
                    'thirdparty/canvg-1.4/canvg.js',
                ]
            }
        },
        Expected => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-3.5.1/jquery.js',
                'thirdparty/canvg-1.4/canvg.js',
            ]
        }
    },
    {
        Name         => 'Array - AddEffectiveValue, UpdateEffectiveValue and DeleteEffectiveValue',
        OriginalData => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js',
                'thirdparty/jquery-3.5.1/jquery.js',
                'thirdparty/jquery-3.4.1/jquery.js',
            ],
            IsValid => 1,
        },
        Data => {
            'EmptyArray' => {
                UpdateEffectiveValue => {
                    'thirdparty/jquery-jstree-3.3.1/jquery.jstree.js' =>
                        'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
                    'thirdparty/jquery-3.5.1/jquery.js' => 'thirdparty/jquery-3.6.0/jquery.js',
                },
                AddEffectiveValue => [
                    'thirdparty/canvg-1.4/canvg.js',
                ],
                DeleteEffectiveValue => [
                    'thirdparty/jquery-3.4.1/jquery.js',
                ],
            }
        },
        Expected => {
            Name           => 'EmptyArray',
            EffectiveValue => [
                'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
                'thirdparty/jquery-3.6.0/jquery.js',
                'thirdparty/canvg-1.4/canvg.js',
            ]
        }
    },

    {
        Name         => 'Hash - AddEffectiveValue',
        OriginalData => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
            },
            IsValid => 1,
        },
        Data => {
            EmptyHash => {
                AddEffectiveValue => {
                    'd' => 4,
                }
            }
        },
        Expected => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
                'd' => 4,
            }
        }
    },
    {
        Name         => 'Hash - UpdateEffectiveValue',
        OriginalData => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
            },
            IsValid => 1,
        },
        Data => {
            EmptyHash => {
                UpdateEffectiveValue => {
                    'b' => {
                        Key   => 'f',
                        Value => '5',
                    },
                },
            }
        },
        Expected => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'c' => 3,
                'f' => 5,
            }
        }
    },
    {
        Name         => 'Hash - DeleteEffectiveValue',
        OriginalData => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
            },
            IsValid => 1,
        },
        Data => {
            EmptyHash => {
                DeleteEffectiveValue => [
                    'a',
                ]
            }
        },
        Expected => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'b' => 2,
                'c' => 3,
            }
        }
    },
    {
        Name         => 'Hash - EffectiveValue',
        OriginalData => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
            },
            IsValid => 1,
        },
        Data => {
            EmptyHash => {
                EffectiveValue => {
                    'a' => 1,
                    'b' => 2,
                    'c' => 3,
                    'd' => 4,
                },
            }
        },
        Expected => {
            Name           => 'EmptyHash',
            EffectiveValue => {
                'a' => 1,
                'b' => 2,
                'c' => 3,
                'd' => 4,
            },
        }
    },
);

# Test it in 'eval' block in order to avoid crash the system after failing the test.
eval {
    for my $Test (@Tests) {

        my $SettingName = $Test->{OriginalData}->{Name};

        my %StartSetting = $SysConfigObject->SettingGet(
            Name => $SettingName,
        );

        my $Result = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => "Deploy $SettingName setting with test",
            Settings => [ $Test->{OriginalData} ],
        );

        my %OriginalSetting = $SysConfigObject->SettingGet(
            Name => $SettingName,
        );

        $Self->IsDeeply(
            $OriginalSetting{EffectiveValue},
            $Test->{OriginalData}->{EffectiveValue},
            $Test->{Name} . " - Settings $SettingName are set original value.",
        );

        # Run migration module
        my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
            Data => $Test->{Data},
        );

        $Self->True(
            $Success,
            $Test->{Name} . " - MigrateModifiedSettings: migration is done.",
        );

        my %ExpectedSetting = $SysConfigObject->SettingGet(
            Name => $SettingName,
        );

        $Self->Is(
            $ExpectedSetting{Name},
            $Test->{Expected}->{Name},
            $Test->{Name} . " - Settings $SettingName are migrated to expected name.",
        );

        $Self->IsDeeply(
            $ExpectedSetting{EffectiveValue},
            $Test->{Expected}->{EffectiveValue},
            $Test->{Name} . " - Settings $SettingName are migrated to expected value.",
        );

        my $Guid = $SysConfigObject->SettingLock(
            UserID    => 1,
            DefaultID => $OriginalSetting{DefaultID},
            Force     => 1,
        );
        $Self->True(
            $Guid,
            $Test->{Name} . " - Lock setting before reset($SettingName).",
        );

        $Success = $SysConfigObject->SettingReset(
            Name              => $SettingName,
            ExclusiveLockGUID => $Guid,
            UserID            => 1,
        );
        $Self->True(
            $Success,
            $Test->{Name} . " - Setting $SettingName reset to the default value.",
        );

        $SysConfigObject->SettingUnlock(
            DefaultID => $OriginalSetting{DefaultID},
        );
    }
};

my $RollbackSuccess = $HelperObject->Rollback();
$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
$Self->True(
    $RollbackSuccess,
    'Rolled back all database changes and cleaned up the cache.',
);

my %Result = $SysConfigObject->ConfigurationDeploy(
    Comments    => "Revert changes.",
    UserID      => 1,
    Force       => 1,
    AllSettings => 1,
);

$Self->True(
    $Result{Success},
    'Configuration restored.',
);

1;
