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
use POSIX qw( floor );

use vars (qw($Self));

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Disable 'Ticket Information', 'Customer Information' and 'Linked Objects' widgets in AgentTicketZoom screen.
        for my $WidgetDisable (qw(0100-TicketInformation 0200-CustomerInformation 0300-LinkTable)) {
            $HelperObject->ConfigSettingChange(
                Valid => 0,
                Key   => "Ticket::Frontend::AgentTicketZoom###Widgets###$WidgetDisable",
                Value => '',
            );
        }

        # enable ticket service, type, responsible
        $HelperObject->ConfigSettingChange(
            Key   => 'Ticket::Service',
            Value => 1,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 1
        );
        $HelperObject->ConfigSettingChange(
            Key   => 'Ticket::Type',
            Value => 1,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Type',
            Value => 1
        );
        $HelperObject->ConfigSettingChange(
            Key   => 'Ticket::Responsible',
            Value => 1,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Responsible',
            Value => 1
        );

        # Use a calendar with the same business hours for every day so that the UT runs correctly
        # on every day of the week and outside usual business hours.
        my %Week;
        my @Days = qw(Sun Mon Tue Wed Thu Fri Sat);
        for my $Day (@Days) {
            $Week{$Day} = [ 0 .. 23 ];
        }
        $HelperObject->ConfigSettingChange(
            Key   => 'TimeWorkingHours',
            Value => \%Week,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'TimeWorkingHours',
            Value => \%Week,
        );

        # Disable default Vacation days.
        $HelperObject->ConfigSettingChange(
            Key   => 'TimeVacationDays',
            Value => {},
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'TimeVacationDays',
            Value => {},
        );

        my $UserObject = $Kernel::OM->Get('Kernel::System::User');

        # Create test responsible user.
        my $ResponsibleUser = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        # Get test user responsible ID.
        my $ResponsibleUserID = $UserObject->UserLookup(
            UserLogin => $ResponsibleUser,
        );

        # Create test user.
        my $UserLogin = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        # Get test user login ID.
        my $UserLoginID = $UserObject->UserLookup(
            UserLogin => $UserLogin,
        );

        # Get test ticket data.
        my $RandomID   = $HelperObject->GetRandomID();
        my %TicketData = (
            Age           => '0 m',
            Type          => "Type$RandomID",
            Service       => "Service$RandomID",
            SLA           => "SLA$RandomID",
            Queue         => "Queue$RandomID",
            Priority      => '5 very high',
            State         => 'open',
            Locked        => 'unlock',
            Responsible   => $ResponsibleUser,
            CreatedByUser => $UserObject->UserName( UserID => $UserLoginID ),
        );

        my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

        # Create test type.
        my $TypeID = $TypeObject->TypeAdd(
            Name    => $TicketData{Type},
            ValidID => 1,
            UserID  => 1,
        );
        $Self->True(
            $TypeID,
            "TypeID $TypeID is created"
        );

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

        # Create test queue.
        my $QueueID = $QueueObject->QueueAdd(
            Name            => $TicketData{Queue},
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Selenium Queue',
            UserID          => 1,
        );
        $Self->True(
            $QueueID,
            "QueueID $QueueID is created"
        );

        # Create test service.
        my $ServiceID = $Kernel::OM->Get('Kernel::System::Service')->ServiceAdd(
            Name    => $TicketData{Service},
            ValidID => 1,
            Comment => 'Selenium Service',
            UserID  => 1,
        );
        $Self->True(
            $ServiceID,
            "ServiceID $ServiceID is created"
        );

        # Create test SLA with low escalation times, so we trigger warning in 'Ticket Information' widget.
        my %EscalationTimes = (
            FirstResponseTime => 30,
            UpdateTime        => 40,
            SolutionTime      => 50,
        );
        my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLAAdd(
            ServiceIDs        => [$ServiceID],
            Name              => $TicketData{SLA},
            FirstResponseTime => $EscalationTimes{FirstResponseTime},
            UpdateTime        => $EscalationTimes{UpdateTime},
            SolutionTime      => $EscalationTimes{SolutionTime},
            ValidID           => 1,
            Comment           => 'Selenium SLA',
            UserID            => 1,
        );
        $Self->True(
            $SLAID,
            "SLAID $SLAID is created"
        );

        my $DynamicFieldObject      = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');

        # Create test dynamic field.
        my $DynamicFieldName = "DFText$RandomID";
        my $DynamicFieldID   = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $DynamicFieldName,
            Label      => "DFLabel",
            FieldOrder => 9991,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue => '',
            },
            ValidID => 1,
            UserID  => 1,
        );
        $Self->True(
            $DynamicFieldID,
            "DynamicFieldID $DynamicFieldID is created"
        );

        # Enable test dynamic field to show in AgentTicketZoom screen in 'Ticket Information' widget.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketZoom###DynamicField',
            Value => {
                $DynamicFieldName => 1,
            },
        );

        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # Create test ticket.
        my $Customer    = "Customer$RandomID";
        my $TitleRandom = "Title$RandomID";
        my $TicketID    = $TicketObject->TicketCreate(
            Title         => $TitleRandom,
            Queue         => $TicketData{Queue},
            TypeID        => $TypeID,
            Lock          => $TicketData{Locked},
            Priority      => $TicketData{Priority},
            State         => $TicketData{State},
            ServiceID     => $ServiceID,
            SLAID         => $SLAID,
            CustomerID    => $Customer,
            ResponsibleID => $ResponsibleUserID,
            OwnerID       => $UserLoginID,
            UserID        => $UserLoginID,
        );
        $Self->True(
            $TicketID,
            "TicketID $TicketID is created",
        );

        # Add dynamic field value to the test ticket.
        my $DFValue = "DFValueText$RandomID";
        my $Success = $DynamicFieldValueObject->ValueSet(
            FieldID    => $DynamicFieldID,
            ObjectType => 'Ticket',
            ObjectID   => $TicketID,
            UserID     => 1,
            Value      => [
                {
                    ValueText => $DFValue,
                },
            ],
        );
        $Self->True(
            $Success,
            "DynamicField value added to the test ticket",
        );

        # Login as test user.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $UserLogin,
            Password => $UserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Navigate to AgentTicketZoom for test created ticket.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID");

        # Verify its right screen.
        $Self->True(
            index( $Selenium->get_page_source(), $TitleRandom ) > -1,
            "Ticket $TitleRandom found on page",
        );

        # Verify there is no 'Ticket Information' widget, it's disabled.
        $Self->True(
            index( $Selenium->get_page_source(), "$TicketData{Service}" ) == -1,
            "Ticket Information widget is disabled",
        );

        # Reset 'Ticket Information' widget sysconfig, enable it and refresh screen.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketZoom###Widgets###0100-TicketInformation',
            Value => {
                'Location' => 'Sidebar',
                'Module'   => 'Kernel::Output::HTML::TicketZoom::TicketInformation',
            },
        );

        $Selenium->VerifiedRefresh();

        # Verify there is 'Ticket Information' widget, it's enabled.
        $Self->Is(
            $Selenium->find_element( '.Header>h2', 'css' )->get_text(),
            'Ticket Information',
            'Ticket Information widget is enabled',
        );

        # Verify there is no collapsed elements on the screen.
        $Self->True(
            $Selenium->find_element("//div[contains(\@class, \'WidgetSimple Expanded')]"),
            "Ticket Information Widget is expanded",
        );

        # Toggle to collapse 'Ticket Information' widget.
        $Selenium->find_element("//a[contains(\@title, \'Show or hide the content' )]")->click();

        $Selenium->WaitFor(
            JavaScript => 'return $("div.WidgetSimple.Collapsed").length'
        );

        # Verify there is collapsed element on the screen.
        $Self->True(
            $Selenium->find_element("//div[contains(\@class, \'WidgetSimple Collapsed')]"),
            "Ticket Information Widget is collapsed",
        );

        # Add article to ticket.
        my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Email')->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 1,
            SenderType           => 'customer',
            Subject              => 'some short description',
            Body                 => 'the message text',
            Charset              => 'ISO-8859-15',
            MimeType             => 'text/plain',
            HistoryType          => 'EmailCustomer',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
        );
        $Self->True(
            $ArticleID,
            "ArticleID $ArticleID is created",
        );

        # Add accounted time to the ticket.
        my $AccountedTime = 123;
        $Success = $TicketObject->TicketAccountTime(
            TicketID  => $TicketID,
            ArticleID => $ArticleID,
            TimeUnit  => $AccountedTime,
            UserID    => 1,
        );
        $Self->True(
            $Success,
            "Accounted Time $AccountedTime added to ticket"
        );

        # Refresh screen to get accounted time value.
        $Selenium->VerifiedRefresh();

        # Verify 'Ticket Information' widget values.
        for my $TicketInformationCheck ( sort keys %TicketData ) {
            $Self->True(
                $Selenium->find_element("//p[contains(\@title, \'$TicketData{$TicketInformationCheck}' )]"),
                "$TicketInformationCheck - $TicketData{$TicketInformationCheck} found in Ticket Information widget"
            );
        }

        # Verify customer link to 'Customer Information Center'.
        $Self->True(
            $Selenium->find_element("//a[contains(\@href, \'AgentCustomerInformationCenter;CustomerID=$Customer' )]"),
            "Customer link to 'Customer Information Center' found",
        );

        # Verify accounted time value.
        $Self->True(
            index( $Selenium->get_page_source(), qq|<p class="Value">$AccountedTime</p>| ) > -1,
            "Accounted Time found in Ticket Information Widget",
        );

        # Verify dynamic field value in 'Ticket Information' widget.
        $Self->True(
            $Selenium->find_element("//span[contains(\@title, \'$DFValue' )]"),
            "DynamicField value - $DFValue found in Ticket Information widget",
        );

        # Recreate TicketObject to let event handlers run also for transaction mode.
        $Kernel::OM->ObjectsDiscard(
            Objects => [
                'Kernel::System::Ticket',
            ],
        );
        $Kernel::OM->Get('Kernel::System::Ticket');

        # Refresh screen to be sure escalation time will get latest times.
        $Selenium->VerifiedRefresh();

        # Get ticket data for escalation time values.
        my %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
            Extended => 1,
            UserID   => 1,
        );

        # Verify escalation times, warning should be active.
        for my $EscalationTime ( sort keys %EscalationTimes ) {
            $EscalationTime = floor( $Ticket{$EscalationTime} / 60 );

            # Check if warning is visible.
            $Self->True(

                # Check for EscalationTime or EscalationTime + 1 (one minute tolerance, since it fails on fast systems).
                $Selenium->find_element(
                    "//p[\@class='Warning'][\@title='Service Time: $EscalationTime m' or \@title='Service Time: "
                        . ( $EscalationTime + 1 ) . " m']"
                ),
                "Escalation Time $EscalationTime m , found in Ticket Information Widget",
            );
        }

        # Cleanup test data.
        # Delete dynamic field value.
        $Success = $DynamicFieldValueObject->ValueDelete(
            FieldID  => $DynamicFieldID,
            ObjectID => $TicketID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "DynamicField value removed from the test ticket",
        );

        # Delete dynamic field.
        $Success = $DynamicFieldObject->DynamicFieldDelete(
            ID     => $DynamicFieldID,
            UserID => 1,
        );
        $Self->True(
            $Success,
            "DynamicFieldID $DynamicFieldID is deleted",
        );

        # Delete test ticket.
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
            "TicketID $TicketID is deleted",
        );

        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # Get delete test data.
        my @DeleteData = (
            {
                SQL     => "DELETE FROM ticket_type WHERE id = $TypeID",
                Message => "TypeID $TypeID is deleted",
            },
            {
                SQL     => "DELETE FROM service_sla WHERE sla_id = $SLAID",
                Message => "Service-SLA relation deleted",
            },
            {
                SQL     => "DELETE FROM sla WHERE id = $SLAID",
                Message => "SLAID $SLAID is deleted",
            },
            {
                SQL     => "DELETE FROM service WHERE id = $ServiceID",
                Message => "ServiceID $ServiceID is deleted",
            },
            {
                SQL     => "DELETE FROM queue WHERE id = $QueueID",
                Message => "QueueID $QueueID is deleted",
            },
        );

        # Delete test created items.
        for my $Item (@DeleteData) {
            $Success = $DBObject->Do(
                SQL => $Item->{SQL},
            );
            $Self->True(
                $Success,
                $Item->{Message},
            );
        }

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure cache is correct.
        for my $Cache (qw( Ticket Type SLA Service Queue DynamicField )) {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
