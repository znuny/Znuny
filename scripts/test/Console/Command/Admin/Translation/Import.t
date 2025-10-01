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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @Tests = (
    {
        Name          => "Import file.",
        CommandModule => 'Kernel::System::Console::Command::Admin::Translation::Import',
        Parameter     => ['scripts/test/sample/Translation/translations.yml'],
        ExitCode      => 0,
        STDOUT        => 'Import...',
        STDERR        => undef,
    },
    {
        Name          => "Import file with overwrite.",
        CommandModule => 'Kernel::System::Console::Command::Admin::Translation::Import',
        Parameter     => [ 'scripts/test/sample/Translation/translations.yml', '--overwrite' ],
        ExitCode      => 0,
        STDOUT        => 'Import...',
        STDERR        => undef,
    },
);

for my $Test (@Tests) {

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => $Test->{CommandModule},
        Parameter     => $Test->{Parameter},
    );

    $Self->True(
        scalar IsHashRefWithData($Result),
        "ConsoleCommand returns a HashRef with data ($Test->{Name})",
    ) || return 1;

    $Self->Is(
        $Result->{ExitCode},
        $Test->{ExitCode},
        "Expected ExitCode ($Test->{Name})",
    );

    STD:
    for my $STD (qw(STDOUT STDERR)) {

        next STD if !IsStringWithData( $Test->{$STD} );

        $Self->True(
            index( $Result->{$STD}, $Test->{$STD} ) > -1,
            "$STD contains '$Test->{ $STD }' ($Test->{Name})",
        );
    }
}

1;
