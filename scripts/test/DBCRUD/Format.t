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

use Kernel::System::ObjectManager;
use Kernel::System::VariableCheck qw(:all);

my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
my $DBCRUDFormatObject = $Kernel::OM->Get('Kernel::System::DBCRUD::Format');

my $Home = $ConfigObject->Get('Home');

$ConfigObject->{'UnitTestDBCRUD'} = {};

my $YMLString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.yml',
);

my $YAMLContent = $DBCRUDFormatObject->GetContent(
    Format    => 'yml',
    Content   => ${$YMLString},
    Overwrite => 1,
);

$Self->IsDeeply(
    $YAMLContent,
    [
        {
            'Age'         => '88',
            'Description' => 'description yaml 88',
            'Name'        => 'yaml 88'
        },
        {
            'Age'         => '99',
            'Description' => 'description yaml 99',
            'Name'        => 'yaml 99'
        }
    ],
    'YAMLContent',
);

my $CSVString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.csv',
);

# Content csv
my $CSVContent = $DBCRUDFormatObject->GetContent(
    Format    => 'CSV',
    Content   => ${$CSVString},
    Overwrite => 1,
);

$Self->IsDeeply(
    $CSVContent,
    [
        {
            'Age'         => '11',
            'Description' => 'description csv 11',
            'Name'        => 'csv 11'
        },
        {
            'Age'         => '22',
            'Description' => 'description csv 22',
            'Name'        => 'csv 22'
        }
    ],
    'CSVContent',
);

# Content Excel
my $ExcelString = $MainObject->FileRead(
    Location => $Home . '/scripts/test/sample/DBCRUD/example.xlsx',
);

my $ExcelContent = $DBCRUDFormatObject->GetContent(
    Format    => 'Excel',
    Content   => ${$ExcelString},
    Overwrite => 1,
);

$Self->IsDeeply(
    $ExcelContent,
    [
        {
            'Age'         => '33',
            'Description' => 'excel description',
            'Name'        => 'excel 1'
        },
        {
            'Age'         => '44',
            'Description' => 'excel description',
            'Name'        => 'excel 2'
        }
    ],
    'ExcelContent',
);

1;
