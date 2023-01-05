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

# get DB object
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

# ------------------------------------------------------------ #
# quoting tests
# ------------------------------------------------------------ #
$Self->Is(
    $DBObject->Quote( 0, 'Integer' ),
    0,
    'Quote() Integer - 0',
);
$Self->Is(
    $DBObject->Quote( 1, 'Integer' ),
    1,
    'Quote() Integer - 1',
);
$Self->Is(
    $DBObject->Quote( 123, 'Integer' ),
    123,
    'Quote() Integer - 123',
);
$Self->Is(
    $DBObject->Quote( 61712, 'Integer' ),
    61712,
    'Quote() Integer - 61712',
);
$Self->Is(
    $DBObject->Quote( -61712, 'Integer' ),
    -61712,
    'Quote() Integer - -61712',
);
$Self->Is(
    $DBObject->Quote( '+61712', 'Integer' ),
    '+61712',
    'Quote() Integer - +61712',
);
$Self->Is(
    $DBObject->Quote( '02', 'Integer' ),
    '02',
    'Quote() Integer - 02',
);
$Self->Is(
    $DBObject->Quote( '0000123', 'Integer' ),
    '0000123',
    'Quote() Integer - 0000123',
);

$Self->Is(
    $DBObject->Quote( 123.23, 'Number' ),
    123.23,
    'Quote() Number - 123.23',
);
$Self->Is(
    $DBObject->Quote( 0.23, 'Number' ),
    0.23,
    'Quote() Number - 0.23',
);
$Self->Is(
    $DBObject->Quote( '+123.23', 'Number' ),
    '+123.23',
    'Quote() Number - +123.23',
);
$Self->Is(
    $DBObject->Quote( '+0.23132', 'Number' ),
    '+0.23132',
    'Quote() Number - +0.23132',
);
$Self->Is(
    $DBObject->Quote( '+12323', 'Number' ),
    '+12323',
    'Quote() Number - +12323',
);
$Self->Is(
    $DBObject->Quote( -123.23, 'Number' ),
    -123.23,
    'Quote() Number - -123.23',
);
$Self->Is(
    $DBObject->Quote( -123, 'Number' ),
    -123,
    'Quote() Number - -123',
);
$Self->Is(
    $DBObject->Quote( -0.23, 'Number' ),
    -0.23,
    'Quote() Number - -0.23',
);
$Self->Is(
    $DBObject->Quote( "2022-12-24 12:34:56", 'DateTime' ),
    "2022-12-24 12:34:56",
    'Quote() DateTime 2022-12-24 12:34:56',
);
$Self->False(
    scalar $DBObject->Quote( "2022-12-2432 12:34:56", 'DateTime' ),
    'Quote() DateTime 2022-12-2432 12:34:56',
);
$Self->Is(
    $DBObject->Quote( "2022-12-24", 'Date' ),
    "2022-12-24",
    'Quote() Date 2022-12-24',
);
$Self->False(
    scalar $DBObject->Quote( "2022-12-2432", 'Date' ),
    'Quote() Date 2022-12-2432',
);

if (
    $DBObject->GetDatabaseFunction('Type') eq 'postgresql' ||
    $DBObject->GetDatabaseFunction('Type') eq 'oracle'     ||
    $DBObject->GetDatabaseFunction('Type') eq 'db2'        ||
    $DBObject->GetDatabaseFunction('Type') eq 'ingres'
    )
{
    $Self->Is(
        $DBObject->Quote("Test'l"),
        'Test\'\'l',
        'Quote() String - Test\'l',
    );

    $Self->Is(
        $DBObject->Quote("Test'l;"),
        'Test\'\'l;',
        "Quote() String - Test\'l;",
    );

    $Self->Is(
        $DBObject->Quote( "Block[12]Block[12]", 'Like' ),
        'Block[12]Block[12]',
        'Quote() Like-String - Block[12]Block[12]',
    );
}
elsif ( $DBObject->GetDatabaseFunction('Type') eq 'mssql' ) {
    $Self->Is(
        $DBObject->Quote("Test'l"),
        'Test\'\'l',
        'Quote() String - Test\'l',
    );

    $Self->Is(
        $DBObject->Quote("Test'l;"),
        'Test\'\'l;',
        'Quote() String - Test\'l;',
    );

    $Self->Is(
        $DBObject->Quote( "Block[12]Block[12]", 'Like' ),
        'Block[[]12]Block[[]12]',
        'Quote() Like-String - Block[12]Block[12]',
    );
}
else {
    $Self->Is(
        $DBObject->Quote("Test'l"),
        'Test\\\'l',
        'Quote() String - Test\'l',
    );

    $Self->Is(
        $DBObject->Quote("Test'l;"),
        'Test\\\'l\\;',
        'Quote() String - Test\'l;',
    );

    $Self->Is(
        $DBObject->Quote( "Block[12]Block[12]", 'Like' ),
        'Block[12]Block[12]',
        'Quote() Like-String - Block[12]Block[12]',
    );
}

1;
