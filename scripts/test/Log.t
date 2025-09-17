# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
#

use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'MinimumLogLevel',
    Value => 'debug'
);
my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

my @Tests = qw( Error Notice Info Debug );

TEST:
for my $Test (@Tests) {
    my $Method = $LogObject->can($Test);

    $Self->True(
        scalar $Method,
        "$Test method found",
    );

    $LogObject->CleanUp();

    $LogObject->$Method("test-$Test");

    next TEST if $Test eq 'Debug';

    $Self->True(
        scalar( $LogObject->GetLog() =~ m{test-$Test} ),
        "$Test logged",
    );
}

1;
