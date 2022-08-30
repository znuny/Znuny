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

use Kernel::Output::HTML::ArticleCheck::PGP;
use Kernel::System::PostMaster;

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $HTMLUtilsObject      = $Kernel::OM->Get('Kernel::System::HTMLUtils');
my $MainObject           = $Kernel::OM->Get('Kernel::System::Main');
my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Email');
my $UserObject           = $Kernel::OM->Get('Kernel::System::User');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
);

# Disable email addresses checking.
$HelperObject->ConfigSettingChange(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

# set config
$ConfigObject->Set(
    Key   => 'PGP',
    Value => 1,
);
$ConfigObject->Set(
    Key   => 'PGP::Options',
    Value => '--batch --no-tty --yes',
);

$ConfigObject->Set(
    Key   => 'PGP::Key::Password',
    Value => { '04A17B7A' => 'somepass' },
);

$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::DoNotSendEmail',
);

my $PGPBin = $ConfigObject->Get('PGP::Bin');

# check if gpg is located there
if ( !$PGPBin || !( -e $PGPBin ) ) {

    if ( -e '/usr/bin/gpg' ) {
        $ConfigObject->Set(
            Key   => 'PGP::Bin',
            Value => '/usr/bin/gpg'
        );
    }

    # maybe it's a mac with macport
    elsif ( -e '/opt/local/bin/gpg' ) {
        $ConfigObject->Set(
            Key   => 'PGP::Bin',
            Value => '/opt/local/bin/gpg'
        );
    }

    # Try to guess using system 'which'
    else {    # try to guess
        my $GPGBin = `which gpg`;
        chomp $GPGBin;
        if ($GPGBin) {
            $ConfigObject->Set(
                Key   => 'PGP::Bin',
                Value => $GPGBin,
            );
        }
    }

}

# create local crypt object
my $PGPObject = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

if ( !$PGPObject ) {
    print STDERR "NOTICE: No PGP support!\n";
    return;
}

# make some preparations
my %Search = (
    1 => 'unittest@example.com',
    2 => 'unittest2@example.com',
);

my %Check = (
    1 => {
        Type             => 'pub',
        Identifier       => 'UnitTest <unittest@example.com>',
        Bit              => '1024',
        Key              => '38677C3B',
        KeyPrivate       => '04A17B7A',
        Created          => '2007-08-21',
        Expires          => 'never',
        Fingerprint      => '4124 DFBD CF52 D129 AB3E  3C44 1404 FBCB 3867 7C3B',
        FingerprintShort => '4124DFBDCF52D129AB3E3C441404FBCB38677C3B',
    },
    2 => {
        Type             => 'pub',
        Identifier       => 'UnitTest2 <unittest2@example.com>',
        Bit              => '1024',
        Key              => 'F0974D10',
        KeyPrivate       => '8593EAE2',
        Created          => '2007-08-21',
        Expires          => '2037-08-13',
        Fingerprint      => '36E9 9F7F AD76 6405 CBE1  BB42 F533 1A46 F097 4D10',
        FingerprintShort => '36E99F7FAD766405CBE1BB42F5331A46F0974D10',
    },
);

# add PGP keys and perform sanity check
for my $Count ( 1 .. 2 ) {

    my @Keys = $PGPObject->KeySearch(
        Search => $Search{$Count},
    );
    $Self->False(
        $Keys[0] || '',
        "Key:$Count - KeySearch()",
    );

    # get keys
    my $KeyString = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/Crypt/",
        Filename  => "PGPPrivateKey-$Count.asc",
    );
    my $Message = $PGPObject->KeyAdd(
        Key => ${$KeyString},
    );
    $Self->True(
        $Message || '',
        "Key:$Count - KeyAdd()",
    );

    @Keys = $PGPObject->KeySearch(
        Search => $Search{$Count},
    );

    $Self->True(
        $Keys[0] || '',
        "Key:$Count - KeySearch()",
    );
    for my $ID (qw(Type Identifier Bit Key KeyPrivate Created Expires Fingerprint FingerprintShort))
    {
        $Self->Is(
            $Keys[0]->{$ID} || '',
            $Check{$Count}->{$ID},
            "Key:$Count - KeySearch() - $ID",
        );
    }

    my $PublicKeyString = $PGPObject->PublicKeyGet(
        Key => $Keys[0]->{Key},
    );
    $Self->True(
        $PublicKeyString || '',
        "Key:$Count - PublicKeyGet()",
    );

    my $PrivateKeyString = $PGPObject->SecretKeyGet(
        Key => $Keys[0]->{KeyPrivate},
    );
    $Self->True(
        $PrivateKeyString || '',
        "Key:$Count - SecretKeyGet()",
    );
}

