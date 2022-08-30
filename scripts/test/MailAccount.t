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

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# get mail account object
my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

my $MailAccountAdd = $MailAccountObject->MailAccountAdd(
    Login         => 'mail',
    Password      => 'SomePassword',
    Host          => 'pop3.example.com',
    Type          => 'POP3',
    ValidID       => 1,
    Trusted       => 0,
    IMAPFolder    => 'Foo',
    DispatchingBy => 'Queue',              # Queue|From
    QueueID       => 1,
    UserID        => 1,
);

$Self->True(
    $MailAccountAdd,
    'MailAccountAdd()',
);

my %MailAccount = $MailAccountObject->MailAccountGet(
    ID => $MailAccountAdd,
);

$Self->True(
    $MailAccount{Login} eq 'mail',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Password} eq 'SomePassword',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Host} eq 'pop3.example.com',
    'MailAccountGet() - Host',
);
$Self->True(
    $MailAccount{Type} eq 'POP3',
    'MailAccountGet() - Type',
);

$Self->True(
    $MailAccount{IMAPFolder} eq '',
    'MailAccountGet() - IMAPFolder',
);

my $MailAccountUpdate = $MailAccountObject->MailAccountUpdate(
    ID            => $MailAccountAdd,
    Login         => 'mail2',
    Password      => 'SomePassword2',
    Host          => 'imap.example.com',
    Type          => 'IMAP',
    ValidID       => 1,
    IMAPFolder    => 'Bar',
    Trusted       => 0,
    DispatchingBy => 'Queue',              # Queue|From
    QueueID       => 1,
    UserID        => 1,
);

$Self->True(
    $MailAccountUpdate,
    'MailAccountUpdate()',
);

%MailAccount = $MailAccountObject->MailAccountGet(
    ID => $MailAccountAdd,
);

$Self->True(
    $MailAccount{Login} eq 'mail2',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Password} eq 'SomePassword2',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Host} eq 'imap.example.com',
    'MailAccountGet() - Host',
);
$Self->True(
    $MailAccount{Type} eq 'IMAP',
    'MailAccountGet() - Type',
);

$Self->True(
    $MailAccount{IMAPFolder} eq 'Bar',
    'MailAccountGet() - IMAPFolder',
);

my %List = $MailAccountObject->MailAccountList(
    Valid => 0,    # just valid/all accounts
);

$Self->True(
    $List{$MailAccountAdd},
    'MailAccountList()',
);

my $MailAccountDelete = $MailAccountObject->MailAccountDelete(
    ID => $MailAccountAdd,
);

$Self->True(
    $MailAccountDelete,
    'MailAccountDelete()',
);

my $MailAccountAddIMAP = $MailAccountObject->MailAccountAdd(
    Login         => 'mail',
    Password      => 'SomePassword',
    Host          => 'imap.example.com',
    Type          => 'IMAPS',
    ValidID       => 1,
    Trusted       => 0,
    IMAPFolder    => 'Foo',
    DispatchingBy => 'Queue',              # Queue|From
    QueueID       => 1,
    UserID        => 1,
);

$Self->True(
    $MailAccountAddIMAP,
    'MailAccountAdd()',
);

%MailAccount = $MailAccountObject->MailAccountGet(
    ID => $MailAccountAddIMAP,
);

$Self->True(
    $MailAccount{Login} eq 'mail',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Password} eq 'SomePassword',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Host} eq 'imap.example.com',
    'MailAccountGet() - Host',
);
$Self->True(
    $MailAccount{Type} eq 'IMAPS',
    'MailAccountGet() - Type',
);

$Self->True(
    $MailAccount{IMAPFolder} eq 'Foo',
    'MailAccountGet() - IMAPFolder',
);

my $MailAccountUpdateIMAP = $MailAccountObject->MailAccountUpdate(
    ID            => $MailAccountAddIMAP,
    Login         => 'mail2',
    Password      => 'SomePassword2',
    Host          => 'imaps.example.com',
    Type          => 'IMAPS',
    ValidID       => 1,
    Trusted       => 0,
    DispatchingBy => 'Queue',               # Queue|From
    QueueID       => 1,
    UserID        => 1,
);

$Self->True(
    $MailAccountUpdateIMAP,
    'MailAccountUpdate()',
);

%MailAccount = $MailAccountObject->MailAccountGet(
    ID => $MailAccountAddIMAP,
);

$Self->True(
    $MailAccount{Login} eq 'mail2',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Password} eq 'SomePassword2',
    'MailAccountGet() - Login',
);
$Self->True(
    $MailAccount{Host} eq 'imaps.example.com',
    'MailAccountGet() - Host',
);
$Self->True(
    $MailAccount{Type} eq 'IMAPS',
    'MailAccountGet() - Type',
);

$Self->True(
    $MailAccount{IMAPFolder} eq 'INBOX',
    'MailAccountGet() - IMAPFolder fallback',
);

my $MailAccountDeleteIMAP = $MailAccountObject->MailAccountDelete(
    ID => $MailAccountAddIMAP,
);

$Self->True(
    $MailAccountDeleteIMAP,
    'MailAccountDelete() IMAP account',
);

1;
