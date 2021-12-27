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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');

my @Tests = (
    {
        Name      => 'Non Existing Directory',
        Directory => 'UnitTest/NonExistingDir',
        Type      => 'False',
    },
    {
        Name    => 'Valid YAML but no Process',
        Process => {
            Name     => 'ZnunyProcessTest',
            FilePath => 'ValidYAMLNoProcess.yml'
        },
        Type => 'False',
    },
    {
        Name    => 'Valid YAML but no Process Name',
        Process => {
            Name     => 'ZnunyProcessTest',
            FilePath => 'ValidYAMLNoProcessName.yml'
        },
        Type => 'False',
    },
    {
        Name    => 'Valid YAML with missing Activity',
        Process => {
            Name     => 'ZnunyProcessTest',
            FilePath => 'ValidYAMLMissingActivity.yml'
        },
        Type => 'False',
    },
    {
        Name      => 'Valid Process',
        Directory => 'UnitTest/ValidProcess',
        Type      => 'True',
    },
    {
        Name    => 'Process exists',
        Process => {
            Name     => 'ZnunyProcessTest',
            FilePath => 'ProcessExists.yml'
        },
        Type => 'False',
    },
);

for my $Test (@Tests) {

    my $Success = 0;
    if ( $Test->{Directory} ) {
        $Success = $ZnunyHelperObject->_ProcessCreateIfNotExists(
            SubDir => $Test->{Directory},
        );

    }
    elsif ( IsHashRefWithData( $Test->{Process} ) ) {
        $Success = $ZnunyHelperObject->_ProcessCreateIfNotExists(
            $Test->{Name} => $Test->{FilePath},
        );
    }

    if ( $Test->{Type} eq 'True' ) {
        $Self->True(
            $Success,
            $Test->{Name},
        );
    }
    elsif ( $Test->{Type} eq 'False' ) {
        $Self->False(
            $Success,
            $Test->{Name},
        );
    }
}

1;
