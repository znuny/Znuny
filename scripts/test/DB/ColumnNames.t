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
# column name tests
# ------------------------------------------------------------ #

my @Tests = (
    {
        Name   => 'SELECT with named columns',
        Data   => 'SELECT id, name FROM permission_groups',
        Result => [qw(id name)],
    },
    {
        Name   => 'SELECT with all columns',
        Data   => 'SELECT * FROM permission_groups',
        Result => [qw(id name comments valid_id create_time create_by change_time change_by)],
    },
    {
        Name   => 'SELECT with unicode characters',
        Data   => 'SELECT name AS äöüüßüöä FROM permission_groups',
        Result => ['äöüüßüöä'],
    },
);

for my $Test (@Tests) {
    my $Result = $DBObject->Prepare(
        SQL => $Test->{Data},
    );
    my @Names = $DBObject->GetColumnNames();

    my $Counter = 0;
    for my $Field ( @{ $Test->{Result} } ) {

        $Self->Is(
            lc $Names[$Counter],
            $Field,
            "GetColumnNames - field $Field - $Test->{Name}",
        );
        $Counter++;
    }
}

1;
