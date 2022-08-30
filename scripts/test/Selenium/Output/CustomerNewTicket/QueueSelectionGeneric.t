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

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # make sure Ticket::Frontend::CustomerTicketMessage###Queue sysconfig is set to 'Yes'
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::CustomerTicketMessage###Queue',
            Value => 1
        );

        # create test queues
        my @QueueIDs;
        my @QueueNames;
        for my $CreateQueue ( 1 .. 2 ) {
            my $QueueName = "Queue" . $HelperObject->GetRandomID();
            my $QueueID   = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
                Name            => $QueueName,
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
                "Queue add $QueueName - ID $QueueID",
            );
            push @QueueIDs,   $QueueID;
            push @QueueNames, $QueueName;
        }

        # create test system address
        my $SystemAddressName = "SystemAddress" . $HelperObject->GetRandomID() . "\@localhost.com";
        my $SystemAddressID   = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressAdd(
            Name     => $SystemAddressName,
            Realname => 'Selenium SystemAddress',
            ValidID  => 1,
            QueueID  => $QueueIDs[1],
            Comment  => 'Selenium SystemAddress',
            UserID   => 1,
        );

        # create test user and login
        my $TestUserLogin = $HelperObject->TestCustomerUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # navigate to create new ticket
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->VerifiedGet("${ScriptAlias}customer.pl?Action=CustomerTicketMessage");

        # check for test queue destination on customer new ticket
        my $ToQueueCheck
            = $Selenium->find_element( "#Dest option[value='$QueueIDs[0]||$QueueNames[0]']", 'css' )->is_enabled();
        $Self->True(
            $ToQueueCheck,
            "Test $QueueNames[0] is enabled"
        );

        # switch to system address as new destination for customer new ticket
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'CustomerPanelSelectionType',
            Value => 'SystemAddress'
        );

        $Selenium->VerifiedRefresh();

        # check for system address queue destination
        my $ToSystemAddressCheck
            = $Selenium->find_element( "#Dest option[value='$QueueIDs[1]||$QueueNames[1]']", 'css' )->is_enabled();
        $Self->True(
            $ToSystemAddressCheck,
            "Test $QueueNames[1] is enabled"
        );

        # verify that other test queue is not present as destination
        $Self->True(
            index( $Selenium->get_page_source(), "$QueueNames[0]" ) == -1,
            "$QueueNames[0] not found on page",
        );

        # get DB object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # delete created test system address
        my $Success = $DBObject->Do(
            SQL => "DELETE FROM system_address WHERE value0 = \'$SystemAddressName\'",
        );
        $Self->True(
            $Success,
            "Deleted system address - $SystemAddressID",
        );

        # delete created test queues
        for my $QueueDelete (@QueueIDs) {
            $Success = $DBObject->Do(
                SQL => "DELETE FROM queue WHERE id = $QueueDelete",
            );
            $Self->True(
                $Success,
                "Deleted queue - $QueueDelete",
            );
        }

        # make sure the cache is correct.
        for my $Cache (qw(Queue SystemAddress)) {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => $Cache );
        }
    }
);

1;
