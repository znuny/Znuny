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

use Kernel::Output::HTML::Layout;

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # Change web max file upload.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'WebMaxFileUpload',
            Value => '68000'
        );

        # Change config for AgentTicketMove.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::MoveType',
            Value => 'link'
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketMove###Note',
            Value => 1
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketMove###NoteMandatory',
            Value => 1
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketOwner###NoteMandatory',
            Value => 1
        );

        # Create test ticket.
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Selenium Test Ticket',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => 'SeleniumCustomer',
            CustomerUser => 'SeleniumCustomer@localhost.com',
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TicketID,
            "Ticket ID $TicketID is created",
        );

        my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );

        # Create test email Article.
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            SenderType           => 'customer',
            Subject              => "Selenium subject article",
            Body                 => 'Selenium body article',
            Charset              => 'ISO-8859-15',
            MimeType             => 'text/plain',
            HistoryType          => 'AddNote',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
            IsVisibleForCustomer => 1,
        );
        $Self->True(
            $ArticleID,
            "Article ID $ArticleID is created",
        );

        # Get RandomID.
        my $RandomID = $HelperObject->GetRandomID();

        my $Language = 'en';

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups   => [ 'admin', 'users' ],
            Language => $Language,
        ) || die "Did not get test user";

        my $LayoutObject = Kernel::Output::HTML::Layout->new(
            Lang         => $Language,
            UserTimeZone => 'UTC',
        );

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $ScriptAlias  = $ConfigObject->Get('ScriptAlias');
        my $Home         = $ConfigObject->Get('Home');

        # Check screens.
        for my $Action (
            qw(
            AgentTicketOwner
            AgentTicketMove
            AgentTicketClose
            AgentTicketPending
            AgentTicketPriority
            AgentTicketForward
            )
            )
        {

            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID");
            sleep 1;

            if ( $Action eq 'AgentTicketOwner' )
            {

                $Selenium->WaitFor(
                    JavaScript =>
                        'return typeof($) === "function" && $(".Cluster ul ul").length;'
                );

                # Force sub menus to be visible in order to be able to click one of the links.
                $Selenium->execute_script("\$('.Cluster ul ul').addClass('ForceVisible');");
            }

            if ( $Action eq 'AgentTicketMove' ) {
                $Selenium->WaitForjQueryEventBound(
                    CSSSelector => "a[title='Change Queue']",
                );

                # Click on 'Move' and switch window.
                $Selenium->find_element("//a[\@title='Change Queue']")->click();
            }
            else {
                $Selenium->find_element("//a[contains(\@href, \'Action=$Action;TicketID=$TicketID' )]")->click();
            }

            $Selenium->WaitFor( WindowCount => 2 );
            my $Handles = $Selenium->get_window_handles();
            $Selenium->switch_to_window( $Handles->[1] );

            # Wait until page has loaded, if necessary.
            $Selenium->WaitFor( JavaScript => "return typeof(\$) === 'function' && \$('.DnDUpload').length;" );

            # Check DnDUpload.
            my $Element = $Selenium->find_element( ".DnDUpload", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();

            # Hide DnDUpload and show input field.
            $Selenium->execute_script("\$('.DnDUpload').css('display', 'none');");
            $Selenium->execute_script("\$('#FileUpload').css('display', 'block');");

            my $Location = "$Home/scripts/test/sample/Main/Main-Test1.doc";
            $Selenium->find_element( "#FileUpload", 'css' )->clear();
            $Selenium->find_element( "#FileUpload", 'css' )->send_keys($Location);

            $Selenium->WaitFor(
                JavaScript =>
                    "return typeof(\$) === 'function' && \$('.AttachmentList tbody tr td.Filename:contains(\"Main-Test1.doc\")').length === 1;"
            );

            # Wait until file is uploaded and 'Progress' class is removed.
            $Selenium->WaitFor(
                JavaScript =>
                    "return !\$('.td.Filename:contains(\"Main-Test1.doc\")').siblings('.Filesize').find('.Progress').length;"
            );
            sleep 2;

            # Check if uploaded.
            $Self->True(
                $Selenium->execute_script(
                    "return \$('.AttachmentList tbody tr td.Filename:contains(\"Main-Test1.doc\")').length;"
                ),
                "$Action - Upload file correct"
            );

            $Selenium->WaitFor(
                JavaScript => "return \$('.AttachmentDelete i').length === 1;"
            );
            sleep 2;

            # Delete Attachment.
            $Selenium->find_element( ".AttachmentDelete i", 'css' )->click();
            sleep 2;

            # Wait until attachment is deleted.
            $Selenium->WaitFor(
                JavaScript => "return !\$('.AttachmentDelete i').length;"
            );

            # Check if deleted.
            $Self->True(
                $Selenium->execute_script(
                    "return !\$('.AttachmentDelete i').length;"
                ),
                "$Action - Uploaded file Main-Test1.doc deleted"
            );

            $Selenium->close();
            $Selenium->WaitFor( WindowCount => 1 );
            $Selenium->switch_to_window( $Handles->[0] );
        }

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
            "Ticket ID $TicketID is deleted"
        );

        # Make sure the cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Ticket' );
    }
);

1;
