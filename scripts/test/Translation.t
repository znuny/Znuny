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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

my $OTRSRootDir = $ConfigObject->Get('Home');
my @LanguageIDs = ( 'de', 'en', 'bg' );

my @List = $TranslationObject->DataListGet(
    Valid  => 0,
    UserID => 1
);

$Self->IsDeeply(
    \@List,
    [],
    'DataListGet should be empty',
);

# DataAdd
for my $LanguageID (@LanguageIDs) {
    my $CreatedID = $TranslationObject->DataAdd(
        LanguageID      => $LanguageID,
        Source          => 'Dashboard',
        Destination     => 'Dashboard' . $LanguageID,
        ValidID         => 1,
        CreateBy        => 1,
        ChangeBy        => 1,
        DeploymentState => 0,
        UserID          => 1,
    );
}

# DataListGet
@List = $TranslationObject->DataListGet(
    Valid  => 0,
    UserID => 1
);

$Self->IsNotDeeply(
    \@List,
    [],
    'DataListGet should not be empty',
);

# DataDeployment
my $Success = $TranslationObject->DataDeployment(
    UserID => 1,
);

for my $LanguageID (@LanguageIDs) {
    my $File     = $LanguageID . "_zzzTranslationAuto.pm";
    my $FilePath = $OTRSRootDir . '/Kernel/Language/' . $File;

    if ( -e "$FilePath" ) {
        $Self->True(
            $File,
            "File $File exists. ($FilePath)",
        );
    }
    else {
        $Self->True(
            $File,
            "File $File not exists. ($FilePath)",
        );
    }
}

# Export yml
my $ExportYML = $TranslationObject->DataExport(
    Format => 'yml',
    Cache  => 0,
);

$ExportYML =~ s{\'}{}g;

$Self->Is(
    $ExportYML,
    "---
- Destination: Dashboardde
  LanguageID: de
  Source: Dashboard
  ValidID: 1
- Destination: Dashboarden
  LanguageID: en
  Source: Dashboard
  ValidID: 1
- Destination: Dashboardbg
  LanguageID: bg
  Source: Dashboard
  ValidID: 1
",
    'Export',
);

my $YMLString = '---
- Destination: Dashboardde
  LanguageID: de
  Source: Dashboard
- DeploymentState: 1
  Destination: Ticket-de
  LanguageID: de
  Source: Ticket
- DeploymentState: 1
  Destination: Ticket-en
  LanguageID: en
  Source: Ticket
- DeploymentState: 1
  Destination: Ticket-bg
  LanguageID: bg
  Source: Ticket
';

# Import yml
my $ImportYML = $TranslationObject->DataImport(
    Format    => 'yml',
    Content   => $YMLString,
    Overwrite => 1,
    Data      => {
        ValidID => 1,
    },
);

$Self->Is(
    $ImportYML,
    1,
    'Import',
);

@List = $TranslationObject->DataListGet(
    UserID => 1,
    Cache  => 0,
);

# DataDelete
for my $Translation (@List) {
    my $Success = $TranslationObject->DataDelete(
        ID     => $Translation->{ID},
        UserID => 1,
    );

    $Self->True(
        $Success,
        "Translation $Translation->{ID} deleted.",
    );
}

for my $LanguageID (@LanguageIDs) {
    my $File     = $LanguageID . "_zzzTranslationAuto.pm";
    my $FilePath = $OTRSRootDir . '/Kernel/Language/' . $File;

    my $FileExists = -e "$FilePath";
    $Self->True(
        $FileExists,
        "File $File exists. ($FilePath)",
    );
}

1;
