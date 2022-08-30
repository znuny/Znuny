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

# get needed objects
my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
my $PDFObject  = $Kernel::OM->Get('Kernel::System::PDF');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# create a pdf document
my $DocumentNew1 = $PDFObject->DocumentNew(
    Title     => 'The Title',
    Encode    => 'latin1',
    Testfonts => 1,
);

$Self->True(
    $DocumentNew1,
    "DocumentNew1()",
);

# create a blank page
my $PageBlankNew1 = $PDFObject->PageBlankNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 50,
    MarginRight  => 50,
    MarginBottom => 50,
    MarginLeft   => 50,
);

$Self->True(
    $PageBlankNew1,
    "PageBlankNew1()",
);

my $PageNew1 = $PDFObject->PageNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 50,
    MarginRight  => 50,
    MarginBottom => 50,
    MarginLeft   => 50,
    HeaderRight  => 'Header Right Text',
    FooterLeft   => 'Footer Left Text',
    FooterRight  => 'Footer Right Text',
);

$Self->True(
    $PageNew1,
    "PageNew1()",
);

# test _StringWidth() - test width calculation
my $StringWidthText   = 'abcikwAXIJWZ 123 öäüß !$-';
my @StringWidthReturn = (
    123.38, 117.82, 115.04, 112.26, 106.15, 100.59, 95.03, 89.47, 86.69, 81.13,
    75.57, 70.01, 67.23, 61.12, 51.68, 46.68, 43.9, 37.23, 30.56, 23.34, 18.34,
    16.12, 11.12, 5.56, 0
);

my $C1 = 0;
while ( chop($StringWidthText) ) {
    my $TestOk = 0;
    my $Width  = $PDFObject->_StringWidth(
        Text     => $StringWidthText,
        Font     => 'Testfont1',
        FontSize => 10,
    );

    if ( $Width eq $StringWidthReturn[$C1] ) {
        $TestOk = 1;
    }
    else {
        print "ERROR Width $C1 --> $Width\n";
    }

    $Self->True(
        $TestOk,
        "_StringWidth$C1()",
    );
    $C1++;
}

# test _TextCalculate()
my %TextCalculateData;

# test0 - test new line calculation with spaces
$TextCalculateData{0}{Text}
    = 'US    Space   Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{0}{Type}            = 'ReturnLeftOverHard';
$TextCalculateData{0}{State}           = 1;
$TextCalculateData{0}{RequiredWidth}   = 96.71;
$TextCalculateData{0}{RequiredHeight}  = 50;
$TextCalculateData{0}{LeftOver}        = '';
$TextCalculateData{0}{PossibleRows}{0} = 'US    Space   Shuttle';
$TextCalculateData{0}{PossibleRows}{1} = 'Atlantis and her STS-';
$TextCalculateData{0}{PossibleRows}{2} = '115 crew safely lande';
$TextCalculateData{0}{PossibleRows}{3} = 'd today at Kennedy S';
$TextCalculateData{0}{PossibleRows}{4} = 'pace Center.';

# test1 - test new line calculation with spaces
$TextCalculateData{1}{Text}
    = ' US   Space   Shuttle  Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{1}{Type}            = 'ReturnLeftOverHard';
$TextCalculateData{1}{State}           = 1;
$TextCalculateData{1}{RequiredWidth}   = 96.71;
$TextCalculateData{1}{RequiredHeight}  = 50;
$TextCalculateData{1}{LeftOver}        = '';
$TextCalculateData{1}{PossibleRows}{0} = 'US   Space   Shuttle ';
$TextCalculateData{1}{PossibleRows}{1} = 'Atlantis and her STS-';
$TextCalculateData{1}{PossibleRows}{2} = '115 crew safely lande';
$TextCalculateData{1}{PossibleRows}{3} = 'd today at Kennedy S';
$TextCalculateData{1}{PossibleRows}{4} = 'pace Center.';

# test2 - test LeftOver function
$TextCalculateData{2}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{2}{Type}            = 'ReturnLeftOverHard';
$TextCalculateData{2}{Width}           = 30;
$TextCalculateData{2}{Height}          = 105;
$TextCalculateData{2}{State}           = 0;
$TextCalculateData{2}{RequiredWidth}   = 29.45;
$TextCalculateData{2}{RequiredHeight}  = 100;
$TextCalculateData{2}{LeftOver}        = 'd today at Kennedy Space Center.';
$TextCalculateData{2}{PossibleRows}{0} = 'US Sp';
$TextCalculateData{2}{PossibleRows}{1} = 'ace S';
$TextCalculateData{2}{PossibleRows}{2} = 'huttle';
$TextCalculateData{2}{PossibleRows}{3} = 'Atlanti';
$TextCalculateData{2}{PossibleRows}{4} = 's and';
$TextCalculateData{2}{PossibleRows}{5} = 'her S';
$TextCalculateData{2}{PossibleRows}{6} = 'TS-11';
$TextCalculateData{2}{PossibleRows}{7} = '5 crew';
$TextCalculateData{2}{PossibleRows}{8} = 'safely';
$TextCalculateData{2}{PossibleRows}{9} = 'lande';

# test3 - test Width and Height
$TextCalculateData{3}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{3}{Type}           = 'ReturnLeftOverHard';
$TextCalculateData{3}{Width}          = 1;
$TextCalculateData{3}{Height}         = 1;
$TextCalculateData{3}{State}          = 0;
$TextCalculateData{3}{RequiredWidth}  = 0;
$TextCalculateData{3}{RequiredHeight} = 0;
$TextCalculateData{3}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test4 - test Width and Height
$TextCalculateData{4}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{4}{Type}           = 'ReturnLeftOverHard';
$TextCalculateData{4}{Width}          = 0;
$TextCalculateData{4}{Height}         = 0;
$TextCalculateData{4}{State}          = 0;
$TextCalculateData{4}{RequiredWidth}  = 0;
$TextCalculateData{4}{RequiredHeight} = 0;
$TextCalculateData{4}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test5 - test new line calculation
$TextCalculateData{5}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{5}{Type}            = 'ReturnLeftOver';
$TextCalculateData{5}{State}           = 1;
$TextCalculateData{5}{RequiredWidth}   = 92.25;
$TextCalculateData{5}{RequiredHeight}  = 60;
$TextCalculateData{5}{LeftOver}        = '';
$TextCalculateData{5}{PossibleRows}{0} = 'US Space Shuttle';
$TextCalculateData{5}{PossibleRows}{1} = 'Atlantis and her';
$TextCalculateData{5}{PossibleRows}{2} = 'STS-115 crew safely';
$TextCalculateData{5}{PossibleRows}{3} = 'landed today at';
$TextCalculateData{5}{PossibleRows}{4} = 'Kennedy Space';
$TextCalculateData{5}{PossibleRows}{5} = 'Center.';

# test6 - test new line and LeftOver calculation
$TextCalculateData{6}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{6}{Type}            = 'ReturnLeftOver';
$TextCalculateData{6}{Width}           = 30;
$TextCalculateData{6}{Height}          = 53;
$TextCalculateData{6}{State}           = 0;
$TextCalculateData{6}{RequiredWidth}   = 28.35;
$TextCalculateData{6}{RequiredHeight}  = 50;
$TextCalculateData{6}{LeftOver}        = 's and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{6}{PossibleRows}{0} = 'US';
$TextCalculateData{6}{PossibleRows}{1} = 'Space';
$TextCalculateData{6}{PossibleRows}{2} = 'Shuttl';
$TextCalculateData{6}{PossibleRows}{3} = 'e';
$TextCalculateData{6}{PossibleRows}{4} = 'Atlanti';

# test7 - test Width and Height
$TextCalculateData{7}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{7}{Type}           = 'ReturnLeftOver';
$TextCalculateData{7}{Width}          = 1;
$TextCalculateData{7}{Height}         = 1;
$TextCalculateData{7}{State}          = 0;
$TextCalculateData{7}{RequiredWidth}  = 0;
$TextCalculateData{7}{RequiredHeight} = 0;
$TextCalculateData{7}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test8 - test Width and Height
$TextCalculateData{8}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{8}{Type}           = 'ReturnLeftOver';
$TextCalculateData{8}{Width}          = 0;
$TextCalculateData{8}{Height}         = 0;
$TextCalculateData{8}{State}          = 0;
$TextCalculateData{8}{RequiredWidth}  = 0;
$TextCalculateData{8}{RequiredHeight} = 0;
$TextCalculateData{8}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test9 - test Type Cut
$TextCalculateData{9}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{9}{Type}            = 'Cut';
$TextCalculateData{9}{State}           = 1;
$TextCalculateData{9}{RequiredWidth}   = 92.25;
$TextCalculateData{9}{RequiredHeight}  = 60;
$TextCalculateData{9}{LeftOver}        = '';
$TextCalculateData{9}{PossibleRows}{0} = 'US Space Shuttle';
$TextCalculateData{9}{PossibleRows}{1} = 'Atlantis and her';
$TextCalculateData{9}{PossibleRows}{2} = 'STS-115 crew safely';
$TextCalculateData{9}{PossibleRows}{3} = 'landed today at';
$TextCalculateData{9}{PossibleRows}{4} = 'Kennedy Space';
$TextCalculateData{9}{PossibleRows}{5} = 'Center.';

# test10 - test new line and [..]
$TextCalculateData{10}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{10}{Type}            = 'Cut';
$TextCalculateData{10}{Width}           = 20;
$TextCalculateData{10}{Height}          = 49;
$TextCalculateData{10}{State}           = 1;
$TextCalculateData{10}{RequiredWidth}   = 17.79;
$TextCalculateData{10}{RequiredHeight}  = 40;
$TextCalculateData{10}{LeftOver}        = '';
$TextCalculateData{10}{PossibleRows}{0} = 'US';
$TextCalculateData{10}{PossibleRows}{1} = 'Spa';
$TextCalculateData{10}{PossibleRows}{2} = 'ce';
$TextCalculateData{10}{PossibleRows}{3} = 'S[..]';

# test11 - test Width and Height
$TextCalculateData{11}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{11}{Type}           = 'Cut';
$TextCalculateData{11}{Width}          = 1;
$TextCalculateData{11}{Height}         = 1;
$TextCalculateData{11}{State}          = 0;
$TextCalculateData{11}{RequiredWidth}  = 0;
$TextCalculateData{11}{RequiredHeight} = 0;
$TextCalculateData{11}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test12 - test Width and Height
$TextCalculateData{12}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{12}{Type}           = 'Cut';
$TextCalculateData{12}{Width}          = 0;
$TextCalculateData{12}{Height}         = 0;
$TextCalculateData{12}{State}          = 0;
$TextCalculateData{12}{RequiredWidth}  = 0;
$TextCalculateData{12}{RequiredHeight} = 0;
$TextCalculateData{12}{LeftOver}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';

# test13 - test new line calculation
$TextCalculateData{13}{Text}
    = 'US Space Shuttle Atlantis and her STS-115 crew safely landed today at Kennedy Space Center.';
$TextCalculateData{13}{Type}            = 'Cut';
$TextCalculateData{13}{Width}           = 10;
$TextCalculateData{13}{Height}          = 40;
$TextCalculateData{13}{State}           = 1;
$TextCalculateData{13}{RequiredWidth}   = 7.22;
$TextCalculateData{13}{RequiredHeight}  = 40;
$TextCalculateData{13}{LeftOver}        = '';
$TextCalculateData{13}{PossibleRows}{0} = 'U';
$TextCalculateData{13}{PossibleRows}{1} = 'S';
$TextCalculateData{13}{PossibleRows}{2} = 'S';
$TextCalculateData{13}{PossibleRows}{3} = 'p';

# test14 - test Width
$TextCalculateData{14}{Text}           = 'ISS - International Space Station';
$TextCalculateData{14}{Type}           = 'ReturnLeftOver';
$TextCalculateData{14}{Width}          = 1;
$TextCalculateData{14}{Height}         = 10000;
$TextCalculateData{14}{State}          = 0;
$TextCalculateData{14}{RequiredWidth}  = 0;
$TextCalculateData{14}{RequiredHeight} = 0;
$TextCalculateData{14}{LeftOver}       = 'ISS - International Space Station';

