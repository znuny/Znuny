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

# get needed objects
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @Tests = (
    {
        Name          => "No 'Parameter'",
        CommandModule => 'Kernel::System::Console::Command::Help',
        ExitCode      => 1,
        STDERR        => "Error: please provide a value for argument 'command'",
    },
    {
        Name          => "Non functional 'Parameter'",
        CommandModule => 'Kernel::System::Console::Command::Help',
        Parameter     => 'Help',
        ExitCode      => 0,
        STDOUT        => 'otrs.Console.pl Help command',
    },
    {
        Name          => "Functional 'Parameter'",
        CommandModule => 'Kernel::System::Console::Command::Help',
        Parameter     => 'Lis',
        ExitCode      => 0,
        STDOUT        => 'List all installed packages',
    },
    {
        Name          => "Expected invalid 'Parameter'",
        CommandModule => 'Kernel::System::Console::Command::Help',
        Parameter     => 'NonExistingSearchTerm',
        ExitCode      => 0,
        STDOUT        => 'No commands found.',
    },
    {
        Name          => "Expected list 'Parameter'",
        CommandModule => 'Kernel::System::Console::Command::Maint::Cache::Delete',
        Parameter     => [ '--type', 'Znuny' ],
        ExitCode      => 0,
        STDOUT        => 'Deleting cache...',
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
