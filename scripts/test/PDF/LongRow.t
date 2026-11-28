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

use Time::HiRes qw(time);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $PDFObject    = $Kernel::OM->Get('Kernel::System::PDF');

# An article body with one very long row, e.g. an inline image that an email
# client wrote into the text/plain part as a base64 data URI.
my @Base64Chars = ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9, '+', '/' );
my $Blob        = join '', map { $Base64Chars[ $_ % @Base64Chars ] } 1 .. 50_000;
my $Text        = "Dear Sir or Madam,\n\nplease see the attachment.\n\n-- \n![](data:image/jpeg;base64,$Blob)\n";

$PDFObject->DocumentNew(
    Title  => 'LongRow',
    Encode => 'utf-8',
);
my %Page = (
    Width        => 595,
    Height       => 842,
    MarginTop    => 30,
    MarginRight  => 40,
    MarginBottom => 40,
    MarginLeft   => 40,
);
$PDFObject->PageNew(%Page);

# Same table parameters as the article body in Kernel::Output::PDF::Ticket.
my %Table = (
    CellData        => [ [ { Content => $Text } ] ],
    Type            => 'Cut',
    Border          => 0,
    Font            => 'Monospaced',
    FontSize        => 7,
    BackgroundColor => '#f2f2f2',
    Padding         => 4,
    PaddingTop      => 4,
    PaddingBottom   => 4,
);

my $Start = time;
PAGE:
for ( 1 .. 100 ) {
    %Table = $PDFObject->Table(%Table);
    last PAGE if $Table{State};
    $PDFObject->PageNew(%Page);
}
my $Seconds = time - $Start;

$Self->True(
    $Table{State},
    'Table() rendered the whole long row',
);
$Self->True(
    $Seconds < 10,
    sprintf( 'Table() with a %d character row took %.1f seconds (limit 10)', length $Blob, $Seconds ),
);

# No characters may get lost when a long row is wrapped.
my %Calculate = $PDFObject->_TextCalculate(
    Text     => $Blob,
    Type     => 'ReturnLeftOverHard',
    Width    => 300,
    Height   => 1_000_000,
    Font     => 'Monospaced',
    FontSize => 7,
    Lead     => 0,
);
$Self->Is(
    join( '', @{ $Calculate{PossibleRows} } ),
    $Blob,
    '_TextCalculate() wraps a long row without losing characters',
);

1;
