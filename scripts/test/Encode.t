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
