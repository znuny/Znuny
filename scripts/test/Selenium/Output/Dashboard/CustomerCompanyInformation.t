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

        my $HelperObject          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
        my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
        my $UserObject            = $Kernel::OM->Get('Kernel::System::User');
        my $CacheObject           = $Kernel::OM->Get('Kernel::System::Cache');
        my $DBObject              = $Kernel::OM->Get('Kernel::System::DB');

        # create test user and login
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get test user ID
        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # create test company
        my $TestCustomerID  = $HelperObject->GetRandomID() . "CID";
        my $TestCompanyName = "Company" . $HelperObject->GetRandomID();
        my @CustomerCompany
            = ( 'Selenium Street', 'Selenium ZIP', 'Selenium City', 'Selenium Country', 'Selenium URL' );
        my $CustomerCompanyID = $CustomerCompanyObject->CustomerCompanyAdd(
            CustomerID             => $TestCustomerID,
            CustomerCompanyName    => $TestCompanyName,
            CustomerCompanyStreet  => $CustomerCompany[0],
            CustomerCompanyZIP     => $CustomerCompany[1],
            CustomerCompanyCity    => $CustomerCompany[2],
            CustomerCompanyCountry => $CustomerCompany[3],
            CustomerCompanyURL     => $CustomerCompany[4],
            CustomerCompanyComment => 'some comment',
            ValidID                => 1,
            UserID                 => $TestUserID,
        );
        $Self->True(
            $CustomerCompanyID,
            "CustomerCompany is created - ID $CustomerCompanyID",
        );

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # navigate to AgentCustomerInformationCenter screen
        $Selenium->VerifiedGet(
            "${ScriptAlias}index.pl?Action=AgentCustomerInformationCenter;CustomerID=$TestCustomerID"
        );

        # test customer information widget
        for my $Test (@CustomerCompany) {
            $Self->True(
                index( $Selenium->get_page_source(), $Test ) > -1,
                "$Test - found on screen"
            );
        }

        # change attribute setting
        $HelperObject->ConfigSettingChange(
            Key   => 'AgentCustomerInformationCenter::Backend###0600-CIC-CustomerCompanyInformation',
            Value => {
                'Attributes'  => 'CustomerCompanyStreet;CustomerCompanyCity',
                'Block'       => 'ContentSmall',
                'Default'     => '1',
                'Description' => 'Customer Information',
                'Group'       => '',
                'Module'      => 'Kernel::Output::HTML::Dashboard::CustomerCompanyInformation',
                'Title'       => "Customer Information",
            },
        );

        # navigate again to AgentCustomerInformationCenter screen
        $Selenium->VerifiedGet(
            "${ScriptAlias}index.pl?Action=AgentCustomerInformationCenter;CustomerID=$TestCustomerID"
        );

        # test customer information widget
        for my $Test (qw(Selenium Street Selenium City)) {
            $Self->True(
                index( $Selenium->get_page_source(), $Test ) > -1,
                "$Test - found on screen"
            );
        }

        # delete test customer company
        my $Success = $DBObject->Do(
            SQL  => "DELETE FROM customer_company WHERE customer_id = ?",
            Bind => [ \$CustomerCompanyID ],
        );
        $Self->True(
            $Success,
            "CustomerCompany is deleted - ID $CustomerCompanyID",
        );

        # make sure the cache is correct
        $CacheObject->CleanUp(
            Type => 'CustomerCompany',
        );

    }
);

1;
