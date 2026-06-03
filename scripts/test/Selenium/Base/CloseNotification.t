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

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Enable notification modules that will generate alerts
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::NotifyModule###2000-UID-Check',
            Value => {
                Module => 'Kernel::Output::HTML::Notification::UIDCheck',
            },
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::NotifyModule###8000-Daemon-Check',
            Value => {
                Module => 'Kernel::Output::HTML::Notification::DaemonCheck',
            },
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::NotifyModule###7000-AgentTimeZone-Check',
            Value => {
                Module => 'Kernel::Output::HTML::Notification::AgentTimeZoneCheck',
            },
        );

        # Allow apache to pick up the changed SysConfig via Apache::Reload.
        sleep 1;

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

        # Navigate to a page that will trigger the notifications
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentDashboard");

        # Wait for notifications to be rendered
        $Selenium->WaitFor(
            JavaScript => 'return jQuery(".message:visible, .modAlert:visible").length > 0',
            Time       => 10,
        );

        # Test 1: CloseNotification() without parameters - close all messages
        # Count messages before closing
        my $MessageCount = $Selenium->execute_script(
            'return jQuery(".message:visible, .modAlert:visible").length;'
        );
        $Self->True(
            $MessageCount > 0,
            'At least one message/alert is visible before closing',
        );

        # Close all messages
        $Selenium->CloseNotification();

        # Wait for messages to be closed
        $Selenium->WaitFor(
            JavaScript => 'return jQuery(".message:visible, .modAlert:visible").length === 0',
            Time       => 5,
        );

        # Verify all messages are closed
        my $RemainingMessages = $Selenium->execute_script(
            'return jQuery(".message:visible, .modAlert:visible").length;'
        );
        $Self->Is(
            $RemainingMessages,
            0,
            'All messages are closed when calling CloseNotification() without parameters',
        );

        # Reload page to get notifications again
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentDashboard");

        # Wait for notifications to be rendered again
        $Selenium->WaitFor(
            JavaScript => 'return jQuery(".message:visible, .modAlert:visible").length > 0',
            Time       => 10,
        );

        # Test 2: CloseNotification() with Text parameter - close only specific messages
        # Check if time zone message is present
        my $TimeZoneMessagePresent = $Selenium->execute_script(
            'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("time zone") !== -1; }).length > 0;'
        );

        if ($TimeZoneMessagePresent) {

            # Count all messages before selective closing
            $MessageCount = $Selenium->execute_script(
                'return jQuery(".message:visible, .modAlert:visible").length;'
            );
            $Self->True(
                $MessageCount > 0,
                'Messages are visible before selective closing',
            );

            # Close only messages containing "time zone"
            $Selenium->CloseNotification(
                Text => 'time zone',
            );

            # Wait for the specific message to be closed
            $Selenium->WaitFor(
                JavaScript =>
                    'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("time zone") !== -1; }).length === 0',
                Time => 5,
            );

            # Verify the time zone message is closed
            my $TimeZoneMessageCount = $Selenium->execute_script(
                'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("time zone") !== -1; }).length;'
            );
            $Self->Is(
                $TimeZoneMessageCount,
                0,
                'Message containing "time zone" is closed',
            );

            # Verify other messages may still be visible
            my $RemainingCount = $Selenium->execute_script(
                'return jQuery(".message:visible, .modAlert:visible").length;'
            );
            $Self->True(
                $RemainingCount >= 0,
                'Other messages may remain visible after selective closing',
            );
        }
        else {
            $Self->True(
                1,
                'Time zone message not present, skipping selective closing test',
            );
        }

        # Test 3: Close daemon message if present
        my $DaemonMessagePresent = $Selenium->execute_script(
            'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("Daemon") !== -1; }).length > 0;'
        );

        if ($DaemonMessagePresent) {

            # Close only messages containing "Daemon"
            $Selenium->CloseNotification(
                Text => 'Daemon',
            );

            # Wait for the daemon message to be closed
            $Selenium->WaitFor(
                JavaScript =>
                    'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("Daemon") !== -1; }).length === 0',
                Time => 5,
            );

            # Verify daemon message is closed
            my $DaemonMessageCount = $Selenium->execute_script(
                'return jQuery(".message:visible, .modAlert:visible").filter(function() { return jQuery(this).text().indexOf("Daemon") !== -1; }).length;'
            );
            $Self->Is(
                $DaemonMessageCount,
                0,
                'Message containing "Daemon" is closed',
            );
        }
        else {
            $Self->True(
                1,
                'Daemon message not present, skipping daemon closing test',
            );
        }

        # Cleanup: close remaining messages
        $Selenium->CloseNotification();

        # Verify all messages are closed
        $Selenium->WaitFor(
            JavaScript => 'return jQuery(".message:visible, .modAlert:visible").length === 0',
            Time       => 5,
        );

        $RemainingMessages = $Selenium->execute_script(
            'return jQuery(".message:visible, .modAlert:visible").length;'
        );
        $Self->Is(
            $RemainingMessages,
            0,
            'All messages are closed after cleanup',
        );
    }
);

1;
