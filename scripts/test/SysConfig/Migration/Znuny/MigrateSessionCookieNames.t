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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MainObject               = $Kernel::OM->Get('Kernel::System::Main');
my $SysConfigObject          = $Kernel::OM->Get('Kernel::System::SysConfig');
my $SysConfigMigrationObject = $Kernel::OM->Get('Kernel::System::SysConfig::Migration');

my $Home            = $ConfigObject->{Home};
my $SampleDirectory = $Home . '/scripts/test/sample/SysConfig/Migration/';

my $ModuleLoaded = $MainObject->Require('scripts::Migration::Znuny::MigrateSysConfigSettings');
$Self->True(
    $ModuleLoaded,
    'Migration module could be loaded.',
);

my $MigrationObject          = scripts::Migration::Znuny::MigrateSysConfigSettings->new();
my %MigrateSysConfigSettings = $MigrationObject->_GetMigrateSysConfigSettings();

my %ExpectedMigration = (
    SessionName => {
        UpdateEffectiveValue => {
            OTRSAgentInterface => 'ZnunyAgentInterface',
        },
    },
    CustomerPanelSessionName => {
        UpdateEffectiveValue => {
            OTRSCustomerInterface => 'ZnunyCustomerInterface',
        },
    },
);

my %Data;
SETTING:
for my $SettingName ( sort keys %ExpectedMigration ) {
    my $MapMatches = $Self->IsDeeply(
        $MigrateSysConfigSettings{$SettingName},
        $ExpectedMigration{$SettingName},
        "$SettingName replaces only the old default cookie name",
    );
    next SETTING if !$MapMatches;

    $Data{$SettingName} = $MigrateSysConfigSettings{$SettingName};
}

# The upgrade reads the cookie name from the config backup, not from the
# database. The database is set to the other case so a mix-up fails the test.
my @Tests = (
    {
        Name      => 'Old default names in the backup are renamed',
        FileClass => 'scripts::test::sample::SysConfig::Migration::SessionCookieNamesLegacy',
        FileName  => 'SessionCookieNamesLegacy.pm',
        Database  => {
            SessionName              => 'NotTheBackup',
            CustomerPanelSessionName => 'NotTheBackup',
        },
        Expected => {
            SessionName              => 'ZnunyAgentInterface',
            CustomerPanelSessionName => 'ZnunyCustomerInterface',
        },
    },
    {
        Name      => 'Custom names in the backup are kept',
        FileClass => 'scripts::test::sample::SysConfig::Migration::SessionCookieNamesCustom',
        FileName  => 'SessionCookieNamesCustom.pm',
        Database  => {
            SessionName              => 'OTRSAgentInterface',
            CustomerPanelSessionName => 'OTRSCustomerInterface',
        },
        Expected => {
            SessionName              => 'CustomAgentSession',
            CustomerPanelSessionName => 'CustomCustomerSession',
        },
    },
);

TEST:
for my $Test (@Tests) {
    next TEST if !%Data;

    my $FilePath = $SampleDirectory . $Test->{FileName};

    $Self->True(
        -e $FilePath,
        "$Test->{Name} - sample config exists",
    );

    my @Settings;
    for my $SettingName ( sort keys %{ $Test->{Database} } ) {
        push @Settings, {
            Name           => $SettingName,
            EffectiveValue => $Test->{Database}->{$SettingName},
            IsValid        => 1,
        };
    }

    my $Stored = $SysConfigObject->SettingsSet(
        UserID   => 1,
        Comments => 'Session cookie migration test setup.',
        Settings => \@Settings,
    );
    $Self->True(
        $Stored,
        "$Test->{Name} - database values stored",
    );

    my $Migrated = $SysConfigMigrationObject->MigrateSysConfigSettings(
        FileClass => $Test->{FileClass},
        FilePath  => $FilePath,
        Data      => \%Data,
    );
    $Self->True(
        $Migrated,
        "$Test->{Name} - migration finished",
    );

    for my $SettingName ( sort keys %{ $Test->{Expected} } ) {
        my %Setting = $SysConfigObject->SettingGet(
            Name    => $SettingName,
            NoCache => 1,
        );

        $Self->Is(
            $Setting{EffectiveValue},
            $Test->{Expected}->{$SettingName},
            "$Test->{Name} - $SettingName",
        );
    }
}

# SettingsSet deploys ZZZAAuto.pm while this test's values are still in the
# transaction. Roll the database back first, then deploy that clean state.
my $CacheObject     = $Kernel::OM->Get('Kernel::System::Cache');
my $RollbackSuccess = $HelperObject->Rollback();
$CacheObject->CleanUp();
$HelperObject->{RestoreDatabase} = 0;

$Self->True(
    $RollbackSuccess,
    'Rolled back all database changes and cleaned up the cache.',
);

my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
    Comments    => 'Revert MigrateSessionCookieNames.t changes.',
    UserID      => 1,
    Force       => 1,
    AllSettings => 1,
);

$Self->True(
    $DeploymentResult{Success},
    'Configuration restored.',
);

1;
