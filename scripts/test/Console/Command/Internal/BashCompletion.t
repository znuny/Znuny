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

my @Tests = (
    {
        Name      => 'Command completion',
        COMP_LINE => 'bin/znuny.Console.pl Hel',
        Arguments => [ 'bin/znuny.Console.pl', 'Hel', 'bin/znuny.Console.pl' ],
        Result    => "Help",
    },
    {
        Name      => 'Argument list',
        COMP_LINE => 'bin/znuny.Console.pl Admin::Article::StorageSwitch ',
        Arguments => [ 'bin/znuny.Console.pl', '', 'Admin::Article::SwitchStorage' ],
        Result    => "--target
--source
--tolerant
--micro-sleep
--force-pid
--tickets-created-before-date
--tickets-created-min-days
--tickets-created-after-date
--tickets-created-max-days
--tickets-closed-before-date
--tickets-closed-min-days
--tickets-closed-after-date
--tickets-closed-max-days",
    },
    {
        Name      => 'Argument list limitted',
        COMP_LINE => 'bin/znuny.Console.pl Admin::Article::StorageSwitch --to',
        Arguments => [ 'bin/znuny.Console.pl', '--to', 'Admin::Article::SwitchStorage' ],
        Result    => "--tolerant",
    },
);

for my $Test (@Tests) {

    my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Internal::BashCompletion');

    my ( $Result, $ExitCode );

    {
        local $ENV{COMP_LINE} = $Test->{COMP_LINE};
        local *STDOUT;
        open STDOUT, '>:utf8', \$Result;    ## no critic
        $ExitCode = $CommandObject->Execute( @{ $Test->{Arguments} } );
    }

    $Self->Is(
        $ExitCode,
        0,
        "$Test->{Name} exit code",
    );

    $Self->Is(
        $Result,
        $Test->{Result},
        "$Test->{Name} result",
    );

}

1;
