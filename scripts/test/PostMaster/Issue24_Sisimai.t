# --
# Copyright (C) 2021 Perl-Services.de
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
#

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::PostMaster;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# Disable email address validation.
$ConfigObject->Set(
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
$Self->True( $TicketID,   'Check if ticket was created' );

$CommunicationLogObject->ObjectLogStop(
    ObjectLogType => 'Message',
    Status        => 'Successful',
);
$CommunicationLogObject->CommunicationStop(
    Status => 'Successful',
);

1;
