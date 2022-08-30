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

# get DB object
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

my @Tests = (
    {
        Name          => 'Single 500',
        Repetitions   => [500],
        OracleSuccess => 1,
    },
    {
        Name          => 'Single 999',
        Repetitions   => [999],
        OracleSuccess => 1,
    },
    {
        Name          => 'Single 1000',
        Repetitions   => [1000],
        OracleSuccess => 1,
    },
    {
        Name          => 'Single 1001',
        Repetitions   => [1001],
        OracleSuccess => 0,
    },
    {
        Name          => 'Single 1100',
        Repetitions   => [1100],
        OracleSuccess => 0,
    },
    {
        Name          => 'Double 200, 200',
        Repetitions   => [ 200, 200 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Double 500, 500',
        Repetitions   => [ 500, 500 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Double 999, 999',
        Repetitions   => [ 999, 999 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Double 500, 1000',
        Repetitions   => [ 500, 1000 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Double 500, 1000',
        Repetitions   => [ 500, 1001 ],
        OracleSuccess => 0,
    },
    {
        Name          => 'Double 1000, 1000',
        Repetitions   => [ 1000, 1000 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Double 1001, 1001',
        Repetitions   => [ 1001, 1001 ],
        OracleSuccess => 0,
    },
    {
        Name          => 'Triple 100, 200, 300',
        Repetitions   => [ 100, 200, 300 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 300, 300, 399',
        Repetitions   => [ 300, 300, 399 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 500, 500, 500',
        Repetitions   => [ 500, 500, 500 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 999, 999, 999',
        Repetitions   => [ 900, 999, 999 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 500, 500, 1000',
        Repetitions   => [ 500, 500, 1000 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 500, 500, 1001',
        Repetitions   => [ 500, 500, 1001 ],
        OracleSuccess => 0,
    },
    {
        Name          => 'Triple 1000, 1000, 1000',
        Repetitions   => [ 1000, 1000, 1000 ],
        OracleSuccess => 1,
    },
    {
        Name          => 'Triple 1001, 1001, 1001',
        Repetitions   => [ 1001, 1001, 1001 ],
        OracleSuccess => 0,
    },
);

my $BaseSQL = '
    SELECT t.tn
    FROM ticket t
    WHERE t.id IN
';

for my $Test (@Tests) {

    my $SQL = $BaseSQL;

    my $Counter = 0;
    for my $RepetitionItem ( @{ $Test->{Repetitions} } ) {

        my @TicketIDs = (1) x $RepetitionItem;

        my $TicketIDsStr = join ',', @TicketIDs;
        if ( $Counter == 0 ) {
            $SQL .= " ( $TicketIDsStr )";
        }
        else {
            $SQL .= "
                OR t.id IN ( $TicketIDsStr )
            ";
        }
        $Counter++;
    }

    my $Success = $DBObject->Prepare(
        SQL   => $SQL,
        Limit => 1,
    );

    if (
        $DBObject->GetDatabaseFunction('Type') eq 'oracle'
        && !$Test->{OracleSuccess}
        )
    {
        $Self->False(
            $Success,
            "$Test->{Name} SQL IN condition - Executed with False",
        );
    }
    else {
        $Self->True(
            $Success,
            "$Test->{Name} SQL IN condition - Executed with True",
        );
    }
}

1;
