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

        my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $SignatureObject    = $Kernel::OM->Get('Kernel::System::Signature');
        my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
        my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');

        my $IsITSMIncidentProblemManagementInstalled
            = $Kernel::OM->Get('Kernel::System::Util')->IsITSMIncidentProblemManagementInstalled();

        # Disable check email addresses.
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

        # Enable session management use html cookies.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'SessionUseCookie',
            Value => 1,
        );

        # Define random test variable.
        my $RandomID = $HelperObject->GetRandomID();

        my @SignatureIDs;
        my @QueueIDs;
        my @QueueNames;
        my @CustomerUserIDs;
        my @TestData = (
            {
                SignatureName => 'Signature1' . $RandomID,
                SignatureText => 'Customer First Name: <OTRS_CUSTOMER_DATA_UserFirstname>',
                QueueName     => 'Queue1' . $RandomID,
                UserFirstName => 'FirstName1' . $RandomID,
                UserLastName  => 'LastName1' . $RandomID,
                UserLogin     => 'UserLogin1' . $RandomID,
            },
            {
                SignatureName => 'Signature2' . $RandomID,
                SignatureText => 'Customer Last Name: <OTRS_CUSTOMER_DATA_UserLastname>',
                QueueName     => 'Queue2' . $RandomID,
                UserFirstName => 'FirstName2' . $RandomID,
                UserLastName  => 'LastName2' . $RandomID,
                UserLogin     => 'UserLogin2' . $RandomID,
            },
        );

        for my $Data (@TestData) {
            my $SignatureID = $SignatureObject->SignatureAdd(
                Name        => $Data->{SignatureName},
                Text        => $Data->{SignatureText},
                ContentType => 'text/plain; charset=utf-8',
                Comment     => 'Selenium signature',
                ValidID     => 1,
                UserID      => 1,
            );
            $Self->True(
                $SignatureID,
                "SignatureID $SignatureID is created"
            );
            push @SignatureIDs, $SignatureID;

            my $QueueID = $QueueObject->QueueAdd(
                Name            => $Data->{QueueName},
                ValidID         => 1,
                GroupID         => 1,
                SystemAddressID => 1,
                SalutationID    => 1,
                SignatureID     => $SignatureID,
                Comment         => 'Selenium Queue',
                UserID          => 1,
            );
            $Self->True(
                $QueueID,
                "QueueID $QueueID is created"
            );
            push @QueueIDs,   $QueueID;
            push @QueueNames, $Data->{QueueName};

            my $CustomerUserID = $CustomerUserObject->CustomerUserAdd(
                Source         => 'CustomerUser',
                UserFirstname  => $Data->{UserFirstName},
                UserLastname   => $Data->{UserLastName},
                UserCustomerID => $Data->{UserLogin},
                UserLogin      => $Data->{UserLogin},
                UserEmail      => "$Data->{UserLogin}\@localhost.com",
                ValidID        => 1,
                UserID         => 1,
            );
            $Self->True(
                $CustomerUserID,
                "CustomerUserID $CustomerUserID is created"
            );
            push @CustomerUserIDs, $CustomerUserID;
        }

        # Create test user and login.
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

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Navigate to AgentTicketEmail screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketEmail");

        # Check page.
        my @AdditionalIDs;
        if ($IsITSMIncidentProblemManagementInstalled) {
            @AdditionalIDs = qw(TypeID ServiceID OptionLinkTicket DynamicField_ITSMImpact);
        }

        for my $ID (
            qw(Dest ToCustomer CcCustomer BccCustomer CustomerID RichText
            Signature FileUpload NextStateID PriorityID submitRichText), @AdditionalIDs
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
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Subject.Error").length' );

        $Self->True(
            $Selenium->execute_script("return \$('#Subject.Error').length"),
            'Client side validation correctly detected missing input value',
        );

        # Navigate to AgentTicketEmail screen again.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketEmail");

        # Verify signature tags like <OTRS_CUSTOMER_DATA_*>, please see bug#12853 for more information.
        #   Select first queue.
        my $Option = $Selenium->execute_script(
            "return \$('#Dest option').filter(function () { return \$(this).html() == '$QueueNames[0]'; }).val();"
        );
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $Option,
        );

        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );

        # There is no selected customer, should be no replaced tags in signature.
        my $SignatureText = "Customer First Name: -";
        $Self->Is(
            $Selenium->execute_script('return $("#Signature").val()'),
            $SignatureText,
            "Signature is found with no replaced tags"
        );

        my $ServiceID;
        if ($IsITSMIncidentProblemManagementInstalled) {

            # get service object
            my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

            # get test user ID
            my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
                UserLogin => $TestUserLogin,
            );

            # create test service
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
                "Service is created - ID $ServiceID",
            );

            # add customer user as member to the test service
            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => $TestData[1]->{UserLogin},
                ServiceID         => $ServiceID,
                Active            => 1,
                UserID            => $TestUserID,
            );
        }

        # Select customer user.
        $Selenium->find_element( "#ToCustomer", 'css' )->clear();
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $Option,
        );
        $Selenium->find_element( "#ToCustomer", 'css' )->send_keys( $TestData[0]->{UserLogin} );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestData[0]->{UserLogin})').click()");
        $Selenium->WaitFor(
            JavaScript =>
                'return typeof($) === "function" && $("#CustomerSelected_1").length && !$(".AJAXLoader:visible").length'
        );

        $SignatureText = "Customer First Name: $TestData[0]->{UserFirstName}";
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#Signature').val().indexOf('$SignatureText') !== -1;"
        );

        # Input subject data.
        my $TicketSubject = "Selenium Ticket";
        $Selenium->find_element( "#Subject", 'css' )->clear();
        $Selenium->find_element( "#Subject", 'css' )->send_keys($TicketSubject);

        # Queue and customer are selected, signature has replaced tags.
        $Self->Is(
            $Selenium->execute_script('return $("#Signature").val()'),
            $SignatureText,
            "Signature is found with replaced tags on selected customer"
        );

        # Change queue, trigger new signature.
        $Option = $Selenium->execute_script(
            "return \$('#Dest option').filter(function () { return \$(this).html() == '$QueueNames[1]'; }).val();"
        );
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $Option,
        );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );

        # Queue is changed, verify signature change with replaced tags.
        $SignatureText = "Customer Last Name: $TestData[0]->{UserLastName}";
        $Self->Is(
            $Selenium->execute_script('return $("#Signature").val()'),
            $SignatureText,
            "Signature is found with replaced tags on queue change"
        );

        # Add new customer in 'To'.
        $Selenium->find_element( "#ToCustomer", 'css' )->clear();
        $Selenium->find_element( "#ToCustomer", 'css' )->send_keys( $TestData[1]->{UserLogin} );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestData[1]->{UserLogin})').click()");

        # Change selected customer, trigger replacement tag in signature.
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#CustomerSelected_2").length' );
        $Selenium->find_element( "#CustomerSelected_2", 'css' )->click();
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );

        $SignatureText = "Customer Last Name: $TestData[1]->{UserLastName}";
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#Signature').val().indexOf('$SignatureText') !== -1;"
        );

        # Input body data.
        my $TicketBody = "Selenium body test";
        $Selenium->find_element( "#RichText", 'css' )->clear();
        $Selenium->find_element( "#RichText", 'css' )->send_keys($TicketBody);

        # Selected customer is changed, signature replaced tags are changed.
        $Self->Is(
            $Selenium->execute_script('return $("#Signature").val()'),
            $SignatureText,
            "Signature is found with replaced tags on selected customer change"
        );

        if ($IsITSMIncidentProblemManagementInstalled) {
            $Selenium->execute_script(
                "\$('#TypeID').val(\$('#TypeID option').filter(function () { return \$(this).html() == 'Unclassified'; } ).val() ).trigger('redraw.InputField').trigger('change');"
            );
            $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );

            $Selenium->WaitFor( JavaScript => "return \$('#ServiceID option[value=\"$ServiceID\"]').length;" );
            $Selenium->execute_script(
                "\$('#ServiceID').val('$ServiceID').trigger('redraw.InputField').trigger('change');"
            );
            $Selenium->WaitFor( JavaScript => 'return $("#ServiceIncidentState").length' );

            # check for service incident state field
            my $ServiceIncidentStateElement = $Selenium->find_element( "#ServiceIncidentState", 'css' );
            $ServiceIncidentStateElement->is_enabled();
            $ServiceIncidentStateElement->is_displayed();

            $Selenium->WaitFor(
                JavaScript => "return \$('#DynamicField_ITSMImpact option[value=\"3 normal\"]').length;"
            );
            $Selenium->WaitFor( JavaScript => "return \$('#PriorityID option[value=\"4\"]').length;" );

            # test priority update based on impact value
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

        # Submit form.
        $Selenium->find_element( "#submitRichText", 'css' )->VerifiedClick();

        # Get created test ticket data.
        my %TicketIDs = $TicketObject->TicketSearch(
            Result         => 'HASH',
            Limit          => 1,
            CustomerUserID => $TestData[1]->{UserLogin},
        );
        my $TicketNumber = (%TicketIDs)[1];
        my $TicketID     = (%TicketIDs)[0];

        $Self->True(
            $TicketID,
            "Ticket was created and found - $TicketID",
        ) || die;

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
            index( $Selenium->get_page_source(), $TestData[1]->{UserLogin} ) > -1,
            "$TestData[1]->{UserLogin} found on page",
        ) || die "$TestData[1]->{UserLogin} not found on page";
        $Self->True(
            index( $Selenium->get_page_source(), $SignatureText ) > -1,
            "Signature found on page"
        ) || die "$SignatureText not found on page";

        if ($IsITSMIncidentProblemManagementInstalled) {

            # Navigate to AgentTicketHistory screen.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketHistory;TicketID=$TicketID");

            # check for ITSM updated fields
            for my $UpdateText (qw(Impact Criticality)) {
                $Self->True(
                    index( $Selenium->get_page_source(), "Changed dynamic field ITSM$UpdateText" ) > -1,
                    "DynamicFieldUpdate $UpdateText - found",
                );
            }
        }

        # Disable session management use html cookies to check signature update (see bug#12890).
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'SessionUseCookie',
            Value => 0,
        );

        # Allow apache to pick up the changed SysConfig via Apache::Reload.
        sleep 1;

        # Navigate to AgentTicketEmail screen and login because there is no session cookies.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketEmail");
        $Selenium->find_element( "#User",        'css' )->send_keys($TestUserLogin);
        $Selenium->find_element( "#Password",    'css' )->send_keys($TestUserLogin);
        $Selenium->find_element( "#LoginButton", 'css' )->VerifiedClick();

        my $DestValue = $Selenium->execute_script(
            "return \$('#Dest option').filter(function () { return \$(this).html() == '$QueueNames[0]'; } ).val();"
        );
        $Selenium->InputFieldValueSet(
            Element => '#Dest',
            Value   => $DestValue,
        );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length' );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#ToCustomer").length' );

        # Select customer user.
        $Selenium->find_element( "#ToCustomer", 'css' )->send_keys( $TestData[0]->{UserLogin} );
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestData[0]->{UserLogin})').click()");
        $Selenium->WaitFor(
            JavaScript =>
                'return typeof($) === "function" && $("#CustomerSelected_1").length && !$(".AJAXLoader:visible").length'
        );

        $SignatureText = "Customer First Name: $TestData[0]->{UserFirstName}";
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#Signature').val().indexOf('$SignatureText') !== -1;"
        );

        # Check if signature have correct text after set queue and customer user.
        $Self->Is(
            $Selenium->execute_script('return $("#Signature").val()'),
            $SignatureText,
            "Signature has correct text"
        );

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

        if ($IsITSMIncidentProblemManagementInstalled) {

            # delete test service - test customer connection
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service_customer_user WHERE service_id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Delete service-customer connection",
            );

            # delete test service preferences
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service_preferences WHERE service_id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Service preferences is deleted - ID $ServiceID",
            );

            # delete created test service
            $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
                SQL => "DELETE FROM service WHERE id = $ServiceID",
            );
            $Self->True(
                $Success,
                "Service is deleted - ID $ServiceID",
            );
        }

        # Delete created test customer users.
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
        for my $CustomerLogin (@CustomerUserIDs) {
            my $TestCustomer = $DBObject->Quote($CustomerLogin);
            $Success = $DBObject->Do(
                SQL  => "DELETE FROM customer_user WHERE login = ?",
                Bind => [ \$TestCustomer ],
            );
            $Self->True(
                $Success,
                "Customer user $TestCustomer is deleted",
            );
        }

        # Delete created test queues.
        for my $QueueID (@QueueIDs) {
            $Success = $DBObject->Do(
                SQL  => "DELETE FROM queue WHERE id = ?",
                Bind => [ \$QueueID ],
            );
            $Self->True(
                $Success,
                "QueueID $QueueID is deleted",
            );
        }

        # Delete created test signature.
        for my $SignatureID (@SignatureIDs) {
            $Success = $DBObject->Do(
                SQL  => "DELETE FROM signature WHERE id = ?",
                Bind => [ \$SignatureID ],
            );
            $Self->True(
                $Success,
                "SignatureID $SignatureID is deleted",
            );
        }

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure the cache is correct.
        my @AdditionalCache = qw (Ticket CustomerUser);
        push @AdditionalCache, 'Service' if ($IsITSMIncidentProblemManagementInstalled);
        for my $Cache (@AdditionalCache) {
            $CacheObject->CleanUp( Type => $Cache );
        }

    }
);

1;