# start testing _TextCalculate()
for ( sort keys %TextCalculateData ) {
    my $Test   = $_;
    my $TestOk = 0;
    if ( !defined( $TextCalculateData{$Test}{Width} ) ) {
        $TextCalculateData{$Test}{Width} = 100;
    }
    if ( !defined( $TextCalculateData{$Test}{Height} ) ) {
        $TextCalculateData{$Test}{Height} = 100;
    }
    $TextCalculateData{$Test}{Font}     = $TextCalculateData{$Test}{Font}     || 'Testfont1';
    $TextCalculateData{$Test}{FontSize} = $TextCalculateData{$Test}{FontSize} || 10;
    $TextCalculateData{$Test}{Lead}     = $TextCalculateData{$Test}{Lead}     || 0;
    $TextCalculateData{$Test}{Type}     = $TextCalculateData{$Test}{Type}     || 'ReturnLeftOver';

    my %Return = $PDFObject->_TextCalculate(
        Text     => $TextCalculateData{$Test}{Text},
        Width    => $TextCalculateData{$Test}{Width},
        Height   => $TextCalculateData{$Test}{Height},
        Font     => $TextCalculateData{$Test}{Font},
        FontSize => $TextCalculateData{$Test}{FontSize},
        Lead     => $TextCalculateData{$Test}{Lead},
        Type     => $TextCalculateData{$Test}{Type},
    );

    my $C1             = 0;
    my $PossibleRowsOK = 1;
    for ( @{ $Return{PossibleRows} } ) {
        if (
            !$TextCalculateData{$Test}{PossibleRows}{$C1}
            || $TextCalculateData{$Test}{PossibleRows}{$C1} ne $_
            )
        {
            $PossibleRowsOK = 0;
            print "ERROR Row $C1 -->" . $_ . "<--\n";
        }
        $C1++;
    }

    if (
        $Return{State} eq $TextCalculateData{$Test}{State}
        &&
        $Return{RequiredWidth} eq $TextCalculateData{$Test}{RequiredWidth}   &&
        $Return{RequiredHeight} eq $TextCalculateData{$Test}{RequiredHeight} &&
        $Return{LeftOver} eq $TextCalculateData{$Test}{LeftOver}             &&
        $PossibleRowsOK
        )
    {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR TextCalculate$Test State -->$Return{State}\n";
        print "ERROR TextCalculate$Test RequiredWidth -->$Return{RequiredWidth}\n";
        print "ERROR TextCalculate$Test RequiredHeight -->$Return{RequiredHeight}\n";
        print "ERROR TextCalculate$Test LeftOver -->$Return{LeftOver}<--\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "_TextCalculate$Test()",
    );
}

# test Text()
my %TextData;

# test0
$TextData{0}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{0}{Type}           = 'ReturnLeftOver';
$TextData{0}{Width}          = 700;
$TextData{0}{State}          = 1;
$TextData{0}{RequiredWidth}  = 516.92;
$TextData{0}{RequiredHeight} = 10;
$TextData{0}{LeftOver}       = '';

# test1
$TextData{1}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{1}{Type}           = 'ReturnLeftOver';
$TextData{1}{Width}          = 300;
$TextData{1}{State}          = 0;
$TextData{1}{RequiredWidth}  = 279.58;
$TextData{1}{RequiredHeight} = 10;
$TextData{1}{LeftOver}       = 'laboratory mission to the International Space Station.';

# test2
$TextData{2}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{2}{Type}           = 'ReturnLeftOver';
$TextData{2}{Width}          = 0;
$TextData{2}{State}          = 0;
$TextData{2}{RequiredWidth}  = 0;
$TextData{2}{RequiredHeight} = 0;
$TextData{2}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# test3
$TextData{3}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{3}{Type}           = 'ReturnLeftOver';
$TextData{3}{Width}          = 1;
$TextData{3}{State}          = 0;
$TextData{3}{RequiredWidth}  = 0;
$TextData{3}{RequiredHeight} = 0;
$TextData{3}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# test4
$TextData{4}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{4}{Type}           = 'ReturnLeftOverHard';
$TextData{4}{Width}          = 700;
$TextData{4}{State}          = 1;
$TextData{4}{RequiredWidth}  = 516.92;
$TextData{4}{RequiredHeight} = 10;
$TextData{4}{LeftOver}       = '';

# test5
$TextData{5}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{5}{Type}           = 'ReturnLeftOverHard';
$TextData{5}{Width}          = 300;
$TextData{5}{State}          = 0;
$TextData{5}{RequiredWidth}  = 295.7;
$TextData{5}{RequiredHeight} = 10;
$TextData{5}{LeftOver}       = 'oratory mission to the International Space Station.';

# test6
$TextData{6}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{6}{Type}           = 'ReturnLeftOverHard';
$TextData{6}{Width}          = 0;
$TextData{6}{State}          = 0;
$TextData{6}{RequiredWidth}  = 0;
$TextData{6}{RequiredHeight} = 0;
$TextData{6}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# test7
$TextData{7}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{7}{Type}           = 'ReturnLeftOverHard';
$TextData{7}{Width}          = 1;
$TextData{7}{State}          = 0;
$TextData{7}{RequiredWidth}  = 0;
$TextData{7}{RequiredHeight} = 0;
$TextData{7}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# test8
$TextData{8}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{8}{Type}           = 'Cut';
$TextData{8}{Width}          = 700;
$TextData{8}{State}          = 1;
$TextData{8}{RequiredWidth}  = 516.92;
$TextData{8}{RequiredHeight} = 10;
$TextData{8}{LeftOver}       = '';

# test9
$TextData{9}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{9}{Type}           = 'Cut';
$TextData{9}{Width}          = 300;
$TextData{9}{State}          = 1;
$TextData{9}{RequiredWidth}  = 290.7;
$TextData{9}{RequiredHeight} = 10;
$TextData{9}{LeftOver}       = '';

# test10
$TextData{10}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{10}{Type}           = 'Cut';
$TextData{10}{Width}          = 0;
$TextData{10}{State}          = 0;
$TextData{10}{RequiredWidth}  = 0;
$TextData{10}{RequiredHeight} = 0;
$TextData{10}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# test11
$TextData{11}{Text}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';
$TextData{11}{Type}           = 'Cut';
$TextData{11}{Width}          = 1;
$TextData{11}{State}          = 0;
$TextData{11}{RequiredWidth}  = 0;
$TextData{11}{RequiredHeight} = 0;
$TextData{11}{LeftOver}
    = 'ESA astronaut Hans Schlegel assigned to European Columbus laboratory mission to the International Space Station.';

# start testing Text()
for ( sort keys %TextData ) {
    my $Test   = $_;
    my $TestOk = 0;

    $TextData{$Test}{Font}     = $TextData{$Test}{Font}     || 'Testfont1';
    $TextData{$Test}{FontSize} = $TextData{$Test}{FontSize} || 10;
    $TextData{$Test}{Type}     = $TextData{$Test}{Type}     || 'ReturnLeftOver';
    $TextData{$Test}{Lead}     = $TextData{$Test}{Lead}     || 0;

    if ( !defined( $TextData{$Test}{Width} ) ) {
        $TextData{$Test}{Width} = 100;
    }
    if ( !defined( $TextData{$Test}{Height} ) ) {
        $TextData{$Test}{Height} = $TextData{$Test}{FontSize};
    }

    my %Return = $PDFObject->Text(
        Text     => $TextData{$Test}{Text},
        Width    => $TextData{$Test}{Width},
        Height   => $TextData{$Test}{Height},
        Font     => $TextData{$Test}{Font},
        FontSize => $TextData{$Test}{FontSize},
        Type     => $TextData{$Test}{Type},
        Lead     => $TextData{$Test}{Lead},
    );

    if (
        $Return{State} eq $TextData{$Test}{State}
        &&
        $Return{RequiredWidth} eq $TextData{$Test}{RequiredWidth}   &&
        $Return{RequiredHeight} eq $TextData{$Test}{RequiredHeight} &&
        $Return{LeftOver} eq $TextData{$Test}{LeftOver}
        )
    {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR Text$Test State -->$Return{State}\n";
        print "ERROR Text$Test RequiredWidth -->$Return{RequiredWidth}\n";
        print "ERROR Text$Test RequiredHeight -->$Return{RequiredHeight}\n";
        print "ERROR Text$Test LeftOver -->$Return{LeftOver}<--\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "Text$Test()",
    );
}

# special Text() tests
my $PageNew2 = $PDFObject->PageNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 30,
    MarginRight  => 40,
    MarginBottom => 40,
    MarginLeft   => 40,
    HeaderRight  => 'header right',
    FooterLeft   => 'footer left',
    FooterRight  => 'footer right',
);

$Self->True(
    $PageNew2,
    "PageNew2()",
);

# position Text() tests
my %TextData2;

# positiontest0
$TextData2{0}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{0}{Type}           = 'ReturnLeftOver';
$TextData2{0}{Width}          = 150;
$TextData2{0}{Position1X}     = 'left';
$TextData2{0}{Position1Y}     = 'bottom';
$TextData2{0}{State}          = 0;
$TextData2{0}{RequiredWidth}  = 0;
$TextData2{0}{RequiredHeight} = 0;
$TextData2{0}{LeftOver}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{0}{PositionReturnX} = 40;
$TextData2{0}{PositionReturnY} = 56;

# positiontest1
$TextData2{1}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{1}{Type}           = 'ReturnLeftOver';
$TextData2{1}{Width}          = 150;
$TextData2{1}{Position1X}     = 'left';
$TextData2{1}{Position1Y}     = 'bottom';
$TextData2{1}{Position2Y}     = 9;
$TextData2{1}{State}          = 0;
$TextData2{1}{RequiredWidth}  = 0;
$TextData2{1}{RequiredHeight} = 0;
$TextData2{1}{LeftOver}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{1}{PositionReturnX} = 40;
$TextData2{1}{PositionReturnY} = 65;

# positiontest2
$TextData2{2}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{2}{Type}            = 'ReturnLeftOver';
$TextData2{2}{Width}           = 150;
$TextData2{2}{Position1X}      = 'left';
$TextData2{2}{Position1Y}      = 'bottom';
$TextData2{2}{Position2Y}      = 10;
$TextData2{2}{State}           = 0;
$TextData2{2}{RequiredWidth}   = 138.94;
$TextData2{2}{RequiredHeight}  = 10;
$TextData2{2}{LeftOver}        = 'Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{2}{PositionReturnX} = 40;
$TextData2{2}{PositionReturnY} = 56;

# positiontest3
$TextData2{3}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{3}{Type}            = 'ReturnLeftOver';
$TextData2{3}{Width}           = 150;
$TextData2{3}{Position1X}      = 'left';
$TextData2{3}{Position1Y}      = 'bottom';
$TextData2{3}{Position2Y}      = 11;
$TextData2{3}{State}           = 0;
$TextData2{3}{RequiredWidth}   = 138.94;
$TextData2{3}{RequiredHeight}  = 10;
$TextData2{3}{LeftOver}        = 'Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{3}{PositionReturnX} = 40;
$TextData2{3}{PositionReturnY} = 57;

# positiontest4
$TextData2{4}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{4}{Type}           = 'ReturnLeftOver';
$TextData2{4}{Width}          = 30;
$TextData2{4}{Position1X}     = 'left';
$TextData2{4}{Position1Y}     = 'bottom';
$TextData2{4}{Position2Y}     = 39;
$TextData2{4}{State}          = 0;
$TextData2{4}{RequiredWidth}  = 29.46;
$TextData2{4}{RequiredHeight} = 30;
$TextData2{4}{LeftOver} = 'space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{4}{PositionReturnX} = 40;
$TextData2{4}{PositionReturnY} = 65;

# positiontest5
$TextData2{5}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{5}{Type}            = 'ReturnLeftOver';
$TextData2{5}{Width}           = 100;
$TextData2{5}{Lead}            = 7;
$TextData2{5}{Position1X}      = 'left';
$TextData2{5}{Position1Y}      = 'bottom';
$TextData2{5}{Position2Y}      = 25;
$TextData2{5}{State}           = 0;
$TextData2{5}{RequiredWidth}   = 94.49;
$TextData2{5}{RequiredHeight}  = 10;
$TextData2{5}{LeftOver}        = 'flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{5}{PositionReturnX} = 40;
$TextData2{5}{PositionReturnY} = 71;

# positiontest6
$TextData2{6}{Text}
    = 'Veteran NASA space flier Navy Cmdr. Stephen Frick will command the STS-122 Shuttle mission to the ISS.';
$TextData2{6}{Type}            = 'ReturnLeftOver';
$TextData2{6}{Width}           = 105;
$TextData2{6}{Lead}            = 9;
$TextData2{6}{State}           = 1;
$TextData2{6}{RequiredWidth}   = 102.82;
$TextData2{6}{RequiredHeight}  = 105;
$TextData2{6}{LeftOver}        = '';
$TextData2{6}{PositionReturnX} = 421;
$TextData2{6}{PositionReturnY} = 188.5;

