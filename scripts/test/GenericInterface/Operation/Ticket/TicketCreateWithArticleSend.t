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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
my $ZnunyHelperObject        = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $UnitTestEmailObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Email');
my $QueueObject              = $Kernel::OM->Get('Kernel::System::Queue');

$UnitTestEmailObject->MailCleanup();

my %Queue = $QueueObject->QueueGet(
    Name => 'Misc',
);
my $Signature = $QueueObject->GetSignature(
    QueueID => $Queue{QueueID}
);

if ( $Signature =~ m{Your Ticket-Team}m ) {
    $Self->True(
        $Signature,
        "Signature of Queue Misc: $Signature",
    );
}

my %UserData = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);

my $Home = $ConfigObject->Get('Home');

$ZnunyHelperObject->_WebserviceCreate(
    Webservices => {
        TicketCreateAndUpdateWithArticleSend => $Home
            . '/scripts/test/sample/Webservice/TicketCreateAndUpdateWithArticleSend.yml',
    },
);

my $Response = $UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'TicketCreateAndUpdateWithArticleSend',
    Operation      => 'TicketCreate',
    Payload        => {
        Ticket => {
            Title        => 'Ticket Title',
            CustomerUser => 'someone@somewhere.com',
            Type         => 'Unclassified',
            Queue        => 'Misc',
            State        => 'open',
            Priority     => '3 normal',
            Owner        => 'root@localhost',
            Responsible  => 'root@localhost',
        },
        Article => {
            Subject              => 'Article subject äöüßÄÖÜ€ис',
            Body                 => 'Article body !"Â§$%&/()=?Ã<U+009C>*Ã<U+0084>Ã<U+0096>L:L@,.-',
            AutoResponseType     => 'auto reply',
            IsVisibleForCustomer => 1,
            CommunicationChannel => 'Email',
            SenderType           => 'agent',
            From                 => 'hello@znuny.org',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'NewTicket',
            HistoryComment       => '% % ',
            ArticleSend          => 1,
            To                   => 'rs+TicketCreateAndUpdateWithArticleSend@znuny.org',
            Cc                   => 'jp+TicketCreateAndUpdateWithArticleSend@znuny.org',
            Bcc                  => 'jp2+TicketCreateAndUpdateWithArticleSend@znuny.org',
        },
        UserLogin => $UserData{UserLogin},
        Password  => $UserData{UserLogin},
    },
);

$Self->True(
    $Response->{Success},
    'ticket created successfully',
);
$Self->True(
    $Response->{Data}->{TicketID},
    'ticket creation result contains ticket id',
);

my @Emails = $UnitTestEmailObject->EmailGet();

my $CcFound;
EMAIL:
for my $Email (@Emails) {
    next EMAIL if !$Email->{Header};
    next EMAIL if $Email->{Header} !~ m{^CC:\s*jp\+TicketCreateAndUpdateWithArticleSend\@znuny\.org$}sm;

    $CcFound = 1;
    last EMAIL;
}

$Self->True(
    $CcFound,
    'Sent email must contain expected Cc address.',
);

$UnitTestEmailObject->EmailValidate(
    UnitTestObject => $Self,
    Message        => 'ticket creation triggered ArticleSend functionality.',
    Email          => \@Emails,
    ToArray        => [
        'rs+TicketCreateAndUpdateWithArticleSend@znuny.org',     # To
        'jp+TicketCreateAndUpdateWithArticleSend@znuny.org',     # Cc
        'jp2+TicketCreateAndUpdateWithArticleSend@znuny.org',    # Bcc (not testable like Cc above)
    ],
    Body => qr{Your Ticket-Team}m,
);

# test with no To-email
$UnitTestEmailObject->MailCleanup();

$Response = $UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'TicketCreateAndUpdateWithArticleSend',
    Operation      => 'TicketCreate',
    Payload        => {
        Ticket => {
            Title        => 'Ticket Title',
            CustomerUser => 'someone@somewhere.com',
            Type         => 'Unclassified',
            Queue        => 'Misc',
            State        => 'open',
            Priority     => '3 normal',
            Owner        => 'root@localhost',
            Responsible  => 'root@localhost',
        },
        Article => {
            Subject              => 'Article subject äöüßÄÖÜ€ис',
            Body                 => 'Article body !"Â§$%&/()=?Ã<U+009C>*Ã<U+0084>Ã<U+0096>L:L@,.-',
            AutoResponseType     => 'auto reply',
            IsVisibleForCustomer => 1,
            CommunicationChannel => 'Email',
            SenderType           => 'agent',
            From                 => 'hello@znuny.org',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'NewTicket',
            HistoryComment       => '% % ',
            ArticleSend          => 1,
        },
        UserLogin => $UserData{UserLogin},
        Password  => $UserData{UserLogin},
    },
);

$Self->Is(
    $Response->{Data}->{Error}->{ErrorCode},
    'TicketCreate.InvalidParameter',
    'ticket creation failed',
);

@Emails = $UnitTestEmailObject->EmailGet();
$Self->False(
    @Emails ? 1 : 0,
    'No emails sent out',
);

1;
