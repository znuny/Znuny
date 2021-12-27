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

my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $EventHandlerObject = $Kernel::OM->Get('Kernel::GenericInterface::Event::Handler');

my $JqIsAvailable = $EventHandlerObject->_IsJqAvailable();
if ( !$JqIsAvailable ) {
    $Self->True(
        1,
        'Jq is not available, skipping tests.',
    );

    return 1;
}

my $ConditionCheck = $EventHandlerObject->_ConditionCheck(
    ConditionLinking => 'and',
    Condition        => {
        1 => {
            Type   => 'and',
            Fields => {
                'jq#.QueueData.Name' => 'Misc',
            },
        },
    },
    Data => {
        QueueData => {
            QueueID => 123,
            Name    => 'Misc',
        },
    },
);

$Self->True(
    $ConditionCheck,
    '_ConditionCheck(jq found queue misc)',
);

$ConditionCheck = $EventHandlerObject->_ConditionCheck(
    ConditionLinking => 'and',
    Condition        => {
        1 => {
            Type   => 'and',
            Fields => {
                'jq#.QueueData.Name' => 'Misc',
            },
        },
    },
    Data => {
        QueueData => {
            QueueID => 123,
        },
    },
);

$Self->False(
    $ConditionCheck,
    '_ConditionCheck(jq did not find queue misc)',
);

$ConditionCheck = $EventHandlerObject->_ConditionCheck(
    ConditionLinking => 'and',
    Condition        => {
        1 => {
            Type   => 'and',
            Fields => {
                'jq#' => 'Misc',
            },
        },
    },
    Data => {
        QueueData => {
            QueueID => 123,
        },
    },
);

$Self->False(
    $ConditionCheck,
    '_ConditionCheck(jq did not find queue misc - empty expression)',
);

1;