# start testing Text()
for ( sort keys %TextData2 ) {
    my $Test   = $_;
    my $TestOk = 0;

    $TextData2{$Test}{Position1X}      = $TextData2{$Test}{Position1X}      || 'center';
    $TextData2{$Test}{Position1Y}      = $TextData2{$Test}{Position1Y}      || 'middle';
    $TextData2{$Test}{Position2X}      = $TextData2{$Test}{Position2X}      || 0;
    $TextData2{$Test}{Position2Y}      = $TextData2{$Test}{Position2Y}      || 0;
    $TextData2{$Test}{Font}            = $TextData2{$Test}{Font}            || 'Testfont1';
    $TextData2{$Test}{FontSize}        = $TextData2{$Test}{FontSize}        || 10;
    $TextData2{$Test}{Type}            = $TextData2{$Test}{Type}            || 'ReturnLeftOver';
    $TextData2{$Test}{Lead}            = $TextData2{$Test}{Lead}            || 0;
    $TextData2{$Test}{PositionReturnX} = $TextData2{$Test}{PositionReturnX} || 0;
    $TextData2{$Test}{PositionReturnY} = $TextData2{$Test}{PositionReturnY} || 0;

    if ( !defined( $TextData2{$Test}{Width} ) ) {
        $TextData2{$Test}{Width} = 100;
    }

    $PDFObject->PositionSet(
        X => $TextData2{$Test}{Position1X},
        Y => $TextData2{$Test}{Position1Y},
    );
    $PDFObject->PositionSet(
        Move => 'relativ',
        X    => $TextData2{$Test}{Position2X},
        Y    => $TextData2{$Test}{Position2Y},
    );

    my %Return = $PDFObject->Text(
        Text     => $TextData2{$Test}{Text},
        Width    => $TextData2{$Test}{Width},
        Font     => $TextData2{$Test}{Font},
        FontSize => $TextData2{$Test}{FontSize},
        Type     => $TextData2{$Test}{Type},
        Lead     => $TextData2{$Test}{Lead},
    );

    my %Position = $PDFObject->PositionGet();

    if (
        $Return{State} eq $TextData2{$Test}{State}
        &&
        $Return{RequiredWidth} eq $TextData2{$Test}{RequiredWidth}   &&
        $Return{RequiredHeight} eq $TextData2{$Test}{RequiredHeight} &&
        $Return{LeftOver} eq $TextData2{$Test}{LeftOver}             &&
        $Position{X} eq $TextData2{$Test}{PositionReturnX}           &&
        $Position{Y} eq $TextData2{$Test}{PositionReturnY}
        )
    {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR Text$Test (Position) State -->$Return{State}\n";
        print "ERROR Text$Test (Position) RequiredWidth -->$Return{RequiredWidth}\n";
        print "ERROR Text$Test (Position) RequiredHeight -->$Return{RequiredHeight}\n";
        print "ERROR Text$Test (Position) LeftOver -->$Return{LeftOver}<--\n";
        print "ERROR Text$Test (Position) Position X -->$Position{X}<--\n";
        print "ERROR Text$Test (Position) Position Y -->$Position{Y}<--\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "Text$Test() (Position)",
    );
}

# _TableCalculate() tests
my %TableCalculate;

# tablecalculatetest0
$TableCalculate{0}{FontColorEven}   = '#101010';
$TableCalculate{0}{BackgroundColor} = 'red';
$TableCalculate{0}{Type}            = 'Cut';
$TableCalculate{0}{Border}          = 1;

$TableCalculate{0}{CellData}[0][0]{Content}         = 'Cell 1-1';
$TableCalculate{0}{CellData}[0][1]{Content}         = 'Cell 1-2';
$TableCalculate{0}{CellData}[0][1]{BackgroundColor} = 'blue';
$TableCalculate{0}{CellData}[0][1]{Type}            = 'ReturnLeftOverHard';
$TableCalculate{0}{CellData}[0][1]{Lead}            = 3;
$TableCalculate{0}{CellData}[1][0]{Content}         = 'Cell 2-1 (Row 2)';
$TableCalculate{0}{CellData}[1][1]{Content}         = '';
$TableCalculate{0}{CellData}[1][1]{Align}           = 'center';

$TableCalculate{0}{ReturnCellData}[0][0]{Content}         = 'Cell 1-1';
$TableCalculate{0}{ReturnCellData}[0][0]{Type}            = 'Cut';
$TableCalculate{0}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{0}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{0}{ReturnCellData}[0][0]{FontColor}       = '#101010';
$TableCalculate{0}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{0}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{0}{ReturnCellData}[0][0]{BackgroundColor} = 'red';
$TableCalculate{0}{ReturnCellData}[0][1]{Content}         = 'Cell 1-2';
$TableCalculate{0}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOverHard';
$TableCalculate{0}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{0}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{0}{ReturnCellData}[0][1]{FontColor}       = '#101010';
$TableCalculate{0}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{0}{ReturnCellData}[0][1]{Lead}            = 3;
$TableCalculate{0}{ReturnCellData}[0][1]{BackgroundColor} = 'blue';
$TableCalculate{0}{ReturnCellData}[1][0]{Content}         = 'Cell 2-1 (Row 2)';
$TableCalculate{0}{ReturnCellData}[1][0]{Type}            = 'Cut';
$TableCalculate{0}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{0}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{0}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{0}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{0}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{0}{ReturnCellData}[1][0]{BackgroundColor} = 'red';
$TableCalculate{0}{ReturnCellData}[1][1]{Content}         = ' ';
$TableCalculate{0}{ReturnCellData}[1][1]{Type}            = 'Cut';
$TableCalculate{0}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{0}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{0}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{0}{ReturnCellData}[1][1]{Align}           = 'center';
$TableCalculate{0}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{0}{ReturnCellData}[1][1]{BackgroundColor} = 'red';

$TableCalculate{0}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{0}{ReturnColumnData}[0]{EstimateWidth} = 47.78;
$TableCalculate{0}{ReturnColumnData}[0]{TextWidth}     = 259.4725;
$TableCalculate{0}{ReturnColumnData}[0]{OutputWidth}   = 261.4725;
$TableCalculate{0}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{0}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{0}{ReturnColumnData}[1]{EstimateWidth} = 25.835;
$TableCalculate{0}{ReturnColumnData}[1]{TextWidth}     = 237.5275;
$TableCalculate{0}{ReturnColumnData}[1]{OutputWidth}   = 239.5275;
$TableCalculate{0}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{0}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{0}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest1
$TableCalculate{1}{Width}  = 300;
$TableCalculate{1}{Border} = 1;

$TableCalculate{1}{CellData}[0][0]{Content}
    = "Welcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n    Manage your communication!";
$TableCalculate{1}{CellData}[0][1]{Content}
    = "\nWelcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n\tManage your communication!\n";
$TableCalculate{1}{CellData}[1][0]{Content}
    = "\tWelcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n    Manage your communication!\n\t";
$TableCalculate{1}{CellData}[1][1]{Content}
    = "\r\r\nWelcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\rYour OTRS Team\n\n    Manage your communication!\r\n";

$TableCalculate{1}{ReturnCellData}[0][0]{Content}
    = "Welcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n    Manage your communication!";
$TableCalculate{1}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{1}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{1}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{1}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{1}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{1}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{1}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{1}{ReturnCellData}[0][1]{Content}
    = "\nWelcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n  Manage your communication!\n";
$TableCalculate{1}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{1}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{1}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{1}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{1}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{1}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{1}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{1}{ReturnCellData}[1][0]{Content}
    = "  Welcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\n\n\nYour OTRS Team\n\n    Manage your communication!\n  ";
$TableCalculate{1}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{1}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{1}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{1}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{1}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{1}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{1}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{1}{ReturnCellData}[1][1]{Content}
    = "\nWelcome to OTRS!\n\nthank you for installing OTRS.\n\nYou will find updates and patches at http://otrs.org/. Online\ndocumentation is available at https://doc.otrs.com/doc/. You can also\ntake advantage of our mailing lists http://lists.otrs.org/.\nYour OTRS Team\n\n    Manage your communication!\n";
$TableCalculate{1}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{1}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{1}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{1}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{1}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{1}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{1}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{1}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{1}{ReturnColumnData}[0]{EstimateWidth} = 298;
$TableCalculate{1}{ReturnColumnData}[0]{TextWidth}     = 298;
$TableCalculate{1}{ReturnColumnData}[0]{OutputWidth}   = 300;
$TableCalculate{1}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{1}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{1}{ReturnColumnData}[1]{EstimateWidth} = 298;
$TableCalculate{1}{ReturnColumnData}[1]{TextWidth}     = 298;
$TableCalculate{1}{ReturnColumnData}[1]{OutputWidth}   = 300;
$TableCalculate{1}{ReturnColumnData}[1]{Block}         = 1;

$TableCalculate{1}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{1}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest2
$TableCalculate{2}{Width}  = 300;
$TableCalculate{2}{Border} = 1;

$TableCalculate{2}{CellData}[0][0]{Content} = "\n";
$TableCalculate{2}{CellData}[0][1]{Content} = "\t ";
$TableCalculate{2}{CellData}[1][0]{Content} = "\t\f";
$TableCalculate{2}{CellData}[1][1]{Content} = "\t\n\r\f\r\r\n";

$TableCalculate{2}{ReturnCellData}[0][0]{Content}         = "\n";
$TableCalculate{2}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{2}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{2}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{2}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{2}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{2}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{2}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{2}{ReturnCellData}[0][1]{Content}         = "   ";
$TableCalculate{2}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{2}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{2}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{2}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{2}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{2}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{2}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{2}{ReturnCellData}[1][0]{Content}         = "  \n\n";
$TableCalculate{2}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{2}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{2}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{2}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{2}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{2}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{2}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{2}{ReturnCellData}[1][1]{Content}         = "  \n\n\n\n";
$TableCalculate{2}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{2}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{2}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{2}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{2}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{2}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{2}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{2}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{2}{ReturnColumnData}[0]{EstimateWidth} = 6.11;
$TableCalculate{2}{ReturnColumnData}[0]{TextWidth}     = 146.835;
$TableCalculate{2}{ReturnColumnData}[0]{OutputWidth}   = 148.835;
$TableCalculate{2}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{2}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{2}{ReturnColumnData}[1]{EstimateWidth} = 9.44;
$TableCalculate{2}{ReturnColumnData}[1]{TextWidth}     = 150.165;
$TableCalculate{2}{ReturnColumnData}[1]{OutputWidth}   = 152.165;
$TableCalculate{2}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{2}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{2}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest3
$TableCalculate{3}{Width}  = 300;
$TableCalculate{3}{Border} = 1;

$TableCalculate{3}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{3}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{3}{CellData}[1][0]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{3}{CellData}[1][1]{Content} = "ISS";

$TableCalculate{3}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{3}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{3}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{3}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{3}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{3}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{3}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{3}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{3}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{3}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{3}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{3}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{3}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{3}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{3}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{3}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{3}{ReturnCellData}[1][0]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{3}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{3}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{3}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{3}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{3}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{3}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{3}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{3}{ReturnCellData}[1][1]{Content}         = "ISS";
$TableCalculate{3}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{3}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{3}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{3}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{3}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{3}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{3}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{3}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{3}{ReturnColumnData}[0]{EstimateWidth} = 298;
$TableCalculate{3}{ReturnColumnData}[0]{TextWidth}     = 298;
$TableCalculate{3}{ReturnColumnData}[0]{OutputWidth}   = 300;
$TableCalculate{3}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{3}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{3}{ReturnColumnData}[1]{EstimateWidth} = 298;
$TableCalculate{3}{ReturnColumnData}[1]{TextWidth}     = 298;
$TableCalculate{3}{ReturnColumnData}[1]{OutputWidth}   = 300;
$TableCalculate{3}{ReturnColumnData}[1]{Block}         = 1;

$TableCalculate{3}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{3}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest4
$TableCalculate{4}{Width}        = 1;
$TableCalculate{4}{PaddingLeft}  = 5;
$TableCalculate{4}{PaddingRight} = 5;
$TableCalculate{4}{Border}       = 2;

$TableCalculate{4}{CellData}[0][0]{Content} = "ISS - International Space Station";

$TableCalculate{4}{ReturnCellData}[0][0]{Content}         = "ISS - International Space Station";
$TableCalculate{4}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{4}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{4}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{4}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{4}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{4}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{4}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';

$TableCalculate{4}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{4}{ReturnColumnData}[0]{EstimateWidth} = 1;
$TableCalculate{4}{ReturnColumnData}[0]{TextWidth}     = 1;
$TableCalculate{4}{ReturnColumnData}[0]{OutputWidth}   = 1;
$TableCalculate{4}{ReturnColumnData}[0]{Block}         = 0;

$TableCalculate{4}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest5
$TableCalculate{5}{Width}  = 300;
$TableCalculate{5}{Border} = 1;

