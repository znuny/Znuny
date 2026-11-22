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

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Use plain textarea instead of CKEditor 5.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        # Enable FormDrafts in AgentTicketActionCommon screens.
        for my $SySConfig (qw(Outbound Inbound)) {
            $HelperObject->ConfigSettingChange(
                Valid => 1,
                Key   => "Ticket::Frontend::AgentTicketPhone${SySConfig}###FormDraft",
                Value => 1
            );
        }

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

        # Get RandomID.
        my $RandomID = $HelperObject->GetRandomID();

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Navigate to zoom view of created test ticket.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID");

        # Create test case matrix.
        my @Tests = (
            {
                Module => 'Outbound',
                Fields => {
                    State => {
                        ID     => 'NextStateID',
                        Type   => 'DropDown',
                        Value  => 3,
                        Update => 7,
                    },
                    Subject => {
                        ID     => 'Subject',
                        Type   => 'Input',
                        Value  => 'Selenium Outbound Subject',
                        Update => 'Selenium OutBound Subject - Update'
                    },
                    Body => {
                        ID     => 'RichText',
                        Type   => 'Input',
                        Value  => 'Selenium Outbound Body',
                        Update => 'Selenium Outbound Body - Update',
                    },
                    Attachments => {
                        ID   => 'FileUpload',
                        Type => 'Attachment',
                    },
                },
            },
            {
                Module => 'Inbound',
                Fields => {
                    State => {
                        ID     => 'NextStateID',
                        Type   => 'DropDown',
                        Value  => 3,
                        Update => 7,
                    },
                    Subject => {
                        ID     => 'Subject',
                        Type   => 'Input',
                        Value  => 'Selenium Inbound Subject',
                        Update => 'Selenium Inbound Subject - Update'
                    },
                    Body => {
                        ID     => 'RichText',
                        Type   => 'Input',
                        Value  => 'Selenium Inbound Body',
                        Update => 'Selenium Inbound Body - Update',
                    },
                    Attachments => {
                        ID   => 'FileUpload',
                        Type => 'Attachment',
                    },
                },
            },
        );

        # Execute test scenarios.
        for my $Test (@Tests) {

            # Create FormDraft name.
            my $Title = $Test->{Module} . 'FormDraft' . $RandomID;

            # Force sub menus to be visible in order to be able to click one of the links.
            $Selenium->execute_script("\$('.Cluster ul ul').addClass('ForceVisible');");
            $Selenium->WaitFor( JavaScript => "return \$('#nav-Communication ul').css('opacity') == 1;" );

            # Click on module and switch window.
            $Selenium->find_element(
                "//a[contains(\@href, \'Action=AgentTicketPhone$Test->{Module};TicketID=$TicketID' )]"
            )->click();

            $Selenium->WaitFor( WindowCount => 2 );
            my $Handles = $Selenium->get_window_handles();
            $Selenium->switch_to_window( $Handles->[1] );

            # Wait until page has loaded, if necessary.
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#submitRichText").length;'
            );

            # Input fields.
            for my $Field ( sort keys %{ $Test->{Fields} } ) {

                if ( $Test->{Fields}->{$Field}->{Type} eq 'DropDown' ) {
                    $Selenium->InputFieldValueSet(
                        Element => "#$Test->{Fields}->{$Field}->{ID}",
                        Value   => $Test->{Fields}->{$Field}->{Value},
                    );
                }
                elsif ( $Test->{Fields}->{$Field}->{Type} eq 'Attachment' ) {

                    # Make the file upload field visible.
                    $Selenium->VerifiedRefresh();
                    $Selenium->execute_script(
                        "\$('#FileUpload').css('display', 'block')"
                    );
                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof($) === "function" && $("#FileUpload:visible").length;'
                    );
                    sleep 1;

                    # upload_file copies the sample onto the Selenium node. Chrome cannot
                    # read /opt/znuny paths from the app container.
                    my $Location = $Selenium->upload_file(
                        $Selenium->{Home} . "/scripts/test/sample/Main/Main-Test1.pdf"
                    );
                    $Selenium->find_element( "#FileUpload", 'css' )->send_keys($Location);

                    # Check if uploaded.
                    $Self->Is(
                        $Selenium->execute_script(
                            "return \$('.AttachmentList tbody tr td.Filename:contains(Main-Test1.pdf)').length"
                        ),
                        1,
                        "Uploaded file correctly"
                    );

                }
                elsif ( $Test->{Fields}->{$Field}->{Type} eq 'RichText' ) {

                    # CKEditor hides #RichText. clear() on that textarea is not interactable.
                    $Selenium->WaitFor(
                        JavaScript =>
                            "return \$('.ck-editor__editable').contents().length >= 1;"
                    );

                    $Selenium->execute_script(
                        "return window.editor.setData('$Test->{Fields}->{$Field}->{Value}');"
                    );
                    $Selenium->execute_script(
                        "return window.editor.updateSourceElement();"
                    );
                }
                else {
                    $Selenium->find_element( "#$Test->{Fields}->{$Field}->{ID}", 'css' )->clear();
                    $Selenium->find_element( "#$Test->{Fields}->{$Field}->{ID}", 'css' )
                        ->send_keys( $Test->{Fields}->{$Field}->{Value} );
                }
            }

            # Create FormDraft and submit.
            $Selenium->execute_script("\$('#FormDraftSave').click();");
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#FormDraftTitle").length;'
            );
            $Selenium->find_element( "#FormDraftTitle", 'css' )->send_keys($Title);
            $Selenium->find_element( "#SaveFormDraft",  'css' )->click();

            # Switch back window.
            $Selenium->WaitFor( WindowCount => 1 );
            $Selenium->switch_to_window( $Handles->[0] );

            # Refresh screen.
            $Selenium->VerifiedRefresh();

            # Verify FormDraft is created in zoom screen.
            $Self->True(
                index( $Selenium->get_page_source(), $Title ) > -1,
                "FormDraft for $Test->{Module} $Title is found",
            );

            my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );

            # Create test Article to trigger that draft is outdated.
            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $TicketID,
                SenderType           => 'customer',
                Subject              => "Article $Test->{Module} OutDate FormDraft trigger",
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

            # Refresh screen.
            $Selenium->VerifiedRefresh();

            # Open the saved FormDraft. Native click is intercepted by the lock/draft alert overlay.
            $Selenium->execute_script(
                "\$('a[href*=\"Action=AgentTicketPhone$Test->{Module};TicketID=$TicketID;LoadFormDraft=1\"]').get(0).click();"
            );

            $Selenium->WaitFor( WindowCount => 2 );
            $Handles = $Selenium->get_window_handles();
            $Selenium->switch_to_window( $Handles->[1] );

            # Wait until page has loaded, if necessary.
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#submitRichText").length;'
            );

            # Make sure that outdated notification is present.
            $Self->True(
                index( $Selenium->get_page_source(), "You have loaded the draft \"$Title\"" ) > 0,
                'Draft loaded notification is present',
            );

            # Make sure that outdated notification is present.
            $Self->True(
                index(
                    $Selenium->get_page_source(),
                    "Please note that this draft is outdated because the ticket was modified since this draft was created."
                    )
                    > 0,
                'Outdated notification is present',
            );

            # Verify initial FormDraft values and update them.
            for my $FieldValue ( sort keys %{ $Test->{Fields} } ) {

                if ( $Test->{Fields}->{$FieldValue}->{Type} eq 'DropDown' ) {
                    $Self->Is(
                        $Selenium->execute_script("return \$('#$Test->{Fields}->{$FieldValue}->{ID}').val()"),
                        $Test->{Fields}->{$FieldValue}->{Value},
                        "Initial FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );

                    $Selenium->InputFieldValueSet(
                        Element => "#$Test->{Fields}->{$FieldValue}->{ID}",
                        Value   => $Test->{Fields}->{$FieldValue}->{Update},
                    );
                }
                elsif ( $Test->{Fields}->{$FieldValue}->{Type} eq 'Attachment' ) {

                    # there should be only one file with a certain name
                    $Self->Is(
                        $Selenium->execute_script(
                            "return \$('.AttachmentList tbody tr td.Filename:contains(Main-Test1.pdf)').length"
                        ),
                        1,
                        "Uploaded file correctly"
                    );
                    $Self->Is(
                        $Selenium->execute_script(
                            "return \$('.AttachmentList tbody tr td.Filename').length"
                        ),
                        1,
                        "Only one file present"
                    );

                    # Add a second file.
                    $Selenium->VerifiedRefresh();
                    $Selenium->execute_script(
                        "\$('#FileUpload').css('display', 'block')"
                    );
                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof($) === "function" && $("#FileUpload:visible").length;'
                    );
                    sleep 1;

                    # upload_file copies the sample onto the Selenium node. Chrome cannot
                    # read /opt/znuny paths from the app container.
                    my $Location = $Selenium->upload_file(
                        $Selenium->{Home} . "/scripts/test/sample/Main/Main-Test1.doc"
                    );
                    $Selenium->find_element( "#FileUpload", 'css' )->send_keys($Location);

                    # Check if uploaded.
                    $Self->Is(
                        $Selenium->execute_script(
                            "return \$('.AttachmentList tbody tr td.Filename:contains(Main-Test1.doc)').length"
                        ),
                        1,
                        "Uploaded file correctly"
                    );
                }
                elsif ( $Test->{Fields}->{$FieldValue}->{Type} eq 'RichText' ) {

                    # CKEditor hides #RichText. clear() on that textarea is not interactable.
                    $Selenium->WaitFor(
                        JavaScript =>
                            "return \$('.ck-editor__editable').contents().length >= 1;"
                    );

                    # CKEditor 5 wraps plain text in a paragraph.
                    $Self->Is(
                        $Selenium->execute_script('return window.editor.getData();'),
                        '<p>' . $Test->{Fields}->{$FieldValue}->{Value} . '</p>',
                        "Initial FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );

                    $Selenium->execute_script(
                        "return window.editor.setData('$Test->{Fields}->{$FieldValue}->{Update}');"
                    );
                    $Selenium->execute_script(
                        "return window.editor.updateSourceElement();"
                    );
                }
                else {
                    $Self->Is(
                        $Selenium->find_element( "#$Test->{Fields}->{$FieldValue}->{ID}", 'css' )->get_value(),
                        $Test->{Fields}->{$FieldValue}->{Value},
                        "Initial FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );

                    $Selenium->find_element( "#$Test->{Fields}->{$FieldValue}->{ID}", 'css' )->clear();
                    $Selenium->find_element( "#$Test->{Fields}->{$FieldValue}->{ID}", 'css' )
                        ->send_keys( $Test->{Fields}->{$FieldValue}->{Update} );
                }
            }

            $Selenium->find_element( "#FormDraftUpdate", 'css' )->click();

            # Switch back window.
            $Selenium->WaitFor( WindowCount => 1 );
            $Selenium->switch_to_window( $Handles->[0] );

            # Refresh screen.
            $Selenium->VerifiedRefresh();

            # Open the saved FormDraft. Native click is intercepted by the lock/draft alert overlay.
            $Selenium->execute_script(
                "\$('a[href*=\"Action=AgentTicketPhone$Test->{Module};TicketID=$TicketID;LoadFormDraft=1\"]').get(0).click();"
            );

            $Selenium->WaitFor( WindowCount => 2 );
            $Handles = $Selenium->get_window_handles();
            $Selenium->switch_to_window( $Handles->[1] );

            # Wait until page has loaded, if necessary.
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#submitRichText").length;'
            );

            # Verify updated FormDraft values.
            for my $FieldValue ( sort keys %{ $Test->{Fields} } ) {

                if ( $Test->{Fields}->{$FieldValue}->{Type} eq 'DropDown' ) {
                    $Self->Is(
                        $Selenium->execute_script("return \$('#$Test->{Fields}->{$FieldValue}->{ID}').val()"),
                        $Test->{Fields}->{$FieldValue}->{Update},
                        "Updated FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );
                }
                elsif ( $Test->{Fields}->{$FieldValue}->{Type} eq 'Attachment' ) {

                    # there should be two files now
                    $Self->Is(
                        $Selenium->execute_script(
                            "return \$('.AttachmentList tbody tr td.Filename').length"
                        ),
                        2,
                        "Uploaded file correctly"
                    );
                }
                elsif ( $Test->{Fields}->{$FieldValue}->{Type} eq 'RichText' ) {

                    $Selenium->WaitFor(
                        JavaScript =>
                            "return \$('.ck-editor__editable').contents().length >= 1;"
                    );

                    # CKEditor 5 wraps plain text in a paragraph.
                    $Self->Is(
                        $Selenium->execute_script('return window.editor.getData();'),
                        '<p>' . $Test->{Fields}->{$FieldValue}->{Update} . '</p>',
                        "Updated FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );
                }
                else {
                    $Self->Is(
                        $Selenium->find_element( "#$Test->{Fields}->{$FieldValue}->{ID}", 'css' )->get_value(),
                        $Test->{Fields}->{$FieldValue}->{Update},
                        "Updated FormDraft value for $Test->{Module} field $FieldValue is correct"
                    );
                }
            }

            $Selenium->close();

            # Switch back window.
            $Selenium->WaitFor( WindowCount => 1 );
            $Selenium->switch_to_window( $Handles->[0] );

            # Refresh screen.
            $Selenium->VerifiedRefresh();

            # Delete draft.
            # Native click misses the control: .table-icon-hover-md uses text-indent:-9999px.
            $Selenium->execute_script("\$('a.FormDraftDelete').click();");
            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $("#DeleteConfirm").length;'
            );
            $Selenium->find_element( "#DeleteConfirm", 'css' )->click();

            $Selenium->WaitFor(
                JavaScript =>
                    'return typeof($) === "function" && $(".FormDraftDelete").length==0;'
            ) || die 'FormDraft was not deleted!';
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
    }
);

1;
