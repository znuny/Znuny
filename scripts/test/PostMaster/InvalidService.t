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

use Kernel::System::PostMaster;

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $ServiceObject         = $Kernel::OM->Get('Kernel::System::Service');
my $CommunicationDBObject = $Kernel::OM->Get('Kernel::System::CommunicationLog::DB');
my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');

$ConfigObject->Set(
    Key   => 'Ticket::Service',
    Value => 1,
);

my $ServiceID = $ServiceObject->ServiceAdd(
    Name    => 'InvalidServiceUnitTestService',
    ValidID => 1,
    UserID  => 1,
);

my @Tests = (
    {
        ServiceName            => 'NotExistingServiceUnitTest',
        ExpectedTicketService  => '',
        InvalidServiceLogCount => 1,
    },
    {
        ServiceName            => 'InvalidServiceUnitTestService',
        ExpectedTicketService  => $ServiceID,
        InvalidServiceLogCount => 0,
    },
);

for my $Test (@Tests) {
    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport => 'Email',
            Direction => 'Incoming',
        },
    );
    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

    my $PostMasterObject = Kernel::System::PostMaster->new(
        CommunicationLogObject => $CommunicationLogObject,
        Email                  => "From: Provider <customeruser\@unittest.com>
To: Agent <agent\@unittest.com>
Subject: InvalidServiceUnitTest
X-OTRS-Service: $Test->{ServiceName}

Some Content in Body",
    );

    my @Return = $PostMasterObject->Run();

    $CommunicationLogObject->ObjectLogStop(
        ObjectLogType => 'Message',
        Status        => 'Successful',
    );

    my $ObjectLogList = $CommunicationDBObject->ObjectLogList(
        CommunicationID => $CommunicationLogObject->{CommunicationID}
    );

    my $ObjectLogEntryList = $CommunicationDBObject->ObjectLogEntryList(
        CommunicationID => $CommunicationLogObject->{CommunicationID},
        ObjectLogID     => $ObjectLogList->[0]->{ObjectLogID}
    );

    my @InvalidServiceLogFound
        = grep { $_->{LogValue} =~ /does not exist or is invalid or is a child of invalid service/ }
        @{$ObjectLogEntryList};

    $Self->Is(
        scalar @InvalidServiceLogFound,
        $Test->{InvalidServiceLogCount},
        "Invalid service for new ticket blocked"
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Return[1],
        UserID   => 1,
    );

    $Self->Is(
        $Ticket{ServiceID},
        $Test->{ExpectedTicketService},
        "Check if ticket has service set"
    );

    $CommunicationLogObject->CommunicationStop(
        Status => 'Successful',
    );
}

1;
