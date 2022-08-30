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

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # Do not check RichText.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # Define test cases.
        my @Queues = ( '', 'Raw', 'Postmaster', 'NotExsising123', '' );

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

        for my $Queue (@Queues) {

            # Enable or disable setting that will influence the new phone ticket initial screen
            if ($Queue) {
                $HelperObject->ConfigSettingChange(
                    Valid => 1,
                    Key   => 'Ticket::Frontend::UserDefaultQueue',
                    Value => $Queue,
                );
            }
            else {
                $HelperObject->ConfigSettingChange(
                    Valid => 0,
                    Key   => 'Ticket::Frontend::UserDefaultQueue',
                    Value => 'Raw',
                );
            }

            my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

            # Navigate to new phone ticket.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

            # Check page.
            for my $ID (
                qw(FromCustomer CustomerID Dest Subject RichText FileUpload
                NextStateID PriorityID submitRichText)
                )
            {
                my $Element = $Selenium->find_element( "#$ID", 'css' );
                $Element->is_enabled();
                $Element->is_displayed();
            }

            # Depending on the test case check if the queue is preselected or not
            if ( $Queue && $Queue ne 'NotExsising123' ) {
                my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );
                $Self->Is(
                    $Selenium->execute_script(
                        "return \$('#Dest').val()"
                    ),
                    "$QueueID||$Queue",
                    "$Queue is preselected",
                );
            }
            else {
                $Self->Is(
                    $Selenium->execute_script(
                        "return \$('#Dest').val()"
                    ),
                    '||-',
                    'No queue is preselected',
                );
            }
        }
    }
);

1;
