# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $CacheObject  = $Kernel::OM->Get('Kernel::System::Cache');

$ConfigObject->Set(
    Key   => 'Ticket::NumberGenerator',
    Value => 'Kernel::System::Ticket::Number::Random',
);
$ConfigObject->Set(
    Key   => 'SystemID',
    Value => 10,
);

# Delete counters
my $Success = $DBObject->Do(
    SQL => 'DELETE FROM ticket_number_counter',
);
$Self->True(
    $Success,
    'Temporary cleared ticket_nuber_counter table',
);

my @Tests = (
    {
        Name => 'TicketNumber with a length of 12.',
    },
);

# Delete current counters.
return if !$DBObject->Do(
    SQL => 'DELETE FROM ticket_number_counter',
);
$CacheObject->CleanUp();

my $TicketNumberGeneratorObject = $Kernel::OM->Get('Kernel::System::Ticket::Number::Random');

for my $Test (@Tests) {

    my $TicketNumber = $TicketNumberGeneratorObject->TicketCreateNumber();

    $Self->Is(
        length $TicketNumber,
        12,
        "$Test->{Name} TicketCreateNumber() length"
    );

    $Self->True(
        IsNumber($TicketNumber),
        "$Test->{Name} TicketCreateNumber() number",
    );
}

1;
