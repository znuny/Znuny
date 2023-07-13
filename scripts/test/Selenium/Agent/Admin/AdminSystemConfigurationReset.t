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

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
        my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Navigate to AdminSysConfig screen.
        $Selenium->VerifiedGet(
            "${ScriptAlias}index.pl?Action=AdminSystemConfiguration;Subaction=View;Setting=Ticket%3A%3AFrontend%3A%3AAgentTicketEscalationView%23%23%23Order%3A%3ADefault;"
        );

        # Hover
        my $SelectedItem = $Selenium->find_element( ".SettingEdit", "css" );
        $Selenium->mouse_move_to_location( element => $SelectedItem );

        # Lock setting.
        $Selenium->find_element( ".SettingEdit", "css" )->click();

        # Wait.
        $Selenium->WaitFor(
            Time       => 120,
            JavaScript => 'return $(".SettingsList .WidgetSimple:first").hasClass("HasOverlay") == 0',
        );

        # Change dropdown value do 'Down'.
        $Selenium->InputFieldValueSet(
            Element => '.SettingContent select',
            Value   => 'Down',
        );

        # Save.
        $Selenium->find_element( ".SettingUpdateBox button[value='Save this setting']", "css" )->click();

        # Wait.
        $Selenium->WaitFor(
            Time       => 120,
            JavaScript => 'return $(".SettingsList .WidgetSimple:first").hasClass("HasOverlay") == 0',
        );

        # Make sure that it's saved properly.
        my %Setting = $SysConfigObject->SettingGet(
            Name => 'Ticket::Frontend::AgentTicketEscalationView###Order::Default',
        );

        $Self->Is(
            $Setting{EffectiveValue},
            'Down',
            'Make sure setting is updated.',
        );

        # Expand header.
        $Selenium->find_element( ".SettingsList .WidgetSimple .Header", "css" )->click();

        # Wait.
        $Selenium->WaitFor(
            JavaScript => 'return $(".ResetSetting:visible").length',
        );

        # Click on reset.
        $Selenium->execute_script('$(".ResetSetting").click()');

        # Wait.
        $Selenium->WaitFor(
            JavaScript => 'return $("#ResetConfirm").length',
        );

        # Confirm.
        $Selenium->find_element( "#ResetConfirm", "css" )->click();

        # Wait.
        $Selenium->WaitFor(
            Time       => 120,
            JavaScript => 'return $(".SettingsList .WidgetSimple:first").hasClass("HasOverlay") == 0',
        );

        # Discard Cache object.
        $Kernel::OM->ObjectsDiscard(
            Objects => ['Kernel::System::Cache'],
        );

        # Make sure that setting is reset properly.
        %Setting = $SysConfigObject->SettingGet(
            Name => 'Ticket::Frontend::AgentTicketEscalationView###Order::Default',
        );

        $Self->Is(
            $Setting{EffectiveValue},
            'Up',
            'Make sure setting is reset.',
        );
    }
);

1;