$TableCalculate{5}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{5}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{5}{CellData}[1][0]{Content} = "ISS";
$TableCalculate{5}{CellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";

$TableCalculate{5}{ColumnData}[1]{Width} = 103;

$TableCalculate{5}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{5}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{5}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{5}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{5}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{5}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{5}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{5}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{5}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{5}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{5}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{5}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{5}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{5}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{5}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{5}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{5}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{5}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{5}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{5}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{5}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{5}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{5}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{5}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{5}{ReturnCellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{5}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{5}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{5}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{5}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{5}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{5}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{5}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{5}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{5}{ReturnColumnData}[0]{EstimateWidth} = 16.12;
$TableCalculate{5}{ReturnColumnData}[0]{TextWidth}     = 194;
$TableCalculate{5}{ReturnColumnData}[0]{OutputWidth}   = 196;
$TableCalculate{5}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{5}{ReturnColumnData}[1]{Width}         = 103;
$TableCalculate{5}{ReturnColumnData}[1]{EstimateWidth} = 103;
$TableCalculate{5}{ReturnColumnData}[1]{TextWidth}     = 103;
$TableCalculate{5}{ReturnColumnData}[1]{OutputWidth}   = 105;
$TableCalculate{5}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{5}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{5}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest6
$TableCalculate{6}{Width}  = 1;
$TableCalculate{6}{Border} = 0;

$TableCalculate{6}{CellData}[0][0]{Content} = "ISS";

$TableCalculate{6}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{6}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{6}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{6}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{6}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{6}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{6}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{6}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';

$TableCalculate{6}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{6}{ReturnColumnData}[0]{EstimateWidth} = 1;
$TableCalculate{6}{ReturnColumnData}[0]{TextWidth}     = 1;
$TableCalculate{6}{ReturnColumnData}[0]{OutputWidth}   = 1;
$TableCalculate{6}{ReturnColumnData}[0]{Block}         = 0;

$TableCalculate{6}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest7
$TableCalculate{7}{Width}  = 300;
$TableCalculate{7}{Border} = 1;

$TableCalculate{7}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{7}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{7}{CellData}[1][0]{Content} = "ISS";
$TableCalculate{7}{CellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";

$TableCalculate{7}{ColumnData}[1]{Width} = 100;

$TableCalculate{7}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{7}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{7}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{7}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{7}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{7}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{7}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{7}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{7}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{7}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{7}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{7}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{7}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{7}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{7}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{7}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{7}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{7}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{7}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{7}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{7}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{7}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{7}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{7}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{7}{ReturnCellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{7}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{7}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{7}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{7}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{7}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{7}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{7}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{7}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{7}{ReturnColumnData}[0]{EstimateWidth} = 16.12;
$TableCalculate{7}{ReturnColumnData}[0]{TextWidth}     = 197;
$TableCalculate{7}{ReturnColumnData}[0]{OutputWidth}   = 199;
$TableCalculate{7}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{7}{ReturnColumnData}[1]{Width}         = 100;
$TableCalculate{7}{ReturnColumnData}[1]{EstimateWidth} = 100;
$TableCalculate{7}{ReturnColumnData}[1]{TextWidth}     = 100;
$TableCalculate{7}{ReturnColumnData}[1]{OutputWidth}   = 102;
$TableCalculate{7}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{7}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{7}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest8
$TableCalculate{8}{Width}  = 300;
$TableCalculate{8}{Border} = 1;

$TableCalculate{8}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{8}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{8}{CellData}[1][0]{Content} = "ISS";
$TableCalculate{8}{CellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";

$TableCalculate{8}{ColumnData}[0]{Width} = 70;
$TableCalculate{8}{ColumnData}[1]{Width} = 130;

$TableCalculate{8}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{8}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{8}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{8}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{8}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{8}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{8}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{8}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{8}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{8}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{8}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{8}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{8}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{8}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{8}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{8}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{8}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{8}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{8}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{8}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{8}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{8}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{8}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{8}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{8}{ReturnCellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{8}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{8}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{8}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{8}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{8}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{8}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{8}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{8}{ReturnColumnData}[0]{Width}         = 70;
$TableCalculate{8}{ReturnColumnData}[0]{EstimateWidth} = 70;
$TableCalculate{8}{ReturnColumnData}[0]{TextWidth}     = 118.5;
$TableCalculate{8}{ReturnColumnData}[0]{OutputWidth}   = 120.5;
$TableCalculate{8}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{8}{ReturnColumnData}[1]{Width}         = 130;
$TableCalculate{8}{ReturnColumnData}[1]{EstimateWidth} = 130;
$TableCalculate{8}{ReturnColumnData}[1]{TextWidth}     = 178.5;
$TableCalculate{8}{ReturnColumnData}[1]{OutputWidth}   = 180.5;
$TableCalculate{8}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{8}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{8}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest9
$TableCalculate{9}{Width}  = 300;
$TableCalculate{9}{Border} = 1;

$TableCalculate{9}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{9}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{9}{CellData}[1][0]{Content} = "ISS";
$TableCalculate{9}{CellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";

$TableCalculate{9}{ColumnData}[0]{Width} = 330;
$TableCalculate{9}{ColumnData}[1]{Width} = 105;

$TableCalculate{9}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{9}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{9}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{9}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{9}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{9}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{9}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{9}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{9}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{9}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{9}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{9}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{9}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{9}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{9}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{9}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{9}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{9}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{9}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{9}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{9}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{9}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{9}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{9}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{9}{ReturnCellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{9}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{9}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{9}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{9}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{9}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{9}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{9}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{9}{ReturnColumnData}[0]{Width}         = 298;
$TableCalculate{9}{ReturnColumnData}[0]{EstimateWidth} = 298;
$TableCalculate{9}{ReturnColumnData}[0]{TextWidth}     = 298;
$TableCalculate{9}{ReturnColumnData}[0]{OutputWidth}   = 300;
$TableCalculate{9}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{9}{ReturnColumnData}[1]{Width}         = 105;
$TableCalculate{9}{ReturnColumnData}[1]{EstimateWidth} = 105;
$TableCalculate{9}{ReturnColumnData}[1]{TextWidth}     = 105;
$TableCalculate{9}{ReturnColumnData}[1]{OutputWidth}   = 107;
$TableCalculate{9}{ReturnColumnData}[1]{Block}         = 1;

$TableCalculate{9}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{9}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest10
$TableCalculate{10}{Width}  = 300;
$TableCalculate{10}{Border} = 1;

$TableCalculate{10}{CellData}[0][0]{Content} = "Columbia";
$TableCalculate{10}{CellData}[0][1]{Content} = "Challenger";
$TableCalculate{10}{CellData}[0][2]{Content} = "Discovery";
$TableCalculate{10}{CellData}[0][3]{Content} = "Atlantis";
$TableCalculate{10}{CellData}[0][4]{Content} = "Endeavour";

$TableCalculate{10}{ReturnCellData}[0][0]{Content}         = "Columbia";
$TableCalculate{10}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{10}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{10}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{10}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{10}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{10}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{10}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{10}{ReturnCellData}[0][1]{Content}         = "Challenger";
$TableCalculate{10}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{10}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{10}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{10}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{10}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{10}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{10}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{10}{ReturnCellData}[0][2]{Content}         = "Discovery";
$TableCalculate{10}{ReturnCellData}[0][2]{Type}            = 'ReturnLeftOver';
$TableCalculate{10}{ReturnCellData}[0][2]{Font}            = 'Testfont1';
$TableCalculate{10}{ReturnCellData}[0][2]{FontSize}        = 10;
$TableCalculate{10}{ReturnCellData}[0][2]{FontColor}       = 'black';
$TableCalculate{10}{ReturnCellData}[0][2]{Align}           = 'left';
$TableCalculate{10}{ReturnCellData}[0][2]{Lead}            = 0;
$TableCalculate{10}{ReturnCellData}[0][2]{BackgroundColor} = 'NULL';
$TableCalculate{10}{ReturnCellData}[0][3]{Content}         = "Atlantis";
$TableCalculate{10}{ReturnCellData}[0][3]{Type}            = 'ReturnLeftOver';
$TableCalculate{10}{ReturnCellData}[0][3]{Font}            = 'Testfont1';
$TableCalculate{10}{ReturnCellData}[0][3]{FontSize}        = 10;
$TableCalculate{10}{ReturnCellData}[0][3]{FontColor}       = 'black';
$TableCalculate{10}{ReturnCellData}[0][3]{Align}           = 'left';
$TableCalculate{10}{ReturnCellData}[0][3]{Lead}            = 0;
$TableCalculate{10}{ReturnCellData}[0][3]{BackgroundColor} = 'NULL';
$TableCalculate{10}{ReturnCellData}[0][4]{Content}         = "Endeavour";
$TableCalculate{10}{ReturnCellData}[0][4]{Type}            = 'ReturnLeftOver';
$TableCalculate{10}{ReturnCellData}[0][4]{Font}            = 'Testfont1';
$TableCalculate{10}{ReturnCellData}[0][4]{FontSize}        = 10;
$TableCalculate{10}{ReturnCellData}[0][4]{FontColor}       = 'black';
$TableCalculate{10}{ReturnCellData}[0][4]{Align}           = 'left';
$TableCalculate{10}{ReturnCellData}[0][4]{Lead}            = 0;
$TableCalculate{10}{ReturnCellData}[0][4]{BackgroundColor} = 'NULL';

$TableCalculate{10}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{10}{ReturnColumnData}[0]{EstimateWidth} = 42.23;
$TableCalculate{10}{ReturnColumnData}[0]{TextWidth}     = 57.906;
$TableCalculate{10}{ReturnColumnData}[0]{OutputWidth}   = 59.906;
$TableCalculate{10}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{10}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{10}{ReturnColumnData}[1]{EstimateWidth} = 48.35;
$TableCalculate{10}{ReturnColumnData}[1]{TextWidth}     = 64.026;
$TableCalculate{10}{ReturnColumnData}[1]{OutputWidth}   = 66.026;
$TableCalculate{10}{ReturnColumnData}[1]{Block}         = 0;
$TableCalculate{10}{ReturnColumnData}[2]{Width}         = 0;
$TableCalculate{10}{ReturnColumnData}[2]{EstimateWidth} = 43.89;
$TableCalculate{10}{ReturnColumnData}[2]{TextWidth}     = 59.566;
$TableCalculate{10}{ReturnColumnData}[2]{OutputWidth}   = 61.566;
$TableCalculate{10}{ReturnColumnData}[2]{Block}         = 0;
$TableCalculate{10}{ReturnColumnData}[3]{Width}         = 0;
$TableCalculate{10}{ReturnColumnData}[3]{EstimateWidth} = 32.79;
$TableCalculate{10}{ReturnColumnData}[3]{TextWidth}     = 48.466;
$TableCalculate{10}{ReturnColumnData}[3]{OutputWidth}   = 50.466;
$TableCalculate{10}{ReturnColumnData}[3]{Block}         = 0;
$TableCalculate{10}{ReturnColumnData}[4]{Width}         = 0;
$TableCalculate{10}{ReturnColumnData}[4]{EstimateWidth} = 48.36;
$TableCalculate{10}{ReturnColumnData}[4]{TextWidth}     = 64.036;
$TableCalculate{10}{ReturnColumnData}[4]{OutputWidth}   = 66.036;
$TableCalculate{10}{ReturnColumnData}[4]{Block}         = 0;

$TableCalculate{10}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest11
$TableCalculate{11}{Width}        = 300;
$TableCalculate{11}{Border}       = 5;
$TableCalculate{11}{PaddingRight} = 10;
$TableCalculate{11}{PaddingLeft}  = 10;

$TableCalculate{11}{CellData}[0][0]{Content} = "Columbus";
$TableCalculate{11}{CellData}[0][1]{Content} = "Destiny";

$TableCalculate{11}{ReturnCellData}[0][0]{Content}         = "Columbus";
$TableCalculate{11}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{11}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{11}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{11}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{11}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{11}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{11}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{11}{ReturnCellData}[0][1]{Content}         = "Destiny";
$TableCalculate{11}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{11}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{11}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{11}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{11}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{11}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{11}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';

$TableCalculate{11}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{11}{ReturnColumnData}[0]{EstimateWidth} = 45.01;
$TableCalculate{11}{ReturnColumnData}[0]{TextWidth}     = 128.335;
$TableCalculate{11}{ReturnColumnData}[0]{OutputWidth}   = 158.335;
$TableCalculate{11}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{11}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{11}{ReturnColumnData}[1]{EstimateWidth} = 33.34;
$TableCalculate{11}{ReturnColumnData}[1]{TextWidth}     = 116.665;
$TableCalculate{11}{ReturnColumnData}[1]{OutputWidth}   = 146.665;
$TableCalculate{11}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{11}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest12
$TableCalculate{12}{CellData}[0][0]{Content}  = "ISS";
$TableCalculate{12}{CellData}[0][0]{FontSize} = 4;
$TableCalculate{12}{CellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{12}{CellData}[0][1]{FontSize} = 9;
$TableCalculate{12}{CellData}[1][0]{Content}  = "ISS";
$TableCalculate{12}{CellData}[1][0]{FontSize} = 18;
$TableCalculate{12}{CellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{12}{CellData}[1][1]{FontSize} = 12;

$TableCalculate{12}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{12}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{12}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{12}{ReturnCellData}[0][0]{FontSize}        = 4;
$TableCalculate{12}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{12}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{12}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{12}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{12}{ReturnCellData}[0][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{12}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{12}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{12}{ReturnCellData}[0][1]{FontSize}        = 9;
$TableCalculate{12}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{12}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{12}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{12}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{12}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{12}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{12}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{12}{ReturnCellData}[1][0]{FontSize}        = 18;
$TableCalculate{12}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{12}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{12}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{12}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{12}{ReturnCellData}[1][1]{Content}
    = "During this time, he and fellow NASA crew member Jeff Williams will install items of hardware in preparation for future ISS assembly work and will also set up for deployment a number of instruments and experiments.";
$TableCalculate{12}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{12}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{12}{ReturnCellData}[1][1]{FontSize}        = 12;
$TableCalculate{12}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{12}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{12}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{12}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{12}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{12}{ReturnColumnData}[0]{EstimateWidth} = 29.016;
$TableCalculate{12}{ReturnColumnData}[0]{TextWidth}     = 500;
$TableCalculate{12}{ReturnColumnData}[0]{OutputWidth}   = 500;
$TableCalculate{12}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{12}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{12}{ReturnColumnData}[1]{EstimateWidth} = 500;
$TableCalculate{12}{ReturnColumnData}[1]{TextWidth}     = 500;
$TableCalculate{12}{ReturnColumnData}[1]{OutputWidth}   = 500;
$TableCalculate{12}{ReturnColumnData}[1]{Block}         = 1;

$TableCalculate{12}{ReturnRowData}[0]{MinFontSize} = 4;
$TableCalculate{12}{ReturnRowData}[1]{MinFontSize} = 12;

# tablecalculatetest13
$TableCalculate{13}{Width}  = 100;
$TableCalculate{13}{Border} = 1;

$TableCalculate{13}{CellData}[0][0]{Content} = "Columbia";
$TableCalculate{13}{CellData}[0][1]{Content} = "Challenger";
$TableCalculate{13}{CellData}[0][2]{Content} = "Discovery";
$TableCalculate{13}{CellData}[0][3]{Content} = "Atlantis";
$TableCalculate{13}{CellData}[0][4]{Content} = "Endeavour";

$TableCalculate{13}{ReturnCellData}[0][0]{Content}         = "Columbia";
$TableCalculate{13}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{13}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{13}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{13}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{13}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{13}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{13}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{13}{ReturnCellData}[0][1]{Content}         = "Challenger";
$TableCalculate{13}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{13}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{13}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{13}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{13}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{13}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{13}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{13}{ReturnCellData}[0][2]{Content}         = "Discovery";
$TableCalculate{13}{ReturnCellData}[0][2]{Type}            = 'ReturnLeftOver';
$TableCalculate{13}{ReturnCellData}[0][2]{Font}            = 'Testfont1';
$TableCalculate{13}{ReturnCellData}[0][2]{FontSize}        = 10;
$TableCalculate{13}{ReturnCellData}[0][2]{FontColor}       = 'black';
$TableCalculate{13}{ReturnCellData}[0][2]{Align}           = 'left';
$TableCalculate{13}{ReturnCellData}[0][2]{Lead}            = 0;
$TableCalculate{13}{ReturnCellData}[0][2]{BackgroundColor} = 'NULL';
$TableCalculate{13}{ReturnCellData}[0][3]{Content}         = "Atlantis";
$TableCalculate{13}{ReturnCellData}[0][3]{Type}            = 'ReturnLeftOver';
$TableCalculate{13}{ReturnCellData}[0][3]{Font}            = 'Testfont1';
$TableCalculate{13}{ReturnCellData}[0][3]{FontSize}        = 10;
$TableCalculate{13}{ReturnCellData}[0][3]{FontColor}       = 'black';
$TableCalculate{13}{ReturnCellData}[0][3]{Align}           = 'left';
$TableCalculate{13}{ReturnCellData}[0][3]{Lead}            = 0;
$TableCalculate{13}{ReturnCellData}[0][3]{BackgroundColor} = 'NULL';
$TableCalculate{13}{ReturnCellData}[0][4]{Content}         = "Endeavour";
$TableCalculate{13}{ReturnCellData}[0][4]{Type}            = 'ReturnLeftOver';
$TableCalculate{13}{ReturnCellData}[0][4]{Font}            = 'Testfont1';
$TableCalculate{13}{ReturnCellData}[0][4]{FontSize}        = 10;
$TableCalculate{13}{ReturnCellData}[0][4]{FontColor}       = 'black';
$TableCalculate{13}{ReturnCellData}[0][4]{Align}           = 'left';
$TableCalculate{13}{ReturnCellData}[0][4]{Lead}            = 0;
$TableCalculate{13}{ReturnCellData}[0][4]{BackgroundColor} = 'NULL';

$TableCalculate{13}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{13}{ReturnColumnData}[0]{EstimateWidth} = 42.23;
$TableCalculate{13}{ReturnColumnData}[0]{TextWidth}     = 45.44;
$TableCalculate{13}{ReturnColumnData}[0]{OutputWidth}   = 47.44;
$TableCalculate{13}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{13}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{13}{ReturnColumnData}[1]{EstimateWidth} = 48.35;
$TableCalculate{13}{ReturnColumnData}[1]{TextWidth}     = 51.56;
$TableCalculate{13}{ReturnColumnData}[1]{OutputWidth}   = 53.56;
$TableCalculate{13}{ReturnColumnData}[1]{Block}         = 0;
$TableCalculate{13}{ReturnColumnData}[2]{Width}         = 0;
$TableCalculate{13}{ReturnColumnData}[2]{EstimateWidth} = 43.89;
$TableCalculate{13}{ReturnColumnData}[2]{TextWidth}     = 54.05;
$TableCalculate{13}{ReturnColumnData}[2]{OutputWidth}   = 56.05;
$TableCalculate{13}{ReturnColumnData}[2]{Block}         = 1;
$TableCalculate{13}{ReturnColumnData}[3]{Width}         = 0;
$TableCalculate{13}{ReturnColumnData}[3]{EstimateWidth} = 32.79;
$TableCalculate{13}{ReturnColumnData}[3]{TextWidth}     = 42.95;
$TableCalculate{13}{ReturnColumnData}[3]{OutputWidth}   = 44.95;
$TableCalculate{13}{ReturnColumnData}[3]{Block}         = 1;
$TableCalculate{13}{ReturnColumnData}[4]{Width}         = 0;
$TableCalculate{13}{ReturnColumnData}[4]{EstimateWidth} = 48.36;
$TableCalculate{13}{ReturnColumnData}[4]{TextWidth}     = 48.36;
$TableCalculate{13}{ReturnColumnData}[4]{OutputWidth}   = 50.36;
$TableCalculate{13}{ReturnColumnData}[4]{Block}         = 2;

$TableCalculate{13}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest14
$TableCalculate{14}{Width}  = 400;
$TableCalculate{14}{Border} = 0;

$TableCalculate{14}{CellData}[0][0]{Content} = "ISS";

$TableCalculate{14}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{14}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{14}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{14}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{14}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{14}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{14}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{14}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';

$TableCalculate{14}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{14}{ReturnColumnData}[0]{EstimateWidth} = 16.12;
$TableCalculate{14}{ReturnColumnData}[0]{TextWidth}     = 400;
$TableCalculate{14}{ReturnColumnData}[0]{OutputWidth}   = 400;
$TableCalculate{14}{ReturnColumnData}[0]{Block}         = 0;

$TableCalculate{14}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest15
$TableCalculate{15}{CellData} = [];

$TableCalculate{15}{ReturnCellData}[0][0]{Content}         = " ";
$TableCalculate{15}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{15}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{15}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{15}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{15}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{15}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{15}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';

$TableCalculate{15}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{15}{ReturnColumnData}[0]{EstimateWidth} = 1.39;
$TableCalculate{15}{ReturnColumnData}[0]{TextWidth}     = 500;
$TableCalculate{15}{ReturnColumnData}[0]{OutputWidth}   = 500;
$TableCalculate{15}{ReturnColumnData}[0]{Block}         = 0;

$TableCalculate{15}{ReturnRowData}[0]{MinFontSize} = 10;

# tablecalculatetest16
$TableCalculate{16}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{16}{CellData}[1][0]{Content} = "ISS";
$TableCalculate{16}{CellData}[1][1]{Content} = "ISS";

$TableCalculate{16}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{16}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{16}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{16}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{16}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{16}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{16}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{16}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{16}{ReturnCellData}[0][1]{Content}         = " ";
$TableCalculate{16}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{16}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{16}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{16}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{16}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{16}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{16}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{16}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{16}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{16}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{16}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{16}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{16}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{16}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{16}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{16}{ReturnCellData}[1][1]{Content}         = "ISS";
$TableCalculate{16}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{16}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{16}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{16}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{16}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{16}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{16}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{16}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{16}{ReturnColumnData}[0]{EstimateWidth} = 16.12;
$TableCalculate{16}{ReturnColumnData}[0]{TextWidth}     = 250;
$TableCalculate{16}{ReturnColumnData}[0]{OutputWidth}   = 250;
$TableCalculate{16}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{16}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{16}{ReturnColumnData}[1]{EstimateWidth} = 16.12;
$TableCalculate{16}{ReturnColumnData}[1]{TextWidth}     = 250;
$TableCalculate{16}{ReturnColumnData}[1]{OutputWidth}   = 250;
$TableCalculate{16}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{16}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{16}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest17
$TableCalculate{17}{CellData}[0][0]{Content} = "ISS";
$TableCalculate{17}{CellData}[0][1]{Content} = "ISS";
$TableCalculate{17}{CellData}[1][0]{Content} = "ISS";

$TableCalculate{17}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{17}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{17}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{17}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{17}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{17}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{17}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{17}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';
$TableCalculate{17}{ReturnCellData}[0][1]{Content}         = "ISS";
$TableCalculate{17}{ReturnCellData}[0][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{17}{ReturnCellData}[0][1]{Font}            = 'Testfont1';
$TableCalculate{17}{ReturnCellData}[0][1]{FontSize}        = 10;
$TableCalculate{17}{ReturnCellData}[0][1]{FontColor}       = 'black';
$TableCalculate{17}{ReturnCellData}[0][1]{Align}           = 'left';
$TableCalculate{17}{ReturnCellData}[0][1]{Lead}            = 0;
$TableCalculate{17}{ReturnCellData}[0][1]{BackgroundColor} = 'NULL';
$TableCalculate{17}{ReturnCellData}[1][0]{Content}         = "ISS";
$TableCalculate{17}{ReturnCellData}[1][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{17}{ReturnCellData}[1][0]{Font}            = 'Testfont1';
$TableCalculate{17}{ReturnCellData}[1][0]{FontSize}        = 10;
$TableCalculate{17}{ReturnCellData}[1][0]{FontColor}       = 'black';
$TableCalculate{17}{ReturnCellData}[1][0]{Align}           = 'left';
$TableCalculate{17}{ReturnCellData}[1][0]{Lead}            = 0;
$TableCalculate{17}{ReturnCellData}[1][0]{BackgroundColor} = 'NULL';
$TableCalculate{17}{ReturnCellData}[1][1]{Content}         = " ";
$TableCalculate{17}{ReturnCellData}[1][1]{Type}            = 'ReturnLeftOver';
$TableCalculate{17}{ReturnCellData}[1][1]{Font}            = 'Testfont1';
$TableCalculate{17}{ReturnCellData}[1][1]{FontSize}        = 10;
$TableCalculate{17}{ReturnCellData}[1][1]{FontColor}       = 'black';
$TableCalculate{17}{ReturnCellData}[1][1]{Align}           = 'left';
$TableCalculate{17}{ReturnCellData}[1][1]{Lead}            = 0;
$TableCalculate{17}{ReturnCellData}[1][1]{BackgroundColor} = 'NULL';

$TableCalculate{17}{ReturnColumnData}[0]{Width}         = 0;
$TableCalculate{17}{ReturnColumnData}[0]{EstimateWidth} = 16.12;
$TableCalculate{17}{ReturnColumnData}[0]{TextWidth}     = 250;
$TableCalculate{17}{ReturnColumnData}[0]{OutputWidth}   = 250;
$TableCalculate{17}{ReturnColumnData}[0]{Block}         = 0;
$TableCalculate{17}{ReturnColumnData}[1]{Width}         = 0;
$TableCalculate{17}{ReturnColumnData}[1]{EstimateWidth} = 16.12;
$TableCalculate{17}{ReturnColumnData}[1]{TextWidth}     = 250;
$TableCalculate{17}{ReturnColumnData}[1]{OutputWidth}   = 250;
$TableCalculate{17}{ReturnColumnData}[1]{Block}         = 0;

$TableCalculate{17}{ReturnRowData}[0]{MinFontSize} = 10;
$TableCalculate{17}{ReturnRowData}[1]{MinFontSize} = 10;

# tablecalculatetest18
$TableCalculate{18}{CellData}[0][0]{Content} = "ISS";

$TableCalculate{18}{ColumnData}[0]{Width} = 100;
$TableCalculate{18}{ColumnData}[1]{Width} = 100;

$TableCalculate{18}{ReturnCellData}[0][0]{Content}         = "ISS";
$TableCalculate{18}{ReturnCellData}[0][0]{Type}            = 'ReturnLeftOver';
$TableCalculate{18}{ReturnCellData}[0][0]{Font}            = 'Testfont1';
$TableCalculate{18}{ReturnCellData}[0][0]{FontSize}        = 10;
$TableCalculate{18}{ReturnCellData}[0][0]{FontColor}       = 'black';
$TableCalculate{18}{ReturnCellData}[0][0]{Align}           = 'left';
$TableCalculate{18}{ReturnCellData}[0][0]{Lead}            = 0;
$TableCalculate{18}{ReturnCellData}[0][0]{BackgroundColor} = 'NULL';

$TableCalculate{18}{ReturnColumnData}[0]{Width}         = 100;
$TableCalculate{18}{ReturnColumnData}[0]{EstimateWidth} = 100;
$TableCalculate{18}{ReturnColumnData}[0]{TextWidth}     = 500;
$TableCalculate{18}{ReturnColumnData}[0]{OutputWidth}   = 500;
$TableCalculate{18}{ReturnColumnData}[0]{Block}         = 0;

$TableCalculate{18}{ReturnRowData}[0]{MinFontSize} = 10;

# start testing TableCalculate()
TEST:
for my $Test ( sort keys %TableCalculate ) {
    my $TestOk = 0;

    my %TableCalculateParams;
    $TableCalculateParams{CellData}        = $TableCalculate{$Test}{CellData};
    $TableCalculateParams{ColumnData}      = $TableCalculate{$Test}{ColumnData} || [];
    $TableCalculateParams{RowData}         = $TableCalculate{$Test}{RowData} || [];
    $TableCalculateParams{Type}            = $TableCalculate{$Test}{Type} || 'ReturnLeftOver';
    $TableCalculateParams{Width}           = $TableCalculate{$Test}{Width} || 500;
    $TableCalculateParams{Height}          = $TableCalculate{$Test}{Height} || 500;
    $TableCalculateParams{Font}            = $TableCalculate{$Test}{Font} || 'Testfont1';
    $TableCalculateParams{FontSize}        = $TableCalculate{$Test}{FontSize} || 10;
    $TableCalculateParams{FontColor}       = $TableCalculate{$Test}{FontColor} || 'black';
    $TableCalculateParams{Align}           = $TableCalculate{$Test}{Align} || 'left';
    $TableCalculateParams{Lead}            = $TableCalculate{$Test}{Lead} || 0;
    $TableCalculateParams{BackgroundColor} = $TableCalculate{$Test}{BackgroundColor} || 'NULL';
    $TableCalculateParams{PaddingLeft}     = $TableCalculate{$Test}{PaddingLeft} || 0;
    $TableCalculateParams{PaddingRight}    = $TableCalculate{$Test}{PaddingRight} || 0;
    $TableCalculateParams{PaddingTop}      = $TableCalculate{$Test}{PaddingTop} || 0;
    $TableCalculateParams{PaddingBottom}   = $TableCalculate{$Test}{PaddingBottom} || 0;
    $TableCalculateParams{Border}          = $TableCalculate{$Test}{Border} || 0;
    $TableCalculateParams{BorderColor}     = $TableCalculate{$Test}{BorderColor} || 'black';

    if ( defined( $TableCalculate{$Test}{FontColorOdd} ) ) {
        $TableCalculateParams{FontColorOdd} = $TableCalculate{$Test}{FontColorOdd};
    }
    if ( defined( $TableCalculate{$Test}{FontColorEven} ) ) {
        $TableCalculateParams{FontColorEven} = $TableCalculate{$Test}{FontColorEven};
    }
    if ( defined( $TableCalculate{$Test}{BackgroundColorOdd} ) ) {
        $TableCalculateParams{BackgroundColorOdd} = $TableCalculate{$Test}{BackgroundColorOdd};
    }
    if ( defined( $TableCalculate{$Test}{BackgroundColorEven} ) ) {
        $TableCalculateParams{BackgroundColorEven} = $TableCalculate{$Test}{BackgroundColorEven};
    }

    my %Return = $PDFObject->_TableCalculate(
        %TableCalculateParams,
    );

    # check returned ColumnData
    my $TestColumnOk  = 0;
    my $CounterColumn = 0;
    COLUMN:
    for my $Column ( @{ $TableCalculate{$Test}{ReturnColumnData} } ) {
        if (
            $Return{ColumnData}->[$CounterColumn]->{Width} eq $Column->{Width}
            &&
            $Return{ColumnData}->[$CounterColumn]->{EstimateWidth} eq $Column->{EstimateWidth} &&
            $Return{ColumnData}->[$CounterColumn]->{TextWidth} eq $Column->{TextWidth}         &&
            $Return{ColumnData}->[$CounterColumn]->{OutputWidth} eq $Column->{OutputWidth}     &&
            $Return{ColumnData}->[$CounterColumn]->{Block} eq $Column->{Block}
            )
        {
            $TestColumnOk = 1;
        }
        else {
            print "\n";
            print
                "ERROR _TableCalculate$Test Column$CounterColumn Width -->$Return{ColumnData}->[$CounterColumn]->{Width}\n";
            print
                "ERROR _TableCalculate$Test Column$CounterColumn EstimateWidth -->$Return{ColumnData}->[$CounterColumn]->{EstimateWidth}\n";
            print
                "ERROR _TableCalculate$Test Column$CounterColumn TextWidth -->$Return{ColumnData}->[$CounterColumn]->{TextWidth}\n";
            print
                "ERROR _TableCalculate$Test Column$CounterColumn OutputWidth -->$Return{ColumnData}->[$CounterColumn]->{OutputWidth}\n";
            print
                "ERROR _TableCalculate$Test Column$CounterColumn Block -->$Return{ColumnData}->[$CounterColumn]->{Block}\n";
            print "\n";

            $TestColumnOk = 0;
            last COLUMN;
        }

        $CounterColumn++;
    }

    # check returned RowData
    my $TestRowOk  = 0;
    my $CounterRow = 0;
    if ($TestColumnOk) {
        ROW:
        for my $Row ( @{ $TableCalculate{$Test}{ReturnRowData} } ) {
            if ( $Return{RowData}->[$CounterRow]->{MinFontSize} eq $Row->{MinFontSize} ) {
                $TestRowOk = 1;
            }
            else {
                print "\n";
                print
                    "ERROR _TableCalculate$Test Row$CounterRow MinFontSize -->$Return{RowData}->[$CounterRow]->{MinFontSize}\n";
                print "\n";

                $TestRowOk = 0;
                last ROW;
            }

            $CounterRow++;
        }
    }

    # check returned CellData
    if ($TestRowOk) {
        my $CounterCellRow = 0;
        ROW:
        for my $Row ( @{ $TableCalculate{$Test}{ReturnCellData} } ) {
            my $CounterCellColumn = 0;
            CELL:
            for my $Cell ( @{ $TableCalculate{$Test}{ReturnCellData}[$CounterCellRow] } ) {
                if (
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Content} eq
                    $Cell->{Content}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Type} eq
                    $Cell->{Type}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Font} eq
                    $Cell->{Font}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{FontSize} eq
                    $Cell->{FontSize}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{FontColor} eq
                    $Cell->{FontColor}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Align} eq
                    $Cell->{Align}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Lead} eq
                    $Cell->{Lead}
                    &&
                    $Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{BackgroundColor} eq
                    $Cell->{BackgroundColor}
                    )
                {
                    $TestOk = 1;
                }
                else {
                    print "\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn Content -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Content}<--\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn Type -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Type}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn Font -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Font}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn FontSize -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{FontSize}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn FontColor -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{FontColor}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn Align -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Align}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn Lead -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{Lead}\n";
                    print
                        "ERROR _TableCalculate$Test Cell$CounterCellRow-$CounterCellColumn BackgroundColor -->$Return{CellData}->[$CounterCellRow]->[$CounterCellColumn]->{BackgroundColor}\n";
                    print "\n";

                    $TestOk = 0;
                    last CELL;
                }
                $CounterCellColumn++;
            }
            $CounterCellRow++;
            if ( !$TestOk ) {
                last ROW;
            }
        }
    }

    $Self->True(
        $TestOk,
        "_TableCalculate$Test()",
    );
}

# _TableBlockNextCalculate() tests
my %TableBlockNextCalculate;

# tableblocknextcalculatetest0
$TableBlockNextCalculate{0}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{0}{CellData}[0][0]{TmpOff} = 0;

$TableBlockNextCalculate{0}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{0}{State}             = 1;
$TableBlockNextCalculate{0}{ReturnBlock}       = 0;
$TableBlockNextCalculate{0}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{0}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{0}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest1
$TableBlockNextCalculate{1}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{1}{CellData}[0][0]{TmpOff} = 0;

$TableBlockNextCalculate{1}{ColumnData}[0][0]{Block} = 0;

$TableBlockNextCalculate{1}{State}             = 0;
$TableBlockNextCalculate{1}{ReturnBlock}       = 0;
$TableBlockNextCalculate{1}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{1}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{1}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest2
$TableBlockNextCalculate{2}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{2}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{2}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{2}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{2}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{2}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{2}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{2}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{2}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{2}{State}             = 1;
$TableBlockNextCalculate{2}{ReturnBlock}       = 0;
$TableBlockNextCalculate{2}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{2}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{2}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest3
$TableBlockNextCalculate{3}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{3}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{3}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{3}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{3}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{3}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{3}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{3}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{3}{ColumnData}[1]{Block} = 1;

$TableBlockNextCalculate{3}{State}             = 1;
$TableBlockNextCalculate{3}{ReturnBlock}       = 1;
$TableBlockNextCalculate{3}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{3}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{3}{ReturnColumnStop}  = 1;

# tableblocknextcalculatetest4
$TableBlockNextCalculate{4}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{4}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{4}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{4}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{4}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{4}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{4}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{4}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{4}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{4}{State}             = 1;
$TableBlockNextCalculate{4}{ReturnBlock}       = 0;
$TableBlockNextCalculate{4}{ReturnRowStart}    = 1;
$TableBlockNextCalculate{4}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{4}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest5
$TableBlockNextCalculate{5}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{5}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{5}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{5}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{5}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{5}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{5}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{5}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{5}{ColumnData}[1]{Block} = 1;

$TableBlockNextCalculate{5}{State}             = 1;
$TableBlockNextCalculate{5}{ReturnBlock}       = 1;
$TableBlockNextCalculate{5}{ReturnRowStart}    = 1;
$TableBlockNextCalculate{5}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{5}{ReturnColumnStop}  = 1;

# tableblocknextcalculatetest6
$TableBlockNextCalculate{6}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{6}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{6}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{6}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{6}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{6}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{6}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{6}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{6}{ColumnData}[1]{Block} = 1;

$TableBlockNextCalculate{6}{State}             = 0;
$TableBlockNextCalculate{6}{ReturnBlock}       = 0;
$TableBlockNextCalculate{6}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{6}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{6}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest7
$TableBlockNextCalculate{7}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[0][2]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[2][0]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{7}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{7}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{7}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{7}{State}             = 1;
$TableBlockNextCalculate{7}{ReturnBlock}       = 0;
$TableBlockNextCalculate{7}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{7}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{7}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest8
$TableBlockNextCalculate{8}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{8}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[0][2]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[2][0]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{8}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{8}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{8}{ColumnData}[1]{Block} = 1;
$TableBlockNextCalculate{8}{ColumnData}[2]{Block} = 1;

$TableBlockNextCalculate{8}{State}             = 1;
$TableBlockNextCalculate{8}{ReturnBlock}       = 1;
$TableBlockNextCalculate{8}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{8}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{8}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest9
$TableBlockNextCalculate{9}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{9}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{9}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[0][2]{Off}    = 1;
$TableBlockNextCalculate{9}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{9}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{9}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{9}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[2][0]{Off}    = 0;
$TableBlockNextCalculate{9}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{9}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{9}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{9}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{9}{ColumnData}[2]{Block} = 2;

$TableBlockNextCalculate{9}{State}             = 1;
$TableBlockNextCalculate{9}{ReturnBlock}       = 2;
$TableBlockNextCalculate{9}{ReturnRowStart}    = 1;
$TableBlockNextCalculate{9}{ReturnColumnStart} = 2;
$TableBlockNextCalculate{9}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest10
$TableBlockNextCalculate{10}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[0][2]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[1][2]{Off}    = 1;
$TableBlockNextCalculate{10}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[2][0]{Off}    = 0;
$TableBlockNextCalculate{10}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{10}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{10}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{10}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{10}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{10}{State}             = 1;
$TableBlockNextCalculate{10}{ReturnBlock}       = 0;
$TableBlockNextCalculate{10}{ReturnRowStart}    = 2;
$TableBlockNextCalculate{10}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{10}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest11
$TableBlockNextCalculate{11}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{11}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[0][2]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{11}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[2][0]{Off}    = 1;
$TableBlockNextCalculate{11}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{11}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{11}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{11}{ColumnData}[1]{Block} = 1;
$TableBlockNextCalculate{11}{ColumnData}[2]{Block} = 1;

$TableBlockNextCalculate{11}{State}             = 1;
$TableBlockNextCalculate{11}{ReturnBlock}       = 1;
$TableBlockNextCalculate{11}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{11}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{11}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest12
$TableBlockNextCalculate{12}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[0][2]{Off}    = 0;
$TableBlockNextCalculate{12}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{12}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[2][0]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[2][1]{Off}    = 1;
$TableBlockNextCalculate{12}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{12}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{12}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{12}{ColumnData}[2]{Block} = 2;

$TableBlockNextCalculate{12}{State}             = 1;
$TableBlockNextCalculate{12}{ReturnBlock}       = 2;
$TableBlockNextCalculate{12}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{12}{ReturnColumnStart} = 2;
$TableBlockNextCalculate{12}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest13
$TableBlockNextCalculate{13}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{13}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{13}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[0][2]{Off}    = 0;
$TableBlockNextCalculate{13}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{13}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{13}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{13}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[2][0]{Off}    = 0;
$TableBlockNextCalculate{13}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{13}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{13}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{13}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{13}{ColumnData}[2]{Block} = 1;

$TableBlockNextCalculate{13}{State}             = 1;
$TableBlockNextCalculate{13}{ReturnBlock}       = 1;
$TableBlockNextCalculate{13}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{13}{ReturnColumnStart} = 2;
$TableBlockNextCalculate{13}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest14
$TableBlockNextCalculate{14}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{14}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{14}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[0][2]{Off}    = 1;
$TableBlockNextCalculate{14}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{14}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{14}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[1][2]{Off}    = 0;
$TableBlockNextCalculate{14}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[2][0]{Off}    = 1;
$TableBlockNextCalculate{14}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[2][1]{Off}    = 0;
$TableBlockNextCalculate{14}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{14}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{14}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{14}{ColumnData}[1]{Block} = 1;
$TableBlockNextCalculate{14}{ColumnData}[2]{Block} = 1;

$TableBlockNextCalculate{14}{State}             = 1;
$TableBlockNextCalculate{14}{ReturnBlock}       = 1;
$TableBlockNextCalculate{14}{ReturnRowStart}    = 1;
$TableBlockNextCalculate{14}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{14}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest15
$TableBlockNextCalculate{15}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[0][2]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[1][2]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[2][0]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[2][1]{Off}    = 1;
$TableBlockNextCalculate{15}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{15}{CellData}[2][2]{Off}    = 0;
$TableBlockNextCalculate{15}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{15}{ColumnData}[2]{Block} = 2;

$TableBlockNextCalculate{15}{State}             = 1;
$TableBlockNextCalculate{15}{ReturnBlock}       = 2;
$TableBlockNextCalculate{15}{ReturnRowStart}    = 2;
$TableBlockNextCalculate{15}{ReturnColumnStart} = 2;
$TableBlockNextCalculate{15}{ReturnColumnStop}  = 2;

# tableblocknextcalculatetest16
$TableBlockNextCalculate{16}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[0][2]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[0][2]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[1][0]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[1][1]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[1][1]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[1][2]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[1][2]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[2][0]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[2][0]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[2][1]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[2][1]{TmpOff} = 0;
$TableBlockNextCalculate{16}{CellData}[2][2]{Off}    = 1;
$TableBlockNextCalculate{16}{CellData}[2][2]{TmpOff} = 0;

$TableBlockNextCalculate{16}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{16}{State}             = 0;
$TableBlockNextCalculate{16}{ReturnBlock}       = 0;
$TableBlockNextCalculate{16}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{16}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{16}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest17
$TableBlockNextCalculate{17}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{17}{CellData}[0][0]{TmpOff} = 1;

$TableBlockNextCalculate{17}{ColumnData}[0]{Block} = 0;

$TableBlockNextCalculate{17}{State}             = 1;
$TableBlockNextCalculate{17}{ReturnBlock}       = 0;
$TableBlockNextCalculate{17}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{17}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{17}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest18
$TableBlockNextCalculate{18}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{18}{CellData}[0][0]{TmpOff} = 1;

$TableBlockNextCalculate{18}{ColumnData}[0][0]{Block} = 0;

$TableBlockNextCalculate{18}{State}             = 0;
$TableBlockNextCalculate{18}{ReturnBlock}       = 0;
$TableBlockNextCalculate{18}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{18}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{18}{ReturnColumnStop}  = 0;

# tableblocknextcalculatetest19
$TableBlockNextCalculate{19}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{19}{CellData}[0][0]{TmpOff} = 1;
$TableBlockNextCalculate{19}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{19}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{19}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{19}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{19}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{19}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{19}{ColumnData}[0]{Block} = 0;
$TableBlockNextCalculate{19}{ColumnData}[1]{Block} = 1;

$TableBlockNextCalculate{19}{State}             = 1;
$TableBlockNextCalculate{19}{ReturnBlock}       = 1;
$TableBlockNextCalculate{19}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{19}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{19}{ReturnColumnStop}  = 1;

# tableblocknextcalculatetest20
$TableBlockNextCalculate{20}{CellData}[0][0]{Off}    = 0;
$TableBlockNextCalculate{20}{CellData}[0][0]{TmpOff} = 1;
$TableBlockNextCalculate{20}{CellData}[0][1]{Off}    = 0;
$TableBlockNextCalculate{20}{CellData}[0][1]{TmpOff} = 1;
$TableBlockNextCalculate{20}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{20}{CellData}[1][0]{TmpOff} = 0;
$TableBlockNextCalculate{20}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{20}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{20}{ColumnData}[0]{Block} = 0;
$TableBlockNextCalculate{20}{ColumnData}[1]{Block} = 0;

$TableBlockNextCalculate{20}{State}             = 1;
$TableBlockNextCalculate{20}{ReturnBlock}       = 0;
$TableBlockNextCalculate{20}{ReturnRowStart}    = 0;
$TableBlockNextCalculate{20}{ReturnColumnStart} = 0;
$TableBlockNextCalculate{20}{ReturnColumnStop}  = 1;

# tableblocknextcalculatetest21
$TableBlockNextCalculate{21}{CellData}[0][0]{Off}    = 1;
$TableBlockNextCalculate{21}{CellData}[0][0]{TmpOff} = 0;
$TableBlockNextCalculate{21}{CellData}[0][1]{Off}    = 1;
$TableBlockNextCalculate{21}{CellData}[0][1]{TmpOff} = 0;
$TableBlockNextCalculate{21}{CellData}[1][0]{Off}    = 0;
$TableBlockNextCalculate{21}{CellData}[1][0]{TmpOff} = 1;
$TableBlockNextCalculate{21}{CellData}[1][1]{Off}    = 0;
$TableBlockNextCalculate{21}{CellData}[1][1]{TmpOff} = 0;

$TableBlockNextCalculate{21}{ColumnData}[0]{Block} = 0;
$TableBlockNextCalculate{21}{ColumnData}[1]{Block} = 1;

$TableBlockNextCalculate{21}{State}             = 1;
$TableBlockNextCalculate{21}{ReturnBlock}       = 1;
$TableBlockNextCalculate{21}{ReturnRowStart}    = 1;
$TableBlockNextCalculate{21}{ReturnColumnStart} = 1;
$TableBlockNextCalculate{21}{ReturnColumnStop}  = 1;

# start testing _TableBlockNextCalculate()
for ( sort keys %TableBlockNextCalculate ) {
    my $Test   = $_;
    my $TestOk = 0;

    my %Return = $PDFObject->_TableBlockNextCalculate(
        CellData   => $TableBlockNextCalculate{$Test}{CellData},
        ColumnData => $TableBlockNextCalculate{$Test}{ColumnData},
    );

    if (
        $Return{State} eq $TableBlockNextCalculate{$Test}{State}
        &&
        $Return{ReturnBlock} eq $TableBlockNextCalculate{$Test}{ReturnBlock}             &&
        $Return{ReturnRowStart} eq $TableBlockNextCalculate{$Test}{ReturnRowStart}       &&
        $Return{ReturnColumnStart} eq $TableBlockNextCalculate{$Test}{ReturnColumnStart} &&
        $Return{ReturnColumnStop} eq $TableBlockNextCalculate{$Test}{ReturnColumnStop}
        )
    {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR _TableBlockNextCalculate$Test State -->$Return{State}\n";
        print "ERROR _TableBlockNextCalculate$Test ReturnBlock -->$Return{ReturnBlock}\n";
        print "ERROR _TableBlockNextCalculate$Test ReturnRowStart -->$Return{ReturnRowStart}\n";
        print
            "ERROR _TableBlockNextCalculate$Test ReturnColumnStart -->$Return{ReturnColumnStart}\n";
        print "ERROR _TableBlockNextCalculate$Test ReturnColumnStop -->$Return{ReturnColumnStop}\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "_TableBlockNextCalculate$Test()",
    );
}

# _TableRowCalculate() tests
my %TableRowCalculate;

# tablerowcalculatetest0
$TableRowCalculate{0}{Border} = 1;

$TableRowCalculate{0}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{0}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{0}{CellData}[0][0]{FontSize} = 14;
$TableRowCalculate{0}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{0}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{0}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{0}{CellData}[0][1]{FontSize} = 10;
$TableRowCalculate{0}{CellData}[0][1]{Lead}     = 2;

$TableRowCalculate{0}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{0}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{0}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{0}{ReturnRowData}[0]{TextHeight}   = 14;
$TableRowCalculate{0}{ReturnRowData}[0]{OutputHeight} = 16;

# tablerowcalculatetest1
$TableRowCalculate{1}{Border}        = 0;
$TableRowCalculate{1}{PaddingTop}    = 2;
$TableRowCalculate{1}{PaddingBottom} = 3;

$TableRowCalculate{1}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{1}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{1}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{1}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{1}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{1}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{1}{CellData}[0][1]{FontSize} = 14;
$TableRowCalculate{1}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{1}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{1}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{1}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{1}{ReturnRowData}[0]{TextHeight}   = 14;
$TableRowCalculate{1}{ReturnRowData}[0]{OutputHeight} = 19;

# tablerowcalculatetest2
$TableRowCalculate{2}{Border} = 0;

$TableRowCalculate{2}{CellData}[0][0]{Content}  = '';
$TableRowCalculate{2}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{2}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{2}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{2}{CellData}[0][1]{Content}  = '';
$TableRowCalculate{2}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{2}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{2}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{2}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{2}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{2}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{2}{ReturnRowData}[0]{TextHeight}   = 11;
$TableRowCalculate{2}{ReturnRowData}[0]{OutputHeight} = 11;

# tablerowcalculatetest3
$TableRowCalculate{3}{Border} = 2;

$TableRowCalculate{3}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{3}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{3}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{3}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{3}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{3}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{3}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{3}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{3}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{3}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{3}{RowData}[0]{Height} = 99;

$TableRowCalculate{3}{ReturnRowData}[0]{Height}       = 99;
$TableRowCalculate{3}{ReturnRowData}[0]{TextHeight}   = 99;
$TableRowCalculate{3}{ReturnRowData}[0]{OutputHeight} = 103;

# tablerowcalculatetest4
$TableRowCalculate{4}{Border} = 2;

$TableRowCalculate{4}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{4}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{4}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{4}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{4}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{4}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{4}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{4}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{4}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{4}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{4}{RowData}[0]{Height} = 0;

$TableRowCalculate{4}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{4}{ReturnRowData}[0]{TextHeight}   = 11;
$TableRowCalculate{4}{ReturnRowData}[0]{OutputHeight} = 15;

# tablerowcalculatetest5
$TableRowCalculate{5}{Border} = 2;

$TableRowCalculate{5}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{5}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{5}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{5}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{5}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{5}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{5}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{5}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{5}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{5}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{5}{RowData}[0]{Height} = 1;

$TableRowCalculate{5}{ReturnRowData}[0]{Height}       = 1;
$TableRowCalculate{5}{ReturnRowData}[0]{TextHeight}   = 1;
$TableRowCalculate{5}{ReturnRowData}[0]{OutputHeight} = 5;

# tablerowcalculatetest6
$TableRowCalculate{6}{Border} = 2;

$TableRowCalculate{6}{CellData}[0][0]{Content}  = 'Cell 1-1';
$TableRowCalculate{6}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{6}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{6}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{6}{CellData}[0][1]{Content}  = 'Cell 1-2';
$TableRowCalculate{6}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{6}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{6}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{6}{ColumnData}[0]{TextWidth} = 1;
$TableRowCalculate{6}{ColumnData}[1]{TextWidth} = 1;

$TableRowCalculate{6}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{6}{ReturnRowData}[0]{TextHeight}   = 11;
$TableRowCalculate{6}{ReturnRowData}[0]{OutputHeight} = 15;

# tablerowcalculatetest7
$TableRowCalculate{7}{Border} = 2;

$TableRowCalculate{7}{CellData}[0][0]{Content}  = 'ISS';
$TableRowCalculate{7}{CellData}[0][0]{Font}     = 'Testfont1';
$TableRowCalculate{7}{CellData}[0][0]{FontSize} = 10;
$TableRowCalculate{7}{CellData}[0][0]{Lead}     = 0;
$TableRowCalculate{7}{CellData}[0][1]{Content}
    = 'Expedition 14 takes over ISS command - The astronauts on board the International Space Station will hold a short ceremony later this evening to mark the change of command from the Expedition 13 to the Expedition 14 crew.';
$TableRowCalculate{7}{CellData}[0][1]{Font}     = 'Testfont1';
$TableRowCalculate{7}{CellData}[0][1]{FontSize} = 11;
$TableRowCalculate{7}{CellData}[0][1]{Lead}     = 5;

$TableRowCalculate{7}{ColumnData}[0]{TextWidth} = 100;
$TableRowCalculate{7}{ColumnData}[1]{TextWidth} = 100;

$TableRowCalculate{7}{ReturnRowData}[0]{Height}       = 0;
$TableRowCalculate{7}{ReturnRowData}[0]{TextHeight}   = 187;
$TableRowCalculate{7}{ReturnRowData}[0]{OutputHeight} = 191;

# start testing TableCalculate()
for ( sort keys %TableRowCalculate ) {
    my $Test   = $_;
    my $TestOk = 0;

    my %TableRowCalculateParams;
    $TableRowCalculateParams{CellData}      = $TableRowCalculate{$Test}{CellData};
    $TableRowCalculateParams{ColumnData}    = $TableRowCalculate{$Test}{ColumnData} || [];
    $TableRowCalculateParams{RowData}       = $TableRowCalculate{$Test}{RowData} || [];
    $TableRowCalculateParams{PaddingTop}    = $TableRowCalculate{$Test}{PaddingTop} || 0;
    $TableRowCalculateParams{PaddingBottom} = $TableRowCalculate{$Test}{PaddingBottom} || 0;
    $TableRowCalculateParams{Border}        = $TableRowCalculate{$Test}{Border} || 0;

    my %Return = $PDFObject->_TableRowCalculate(
        Row => 0,
        %TableRowCalculateParams,
    );

    if (
        $Return{RowData}->[0]->{Height} eq $TableRowCalculate{$Test}{ReturnRowData}[0]{Height}
        &&
        $Return{RowData}->[0]->{TextHeight} eq
        $TableRowCalculate{$Test}{ReturnRowData}[0]{TextHeight}
        &&
        $Return{RowData}->[0]->{OutputHeight} eq
        $TableRowCalculate{$Test}{ReturnRowData}[0]{OutputHeight}
        )
    {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR _TableRowCalculate$Test Height -->$Return{RowData}->[0]->{Height}\n";
        print "ERROR _TableRowCalculate$Test TextHeight -->$Return{RowData}->[0]->{TextHeight}\n";
        print
            "ERROR _TableRowCalculate$Test OutputHeight -->$Return{RowData}->[0]->{OutputHeight}\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "_TableRowCalculate$Test()",
    );
}

# _TableCellOnCount() tests
my %TableCellOnCount;

# tablecelloncounttest0
$TableCellOnCount{0}{CellData}[0][0]{Off} = 0;
$TableCellOnCount{0}{Return} = 1;

# tablecelloncounttest1
$TableCellOnCount{1}{CellData}[0][0]{Off} = 1;
$TableCellOnCount{1}{Return} = 0;

# tablecelloncounttest2
$TableCellOnCount{2}{CellData}[0][0]{Off} = 0;
$TableCellOnCount{2}{CellData}[0][1]{Off} = 0;
$TableCellOnCount{2}{CellData}[1][0]{Off} = 0;
$TableCellOnCount{2}{CellData}[1][1]{Off} = 0;
$TableCellOnCount{2}{Return}              = 4;

# tablecelloncounttest3
$TableCellOnCount{3}{CellData}[0][0]{Off} = 1;
$TableCellOnCount{3}{CellData}[0][1]{Off} = 0;
$TableCellOnCount{3}{CellData}[1][0]{Off} = 0;
$TableCellOnCount{3}{CellData}[1][1]{Off} = 0;
$TableCellOnCount{3}{Return}              = 3;

# tablecelloncounttest4
$TableCellOnCount{4}{CellData}[0][0]{Off} = 1;
$TableCellOnCount{4}{CellData}[0][1]{Off} = 1;
$TableCellOnCount{4}{CellData}[1][0]{Off} = 0;
$TableCellOnCount{4}{CellData}[1][1]{Off} = 0;
$TableCellOnCount{4}{Return}              = 2;

# tablecelloncounttest5
$TableCellOnCount{5}{CellData}[0][0]{Off} = 1;
$TableCellOnCount{5}{CellData}[0][1]{Off} = 1;
$TableCellOnCount{5}{CellData}[1][0]{Off} = 1;
$TableCellOnCount{5}{CellData}[1][1]{Off} = 0;
$TableCellOnCount{5}{Return}              = 1;

# tablecelloncounttest6
$TableCellOnCount{6}{CellData}[0][0]{Off} = 1;
$TableCellOnCount{6}{CellData}[0][1]{Off} = 1;
$TableCellOnCount{6}{CellData}[1][0]{Off} = 1;
$TableCellOnCount{6}{CellData}[1][1]{Off} = 1;
$TableCellOnCount{6}{Return}              = 0;

# start testing TableCellOnCount()
for ( sort keys %TableCellOnCount ) {
    my $Test   = $_;
    my $TestOk = 0;

    my $Return = $PDFObject->_TableCellOnCount(
        CellData => $TableCellOnCount{$Test}{CellData},
    );

    if ( $Return eq $TableCellOnCount{$Test}{Return} ) {
        $TestOk = 1;
    }
    else {
        print "\n";
        print "ERROR _TableCellOnCount$Test Count -->$Return\n";
        print "\n";
    }

    $Self->True(
        $TestOk,
        "_TableCellOnCount$Test()",
    );
}

# charset font test 1 (iso-8859-1)
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::PDF'] );
$PDFObject = $Kernel::OM->Get('Kernel::System::PDF');

# create a pdf document
my $DocumentNew2 = $PDFObject->DocumentNew(
    Title     => 'The Title',
    Encode    => 'latin1',
    Testfonts => 1,
);

$Self->True(
    $DocumentNew2,
    "DocumentNew2()",
);

# create a blank page
my $PageBlankNew2 = $PDFObject->PageBlankNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 50,
    MarginRight  => 50,
    MarginBottom => 50,
    MarginLeft   => 50,
);

$Self->True(
    $PageBlankNew2,
    "PageBlankNew2()",
);

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $Home = $ConfigObject->Get('Home');

my $FileContent1 = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/PDF/PDF-test1-iso-8859-1.txt',
);

my %CharsetTestData1;
$CharsetTestData1{Text} = ${$FileContent1};

$CharsetTestData1{Type}           = 'ReturnLeftOver';
$CharsetTestData1{Font}           = 'Testfont2';
$CharsetTestData1{FontSize}       = 10;
$CharsetTestData1{Lead}           = 0;
$CharsetTestData1{Width}          = 1000;
$CharsetTestData1{Height}         = $CharsetTestData1{FontSize};
$CharsetTestData1{State}          = 1;
$CharsetTestData1{RequiredWidth}  = 46.87;
$CharsetTestData1{RequiredHeight} = 10;
$CharsetTestData1{LeftOver}       = '';

my %ReturnCharsetTestData1 = $PDFObject->Text(
    Text     => $CharsetTestData1{Text},
    Width    => $CharsetTestData1{Width},
    Height   => $CharsetTestData1{Height},
    Font     => $CharsetTestData1{Font},
    FontSize => $CharsetTestData1{FontSize},
    Type     => $CharsetTestData1{Type},
    Lead     => $CharsetTestData1{Lead},
);

my $CharsetTest1Ok = 0;
if (
    $ReturnCharsetTestData1{State} eq $CharsetTestData1{State}
    &&
    $ReturnCharsetTestData1{RequiredWidth} eq $CharsetTestData1{RequiredWidth}   &&
    $ReturnCharsetTestData1{RequiredHeight} eq $CharsetTestData1{RequiredHeight} &&
    $ReturnCharsetTestData1{LeftOver} eq $CharsetTestData1{LeftOver}
    )
{
    $CharsetTest1Ok = 1;
}
else {
    print "\n";
    print "ERROR CharsetTest1 State -->$ReturnCharsetTestData1{State}\n";
    print "ERROR CharsetTest1 RequiredWidth -->$ReturnCharsetTestData1{RequiredWidth}\n";
    print "ERROR CharsetTest1 RequiredHeight -->$ReturnCharsetTestData1{RequiredHeight}\n";
    print "ERROR CharsetTest1 LeftOver -->$ReturnCharsetTestData1{LeftOver}<--\n";
    print "\n";
}

$Self->True(
    $CharsetTest1Ok,
    "CharsetTest1()",
);

# charset font test 2 (utf-8)
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::PDF'] );
$PDFObject = $Kernel::OM->Get('Kernel::System::PDF');

# create a pdf document
my $DocumentNew3 = $PDFObject->DocumentNew(
    Title     => 'The Title',
    Encode    => 'utf-8',
    Testfonts => 1,
);

$Self->True(
    $DocumentNew3,
    "DocumentNew3()",
);

# create a blank page
my $PageBlankNew3 = $PDFObject->PageBlankNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 50,
    MarginRight  => 50,
    MarginBottom => 50,
    MarginLeft   => 50,
);

$Self->True(
    $PageBlankNew3,
    "PageBlankNew3()",
);

my $FileContent2 = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/PDF/PDF-test1-utf-8.txt',
);

my %CharsetTestData2;
$CharsetTestData2{Text} = ${$FileContent2};

$CharsetTestData2{Type}           = 'ReturnLeftOver';
$CharsetTestData2{Font}           = 'Testfont2';
$CharsetTestData2{FontSize}       = 10;
$CharsetTestData2{Lead}           = 0;
$CharsetTestData2{Width}          = 1000;
$CharsetTestData2{Height}         = $CharsetTestData2{FontSize};
$CharsetTestData2{State}          = 1;
$CharsetTestData2{RequiredWidth}  = 46.87;
$CharsetTestData2{RequiredHeight} = 10;
$CharsetTestData2{LeftOver}       = '';

my %ReturnCharsetTestData2 = $PDFObject->Text(
    Text     => $CharsetTestData2{Text},
    Width    => $CharsetTestData2{Width},
    Height   => $CharsetTestData2{Height},
    Font     => $CharsetTestData2{Font},
    FontSize => $CharsetTestData2{FontSize},
    Type     => $CharsetTestData2{Type},
    Lead     => $CharsetTestData2{Lead},
);

my $CharsetTest2Ok = 0;
if (
    $ReturnCharsetTestData2{State} eq $CharsetTestData2{State}
    &&
    $ReturnCharsetTestData2{RequiredWidth} eq $CharsetTestData2{RequiredWidth}   &&
    $ReturnCharsetTestData2{RequiredHeight} eq $CharsetTestData2{RequiredHeight} &&
    $ReturnCharsetTestData2{LeftOver} eq $CharsetTestData2{LeftOver}
    )
{
    $CharsetTest2Ok = 1;
}
else {
    print "\n";
    print "ERROR CharsetTest2 State -->$ReturnCharsetTestData2{State}\n";
    print "ERROR CharsetTest2 RequiredWidth -->$ReturnCharsetTestData2{RequiredWidth}\n";
    print "ERROR CharsetTest2 RequiredHeight -->$ReturnCharsetTestData2{RequiredHeight}\n";
    print "ERROR CharsetTest2 LeftOver -->$ReturnCharsetTestData2{LeftOver}<--\n";
    print "\n";
}

$Self->True(
    $CharsetTest2Ok,
    "CharsetTest2()",
);

# charset font test 3 (utf-8)
$Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::PDF'] );
$PDFObject = $Kernel::OM->Get('Kernel::System::PDF');

# create a pdf document
my $DocumentNew4 = $PDFObject->DocumentNew(
    Title     => 'The Title',
    Encode    => 'utf-8',
    Testfonts => 1,
);

$Self->True(
    $DocumentNew4,
    "DocumentNew4()",
);

# create a blank page
my $PageBlankNew4 = $PDFObject->PageBlankNew(
    Width        => 842,
    Height       => 595,
    MarginTop    => 50,
    MarginRight  => 50,
    MarginBottom => 50,
    MarginLeft   => 50,
);

$Self->True(
    $PageBlankNew4,
    "PageBlankNew4()",
);

my $FileContent3 = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/PDF/PDF-test2-utf-8.txt',
);

my %CharsetTestData3;
$CharsetTestData3{Text} = ${$FileContent3};

$CharsetTestData3{Type}           = 'ReturnLeftOver';
$CharsetTestData3{Font}           = 'Testfont1';
$CharsetTestData3{FontSize}       = 10;
$CharsetTestData3{Lead}           = 0;
$CharsetTestData3{Width}          = 1000;
$CharsetTestData3{Height}         = $CharsetTestData3{FontSize};
$CharsetTestData3{State}          = 1;
$CharsetTestData3{RequiredWidth}  = 88.96;
$CharsetTestData3{RequiredHeight} = 10;
$CharsetTestData3{LeftOver}       = '';

my %ReturnCharsetTestData3 = $PDFObject->Text(
    Text     => $CharsetTestData3{Text},
    Width    => $CharsetTestData3{Width},
    Height   => $CharsetTestData3{Height},
    Font     => $CharsetTestData3{Font},
    FontSize => $CharsetTestData3{FontSize},
    Type     => $CharsetTestData3{Type},
    Lead     => $CharsetTestData3{Lead},
);

my $CharsetTest3Ok = 0;
if (
    $ReturnCharsetTestData3{State} eq $CharsetTestData3{State}
    &&
    $ReturnCharsetTestData3{RequiredWidth} eq $CharsetTestData3{RequiredWidth}   &&
    $ReturnCharsetTestData3{RequiredHeight} eq $CharsetTestData3{RequiredHeight} &&
    $ReturnCharsetTestData3{LeftOver} eq $CharsetTestData3{LeftOver}
    )
{
    $CharsetTest3Ok = 1;
}
else {
    print "\n";
    print "ERROR CharsetTest3 State -->$ReturnCharsetTestData3{State}\n";
    print "ERROR CharsetTest3 RequiredWidth -->$ReturnCharsetTestData3{RequiredWidth}\n";
    print "ERROR CharsetTest3 RequiredHeight -->$ReturnCharsetTestData3{RequiredHeight}\n";
    print "ERROR CharsetTest3 LeftOver -->$ReturnCharsetTestData3{LeftOver}<--\n";
    print "\n";
}

$Self->True(
    $CharsetTest3Ok,
    "CharsetTest3()",
);

# cleanup cache is done by RestoreDatabase

1;
