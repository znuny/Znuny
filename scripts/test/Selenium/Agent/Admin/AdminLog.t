# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # Set log module in sysconfig.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'LogModule',
            Value => 'Kernel::System::Log::SysLog',
        );

        # Clear log.
        $LogObject->CleanUp();

        # Destroy and instantiate log object.
        $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Log'] );
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::Log' => {
                LogPrefix => 'TestAdminLog',
            },
        );
        $LogObject = $Kernel::OM->Get('Kernel::System::Log');

        my @LogMessages;

        # Create log entries.
        for ( 0 .. 1 ) {
            my $LogMessage = 'LogMessage' . $HelperObject->GetRandomNumber();

            $LogObject->Log(
                Priority => 'error',
                Message  => $LogMessage,
            );

            push @LogMessages, $LogMessage;
        }

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # Navigate to AdminLog screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminLog");

        # filter with the first log entry
        $Selenium->find_element( "#FilterLogEntries", 'css' )->clear();
        $Selenium->find_element( "#FilterLogEntries", 'css' )->send_keys( $LogMessages[0], "\N{U+E007}" );
        sleep 1;

        # Check if the first log entry is shown in the table.
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#LogEntries tr td:contains($LogMessages[0])').parent().css('display')"
            ),
            'table-row',
            "First log entry exists in the table",
        );

        # Check if the second log entry is not shown in the table.
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#LogEntries tr td:contains($LogMessages[1])').parent().css('display')"
            ),
            'none',
            "Second log entry does not exist in the table",
        );

        # Click on 'Hide this message'.
        $Selenium->find_element( "#HideHint", 'css' )->click();
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $(".SidebarColumn:hidden").length'
        );

        # Check if sidebar column is shown.
        $Self->Is(
            $Selenium->execute_script(
                "return \$('.SidebarColumn').css('display')"
            ),
            'none',
            "Sidebar column is not visible on the screen",
        );

        # Verify log time stamp is in user default time zone (UTC).
        $Self->True(
            $Selenium->execute_script("return \$('#LogEntries .Error:eq(0)').text().indexOf('UTC') !== -1"),
            "Log time stamp is in user default time zone (UTC) format."
        );

        # Get test UserID.
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my $UserID     = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # Set test user's time zone.
        my $UserTimeZone = 'Europe/Berlin';
        $UserObject->SetPreferences(
            Key    => 'UserTimeZone',
            Value  => $UserTimeZone,
            UserID => $UserID,
        );

        # Relog test user.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminLog");

        # Verify log time stamp is in user preference time zone (Europe/Berlin).
        $Self->True(
            $Selenium->execute_script("return \$('#LogEntries .Error:eq(0)').text().indexOf('$UserTimeZone') !== -1"),
            "Log time stamp is in user preference time zone ($UserTimeZone) format."
        );

        # Login test user again.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminLog");

        $Self->True(
            $Selenium->execute_script(
                "return \$('#LogEntries tbody tr').length == 4"
            ),
            "4 log entries exists in the table",
        );

        $Selenium->find_element( '#ClearLogEntries', 'css' )->click();

        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminLog");

        # Check for expected result.
        $Self->True(
            $Selenium->execute_script(
                "return \$(\"#LogEntries tr td:contains('No data found')\").length == 1"
            ),
            "No log entries exists in the table",
        );

        # Clear log.
        $LogObject->CleanUp();

        # Make sure cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
    }
);

1;