# tests for handling signed / encrypted emails
my @Tests = (
    {
        Name           => 'Encrypted Body, Plain Attachments',
        EmailFile      => '/scripts/test/sample/PGP/PGP_Test_2013-07-02-1977-1.eml',
        ArticleSubject => 'PGP Test 2013-07-02-1977-1',
        ArticleBody    => "This is only a test.\n",
    },
    {
        Name           => 'Encrypted Body and Attachments as whole',
        EmailFile      => '/scripts/test/sample/PGP/PGP_Test_2013-07-02-1977-2.eml',
        ArticleSubject => 'PGP Test 2013-07-02-1977-2',
        ArticleBody    => "This is only a test.\n",
    },
    {
        Name           => 'Encrypted Body and Attachments independently',
        EmailFile      => '/scripts/test/sample/PGP/PGP_Test_2013-07-02-1977-3.eml',
        ArticleSubject => 'PGP Test 2013-07-02-1977-3',
        ArticleBody    => "This is only a test.\n",
    },
    {
        Name               => 'Signed 7bit (Short lines)',
        EmailFile          => '/scripts/test/sample/PGP/Signed_PGP_Test_7bit.eml',
        CheckSignatureOnly => 1,
    },
    {
        Name               => 'Signed Quoted-Printable (Long Lines)',
        EmailFile          => '/scripts/test/sample/PGP/Signed_PGP_Test_QuotedPrintable.eml',
        CheckSignatureOnly => 1,
    },
);

# to store added tickets into the system (will be deleted later)
my @AddedTickets;

# lookup table to get a better idea of postmaster result
my %PostMasterReturnLookup = (
    0 => 'error (also false)',
    1 => 'new ticket created',
    2 => 'follow up / open/reopen',
    3 => 'follow up / close -> new ticket',
    4 => 'follow up / close -> reject',
    5 => 'ignored (because of X-OTRS-Ignore header)',
);

