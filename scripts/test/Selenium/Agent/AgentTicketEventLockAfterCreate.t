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

# Get selenium object.
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get needed objects
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Do not check email addresses.
        $HelperObject->ConfigSettingChange(
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );

        # Do not check RichText.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        # Do not check service and type.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 0,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Type',
            Value => 0,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'DefaultLanguage',
            Value => 'en',
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

        # Get test user ID.
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        my $RandomID = $HelperObject->GetRandomID();

        # Add test customer for testing.
        my $TestCustomer       = 'Customer' . $RandomID;
        my $TestCustomerUserID = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserFirstname  => $TestCustomer,
            UserLastname   => $TestCustomer,
            UserCustomerID => $TestCustomer,
            UserLogin      => $TestCustomer,
            UserEmail      => "$TestCustomer\@localhost.com",
            ValidID        => 1,
            UserID         => $TestUserID,
        );
        $Self->True(
            $TestCustomerUserID,
            "CustomerUserAdd - ID $TestCustomerUserID"
        );

        # Get script alias.
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        for my $LockStatus (qw(lock unlock)) {

            $HelperObject->ConfigSettingChange(
                Valid => $LockStatus eq 'lock' ? 1 : 0,
                Key   => 'Ticket::EventModulePost###3100-LockAfterCreate',
                Value => {
                    Action      => 'AgentTicketPhone|AgentTicketEmail',
                    Event       => 'TicketCreate',
                    Module      => 'Kernel::System::Ticket::Event::LockAfterCreate',
                    Transaction => 0,
                },
            );

            # Navigate to AgentTicketPhone screen.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

            # Create test phone ticket.
            my $TicketSubject = "Selenium Ticket";
            my $TicketBody    = "Selenium body test";

            $Selenium->find_element( "#FromCustomer", 'css' )->clear();
            $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomer);
            $Selenium->WaitFor(
                JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length'
            );
            $Selenium->execute_script("\$('li.ui-menu-item:contains($TestCustomer)').click()");

            # Wait for "Customer Information".
            $Selenium->WaitFor(
                JavaScript => 'return typeof($) === "function" && $(".SidebarColumn fieldset .Value").length'
            );
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );

            $Selenium->InputFieldValueSet(
                Element => '#Dest',
                Value   => '2||Raw',
            );

            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Dest").val() === "2||Raw";' );

            $Selenium->find_element( "#Subject",  'css' )->send_keys($TicketSubject);
            $Selenium->find_element( "#RichText", 'css' )->send_keys($TicketBody);

            $Selenium->find_element( "#submitRichText", 'css' )->VerifiedClick();

            my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

            # Get created test ticket ID and number.
            my @Ticket = split( 'TicketID=', $Selenium->get_current_url() );

            my $TicketID = $Ticket[1];

            my $TicketNumber = $TicketObject->TicketNumberLookup(
                TicketID => $TicketID,
                UserID   => 1,
            );

            $Self->True(
                $TicketID,
                "Ticket was created and found - $TicketID",
            );

            $Self->True(
                $Selenium->find_element("//a[contains(\@href, \'Action=AgentTicketZoom;TicketID=$TicketID' )]"),
                "Ticket with ticket number $TicketNumber is created",
            );

            # Go to ticket zoom page of created test ticket.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID");

            # Check if test ticket values are genuine.
            $Self->True(
                index( $Selenium->get_page_source(), $TicketSubject ) > -1,
                "$TicketSubject found on page",
            ) || die "$TicketSubject not found on page";
            $Self->True(
                index( $Selenium->get_page_source(), $TicketBody ) > -1,
                "$TicketBody found on page",
            ) || die "$TicketBody not found on page";
            $Self->True(
                index( $Selenium->get_page_source(), $TestCustomer ) > -1,
                "$TestCustomer found on page",
            ) || die "$TestCustomer not found on page";
            $Self->True(
                index( $Selenium->get_page_source(), ">$LockStatus<" ) > -1,
                "$LockStatus found on page",
            ) || die "lock not found on page";

            # Delete created test ticket.
            my $Success = $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => 1,
            );

            # Ticket deletion could fail if apache still writes to ticket history. Try again in this case.
            if ( !$Success ) {
                sleep 3;
                $Success = $TicketObject->TicketDelete(
                    TicketID => $TicketID,
                    UserID   => 1,
                );
            }
            $Self->True(
                $Success,
                "Ticket with ticket ID $TicketID is deleted",
            );

            # Delete created test customer user.
            my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
            $TestCustomer = $DBObject->Quote($TestCustomer);
            $Success      = $DBObject->Do(
                SQL  => "DELETE FROM customer_user WHERE login = ?",
                Bind => [ \$TestCustomer ],
            );
            $Self->True(
                $Success,
                "Delete customer user - $TestCustomer",
            );
        }

        # Make sure the cache is correct.
        for my $Cache (
            qw (Ticket CustomerUser)
            )
        {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }
    }
);

1;
