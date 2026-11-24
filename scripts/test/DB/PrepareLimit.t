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

my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

my $SQL = 'SELECT id FROM valid';

my @InvalidValues = (
    {
        Name  => 'statement separator',
        Value => '1;SELECT 1',
    },
    {
        Name  => 'subquery',
        Value => '(SELECT 1)',
    },
    {
        Name  => 'negative',
        Value => '-1',
    },
    {
        Name  => 'fraction',
        Value => '1.5',
    },
    {
        Name  => 'trailing newline',
        Value => "10\n",
    },
);

for my $InvalidValue (@InvalidValues) {
    my $Success = $DBObject->Prepare(
        SQL   => $SQL,
        Limit => $InvalidValue->{Value},
    );
    $Self->False(
        $Success,
        "Prepare() rejects Limit ($InvalidValue->{Name})",
    );

    my $ErrorMessage = $LogObject->GetLogEntry(
        Type => 'error',
        What => 'Message',
    );
    $Self->Is(
        $ErrorMessage,
        'Limit must be a non-negative integer!',
        "Prepare() logs invalid Limit ($InvalidValue->{Name})",
    );

    $Success = $DBObject->Prepare(
        SQL   => $SQL,
        Limit => 1,
        Start => $InvalidValue->{Value},
    );
    $Self->False(
        $Success,
        "Prepare() rejects Start ($InvalidValue->{Name})",
    );

    $ErrorMessage = $LogObject->GetLogEntry(
        Type => 'error',
        What => 'Message',
    );
    $Self->Is(
        $ErrorMessage,
        'Start must be a non-negative integer!',
        "Prepare() logs invalid Start ($InvalidValue->{Name})",
    );
}

my $Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => ( '9' x 30 ),
    Start => ( '9' x 30 ),
);
$Self->False(
    $Success,
    'Prepare() rejects Limit+Start that does not stay an integer literal',
);
$Self->Is(
    $LogObject->GetLogEntry(
        Type => 'error',
        What => 'Message',
    ),
    'Limit must be a non-negative integer!',
    'Prepare() logs Limit+Start overflow',
);

$Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => 0,
);
$Self->True(
    $Success,
    'Prepare() accepts Limit 0',
);

my $UnlimitedRowCount = 0;
while ( my @Row = $DBObject->FetchrowArray() ) {
    $UnlimitedRowCount++ if $Row[0];
}
$Self->True(
    $UnlimitedRowCount > 1,
    'Prepare() Limit 0 does not add a limit clause',
);

$Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => 1,
);
$Self->True(
    $Success,
    'Prepare() accepts Limit 1',
);

my $LimitedRowCount = 0;
while ( my @Row = $DBObject->FetchrowArray() ) {
    $LimitedRowCount++ if $Row[0];
}
$Self->Is(
    $LimitedRowCount,
    1,
    'Prepare() Limit 1 returns one row',
);

$Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => '01',
);
$Self->True(
    $Success,
    'Prepare() accepts a leading-zero Limit',
);

my $LeadingZeroRowCount = 0;
while ( my @Row = $DBObject->FetchrowArray() ) {
    $LeadingZeroRowCount++ if $Row[0];
}
$Self->Is(
    $LeadingZeroRowCount,
    1,
    'Prepare() leading-zero Limit returns one row',
);

$Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => 1,
    Start => 1,
);
$Self->True(
    $Success,
    'Prepare() accepts Limit 1 and Start 1',
);

my $StartRowCount = 0;
while ( my @Row = $DBObject->FetchrowArray() ) {
    $StartRowCount++ if $Row[0];
}
$Self->Is(
    $StartRowCount,
    1,
    'Prepare() Limit 1 and Start 1 returns one row',
);

$Success = $DBObject->Prepare(
    SQL   => $SQL,
    Limit => 100_000_000,
);
$Self->True(
    $Success,
    'Prepare() accepts a large integer Limit',
);

1;
