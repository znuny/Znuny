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

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $CacheObject           = $Kernel::OM->Get('Kernel::System::Cache');
        my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
        my $CustomerUserObject    = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $DBObject              = $Kernel::OM->Get('Kernel::System::DB');
        my $HelperObject          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');
        my $UserObject            = $Kernel::OM->Get('Kernel::System::User');

        $HelperObject->ConfigSettingChange(
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );

        # enable tool bar CICSearchCustomerID
        my %CICSearchCustomerID = (
            Block       => 'ToolBarSearch',
            CSS         => 'Core.Agent.Toolbar.CICSearch.css',
            Description => 'CustomerID search',
            Module      => 'Kernel::Output::HTML::ToolBar::Generic',
            Name        => 'CustomerID',
            Priority    => '1990020',
            Size        => '10',
        );

        $HelperObject->ConfigSettingChange(
            Key   => 'Frontend::ToolBarModule###230-CICSearchCustomerID',
            Value => \%CICSearchCustomerID,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::ToolBarModule###230-CICSearchCustomerID',
            Value => \%CICSearchCustomerID,
        );

        # create test user and login
        my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        );

        $UserObject->SetPreferences(
            UserID => $TestUserID,
            Key    => 'UserToolBar',
            Value  => 1,
        );
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # create test company
        my $TestCustomerID    = $HelperObject->GetRandomID() . 'CID';
        my $TestCompanyName   = 'Company' . $HelperObject->GetRandomID();
        my $CustomerCompanyID = $CustomerCompanyObject->CustomerCompanyAdd(
            CustomerID             => $TestCustomerID,
            CustomerCompanyName    => $TestCompanyName,
            CustomerCompanyStreet  => '5201 Blue Lagoon Drive',
            CustomerCompanyZIP     => '33126',
            CustomerCompanyCity    => 'Miami',
            CustomerCompanyCountry => 'USA',
            CustomerCompanyURL     => 'http://www.example.org',
            CustomerCompanyComment => 'some comment',
            ValidID                => 1,
            UserID                 => $TestUserID,
        );

        $Self->True(
            $CustomerCompanyID,
            "CustomerCompany is created - ID $CustomerCompanyID",
        );

        # create test customer
        my $TestCustomerLogin = 'Customer' . $HelperObject->GetRandomID();
        my $CustomerID        = $CustomerUserObject->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserFirstname  => $TestCustomerLogin,
            UserLastname   => $TestCustomerLogin,
            UserCustomerID => $TestCustomerID,
            UserLogin      => $TestCustomerLogin,
            UserEmail      => $TestCustomerLogin . '@localhost.com',
            ValidID        => 1,
            UserID         => $TestUserID,
        );

        $Self->True(
            $CustomerID,
            "CustomerUser is created - ID $CustomerID",
        );

        # input test user in search CustomerID
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#ToolBarSearchTerm").length' );
        $Selenium->find_element( "#ToolBarSearchTerm", 'css' )->click();

        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("#ToolBarSearchBackendCustomerID").length'
        );
        $Selenium->find_element( "#ToolBarSearchBackendCustomerID", 'css' )->click();
        $Selenium->find_element( "#ToolBarSearchTerm",              'css' )->send_keys($TestCustomerID);

        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("li.ui-menu-item:visible").length' );
        $Selenium->execute_script("\$('li.ui-menu-item:contains($TestCustomerID)').click()");

        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' &&  \$('tbody a:contains($TestCustomerLogin)').length;"
        );

        $Self->True(
            $Selenium->execute_script("return \$('tbody a:contains($TestCustomerLogin)').length;"),
            "Search by CustomerID success - found $TestCustomerLogin",
        );

        $Self->True(
            $Selenium->find_element( '#CustomerInformationCenterHeading', 'css' ),
            "Check heading for CustomerInformationCenter",
        );

        # delete test customer company
        my $Success = $DBObject->Do(
            SQL  => "DELETE FROM customer_company WHERE customer_id = ?",
            Bind => [ \$CustomerCompanyID ],
        );
        $Self->True(
            $Success,
            "CustomerCompany is deleted - ID $CustomerCompanyID",
        );

        # delete test customer
        $Success = $DBObject->Do(
            SQL  => "DELETE FROM customer_user WHERE customer_id = ?",
            Bind => [ \$CustomerID ],
        );
        $Self->True(
            $Success,
            "CustomerUser is deleted - ID $CustomerID",
        );

        # make sure the cache is correct
        for my $Cache (
            qw (CustomerCompany CustomerUser)
            )
        {
            $CacheObject->CleanUp(
                Type => $Cache,
            );
        }

    }
);

1;
