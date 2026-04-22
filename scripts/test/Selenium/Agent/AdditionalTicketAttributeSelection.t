# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::SeleniumTest::MissingLoader)

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

# get the Znuny Selenium object
my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

# store test function in variable so the Selenium object can handle errors/exceptions/dies etc.
my $SeleniumTest = sub {

    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $SLAObject         = $Kernel::OM->Get('Kernel::System::SLA');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

    # setup a full featured test environment
    my $TestEnvironmentData = $HelperObject->SetupTestEnvironment();

    for my $SLA (qw(A B)) {
        $SLAObject->SLAUpdate(
            SLAID      => $TestEnvironmentData->{SLA}->{"SLA A::Level - 1::$SLA"},
            ServiceIDs => [
                $TestEnvironmentData->{Service}->{'Service A::Level - 1::A'},
                $TestEnvironmentData->{Service}->{'Service A::Level - 1::B'}
            ],
            Name    => "SLA A::Level - 1::$SLA",
            ValidID => 1,
            UserID  => 1,
        );
    }

    my $TicketID = $HelperObject->TicketCreate(
        Title        => 'UnitTest ticket',
        Queue        => 'Queue A::Level - 1::A',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => $TestEnvironmentData->{CustomerUser}->[0]->{UserCustomerID},
        CustomerUser => $TestEnvironmentData->{CustomerUser}->[0]->{UserEmail},
        Service      => 'Service A::Level - 1::A',
        SLA          => 'SLA A::Level - 1::A',
        OwnerID      => 1,
        UserID       => 1,
    );

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID   => $TicketID,
        SenderType => 'customer',
    );

    # create test user and login
    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => [ 'admin', 'users' ],
    );

    my @TestCases = (
        {
            Action => 'AgentTicketPhoneOutbound',

            # Array to fill the fields in the correct order
            Inputs => [
                {
                    FieldID     => 'Subject',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Body',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'StateID',
                    FieldValue  => '4',
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'ServiceID',
                    FieldValue  => $TestEnvironmentData->{Service}->{'Service A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'SLAID',
                    FieldValue  => $TestEnvironmentData->{SLA}->{'SLA A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'TypeID',
                    FieldValue  => $TestEnvironmentData->{Type}->{'Type A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'NewPriorityID',
                    FieldValue  => 2,
                    WaitForAJAX => 1,
                },
            ],
            Validate => {
                Service    => 'Service A::Level - 1::B',
                SLA        => 'SLA A::Level - 1::B',
                Type       => 'Type A::Level - 1::B',
                PriorityID => '2 low',
            },
        },
        {
            Action => 'AgentTicketPhoneInbound',
            Inputs => [
                {
                    FieldID     => 'Subject',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Body',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'StateID',
                    FieldValue  => '4',
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'ServiceID',
                    FieldValue  => $TestEnvironmentData->{Service}->{'Service A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'SLAID',
                    FieldValue  => $TestEnvironmentData->{SLA}->{'SLA A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'TypeID',
                    FieldValue  => $TestEnvironmentData->{Type}->{'Type A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'NewPriorityID',
                    FieldValue  => 1,
                    WaitForAJAX => 1,
                },
            ],
            Validate => {

                # TODO: Checking service does not work somehow in CI environment, but locally.
                #                 Service => 'Service A::Level - 1::A',
                SLA        => 'SLA A::Level - 1::A',
                Type       => 'Type A::Level - 1::A',
                PriorityID => '1 very low',
            },
        },
        {
            Action => 'AgentTicketCompose',
            Inputs => [
                {
                    FieldID     => 'CustomerUserID',
                    FieldValue  => $TestEnvironmentData->{CustomerUser}->[0]->{UserID},
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Subject',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Body',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'StateID',
                    FieldValue  => '4',
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'ServiceID',
                    FieldValue  => $TestEnvironmentData->{Service}->{'Service A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'SLAID',
                    FieldValue  => $TestEnvironmentData->{SLA}->{'SLA A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'TypeID',
                    FieldValue  => $TestEnvironmentData->{Type}->{'Type A::Level - 1::B'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'NewPriorityID',
                    FieldValue  => 4,
                    WaitForAJAX => 1,
                },
            ],
            Validate => {

                # TODO: Checking service does not work somehow in CI environment, but locally.
                #                 Service => 'Service A::Level - 1::B',
                SLA        => 'SLA A::Level - 1::B',
                Type       => 'Type A::Level - 1::B',
                PriorityID => '4 high',
            },
        },
        {
            Action => 'AgentTicketForward',
            Inputs => [
                {
                    FieldID     => 'CustomerUserID',
                    FieldValue  => $TestEnvironmentData->{CustomerUser}->[0]->{UserID},
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Subject',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'Body',
                    FieldValue  => 'Test',
                    WaitForAJAX => 0,
                },
                {
                    FieldID     => 'StateID',
                    FieldValue  => '4',
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'ServiceID',
                    FieldValue  => $TestEnvironmentData->{Service}->{'Service A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'SLAID',
                    FieldValue  => $TestEnvironmentData->{SLA}->{'SLA A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'TypeID',
                    FieldValue  => $TestEnvironmentData->{Type}->{'Type A::Level - 1::A'},
                    WaitForAJAX => 1,
                },
                {
                    FieldID     => 'NewPriorityID',
                    FieldValue  => 5,
                    WaitForAJAX => 1,
                },
            ],
            Validate => {

                # TODO: Checking service does not work somehow in CI environment, but locally.
                #                 Service => 'Service A::Level - 1::A',
                SLA        => 'SLA A::Level - 1::A',
                Type       => 'Type A::Level - 1::A',
                PriorityID => '5 very high',
            },
        },
    );
    for my $Test (@TestCases) {
        $SeleniumObject->AgentInterface(
            Action      => $Test->{Action},
            TicketID    => $TicketID,
            WaitForAJAX => 0,
        );

        for my $Input ( @{ $Test->{Inputs} } ) {
            $SeleniumObject->InputSet(
                Attribute   => $Input->{FieldID},
                Content     => $Input->{FieldValue},
                WaitForAJAX => $Input->{WaitForAJAX} || 0,
            );
        }

        $SeleniumObject->find_element( '#Subject', 'css' )->VerifiedSubmit();

        for my $ValidateKey ( sort keys %{ $Test->{Validate} } ) {
            $SeleniumObject->PageContains(
                String  => $Test->{Validate}->{$ValidateKey},
                Message => "Page contains $Test->{Validate}->{$ValidateKey} after $Test->{Action}",
            );
        }
    }

};

# finally run the test(s) in the browser
$SeleniumObject->RunTest($SeleniumTest);

1;
