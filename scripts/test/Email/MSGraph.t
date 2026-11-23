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

my $MSGraphObject = $Kernel::OM->Get('Kernel::System::Email::MSGraph');

my $FoldedToHeader = <<'END';
From: sender@example.com
To: "Alice Example" <alice@example.com>, "Bob Example"
 <bob@example.com>, carol@example.com
Subject: test
END

my $FoldedToWithBccHeader = <<'END';
From: sender@example.com
To: "Alice Example" <alice@example.com>, "Bob Example"
 <bob@example.com>, carol@example.com
Bcc: hidden@example.com
Subject: test
END

my $SingleLineToHeader = <<'END';
From: sender@example.com
To: a@example.com, b@example.com
Subject: test
END

my $SingleLineToWithBccHeader = <<'END';
From: sender@example.com
To: a@example.com, b@example.com
Bcc: hidden@example.com
Subject: test
END

my $FoldedCcHeader = <<'END';
From: sender@example.com
To: a@example.com
Cc: "Carol Example" <carol@example.com>,
 dave@example.com
Subject: test
END

my $FoldedCcWithoutToHeader = <<'END';
From: sender@example.com
Cc: "Carol Example" <carol@example.com>,
 dave@example.com
Subject: test
END

my $FoldedCcWithoutToWithBccHeader = <<'END';
From: sender@example.com
Cc: "Carol Example" <carol@example.com>,
 dave@example.com
Subject: test
Bcc: hidden@example.com
END

my $PlusAddressHeader = <<'END';
From: sender@example.com
To: user+tag@example.com
Subject: test
END

my $MixedCaseHeader = <<'END';
From: sender@example.com
To: Alice@Example.com
Subject: test
END

my @Tests = (
    {
        Name     => 'Folded To, all recipients visible',
        Header   => $FoldedToHeader,
        ToArray  => [ 'alice@example.com', 'bob@example.com', 'carol@example.com' ],
        Expected => $FoldedToHeader,
    },
    {
        Name     => 'Folded To, real Bcc inserted after the whole field',
        Header   => $FoldedToHeader,
        ToArray  => [ 'alice@example.com', 'bob@example.com', 'carol@example.com', 'hidden@example.com' ],
        Expected => $FoldedToWithBccHeader,
    },
    {
        Name     => 'Single-line To, all recipients visible',
        Header   => $SingleLineToHeader,
        ToArray  => [ 'a@example.com', 'b@example.com' ],
        Expected => $SingleLineToHeader,
    },
    {
        Name     => 'Single-line To, real Bcc inserted after To',
        Header   => $SingleLineToHeader,
        ToArray  => [ 'a@example.com', 'b@example.com', 'hidden@example.com' ],
        Expected => $SingleLineToWithBccHeader,
    },
    {
        Name     => 'Folded Cc, all recipients visible',
        Header   => $FoldedCcHeader,
        ToArray  => [ 'a@example.com', 'carol@example.com', 'dave@example.com' ],
        Expected => $FoldedCcHeader,
    },
    {
        Name     => 'No To header, folded Cc, real Bcc appended',
        Header   => $FoldedCcWithoutToHeader,
        ToArray  => [ 'carol@example.com', 'dave@example.com', 'hidden@example.com' ],
        Expected => $FoldedCcWithoutToWithBccHeader,
    },
    {
        Name     => 'Plus address stays on To',
        Header   => $PlusAddressHeader,
        ToArray  => ['user+tag@example.com'],
        Expected => $PlusAddressHeader,
    },
    {
        Name     => 'Address comparison is case-insensitive',
        Header   => $MixedCaseHeader,
        ToArray  => ['alice@example.com'],
        Expected => $MixedCaseHeader,
    },
);

TEST:
for my $Test (@Tests) {
    my $Header = $MSGraphObject->_AddBccHeader(
        Header  => $Test->{Header},
        ToArray => $Test->{ToArray},
    );

    $Self->Is(
        $Header,
        $Test->{Expected},
        $Test->{Name},
    );
}

1;