TEST:
for my $Test (@Tests) {

    # read email content (from a file)
    my $Email = $MainObject->FileRead(
        Location => $ConfigObject->Get('Home') . $Test->{EmailFile},
        Result   => 'ARRAY',
    );

    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport => 'Email',
            Direction => 'Incoming',
        },
    );
    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

    # use post master to import mail into OTRS
    my $PostMasterObject = Kernel::System::PostMaster->new(
        CommunicationLogObject => $CommunicationLogObject,
        Email                  => $Email,
        Trusted                => 1,
    );
    my @PostMasterResult = $PostMasterObject->Run( Queue => '' );

    $CommunicationLogObject->ObjectLogStop(
        ObjectLogType => 'Message',
        Status        => 'Successful',
    );
    $CommunicationLogObject->CommunicationStop(
        Status => 'Successful',
    );

    # sanity check (if postmaster runs correctly)
    $Self->IsNot(
        $PostMasterResult[0],
        0,
        "$Test->{Name} - PostMaster result should not be 0"
            . " ($PostMasterReturnLookup{ $PostMasterResult[0] })",
    );

    # check if we get a new TicketID
    $Self->IsNot(
        $PostMasterResult[1],
        undef,
        "$Test->{Name} - PostMaster TicketID should not be undef",
    );

    # set the TicketID as the result form PostMaster
    my $TicketID = $PostMasterResult[1] || 0;

    if ( $PostMasterResult[1] > 0 ) {
        push @AddedTickets, $TicketID;

        # get ticket articles
        my @Articles = $ArticleObject->ArticleList(
            TicketID  => $TicketID,
            OnlyFirst => 1,
        );

        # use the first result (it should be only 1)
        my %RawArticle;
        if ( scalar @Articles ) {
            %RawArticle = %{ $Articles[0] };
        }

        # use ArticleCheck::PGP to decrypt the article
        my $CheckObject = Kernel::Output::HTML::ArticleCheck::PGP->new(
            ArticleID => $Articles[0]->{ArticleID},
            UserID    => $TestUserID,
        );

        my %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $RawArticle{TicketID},
            ArticleID => $RawArticle{ArticleID},
        );

        my @CheckResult = $CheckObject->Check( Article => \%Article );

        # sanity destroy object
        $CheckObject = undef;

        if ( $Test->{CheckSignatureOnly} ) {

            RESULTITEM:
            for my $ResultItem (@CheckResult) {

                next RESULTITEM if $ResultItem->{Key} ne 'Signed';

                $Self->True(
                    $ResultItem->{SignatureFound},
                    "$Test->{Name} - Signature found with true",
                );

                $Self->True(
                    $ResultItem->{Successful},
                    "$Test->{Name} - Signature verify with true",
                );

                last RESULTITEM;
            }

            next TEST;
        }

        # check actual contents (subject and body)
        %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $RawArticle{TicketID},
            ArticleID => $RawArticle{ArticleID},
        );

        $Self->Is(
            $Article{Subject},
            $Test->{ArticleSubject},
            "$Test->{Name} - Decrypted article subject",
        );

        $Self->Is(
            $Article{Body},
            $Test->{ArticleBody},
            "$Test->{Name} - Decrypted article body",
        );

        # get the list of attachments
        my %AtmIndex = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID        => $Articles[0]->{ArticleID},
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );

        FILEID:
        for my $FileID ( sort keys %AtmIndex ) {

            # skip non important attachments
            next FILEID if $AtmIndex{$FileID}->{Filename} =~ m{\A file-\d+ \z}msx;

            # get the attachment from the article (it should be already decrypted)
            my %Attachment = $ArticleBackendObject->ArticleAttachment(
                ArticleID => $Articles[0]->{ArticleID},
                FileID    => $FileID,
            );

            # read the original file (from file system)
            my $FileStringRef = $MainObject->FileRead(
                Location => $ConfigObject->Get('Home')
                    . '/scripts/test/sample/Crypt/'
                    . $AtmIndex{$FileID}->{Filename},
            );

            # check actual contents (attachment)
            $Self->Is(
                $Attachment{Content},
                ${$FileStringRef},
                "$Test->{Name} - Decrypted attachment $AtmIndex{$FileID}->{Filename}",
            );
        }
    }
}

