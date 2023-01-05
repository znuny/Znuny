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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $FileTempObject    = $Kernel::OM->Get('Kernel::System::FileTemp');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $StorableObject    = $Kernel::OM->Get('Kernel::System::Storable');
my $SysConfigObject   = $Kernel::OM->Get('Kernel::System::SysConfig');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
my $YAMLObject        = $Kernel::OM->Get('Kernel::System::YAML');

my ( $FH, $Filename ) = $FileTempObject->TempFile();

my $Home = $ConfigObject->Get('Home');

$CacheObject->CleanUp();

#
# Check default setting
#

my %Setting = $SysConfigObject->SettingGet(
    Name     => 'Loader::Agent::CommonCSS###000-Framework',
    Deployed => 1,
    NoLog    => 1,
    NoCache  => 1,
    UserID   => 1,
);

my @ExpectedSettingClean = (
    'Core.Color.css',
    'Core.Reset.css',
    'Core.Default.css',
    'Core.Header.css',
    'Core.OverviewControl.css',
    'Core.OverviewSmall.css',
    'Core.OverviewMedium.css',
    'Core.OverviewLarge.css',
    'Core.Footer.css',
    'Core.PageLayout.css',
    'Core.Form.css',
    'Core.Table.css',
    'Core.Login.css',
    'Core.Widget.css',
    'Core.WidgetMenu.css',
    'Core.TicketDetail.css',
    'Core.Tooltip.css',
    'Core.Dialog.css',
    'Core.InputFields.css',
    'Core.Print.css',
    'Core.Animations.css',
);

$Self->IsDeeply(
    $Setting{EffectiveValue},
    \@ExpectedSettingClean,
    'config is ready for the test and actual the same as the expected test result',
);

my $Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::FixMissingFrontendFiles',
    Parameter     => ['--dryrun'],
);

$Self->True(
    $Result->{STDOUT} =~ m{\{\}}xmsi ? 1 : 0,
    'MissingFiles console command shows all framework files are correct',
);

$CacheObject->CleanUp();

#
# Change relevant setting
#
my $NewEffectiveValue = $StorableObject->Clone(
    Data => $Setting{EffectiveValue},
);
$NewEffectiveValue->[-1] = 'xxx.css';

my $YAMLString = $YAMLObject->Dump(
    Data => $NewEffectiveValue,
);
my $FileLocation = $MainObject->FileWrite(
    Location => $Filename,
    Content  => \$YAMLString,
);

$Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::Update',
    Parameter     => [ '--setting-name', 'Loader::Agent::CommonCSS###000-Framework', '--source-path', $Filename ],
);

$CacheObject->CleanUp();

$Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::FixMissingFrontendFiles',
    Parameter     => ['--dryrun'],
);

$Self->True(
    $Result->{STDOUT} =~ m{\QCore.Animations.css\E}xmsi ? 1 : 0,
    'MissingFiles console command shows that the animation css file is missing',
);

$CacheObject->CleanUp();

#
# Check new setting
#

%Setting = $SysConfigObject->SettingGet(
    Name     => 'Loader::Agent::CommonCSS###000-Framework',
    Deployed => 1,
    NoLog    => 1,
    NoCache  => 1,
    UserID   => 1,
);

my @ExpectedSetting = (
    'Core.Color.css',
    'Core.Reset.css',
    'Core.Default.css',
    'Core.Header.css',
    'Core.OverviewControl.css',
    'Core.OverviewSmall.css',
    'Core.OverviewMedium.css',
    'Core.OverviewLarge.css',
    'Core.Footer.css',
    'Core.PageLayout.css',
    'Core.Form.css',
    'Core.Table.css',
    'Core.Login.css',
    'Core.Widget.css',
    'Core.WidgetMenu.css',
    'Core.TicketDetail.css',
    'Core.Tooltip.css',
    'Core.Dialog.css',
    'Core.InputFields.css',
    'Core.Print.css',
    'Core.Animations.css',
    'xxx.css',
);

$Self->IsNotDeeply(
    $Setting{EffectiveValue},
    \@ExpectedSetting,
    'config is ready for the test and actual the same as the expected test result',
);

$Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::FixMissingFrontendFiles',
);

$CacheObject->CleanUp();

$Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::FixMissingFrontendFiles',
    Parameter     => ['--dryrun'],
);

$Self->True(
    $Result->{STDOUT} =~ m{\{\}}xmsi ? 1 : 0,
    'MissingFiles console command shows all framework files are correct',
);

$CacheObject->CleanUp();

#
# Undo config changes
#

$Result = $HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Admin::Config::Update',
    Parameter => [ '--setting-name', 'Loader::Agent::CommonCSS###000-Framework', '--value', \@ExpectedSettingClean ],
);

$CacheObject->CleanUp();

1;
