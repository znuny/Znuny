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

my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

my @Tests = (
    {
        Name   => 'Empty document',
        String => '123',
        Result => '123',
    },
    {
        Name => 'Image with ContentID, no session',
        String =>
            '123 <img src="index.pl?Action=SomeAction;FileID=0;ContentID=inline105816.238987884.1382708457.5104380.88084622@localhost" /> 234',
        Result => '123 <img src="cid:inline105816.238987884.1382708457.5104380.88084622@localhost" /> 234',
    },
    {
        Name => 'Image with ContentID, with session',
        String =>
            '123 <img src="index.pl?Action=SomeAction;FileID=0;ContentID=inline105816.238987884.1382708457.5104380.88084622@localhost;SessionID=123" /> 234',
        Result => '123 <img src="cid:inline105816.238987884.1382708457.5104380.88084622@localhost" /> 234',
    },
    {
        Name => 'Image with ContentID, with session',
        String =>
            '123 <img src="index.pl?Action=SomeAction;FileID=0;ContentID=inline105816.238987884.1382708457.5104380.88084622@localhost&SessionID=123" /> 234',
        Result => '123 <img src="cid:inline105816.238987884.1382708457.5104380.88084622@localhost" /> 234',
    },
);

for my $Test (@Tests) {
    my $Result = $LayoutObject->RichTextDocumentComplete(
        String => $Test->{String},
    );

    # Quote the expected text to avoid problems with special characters.
    $Test->{Result} = quotemeta( $Test->{Result} );

    # Check if the result contains the expected HTML structure between <body> tags.
    my $Contains = $Result =~ m{$Test->{Result}};

    $Self->True(
        $Contains,
        "$Test->{Name}",
    );
}

1;