# different mails to test
@Tests = (
    {
        Name        => 'simple string',
        ArticleData => {
            Body     => 'Simple string',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with unix newline',
        ArticleData => {
            Body     => 'Simple string \n with unix newline',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with windows newline',
        ArticleData => {
            Body     => 'Simple string \r\n with windows newline',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with long word',
        ArticleData => {
            Body =>
                'SimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleString',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with long lines',
        ArticleData => {
            Body =>
                'Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with unicode data',
        ArticleData => {
            Body     => 'äöüßø@«∑€©ƒ',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'Multiline HTML',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Simple Line<br/><br/><br/>Your Ticket-Team<br/><br/>Your Agent<br/><br/>--<br/> Super Support - Waterford Business Park<br/> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br/> Email: hot@example.com - Web: <a href="http://www.example.com/" title="http://www.example.com/" target="_blank">http://www.example.com/</a><br/>--</body></html>',
            MimeType => 'text/html',
        },
    },
    {
        Name        => 'Reply to a previously signed message',
        ArticleData => {
            Body => '
Reply text
> -----BEGIN PGP SIGNED MESSAGE-----
> Hash: SHA1
>
> Original signed text
>
> -----BEGIN PGP SIGNATURE-----
> Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
> Comment: GPGTools - http://gpgtools.org
>
> iEYEARECAAYFAlJzpy4ACgkQjDflB7tFqcf4pgCbBf/f5dTEVDagR7Sq2mJq+lL+
> rpAAn3qKwT7j8PMYfSnBwGs0tM1ekbpd
> =eLoO
> -----END PGP SIGNATURE-----
>
>',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'Inline Attachment',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Hi<img alt="" src="cid:inline835421.188799263.1394842906.6253839.53368344@Mandalore.local" style="height:16px; width:16px" /></body></html>',
            MimeType   => 'text/html',
            Attachment => [
                {
                    ContentID =>
                        'inline835421.188799263.1394842906.6253839.53368344@Mandalore.local',
                    Content     => 'Any',
                    ContentType => 'image/png; name="ui-toolbar-bookmark.png"',
                    Filename    => 'ui-toolbar-bookmark.png',
                    Disposition => 'inline',
                },
            ],
        },
    },
    {
        Name        => 'Normal Attachment',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Simple Line<br/><br/><br/>Your Ticket-Team<br/><br/>Your Agent<br/><br/>--<br/> Super Support - Waterford Business Park<br/> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br/> Email: hot@example.com - Web: <a href="http://www.example.com/" title="http://www.example.com/" target="_blank">http://www.example.com/</a><br/>--</body></html>',
            MimeType   => 'text/html',
            Attachment => [
                {
                    ContentID   => '',
                    Content     => 'Any',
                    ContentType => 'image/png; name="ui-toolbar-bookmark.png"',
                    Filename    => 'ui-toolbar-bookmark.png',
                    Disposition => 'attachment',
                },
            ],
        },
    },
);

# test each mail with sign/crypt/sign+crypt
my @TestVariations;

for my $Test (@Tests) {
    push @TestVariations, {
        Name        => $Test->{Name} . " (old API) sign only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'unittest@example.org',
            To   => 'unittest@example.org',
            Sign => {
                Type    => 'PGP',
                SubType => 'Detached',
                Key     => $Check{1}->{KeyPrivate},
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " (old API) crypt only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From  => 'unittest2@example.org',
            To    => 'unittest2@example.org',
            Crypt => {
                Type    => 'PGP',
                SubType => 'Detached',
                Key     => $Check{2}->{Key},
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " (old API) sign and crypt (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'unittest2@example.org',
            To   => 'unittest2@example.org',
            Sign => {
                Type    => 'PGP',
                SubType => 'Detached',
                Key     => $Check{2}->{KeyPrivate},
            },
            Crypt => {
                Type    => 'PGP',
                SubType => 'Detached',
                Key     => $Check{2}->{Key},
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

    # TODO: currently inline signatures tests does not work as OTRS does not save the signature
    #    in the Article{Body}, the body remains intact after sending the email, only the email has
    #    the signature

    # here starts the tests for new API

    push @TestVariations, {
        Name        => $Test->{Name} . " sign only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org',
            EmailSecurity => {
                Backend => 'PGP',
                Method  => 'Detached',
                SignKey => $Check{1}->{KeyPrivate},
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " crypt only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest2@example.org',
            To            => 'unittest2@example.org',
            EmailSecurity => {
                Backend     => 'PGP',
                Method      => 'Detached',
                EncryptKeys => [ $Check{2}->{Key} ],
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " sign and crypt (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest2@example.org',
            To            => 'unittest2@example.org',
            EmailSecurity => {
                Backend     => 'PGP',
                Method      => 'Detached',
                SignKey     => $Check{2}->{KeyPrivate},
                EncryptKeys => [ $Check{2}->{Key} ],
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

    # start tests with 2 recipients

    push @TestVariations, {
        Name        => $Test->{Name} . " sign only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org, unittest2@example.org',
            EmailSecurity => {
                Backend => 'PGP',
                Method  => 'Detached',
                SignKey => $Check{1}->{KeyPrivate},
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " crypt only (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest2@example.org',
            To            => 'unittest@example.org, unittest2@example.org',
            EmailSecurity => {
                Backend     => 'PGP',
                Method      => 'Detached',
                EncryptKeys => [ $Check{1}->{Key}, $Check{2}->{Key} ],
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        Name        => $Test->{Name} . " sign and crypt (Detached)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest2@example.org',
            To            => 'unittest@example.org, unittest2@example.org',
            EmailSecurity => {
                Backend     => 'PGP',
                Method      => 'Detached',
                SignKey     => $Check{2}->{KeyPrivate},
                EncryptKeys => [ $Check{1}->{Key}, $Check{2}->{Key} ],
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

}

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Some Ticket_Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'closed successful',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => $TestUserID,
);

$Self->True(
    $TicketID,
    'TicketCreate()',
);

my $TicketNumber = $TicketObject->TicketNumberLookup(
    TicketID => $TicketID,
);

push @AddedTickets, $TicketID;

for my $Test (@TestVariations) {

    my $ArticleID = $ArticleBackendObject->ArticleSend(
        %{ $Test->{ArticleData} },
        TicketID             => $TicketID,
        SenderType           => 'customer',
        IsVisibleForCustomer => 1,
        HistoryType          => 'AddNote',
        HistoryComment       => 'note',
        Subject              => 'Unittest data',
        Charset              => 'utf-8',
        UserID               => 1,
    );

    $Self->True(
        $ArticleID,
        "$Test->{Name} - ArticleSend()",
    );

    # Read generated email and use it to create yet another article.
    # This is necessary because otherwise reading the existing article will result in using the internal body
    #   which doesn't contain signatures etc.
    my $Email = $ArticleBackendObject->ArticlePlain(
        ArticleID => $ArticleID,
        UserID    => $TestUserID,
    );

    # Add ticket number to subject (to ensure mail will be attached to original ticket)
    my @FollowUp;
    for my $Line ( split "\n", $Email ) {
        if ( $Line =~ /^Subject:/ ) {
            $Line = 'Subject: ' . $TicketObject->TicketSubjectBuild(
                TicketNumber => $TicketNumber,
                Subject      => $Line,
            );
        }
        push @FollowUp, $Line;
    }
    my $NewEmail = join "\n", @FollowUp;

    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport => 'Email',
            Direction => 'Incoming',
        },
    );
    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

    my $PostMasterObject = Kernel::System::PostMaster->new(
        Email                  => \$NewEmail,
        CommunicationLogObject => $CommunicationLogObject,
    );

    my @Return = $PostMasterObject->Run();
    $Self->IsDeeply(
        \@Return,
        [ 2, $TicketID ],
        "$Test->{Name} - PostMaster()",
    );

    my @Articles = $ArticleObject->ArticleList(
        TicketID => $TicketID,
        OnlyLast => 1,
    );
    my %Article = $ArticleBackendObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $Articles[0]->{ArticleID},
    );

    my $CheckObject = Kernel::Output::HTML::ArticleCheck::PGP->new(
        ArticleID => $Article{ArticleID},
        UserID    => $TestUserID,
    );

    my @CheckResult = $CheckObject->Check( Article => \%Article );

    # Run check a second time to simulate repeated views.
    my @FirstCheckResult = @CheckResult;
    @CheckResult = $CheckObject->Check( Article => \%Article );

    $Self->IsDeeply(
        \@FirstCheckResult,
        \@CheckResult,
        "$Test->{Name} - CheckObject() stable",
    );

    if ( $Test->{VerifySignature} ) {
        my $SignatureVerified =
            grep {
            $_->{Successful} && $_->{Key} eq 'Signed' && $_->{SignatureFound} && $_->{Message}
            } @CheckResult;

        $Self->True(
            $SignatureVerified,
            "$Test->{Name} - signature verified",
        );
    }

    if ( $Test->{VerifyDecryption} ) {
        my $DecryptionVerified =
            grep { $_->{Successful} && $_->{Key} eq 'Crypted' && $_->{Message} } @CheckResult;

        $Self->True(
            $DecryptionVerified,
            "$Test->{Name} - decryption verified",
        );
    }

    my %FinalArticleData = $ArticleBackendObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $Article{ArticleID},
    );

    my $TestBody = $Test->{ArticleData}->{Body};

    # convert test body to ASCII if it was HTML
    if ( $Test->{ArticleData}->{MimeType} eq 'text/html' ) {
        $TestBody = $HTMLUtilsObject->ToAscii(
            String => $TestBody,
        );
    }

    $Self->Is(
        $FinalArticleData{Body},
        $TestBody,
        "$Test->{Name} - verified body content",
    );

    if ( defined $Test->{ArticleData}->{Attachment} ) {
        my $Found;
        my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID => $Article{ArticleID},
        );

        TESTATTACHMENT:
        for my $Attachment ( @{ $Test->{ArticleData}->{Attachment} } ) {

            next TESTATTACHMENT if !$Attachment->{Filename};

            ATTACHMENTINDEX:
            for my $AttachmentIndex ( sort keys %Index ) {

                if ( $Index{$AttachmentIndex}->{Filename} ne $Attachment->{Filename} ) {
                    next ATTACHMENTINDEX;
                }

                # when the attachment originally does not include a ContentID at create time is not
                #   changed to '<>', it is still empty, also if the mail is just signed but not
                #   encrypted, the attachment is not rewritten so it keeps without the surrounding
                #   '<>'
                my $ExpectedContentID = $Attachment->{ContentID};
                if ( $Attachment->{ContentID} ) {
                    $ExpectedContentID = '<' . $Attachment->{ContentID} . '>';
                }
                $Self->Is(
                    $Index{$AttachmentIndex}->{ContentID},
                    $ExpectedContentID,
                    "$Test->{Name} - Attachment '$Attachment->{Filename}' ContentID",
                );
                $Found = 1;
                last ATTACHMENTINDEX;
            }
            $Self->True(
                $Found,
                "$Test->{Name} - Attachment '$Attachment->{Filename}' was found"
            );
        }

        # Remove all attachments, then run CheckObject again to verify they are not written again.
        $ArticleBackendObject->ArticleDeleteAttachment(
            ArticleID => $Article{ArticleID},
            UserID    => 1,
        );

        $CheckObject->Check( Article => \%Article );

        %Index = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID => $Article{ArticleID},
        );
        $Self->False(
            scalar keys %Index,
            "$Test->{Name} - Attachments not rewritten by ArticleCheck module"
        );
    }
}

# delete PGP keys
for my $Count ( 1 .. 2 ) {
    my @Keys = $PGPObject->KeySearch(
        Search => $Search{$Count},
    );
    $Self->True(
        $Keys[0] || '',
        "Key:$Count - KeySearch()",
    );
    my $DeleteSecretKey = $PGPObject->SecretKeyDelete(
        Key => $Keys[0]->{KeyPrivate},
    );
    $Self->True(
        $DeleteSecretKey || '',
        "Key:$Count - SecretKeyDelete()",
    );

    my $DeletePublicKey = $PGPObject->PublicKeyDelete(
        Key => $Keys[0]->{Key},
    );
    $Self->True(
        $DeletePublicKey || '',
        "Key:$Count - PublicKeyDelete()",
    );

    @Keys = $PGPObject->KeySearch(
        Search => $Search{$Count},
    );
    $Self->False(
        $Keys[0] || '',
        "Key:$Count - KeySearch()",
    );
}

# cleanup is done by RestoreDatabase.

1;
