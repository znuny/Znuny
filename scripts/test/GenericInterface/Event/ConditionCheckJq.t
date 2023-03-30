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
my @Tests = (
    {
        Name => 'String _ConditionCheck(jq found queue misc)',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#.QueueData.Name' => {
                            Match => 'Misc',
                            Type  => 'String',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    Name => 'Misc',
                },
            },
        },
        Expected => 1,
    },
    {
        Name => 'String _ConditionCheck(jq did not find queue misc)',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#.QueueData.Name' => {
                            Match => 'Misc',
                            Type  => 'String',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    QueueID => 123,
                },
            },
        },
        Expected => undef,
    },
    {
        Name => 'String _ConditionCheck(jq did not find queue misc - empty expression)',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#' => {
                            Match => 'Misc',
                            Type  => 'String',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    QueueID => 123,
                },
            },
        },
        Expected => undef,
    },
    {
        Name => 'Regexp _ConditionCheck(jq found queue Misc)',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#.QueueData.Name' => {
                            Match => '(Postmaster|Misc)',
                            Type  => 'Regexp',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    Name => 'Misc',
                },
            },
        },
        Expected => 1,
    },
    {
        Name => 'Regexp _ConditionCheck(jq found no queue Postmaster or Raw)',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#.QueueData.Name' => {
                            Match => '(Postmaster|Raw)',
                            Type  => 'Regexp',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    Name => 'Misc',
                },
            },
        },
        Expected => undef,
    },
    {
        Name => 'Regexp _ConditionCheck(jq found queue Postmaster by "master")',
        Data => {
            ConditionLinking => 'and',
            Condition        => {
                1 => {
                    Type   => 'and',
                    Fields => {
                        'jq#.QueueData.Name' => {
                            Match => '(master|Raw)',
                            Type  => 'Regexp',
                        },
                    },
                },
            },
            Data => {
                QueueData => {
                    Name => 'Postmaster',
                },
            },
        },
        Expected => 1,
    },
);

for my $Test (@Tests) {

    my $ConditionCheck = $EventHandlerObject->_ConditionCheck(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $ConditionCheck,
        $Test->{Expected},
        $Test->{Name},
    );
}

1;
