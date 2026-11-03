# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::GenericInterface::Invoker::Ticket::Generic;

my $InvokerObject = bless {}, 'Kernel::GenericInterface::Invoker::Ticket::Generic';

my $Normalized = $InvokerObject->_NormalizeTags(
    Data => {
        OTRS_TicketCreate       => 'from-otrs',
        ZNUNY_TicketTitleUpdate => 'from-znuny',
        OTRS_TicketStateSet     => 'legacy-state',
        ZNUNY_TicketStateSet    => 'canonical-state',
        znuny_TicketQueueSet    => 'mixed-case-queue',
        PlainKey                => 'keep-me',
    },
);

$Self->Is(
    $Normalized->{ZNUNY_TicketCreate},
    'from-otrs',
    'OTRS_TicketCreate becomes ZNUNY_TicketCreate',
);
$Self->Is(
    $Normalized->{ZNUNY_TicketTitleUpdate},
    'from-znuny',
    'ZNUNY_TicketTitleUpdate stays',
);
$Self->Is(
    $Normalized->{ZNUNY_TicketStateSet},
    'canonical-state',
    'When both spellings are present, the ZNUNY value is kept',
);
$Self->Is(
    $Normalized->{ZNUNY_TicketQueueSet},
    'mixed-case-queue',
    'znuny_TicketQueueSet becomes ZNUNY_TicketQueueSet',
);
$Self->Is(
    $Normalized->{PlainKey},
    'keep-me',
    'Non-tag keys stay unchanged',
);
$Self->False(
    exists $Normalized->{OTRS_TicketCreate},
    'Legacy OTRS_TicketCreate key is removed',
);
$Self->False(
    exists $Normalized->{OTRS_TicketStateSet},
    'Legacy OTRS_TicketStateSet key is removed',
);
$Self->False(
    exists $Normalized->{znuny_TicketQueueSet},
    'Mixed-case znuny_ prefix key is removed',
);

1;
