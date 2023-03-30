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

use Kernel::System::VariableCheck qw(:all);

my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

my $ZnunyHelperObject   = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestEmailObject = $Kernel::OM->Get('Kernel::System::UnitTest::Email');
my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');
my $TestEmailObject     = $Kernel::OM->Get('Kernel::System::Email::Test');
my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');

my $Success = $UnitTestEmailObject->MailBackendSetup();
$Self->True( $Success, 'Test Mail Backend Setup' );

my @Email = $UnitTestEmailObject->EmailGet();

$UnitTestEmailObject->MailCleanup();
@Email = $UnitTestEmailObject->EmailGet();

$Self->False(
    scalar @Email,
    'No Emails received after cleanup',
);

my $Sent = $EmailObject->Send(
    From          => 'sender@test.com',
    To            => 'to@test.com',
    Cc            => 'cc@test.com',
    Bcc           => 'bcc@test.com',
    ReplyTo       => 'ccr@test.com',
    Subject       => 'MySubject',
    Charset       => 'utf8',
    MimeType      => 'text/html',
    Body          => 'MyBody',
    Loop          => 1,
    CustomHeaders => {
    },
);

$Self->True(
    $Sent,
    'Test Email sent.',
);

$Success = $UnitTestEmailObject->MailObjectDiscard();

$Self->True( $Success, 'Mail Object Discard' );

$UnitTestEmailObject->EmailValidate(
    UnitTestObject => $Self,
    Header         => [ qr{To\:[ ]to\@test\.com}xms, qr{CC\:[ ]cc\@test\.com}xms, ],
    Body           => qr{MyBody}xms,
    ToArray        => [ qr{to\@test\.com}xms, qr{cc\@test\.com}xms, qr{bcc\@test\.com}, ],
);

$UnitTestEmailObject->MailCleanup();

@Email = $UnitTestEmailObject->EmailGet();

$Self->False(
    scalar @Email,
    'No Emails after cleanup',
);
1;
