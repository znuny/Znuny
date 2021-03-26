# --
# Copyright (C) 2021 Perl-Services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY.
# It is licensed under GNU AFFERO GENERAL PUBLIC LICENSE (AGPL),
# see https://www.gnu.org/licenses/agpl-3.0.txt.
#

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::PostMaster;

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# Disable emails validation.
$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);


# Read email content (from a file).
my $Email = $MainObject->FileRead(
    Location => $ConfigObject->Get('Home') . '/scripts/test/sample/PostMaster/Issue24.eml',

    # Type            => 'Attachment',
    Result => 'ARRAY',
);


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
    Email                  => $Email,
    Debug                  => 2,
);

my ( $ReturnCode, $TicketID ) = $PostMasterObject->Run();

$Self->True( $ReturnCode, 'Check return code' );
$Self->True( $TicketID, 'Check if ticket was created' );

$CommunicationLogObject->ObjectLogStop(
    ObjectLogType => 'Message',
    Status        => 'Successful',
);
$CommunicationLogObject->CommunicationStop(
    Status => 'Successful',
);


# cleanup is done by RestoreDatabase.

1;
