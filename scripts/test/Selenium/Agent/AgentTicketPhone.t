# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
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

        my $CacheObject            = $Kernel::OM->Get('Kernel::System::Cache');
        my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
        my $CustomerUserObject     = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $DBObject               = $Kernel::OM->Get('Kernel::System::DB');
        my $HelperObject           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $QueueObject            = $Kernel::OM->Get('Kernel::System::Queue');
        my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
        my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
        my $UserObject             = $Kernel::OM->Get('Kernel::System::User');

        my $IsITSMIncidentProblemManagementInstalled
            = $Kernel::OM->Get('Kernel::System::Util')->IsITSMIncidentProblemManagementInstalled();

        # Overload CustomerUser => Map setting defined in the Defaults.pm - use external url.
        my $DefaultCustomerUser = $ConfigObject->Get("CustomerUser");
        $DefaultCustomerUser->{Map}->[5] = [
            'UserEmail',
            'Email',
            'email',
            1,
            1,
            'var',
            'http://www.otrs.com',
            0,
            '',
            'AsPopup OTRSPopup_TicketAction',
        ];
        $HelperObject->ConfigSettingChange(
            Key   => 'CustomerUser',
            Value => $DefaultCustomerUser,
        );

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

        if ($IsITSMIncidentProblemManagementInstalled) {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => 'Ticket::Frontend::AgentTicketPhone###DynamicField',
                Value => {
                    'ITSMCriticality' => 1,
                    'ITSMDueDate'     => 1,
                    'ITSMImpact'      => 1,
                },
            );
        }

        # Do not check service and type.
        if ($IsITSMIncidentProblemManagementInstalled) {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => 'Ticket::Service',
                Value => 1,
            );
        }
        else {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => 'Ticket::Service',
                Value => 0,
            );
        }

        if ($IsITSMIncidentProblemManagementInstalled) {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => 'Ticket::Type',
                Value => 1,
            );
        }
        else {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => 'Ticket::Type',
                Value => 0,
            );
        }

        my %TestUserLoginGroup = (
            Groups => [ 'admin', 'users' ]
        );
        if ($IsITSMIncidentProblemManagementInstalled) {
            $TestUserLoginGroup{Groups} = [ 'admin', 'users', 'itsm-service' ];
        }

        # Create test user.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            %TestUserLoginGroup,
        ) || die "Did not get test user";

        # Get test user ID.
        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        my $RandomID = $HelperObject->GetRandomID();

        # Add test customer for testing.
        my $TestCustomer       = 'Customer' . $RandomID;
        my $TestCustomerUserID = $CustomerUserObject->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserFirstname  => 'FirstName' . $TestCustomer,
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

        # Add test template of type 'Create'.
        my $TemplateText = 'This is selected customer user first name: "<OTRS_CUSTOMER_DATA_UserFirstname>"';
        my $TemplateID   = $StandardTemplateObject->StandardTemplateAdd(
            Name         => 'CreateTemplate' . $RandomID,
            Template     => $TemplateText,
            ContentType  => 'text/plain; charset=utf-8',
            TemplateType => 'Create',
            ValidID      => 1,
            UserID       => $TestUserID,
        );
        $Self->True(
            $TemplateID,
            "Template ID $TemplateID is created.",
        );

        my $QueueID = $QueueObject->QueueLookup( Queue => 'Raw' );

        # Assign test template to queue 'Raw'.
        my $Success = $QueueObject->QueueStandardTemplateMemberAdd(
            QueueID            => $QueueID,
            StandardTemplateID => $TemplateID,
            Active             => 1,
            UserID             => $TestUserID,
        );
        $Self->True(
            $Success,
            "Template ID $TemplateID got assigned to queue 'Raw'",
        );

        # Login as test user.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Navigate to AgentTicketPhone screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        my @AdditionalIDs;
        if ($IsITSMIncidentProblemManagementInstalled) {
            @AdditionalIDs = qw(TypeID ServiceID OptionLinkTicket DynamicField_ITSMImpact DynamicField_ITSMCriticality);
        }

        # Check page.
        for my $ID (
            qw(FromCustomer CustomerID Dest Subject RichText FileUpload
            NextStateID PriorityID submitRichText), @AdditionalIDs
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # Check client side validation.
        my $Element = $Selenium->find_element( "#Subject", 'css' );
        $Element->send_keys("");
        $Selenium->find_element( "#submitRichText", 'css' )->click();
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Subject.Error").length;' );

        $Self->Is(
            $Selenium->execute_script(
                "return \$('#Subject').hasClass('Error');"
            ),
            '1',
            'Client side validation correctly detected missing input value',
        );

        # Navigate to AgentTicketPhone screen again.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        # Create test phone ticket.
        my $TicketSubject = "Selenium Ticket";
        my $TicketBody    = "Selenium body test";

        my $ServiceID;
        if ($IsITSMIncidentProblemManagementInstalled) {
            my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

            # Create test service.
            my $ServiceName = "Selenium" . $HelperObject->GetRandomID();
            $ServiceID = $ServiceObject->ServiceAdd(
                Name        => $ServiceName,
                ValidID     => 1,
                Comment     => 'Selenium Test Service',
                TypeID      => 2,
                Criticality => '5 very high',
                UserID      => $TestUserID,
            );

            $Self->True(
                $ServiceID,
                "Created service ID - $ServiceID",
            );

            # Link test service with test customer.
            my $ServiceMemberAddSuccess = $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => $TestCustomer,
                ServiceID         => $ServiceID,
                Active            => 1,
                UserID            => $TestUserID,
            );

            $Self->True(
                $ServiceMemberAddSuccess,
                "Added service ID $ServiceID to CustomerUser $TestCustomer.",
            );

            $Selenium->execute_script(
                "\$('#TypeID').val(\$('#TypeID option').filter(function () { return \$(this).html() == 'Unclassified'; } ).val() ).trigger('redraw.InputField').trigger('change');"
            );
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );
        }

        $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomer);
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length;' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestCustomer)').click();");

        if ($IsITSMIncidentProblemManagementInstalled) {
            $Selenium->WaitFor( JavaScript => "return \$('#ServiceID option[value=\"$ServiceID\"]').length;" );
            $Selenium->execute_script(
                "\$('#ServiceID').val('$ServiceID').trigger('redraw.InputField').trigger('change');"
            );
            $Selenium->WaitFor( JavaScript => 'return $("#ServiceIncidentState").length' );

            # Check for service incident state field.
            my $ServiceIncidentStateElement = $Selenium->find_element( "#ServiceIncidentState", 'css' );
            $ServiceIncidentStateElement->is_enabled();
            $ServiceIncidentStateElement->is_displayed();

            $Selenium->WaitFor(
                JavaScript => "return \$('#DynamicField_ITSMImpact option[value=\"3 normal\"]').length;"
            );
            $Selenium->WaitFor( JavaScript => "return \$('#PriorityID option[value=\"4\"]').length;" );

            # Check if ITSMCriticality has correct value, see bug#10550.
            $Self->Is(
                $Selenium->find_element( '#DynamicField_ITSMCriticality', 'css' )->get_value(),
                '5 very high',
                "#DynamicField_ITSMCriticality updated value",
            );

            # Test priority update based on impact value.
            $Self->Is(
                $Selenium->find_element( '#PriorityID', 'css' )->get_value(),
                '4',
                "#PriorityID stored value",
            );

            $Selenium->execute_script(
                "\$('#DynamicField_ITSMImpact').val('1 very low').trigger('redraw.InputField').trigger('change');"
            );

            sleep 2;

            $Self->Is(
                $Selenium->find_element( '#PriorityID', 'css' )->get_value(),
                '3',
                "#PriorityID updated value",
            );
        }

        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => '2||Raw',
        );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );

        # Select test created template and verify selected customer information is correctly replaced. See bug#14455.
        $Selenium->InputFieldValueSet(
            Element => '#StandardTemplateID',
            Value   => $TemplateID,
        );

        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );

        $Self->Is(
            $Selenium->execute_script("return \$('#RichText').val().trim();"),
            "This is selected customer user first name: \"FirstName$TestCustomer\"",
            "Template type 'Create' has customer information correct"
        );

        $Selenium->find_element( "#Subject",  'css' )->send_keys($TicketSubject);
        $Selenium->find_element( "#RichText", 'css' )->clear();
        $Selenium->find_element( "#RichText", 'css' )->send_keys($TicketBody);

        # Wait for "Customer Information".
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $(".SidebarColumn fieldset .Value").length;'
        );

        # Make sure that Customer email is link.
        my $LinkVisible = $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $(".SidebarColumn fieldset a.AsPopup:visible").length;'
        );
        $Self->True(
            $LinkVisible,
            "Customer email is a link with class AsPopup."
        );

        # Overload CustomerUser => Map setting defined in the Defaults.pm - use internal url.
        $DefaultCustomerUser->{Map}->[5] = [
            'UserEmail',
            'Email',
            'email',
            1,
            1,
            'var',
            '[% Env("CGIHandle") %]?Action=AgentTicketCompose;ResponseID=1;TicketID=[% Data.TicketID | uri %];ArticleID=[% Data.ArticleID | uri %]',
            0,
            '',
            'AsPopup OTRSPopup_TicketAction',
        ];
        $HelperObject->ConfigSettingChange(
            Key   => 'CustomerUser',
            Value => $DefaultCustomerUser,
        );

        # Remove customer.
        $Selenium->find_element( "#TicketCustomerContentFromCustomer a.CustomerTicketRemove", "css" )->click();

        # Add customer again.
        $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomer);
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length;' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestCustomer)').click();");

        # Make sure that Customer email is not a link.
        $LinkVisible = $Selenium->execute_script("return \$('.SidebarColumn fieldset a.AsPopup').length;");
        $Self->False(
            $LinkVisible,
            "Customer email is not a link with class AsPopup."
        );

        $Selenium->find_element( "#submitRichText", 'css' )->click();
        $Selenium->WaitFor(
            JavaScript =>
                'return typeof($) === "function" && $(".MessageBox a[href*=\'AgentTicketZoom;TicketID=\']").length !== 0;'
        );

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

        if ($IsITSMIncidentProblemManagementInstalled) {

            # Force sub menus to be visible in order to be able to click one of the links.
            $Selenium->execute_script("\$('.Cluster ul ul').addClass('ForceVisible');");

            # Click on history and switch window.
            $Selenium->find_element("//*[text()='History']")->click();

            $Selenium->WaitFor( WindowCount => 2 );
            my $Handles = $Selenium->get_window_handles();
            $Selenium->switch_to_window( $Handles->[1] );

            # Wait until page has loaded, if necessary.
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $(".CancelClosePopup").length' );

            # Check for ITSM updated fields.
            for my $UpdateText (qw(Impact Criticality)) {
                $Self->True(
                    index( $Selenium->get_page_source(), "Changed dynamic field ITSM$UpdateText" ) > -1,
                    "DynamicFieldUpdate $UpdateText - found",
                );
            }
        }

        # Test bug #12229.
        my $QueueID1 = $QueueObject->QueueAdd(
            Name            => "<Queue>$RandomID",
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Some comment',
            UserID          => 1,
        );
        my $QueueID2 = $QueueObject->QueueAdd(
            Name            => "Junk::SubQueue $RandomID  $RandomID",
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Some comment',
            UserID          => 1,
        );

        $Self->True(
            $QueueID1,
            "Queue #1 created."
        );
        $Self->True(
            $QueueID2,
            "Queue #2 created."
        );

        # Navigate to AgentTicketPhone screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        # Select <Queue>.
        my $QueueValue    = "<Queue>$RandomID";
        my $QueueValueSet = $QueueID1 . "||" . $QueueValue;
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $QueueValueSet,
        );

        # Wait for loader.
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );

        # Check Queue #1 is displayed as selected.
        $Self->Is(
            $Selenium->InputGet(
                Attribute => 'Dest',
                Options   => { KeyOrValue => 'Value' }
            ),
            $QueueValue,
            'Queue #1 is selected.',
        );

        # Check Queue #1 is displayed properly.
        $Self->Is(
            $Selenium->InputGet(
                Attribute => 'Dest',
                Options   => { KeyOrValue => 'Value' }
            ),
            $QueueValue,
            'Queue #1 is selected.',
        );

        # Select SubQueue on loading screen.
        # Bug#12819 ( https://bugs.otrs.org/show_bug.cgi?id=12819 ) - queue contains spaces in the name.
        # Navigate to AgentTicketPhone screen again to check selecting a queue after loading screen.
        $QueueValue    = "Junk::SubQueue $RandomID  $RandomID";
        $QueueValueSet = $QueueID2 . "||" . $QueueValue;

        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $QueueValueSet,
        );

        # Wait for loader.
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;' );

        # Check SubQueue is displayed properly.
        $Self->Is(
            $Selenium->InputGet(
                Attribute => 'Dest',
                Options   => { KeyOrValue => 'Value' }
            ),
            $QueueValue,
            'Queue #2 is selected.',
        );

        if ($IsITSMIncidentProblemManagementInstalled) {

   # Verify Service Incident State is not available when config 'Ticket::Frontend::AgentTicketPhone###ShowIncidentState'
   #   is disabled. See bug#14150 (https://bugs.otrs.org/show_bug.cgi?id=14150)
            $HelperObject->ConfigSettingChange(
                Key   => 'Ticket::Frontend::AgentTicketPhone###ShowIncidentState',
                Value => 0,
            );
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

            $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomer);
            $Selenium->WaitFor(
                JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length'
            );
            $Selenium->execute_script("\$('li.ui-menu-item:contains($TestCustomer)').click()");

            $Selenium->WaitFor( JavaScript => "return \$('#ServiceID option[value=\"$ServiceID\"]').length;" );
            $Selenium->execute_script(
                "\$('#ServiceID').val('$ServiceID').trigger('redraw.InputField').trigger('change');"
            );

            $Self->False(
                $Selenium->execute_script("return \$('#ServiceIncidentStateContainer').length;"),
                "Service Incident State is not available when config ShowIncidentState is disabled."
            );
        }

        # Delete Queues.
        $Success = $DBObject->Do(
            SQL  => "DELETE FROM queue WHERE id IN (?, ?)",
            Bind => [ \$QueueID1, \$QueueID2 ],
        );
        $Self->True(
            $Success,
            "Queues deleted.",
        );

        # Delete created test ticket.
        $Success = $TicketObject->TicketDelete(
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
            "Ticket with ticket ID $TicketID is deleted.",
        );

        if ($IsITSMIncidentProblemManagementInstalled) {

            # Delete test service - test customer connection.
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service_customer_user WHERE service_id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Service-customer connection is deleted",
            );

            # Delete test service preferences.
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service_preferences WHERE service_id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Service preferences is deleted - ID $ServiceID",
            );

            # Delete created test service.
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service WHERE id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Service is deleted - ID $ServiceID",
            );
        }

        # Delete created test customer user.
        $TestCustomer = $DBObject->Quote($TestCustomer);
        $Success      = $DBObject->Do(
            SQL  => "DELETE FROM customer_user WHERE login = ?",
            Bind => [ \$TestCustomer ],
        );
        $Self->True(
            $Success,
            "Customer user $TestCustomer is deleted.",
        );

        # Delete test created template.
        $Success = $StandardTemplateObject->StandardTemplateDelete(
            ID => $TemplateID,
        );
        $Self->True(
            $Success,
            "Template ID $TemplateID is deleted.",
        );

        # Make sure the cache is correct.
        for my $Cache (qw( Ticket CustomerUser )) {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
