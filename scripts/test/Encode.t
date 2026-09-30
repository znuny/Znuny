# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic(RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

# get encode object
my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

# convert tests
{
    use utf8;
    my @Tests = (
        {
            Name          => 'Convert()',
            Input         => 'abc123',
            Result        => 'abc123',
            InputCharset  => 'ascii',
            ResultCharset => 'utf8',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123',
            Result        => 'abc123',
            InputCharset  => 'us-ascii',
            ResultCharset => 'utf8',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123���',
            Result        => 'abc123���',
            InputCharset  => 'utf8',
            ResultCharset => 'utf8',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123���',
            Result        => 'abc123���',
            InputCharset  => 'iso-8859-15',
            ResultCharset => 'utf8',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123���',
            Result        => 'abc123���',
            InputCharset  => 'utf8',
            ResultCharset => 'utf-8',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123���',
            Result        => 'abc123���',
            InputCharset  => 'utf8',
            ResultCharset => 'iso-8859-15',
            UTF8          => 1,
        },
        {
            Name          => 'Convert()',
            Input         => 'abc123���',
            Result        => 'abc123???',
            InputCharset  => 'utf8',
            ResultCharset => 'iso-8859-1',
            Force         => 1,
            UTF8          => '',
        },
    );
    for my $Test (@Tests) {
        my $Result = $EncodeObject->Convert(
            Text  => $Test->{Input},
            From  => $Test->{InputCharset},
            To    => $Test->{ResultCharset},
            Force => $Test->{Force},
        );
        my $IsUTF8 = Encode::is_utf8($Result);
        $Self->True(
            $IsUTF8 eq $Test->{UTF8},
            $Test->{Name} . " is_utf8",
        );
        $Self->True(
            $Result eq $Test->{Result},
            $Test->{Name},
        );
    }
}

# EncodeInput tests
{
    use utf8;
    use Try::Tiny;

    my @Tests = (
        {
            Name   => 'Promotes UTF-8 bytes',
            Input  => do { no utf8;  "f\x{c3}\x{bc}nftgr\x{c3}\x{b6}\x{c3}\x{9f}te" },
            Result => do { use utf8; "fünftgrößte" },
            UTF8   => 1,
        },
        {
            Name  => 'Promotes UTF-8 bytes for non-latin charsets',
            Input => do {
                no utf8;
                "\x{e0}\x{ba}\x{aa}\x{e0}\x{ba}\x{b0}\x{e0}\x{ba}\x{9a}\x{e0}\x{ba}\x{b2}\x{e0}\x{ba}\x{8d}\x{e0}\x{ba}\x{94}\x{e0}\x{ba}\x{b5}";
            },
            Result => do { use utf8; "ສະບາຍດີ" },
            UTF8   => 1,
        },
        {
            Name   => 'Breaks with 8-bit charsets',
            Input  => do { no utf8; "f\x{fc}nftgr\x{f6}\x{df}te" },
            Result => qr{ ^ Exception:\ Malformed\ UTF-8 }x,
        },
        {
            Name   => 'Safe mode behaves the same with proper UTF-8 bytes',
            Input  => do { no utf8;  "f\x{c3}\x{bc}nftgr\x{c3}\x{b6}\x{c3}\x{9f}te" },
            Result => do { use utf8; "fünftgrößte" },
            UTF8   => 1,
            Safe   => 1,
        },
        {
            Name   => 'Safe mode replaces malformed UTF-8',
            Input  => do { no utf8; "f\x{fc}nftgr\x{f6}\x{df}te" },
            Result => 'f\x{fc}nftgr\x{f6}\x{df}te',
            Safe   => 1,
        },
        {
            Name   => 'Safe mode with Latin-1 fallback decodes correctly',
            Input  => do { no utf8;  "f\x{fc}nftgr\x{f6}\x{df}te" },
            Result => do { use utf8; "fünftgrößte" },
            Safe   => 'iso-8859-1',
            UTF8   => 1,
        },
        {
            Name   => 'Safe mode with custom callback works',
            Input  => do { no utf8;  "f\x{fc}nftgr\x{f6}\x{df}te" },
            Result => do { use utf8; 'f\374nftgr\366\337te' },
            Safe   => sub { sprintf( '\\%o', shift ) },
        },
    );
    for my $Test (@Tests) {
        my $Result = $Test->{Input};
        $Result = try {
            use warnings FATAL => 'utf8';
            $EncodeObject->EncodeInput( \$Result, $Test->{Safe} );
            $Result =~ /\w+/;
            $Result;
        }
        catch {
            "Exception: $_";
        };
        if ( ref $Test->{Result} eq 'Regexp' ) {
            $Self->True( scalar( $Result =~ $Test->{Result} ), $Test->{Name} );
        }
        else {
            $Self->Is( $Result, $Test->{Result}, $Test->{Name} );
        }
        if ( exists $Test->{UTF8} ) {
            my $IsUTF8 = Encode::is_utf8($Result);
            $Self->True(
                $IsUTF8 eq $Test->{UTF8},
                $Test->{Name} . ": is_utf8 matches",
            );
        }
    }
}

$Self->True(
    $EncodeObject->EncodingIsAsciiSuperset( Encoding => 'UTF-8' ),
    'UTF-8 is a superset of ASCII',
);
$Self->False(
    $EncodeObject->EncodingIsAsciiSuperset( Encoding => 'UTF-16-LE' ),
    'UTF-16 is a not superset of ASCII',
);

$Self->Is(
    $EncodeObject->FindAsciiSupersetEncoding(
        Encodings => [ 'UTF-7', 'UTF-16-LE', 'ISO-8859-1' ],
    ),
    'ISO-8859-1',
    'FindAsciiSupersetEncoding',
);

$Self->Is(
    $EncodeObject->FindAsciiSupersetEncoding(
        Encodings => ['UTF-7'],
    ),
    'ASCII',
    'FindAsciiSupersetEncoding falls back to ASCII',
);

#
# Tests for RemoveUTF8BOM
#
my $String = 'This is a UTF-8 string öäüÖÄÜ€.';

my $ProcessedString = $EncodeObject->RemoveUTF8BOM(
    String => $String,
);

$Self->Is(
    $ProcessedString,
    $String,
    'RemoveUTF8BOM() must not change string that has no UTF-8 BOM.',
);

$ProcessedString = $EncodeObject->RemoveUTF8BOM(
    String => "\xef\xbb\xbf$String",
);

$Self->Is(
    $ProcessedString,
    $String,
    'RemoveUTF8BOM() must remove UTF-8 BOM from string.',
);

1;
