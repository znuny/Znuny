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
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
        my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');
        my $StateObject  = $Kernel::OM->Get('Kernel::System::State');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'LinkObject::ViewMode',
            Value => 'Complex',
        );
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'LinkObject::ComplexTable::ColumnFilters###Ticket',
            Value => 1,
        );

        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        my $OpenStateID = $StateObject->StateLookup(
            State => 'open',
        );
        my $ClosedStateID = $StateObject->StateLookup(
            State => 'closed successful',
        );

        my $SourceTicketID = $TicketObject->TicketCreate(
            Title        => 'LinkObject ColumnFilter Selenium Source',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerID   => 'LinkObjectColumnFilterSelenium',
            CustomerUser => 'customer@example.com',
            OwnerID      => $TestUserID,
            UserID       => $TestUserID,
        );
        $Self->True( $SourceTicketID, "Created source ticket $SourceTicketID" );

        my $OpenTicketID = $TicketObject->TicketCreate(
            Title        => 'LinkObject ColumnFilter Selenium Open',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerID   => 'LinkObjectColumnFilterSelenium',
            CustomerUser => 'customer@example.com',
            OwnerID      => $TestUserID,
            UserID       => $TestUserID,
        );
        $Self->True( $OpenTicketID, "Created open linked ticket $OpenTicketID" );

        my $ClosedTicketID = $TicketObject->TicketCreate(
            Title        => 'LinkObject ColumnFilter Selenium Closed',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            StateID      => $ClosedStateID,
            CustomerID   => 'LinkObjectColumnFilterSelenium',
            CustomerUser => 'customer@example.com',
            OwnerID      => $TestUserID,
            UserID       => $TestUserID,
        );
        $Self->True( $ClosedTicketID, "Created closed linked ticket $ClosedTicketID" );

        for my $TargetTicketID ( $OpenTicketID, $ClosedTicketID ) {
            my $Success = $LinkObject->LinkAdd(
                SourceObject => 'Ticket',
                SourceKey    => $SourceTicketID,
                TargetObject => 'Ticket',
                TargetKey    => $TargetTicketID,
                Type         => 'Normal',
                State        => 'Valid',
                UserID       => $TestUserID,
            );
            $Self->True( $Success, "Linked source ticket to $TargetTicketID" );
        }

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$SourceTicketID");
        $Selenium->WaitFor(
            ElementMissing => [ '.WidgetIsLoading', 'css' ],
        );
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#WidgetTicket').length && \$('#ColumnFilterState').length;"
        );

        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length;"
            ),
            1,
            'Open linked ticket visible before filter',
        );
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length;"
            ),
            1,
            'Closed linked ticket visible before filter',
        );

        $Selenium->execute_script("\$('#WidgetTicket th.State .ColumnSettingsTrigger').click();");
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#ColumnFilterState option[value=\"$OpenStateID\"]').length;"
        );

        $Selenium->execute_script(
            "\$('#ColumnFilterState').val(['$OpenStateID']).trigger('change');"
        );
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length === 1 && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length === 0;"
        );

        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length;"
            ),
            1,
            'Open linked ticket remains after State filter',
        );
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length;"
            ),
            0,
            'Closed linked ticket hidden after State filter',
        );

        $Self->True(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .LinkObjectClearColumnFilters').length === 1;"
            ),
            'Clear all filters link is shown while column filters are active',
        );
        $Self->True(
            $Selenium->execute_script(
                "return \$('#WidgetTicket th.State').hasClass('FilterActive');"
            ),
            'State column has FilterActive while filter is applied',
        );

        $Selenium->execute_script("\$('#WidgetTicket th.State .ColumnSettingsTrigger').click();");
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#ColumnFilterState').length;"
        );

        # Empty multiselect must clear the filter (jQuery .val() is null when cleared).
        $Selenium->execute_script("\$('#ColumnFilterState').val(null).trigger('change');");
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length === 1 && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length === 1;"
        );

        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length;"
            ),
            1,
            'Open linked ticket visible after clearing State filter',
        );
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length;"
            ),
            1,
            'Closed linked ticket visible after clearing State filter',
        );

        # Apply filter again, then clear via "Clear all filters".
        $Selenium->execute_script("\$('#WidgetTicket th.State .ColumnSettingsTrigger').click();");
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#ColumnFilterState option[value=\"$OpenStateID\"]').length;"
        );
        $Selenium->execute_script(
            "\$('#ColumnFilterState').val(['$OpenStateID']).trigger('change');"
        );
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#WidgetTicket .LinkObjectClearColumnFilters').length === 1 && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length === 0;"
        );

        $Selenium->execute_script("\$('#WidgetTicket .LinkObjectClearColumnFilters').click();");
        $Selenium->WaitFor(
            JavaScript =>
                "return typeof(\$) === 'function' && \$('#WidgetTicket .LinkObjectClearColumnFilters').length === 0 && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length === 1 && \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length === 1;"
        );

        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .LinkObjectClearColumnFilters').length;"
            ),
            0,
            'Clear all filters link is hidden after clearing all filters',
        );
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$OpenTicketID\"]').length;"
            ),
            1,
            'Open linked ticket visible after Clear all filters',
        );
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#WidgetTicket .DataTable tbody tr a[href*=\"TicketID=$ClosedTicketID\"]').length;"
            ),
            1,
            'Closed linked ticket visible after Clear all filters',
        );

        for my $TicketID ( $SourceTicketID, $OpenTicketID, $ClosedTicketID ) {
            my $Success = $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => $TestUserID,
            );
            if ( !$Success ) {
                sleep 3;
                $Success = $TicketObject->TicketDelete(
                    TicketID => $TicketID,
                    UserID   => $TestUserID,
                );
            }
            $Self->True(
                $Success,
                "TicketID $TicketID is deleted",
            );
        }
    }
);

1;
