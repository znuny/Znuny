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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $ExcelObject  = $Kernel::OM->Get('Kernel::System::Excel');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $StatsObject  = $Kernel::OM->Get('Kernel::System::Stats');

my %DemoData;

# Multiple Worksheet statistic
%{ $DemoData{MultipleWorksheet} } = (
    'Worksheets' => [
        {
            'TableData' => [
                [
                    {
                        'Format' => {
                            'bg_color' => 'silver',
                            'right'    => 1
                        },
                    },
                    {
                        'Format' => {
                            'bg_color' => 'silver',
                            'left'     => 1,
                            'right'    => 1
                        },
                    },
                    {
                        'Format' => {
                            'bg_color' => 'silver',
                            'left'     => 1,
                            'right'    => 1
                        },
                    },
                    {
                        'Value'  => 'Response Time',
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver',
                            'align'    => 'center',
                            'valign'   => 'vcentre'
                        },
                        'Merge' => 1
                    },
                    {
                        'Merge' => 2
                    },
                    {
                        'Merge' => 3
                    },
                    {
                        'Value'  => 'Solution Time',
                        'Merge'  => 1,
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver',
                            'valign'   => 'vcentre',
                            'align'    => 'center'
                        },
                    },
                    {
                        'Merge' => 2
                    },
                    {
                        'Merge' => 3
                    }
                ],
                [
                    {
                        'Format' => {
                            'right'    => 1,
                            'valign'   => 'vcentre',
                            'bottom'   => 1,
                            'align'    => 'center',
                            'bg_color' => 'silver'
                        },
                        'Value' => 'Service'
                    },
                    {
                        'Value'  => 'SLA',
                        'Format' => {
                            'bg_color' => 'silver',
                            'valign'   => 'vcentre',
                            'right'    => 1,
                            'left'     => 1,
                            'bottom'   => 1,
                            'align'    => 'center'
                        },
                    },
                    {
                        'Value'  => '#Tickets',
                        'Format' => {
                            'valign'   => 'vcentre',
                            'right'    => 1,
                            'left'     => 1,
                            'bottom'   => 1,
                            'align'    => 'center',
                            'bg_color' => 'silver'
                        },
                    },
                    {
                        'Value'  => '#IN',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                    },
                    {
                        'Value'  => '%IN',
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                    },
                    {
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                        'Value' => '#OUT'
                    },
                    {
                        'Value'  => '#IN',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                    },
                    {
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                        'Value' => '%IN'
                    },
                    {
                        'Value'  => '#OUT',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                    }
                ],
                [
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 100
                    },
                    {
                        'Value' => 65
                    },
                    {
                        'Value' => '65.0%'
                    },
                    {
                        'Value' => 35
                    },
                    {
                        'Value' => 65
                    },
                    {
                        'Value' => '65.0%'
                    },
                    {
                        'Value' => 35
                    }
                ],
                [
                    {
                        'Format' => {
                            'bottom' => 1,
                            'top'    => 1,
                            'right'  => 1
                        },
                    },
                    {
                        'Format' => {
                            'border' => 1,
                            'bold'   => 1
                        },
                        'Value' => 'Total'
                    },
                    {
                        'Format' => {
                            'bold'   => 1,
                            'border' => 1
                        },
                        'Value' => 100
                    },
                    {
                        'Value'  => 65,
                        'Format' => {
                            'bold'   => 1,
                            'border' => 1
                        },
                    },
                    {
                        'Format' => {
                            'bold'   => 1,
                            'border' => 1,
                            'color'  => 'green'
                        },
                        'Value' => '65.0%'
                    },
                    {
                        'Value'  => 35,
                        'Format' => {
                            'border' => 1,
                            'bold'   => 1
                        },
                    },
                    {
                        'Value'  => 65,
                        'Format' => {
                            'border' => 1,
                            'bold'   => 1
                        },
                    },
                    {
                        'Value'  => '65.0%',
                        'Format' => {
                            'color'  => 'green',
                            'bold'   => 1,
                            'border' => 1
                        },
                    },
                    {
                        'Value'  => 35,
                        'Format' => {
                            'border' => 1,
                            'bold'   => 1
                        },
                    }
                ]
            ],
            'Name'        => 'Overview',
            'FreezePanes' => [
                {
                    'Column' => 0,
                    'Row'    => 2
                }
            ]
        },
        {
            'FreezePanes' => [
                {
                    'Row'    => 1,
                    'Column' => 0
                }
            ],
            'TableData' => [
                [
                    {
                        'Value'  => 'TicketNumber',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1,
                            'align'    => 'center',
                            'valign'   => 'vcentre'
                        },
                    },
                    {
                        'Value'  => 'Title',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1,
                            'align'    => 'center',
                            'valign'   => 'vcentre'
                        },
                    },
                    {
                        'Value'  => 'Service',
                        'Format' => {
                            'align'    => 'center',
                            'valign'   => 'vcentre',
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                    },
                    {
                        'Value'  => 'SLA',
                        'Format' => {
                            'bg_color' => 'silver',
                            'border'   => 1,
                            'valign'   => 'vcentre',
                            'align'    => 'center'
                        },
                    },
                    {
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver',
                            'align'    => 'center',
                            'valign'   => 'vcentre'
                        },
                        'Value' => 'Type'
                    },
                    {
                        'Value'  => 'Owner',
                        'Format' => {
                            'align'    => 'center',
                            'valign'   => 'vcentre',
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                    },
                    {
                        'Format' => {
                            'align'    => 'center',
                            'valign'   => 'vcentre',
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                        'Value' => 'CustomerUserID'
                    },
                    {
                        'Value'  => 'CustomerID',
                        'Format' => {
                            'valign'   => 'vcentre',
                            'align'    => 'center',
                            'border'   => 1,
                            'bg_color' => 'silver'
                        },
                    },
                    {
                        'Value'  => 'FirstResponse',
                        'Format' => {
                            'valign'   => 'vcentre',
                            'align'    => 'center',
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                    },
                    {
                        'Value'  => 'FirstResponseTime',
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver',
                            'valign'   => 'vcentre',
                            'align'    => 'center'
                        },
                    },
                    {
                        'Value'  => 'Solution',
                        'Format' => {
                            'border'   => 1,
                            'bg_color' => 'silver',
                            'align'    => 'center',
                            'valign'   => 'vcentre'
                        },
                    },
                    {
                        'Format' => {
                            'valign'   => 'vcentre',
                            'align'    => 'center',
                            'bg_color' => 'silver',
                            'border'   => 1
                        },
                        'Value' => 'SolutionTime'
                    }
                ],
                [
                    {
                        'Value'         => '2016050754000026',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050754000053'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050754000081',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050754000017'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050754000044',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050754000071',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050754000106'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050754000035'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050754000062'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050754000099',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day10 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050654000091',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050654000028',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050654000055',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050654000082'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050654000019'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050654000046',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050654000073'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050654000108'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050654000037',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050654000064'
                    },
                    {
                        'Value' => 'UnitTestTicket Day9 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000039'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050554000066',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000093'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050554000021',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000057'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000084'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000011'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050554000048',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000075'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050554000101'
                    },
                    {
                        'Value' => 'UnitTestTicket Day8 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000031',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000068',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000095',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050454000022'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050454000059'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050454000086'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000013',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000041',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050454000077'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050454000102',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day7 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000079',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000104',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000033',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000061',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000097',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000024',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000051',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000088',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050354000015'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050354000042',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day6 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050254000017'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000044',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000071',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000106',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000035',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050254000062'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050254000099'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000026',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050254000053',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050254000081'
                    },
                    {
                        'Value' => 'UnitTestTicket Day5 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050154000019'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050154000046',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050154000073',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050154000108'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050154000037',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050154000064',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050154000091'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016050154000028',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050154000055'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016050154000082'
                    },
                    {
                        'Value' => 'UnitTestTicket Day4 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000056',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000083',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000011',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016043054000047'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000074',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016043054000109'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016043054000038'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016043054000065'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000092',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016043054000029',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day3 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '0 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000022',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042954000059'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000086',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000013',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000041',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042954000077'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000102',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000031',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042954000068',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042954000095'
                    },
                    {
                        'Value' => 'UnitTestTicket Day2 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042854000195'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 9'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '6 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000122',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 2'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000159',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 5'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000186',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 8'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '20 minutes'
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042854000113'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 1'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000141',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 4'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000177',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 7'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000202',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 10'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ],
                [
                    {
                        'ContentFormat' => 'String',
                        'Value'         => '2016042854000131'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 3'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '2 minutes'
                    },
                    {
                        'Value' => 'In'
                    },
                    {
                        'Value' => '8 minutes'
                    }
                ],
                [
                    {
                        'Value'         => '2016042854000168',
                        'ContentFormat' => 'String'
                    },
                    {
                        'Value' => 'UnitTestTicket Day1 Number 6'
                    },
                    {
                        'Value' => 'UnitTestServicetest648960397242'
                    },
                    {
                        'Value' => 'UnitTestSLAtest648960397242'
                    },
                    {
                        'Value' => 'Unclassified'
                    },
                    {
                        'Value' => 'test648960397240'
                    },
                    {
                        'Value' => 'test648960397241@localunittest.com'
                    },
                    {
                        'Value' => 'test648960397241'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Format' => {
                            'color' => 'red'
                        },
                        'Value' => '6 minutes'
                    },
                    {
                        'Value' => 'Out'
                    },
                    {
                        'Value'  => '20 minutes',
                        'Format' => {
                            'color' => 'red'
                        },
                    }
                ]
            ],
            'Name' => 'Ticket list'
        }
    ],
    'Stat' => {
        'Format' => [
            'Excel'
        ],
        'Cache'            => '0',
        'StatType'         => 'static',
        'SumRow'           => '0',
        'ObjectBehaviours' => {
            'ProvidesDashboardWidget' => 0
        },
        'Changed'      => '2016-08-31 11:48:22',
        'Title'        => 'TestSLAReport',
        'Valid'        => '1',
        'ObjectModule' => 'Kernel::System::Stats::Static::SLAReport',
        'Created'      => '2016-08-31 11:48:22',
        'ChangedBy'    => '2',
        'CreatedBy'    => '2',
        'File'         => 'SLAReport',
        'Description'  => 'TestSLAReport',
        'StatID'       => '12',
        'SumCol'       => '0',
        'Permission'   => [
            '3'
        ],
        'StatNumber'            => '10012',
        'ShowAsDashboardWidget' => ''
    }
);

# Single Worksheet statistic
%{ $DemoData{SingleWorksheet} } = (
    'Stat' => {
        'StatType'  => 'dynamic',
        'ChangedBy' => '2',
        'Valid'     => '1',
        'Format'    => [
            'CSV',
            'D3::BarChart',
            'D3::LineChart',
            'D3::StackedAreaChart',
            'Excel',
            'Print'
        ],
        'Description' => "Aktueller Status aller im System befindlicher Tickets ohne Zeitbeschr\x{e4}nkung.",
        'Object'      => 'Ticket',
        'Permission'  => [
            '3'
        ],
        'SumRow'           => '1',
        'ObjectName'       => 'TicketAccumulation',
        'Changed'          => '2016-08-18 12:38:34',
        'Title'            => "\x{dc}berblick \x{fc}ber alle Tickets im System",
        'Created'          => '2016-08-18 12:38:34',
        'ObjectBehaviours' => {
            'ProvidesDashboardWidget' => 1
        },
        'ObjectModule' => 'Kernel::System::Stats::Dynamic::Ticket',
        'StatNumber'   => '10011',
        'UseAsXvalue'  => [
            {
                'Block'       => 'MultiSelectField',
                'Name'        => 'Service',
                'Translation' => 0,
                'Values'      => {
                    '683' => 'UnitTestServicetest648960397242'
                },
                'TreeView' => 1,
                'Element'  => 'ServiceIDs'
            },
            {
                'Values' => {
                    '413' => 'UnitTestSLAtest648960397242'
                },
                'Translation' => 0,
                'Element'     => 'SLAIDs',
                'Block'       => 'MultiSelectField',
                'Name'        => 'SLA'
            },
            {
                'Name'        => 'Queue',
                'Block'       => 'MultiSelectField',
                'TreeView'    => 1,
                'Element'     => 'QueueIDs',
                'Translation' => 0,
                'Values'      => {
                    '4' => 'Misc',
                    '3' => 'Junk',
                    '2' => 'Raw',
                    '1' => 'Postmaster'
                }
            },
            {
                'Fixed'       => 1,
                'Selected'    => 1,
                'Name'        => 'State',
                'Element'     => 'StateIDs',
                'Translation' => 1,
                'Values'      => {
                    '2' => 'closed successful',
                    '1' => 'new',
                    '7' => 'pending auto close+',
                    '6' => 'pending reminder',
                    '4' => 'open',
                    '9' => 'merged',
                    '5' => 'removed',
                    '8' => 'pending auto close-',
                    '3' => 'closed unsuccessful'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Translation' => 1,
                'Values'      => {
                    '7' => 'merged',
                    '1' => 'new',
                    '6' => 'removed',
                    '2' => 'open',
                    '4' => 'pending reminder',
                    '3' => 'closed',
                    '5' => 'pending auto'
                },
                'Block'   => 'MultiSelectField',
                'Name'    => 'State Type',
                'Element' => 'StateTypeIDs'
            },
            {
                'Name'        => 'Priority',
                'Element'     => 'PriorityIDs',
                'Translation' => 1,
                'Values'      => {
                    '5' => '5 very high',
                    '3' => '3 normal',
                    '4' => '4 high',
                    '2' => '2 low',
                    '1' => '1 very low'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Name'     => 'Created in Queue',
                'Block'    => 'MultiSelectField',
                'Element'  => 'CreatedQueueIDs',
                'TreeView' => 1,
                'Values'   => {
                    '4' => 'Misc',
                    '3' => 'Junk',
                    '2' => 'Raw',
                    '1' => 'Postmaster'
                },
                'Translation' => 0
            },
            {
                'Translation' => 1,
                'Values'      => {
                    '5' => '5 very high',
                    '3' => '3 normal',
                    '4' => '4 high',
                    '2' => '2 low',
                    '1' => '1 very low'
                },
                'Block'   => 'MultiSelectField',
                'Name'    => 'Created Priority',
                'Element' => 'CreatedPriorityIDs'
            },
            {
                'Name'        => 'Created State',
                'Element'     => 'CreatedStateIDs',
                'Translation' => 1,
                'Block'       => 'MultiSelectField',
                'Values'      => {
                    '2' => 'closed successful',
                    '1' => 'new',
                    '7' => 'pending auto close+',
                    '6' => 'pending reminder',
                    '4' => 'open',
                    '9' => 'merged',
                    '5' => 'removed',
                    '8' => 'pending auto close-',
                    '3' => 'closed unsuccessful'
                },
            },
            {
                'Element' => 'LockIDs',
                'Name'    => 'Lock',
                'Values'  => {
                    '3' => 'tmp_lock',
                    '1' => 'unlock',
                    '2' => 'lock'
                },
                'Block'       => 'MultiSelectField',
                'Translation' => 1
            },
            {
                'Block'            => 'Time',
                'Name'             => 'Create Time',
                'TimePeriodFormat' => 'DateInputFormat',
                'Values'           => {
                    'TimeStop'  => 'TicketCreateTimeOlderDate',
                    'TimeStart' => 'TicketCreateTimeNewerDate'
                },
                'Translation' => 1,
                'TimeStop'    => '2016-09-09 23:59:59',
                'Element'     => 'CreateTime'
            },
            {
                'Name'             => 'Last changed times',
                'TimePeriodFormat' => 'DateInputFormat',
                'Block'            => 'Time',
                'TimeStop'         => '2016-09-09 23:59:59',
                'Element'          => 'LastChangeTime',
                'Translation'      => 1,
                'Values'           => {
                    'TimeStart' => 'TicketLastChangeTimeNewerDate',
                    'TimeStop'  => 'TicketLastChangeTimeOlderDate'
                }
            },
            {
                'Block'            => 'Time',
                'TimePeriodFormat' => 'DateInputFormat',
                'Name'             => 'Change times',
                'Values'           => {
                    'TimeStop'  => 'TicketChangeTimeOlderDate',
                    'TimeStart' => 'TicketChangeTimeNewerDate'
                },
                'Translation' => 1,
                'Element'     => 'ChangeTime',
                'TimeStop'    => '2016-09-09 23:59:59'
            },
            {
                'Block'            => 'Time',
                'Name'             => 'Close Time',
                'TimePeriodFormat' => 'DateInputFormat',
                'Translation'      => 1,
                'Values'           => {
                    'TimeStop'  => 'TicketCloseTimeOlderDate',
                    'TimeStart' => 'TicketCloseTimeNewerDate'
                },
                'TimeStop' => '2016-09-09 23:59:59',
                'Element'  => 'CloseTime2'
            },
            {
                'TimeStop'    => '2016-09-09 23:59:59',
                'Element'     => 'EscalationTime',
                'Translation' => 1,
                'Values'      => {
                    'TimeStop'  => 'TicketEscalationTimeOlderDate',
                    'TimeStart' => 'TicketEscalationTimeNewerDate'
                },
                'Name'             => 'Escalation',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Block'            => 'Time'
            },
            {
                'Translation' => 1,
                'Values'      => {
                    'TimeStart' => 'TicketEscalationResponseTimeNewerDate',
                    'TimeStop'  => 'TicketEscalationResponseTimeOlderDate'
                },
                'Element'          => 'EscalationResponseTime',
                'TimeStop'         => '2016-09-09 23:59:59',
                'Block'            => 'Time',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - First Response Time'
            },
            {
                'Element'  => 'EscalationUpdateTime',
                'TimeStop' => '2016-09-09 23:59:59',
                'Values'   => {
                    'TimeStop'  => 'TicketEscalationUpdateTimeOlderDate',
                    'TimeStart' => 'TicketEscalationUpdateTimeNewerDate'
                },
                'Translation'      => 1,
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - Update Time',
                'Block'            => 'Time'
            },
            {
                'Element'  => 'EscalationSolutionTime',
                'TimeStop' => '2016-09-09 23:59:59',
                'Values'   => {
                    'TimeStop'  => 'TicketEscalationSolutionTimeOlderDate',
                    'TimeStart' => 'TicketEscalationSolutionTimeNewerDate'
                },
                'Translation'      => 1,
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - Solution Time',
                'Block'            => 'Time'
            },
            {
                'Block'  => 'MultiSelectField',
                'Values' => {
                    'customer-1@localhost' => 'customer-1@localhost',
                    'test648960397241'     => 'test648960397241'
                },
                'Translation' => 1,
                'Element'     => 'CustomerID',
                'Name'        => 'CustomerID'
            },
            {
                'Block'          => 'MultiSelectField',
                'Name'           => 'TestDD',
                'Translation'    => 0,
                'IsDynamicField' => 1,
                'Values'         => {
                    '3' => 'Drei',
                    '1' => 'Eins',
                    '2' => 'Zwei'
                },
                'ShowAsTree' => 0,
                'Element'    => 'DynamicField_TestDD'
            },
            {
                'Block'            => 'Time',
                'Name'             => 'TestDT',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Translation'      => 1,
                'Values'           => {
                    'TimeStart' => 'DynamicField_TestDT_GreaterThanEquals',
                    'TimeStop'  => 'DynamicField_TestDT_SmallerThanEquals'
                },
                'Element' => 'DynamicField_TestDT'
            }
        ],
        'Cache'            => '0',
        'StatID'           => '11',
        'UseAsValueSeries' => [
            {
                'Name'        => 'Service',
                'Block'       => 'MultiSelectField',
                'Element'     => 'ServiceIDs',
                'TreeView'    => 1,
                'Translation' => 0,
                'Values'      => {
                    '683' => 'UnitTestServicetest648960397242'
                }
            },
            {
                'Name'    => 'SLA',
                'Block'   => 'MultiSelectField',
                'Element' => 'SLAIDs',
                'Values'  => {
                    '413' => 'UnitTestSLAtest648960397242'
                },
                'Translation' => 0
            },
            {
                'Translation' => 0,
                'Values'      => {
                    '3' => 'Junk',
                    '4' => 'Misc',
                    '2' => 'Raw',
                    '1' => 'Postmaster'
                },
                'Selected' => 1,
                'TreeView' => 1,
                'Element'  => 'QueueIDs',
                'Fixed'    => 1,
                'Block'    => 'MultiSelectField',
                'Name'     => 'Queue'
            },
            {
                'Translation' => 1,
                'Values'      => {
                    '6' => 'removed',
                    '7' => 'merged',
                    '1' => 'new',
                    '2' => 'open',
                    '4' => 'pending reminder',
                    '3' => 'closed',
                    '5' => 'pending auto'
                },
                'Block'   => 'MultiSelectField',
                'Name'    => 'State Type',
                'Element' => 'StateTypeIDs'
            },
            {
                'Translation' => 1,
                'Values'      => {
                    '5' => '5 very high',
                    '3' => '3 normal',
                    '4' => '4 high',
                    '2' => '2 low',
                    '1' => '1 very low'
                },
                'Block'   => 'MultiSelectField',
                'Name'    => 'Priority',
                'Element' => 'PriorityIDs'
            },
            {
                'Translation' => 0,
                'Values'      => {
                    '3' => 'Junk',
                    '4' => 'Misc',
                    '2' => 'Raw',
                    '1' => 'Postmaster'
                },
                'TreeView' => 1,
                'Element'  => 'CreatedQueueIDs',
                'Block'    => 'MultiSelectField',
                'Name'     => 'Created in Queue'
            },
            {
                'Element' => 'CreatedPriorityIDs',
                'Name'    => 'Created Priority',
                'Values'  => {
                    '5' => '5 very high',
                    '3' => '3 normal',
                    '4' => '4 high',
                    '2' => '2 low',
                    '1' => '1 very low'
                },
                'Block'       => 'MultiSelectField',
                'Translation' => 1
            },
            {
                'Name'        => 'Created State',
                'Element'     => 'CreatedStateIDs',
                'Translation' => 1,
                'Values'      => {
                    '4' => 'open',
                    '7' => 'pending auto close+',
                    '1' => 'new',
                    '6' => 'pending reminder',
                    '2' => 'closed successful',
                    '3' => 'closed unsuccessful',
                    '9' => 'merged',
                    '8' => 'pending auto close-',
                    '5' => 'removed'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Name'        => 'Lock',
                'Element'     => 'LockIDs',
                'Translation' => 1,
                'Values'      => {
                    '3' => 'tmp_lock',
                    '2' => 'lock',
                    '1' => 'unlock'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Block'  => 'MultiSelectField',
                'Values' => {
                    'test648960397241'     => 'test648960397241',
                    'customer-1@localhost' => 'customer-1@localhost'
                },
                'Translation' => 1,
                'Element'     => 'CustomerID',
                'Name'        => 'CustomerID'
            },
            {
                'Element'        => 'DynamicField_TestDD',
                'ShowAsTree'     => 0,
                'Translation'    => 0,
                'IsDynamicField' => 1,
                'Values'         => {
                    '3' => 'Drei',
                    '1' => 'Eins',
                    '2' => 'Zwei'
                },
                'Name'  => 'TestDD',
                'Block' => 'MultiSelectField'
            }
        ],
        'UseAsRestriction' => [
            {
                'Block'  => 'MultiSelectField',
                'Name'   => 'Service',
                'Values' => {
                    '683' => 'UnitTestServicetest648960397242'
                },
                'Translation' => 0,
                'Element'     => 'ServiceIDs',
                'TreeView'    => 1
            },
            {
                'Block'       => 'MultiSelectField',
                'Name'        => 'SLA',
                'Translation' => 0,
                'Values'      => {
                    '413' => 'UnitTestSLAtest648960397242'
                },
                'Element' => 'SLAIDs'
            },
            {
                'Name'    => 'State Type',
                'Element' => 'StateTypeIDs',
                'Values'  => {
                    '7' => 'merged',
                    '1' => 'new',
                    '6' => 'removed',
                    '2' => 'open',
                    '3' => 'closed',
                    '4' => 'pending reminder',
                    '5' => 'pending auto'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Name'    => 'Priority',
                'Element' => 'PriorityIDs',
                'Values'  => {
                    '1' => '1 very low',
                    '2' => '2 low',
                    '4' => '4 high',
                    '3' => '3 normal',
                    '5' => '5 very high'
                },
                'Block' => 'MultiSelectField'
            },
            {
                'Name'     => 'Created in Queue',
                'Block'    => 'MultiSelectField',
                'TreeView' => 1,
                'Element'  => 'CreatedQueueIDs',
                'Values'   => {
                    '4' => 'Misc',
                    '3' => 'Junk',
                    '1' => 'Postmaster',
                    '2' => 'Raw'
                },
                'Translation' => 0
            },
            {
                'Values' => {
                    '1' => '1 very low',
                    '2' => '2 low',
                    '4' => '4 high',
                    '3' => '3 normal',
                    '5' => '5 very high'
                },
                'Block'   => 'MultiSelectField',
                'Name'    => 'Created Priority',
                'Element' => 'CreatedPriorityIDs'
            },
            {
                'Values' => {
                    '3' => 'closed unsuccessful',
                    '9' => 'merged',
                    '8' => 'pending auto close-',
                    '5' => 'removed',
                    '6' => 'pending reminder',
                    '7' => 'pending auto close+',
                    '1' => 'new',
                    '2' => 'closed successful',
                    '4' => 'open'
                },
                'Block'   => 'MultiSelectField',
                'Element' => 'CreatedStateIDs',
                'Name'    => 'Created State'
            },
            {
                'Element' => 'LockIDs',
                'Name'    => 'Lock',
                'Block'   => 'MultiSelectField',
                'Values'  => {
                    '3' => 'tmp_lock',
                    '1' => 'unlock',
                    '2' => 'lock'
                }
            },
            {
                'Name'    => 'Title',
                'Element' => 'Title',
                'Block'   => 'InputField'
            },
            {
                'Block'   => 'InputField',
                'Name'    => 'CustomerUserLogin',
                'Element' => 'CustomerUserLogin'
            },
            {
                'Block'   => 'InputField',
                'Element' => 'From',
                'Name'    => 'From'
            },
            {
                'Element' => 'To',
                'Name'    => 'To',
                'Block'   => 'InputField'
            },
            {
                'Element' => 'Cc',
                'Name'    => 'Cc',
                'Block'   => 'InputField'
            },
            {
                'Name'    => 'Subject',
                'Element' => 'Subject',
                'Block'   => 'InputField'
            },
            {
                'Block'   => 'InputField',
                'Element' => 'Body',
                'Name'    => 'Text'
            },
            {
                'Block'            => 'Time',
                'Name'             => 'Create Time',
                'TimePeriodFormat' => 'DateInputFormat',
                'Values'           => {
                    'TimeStart' => 'TicketCreateTimeNewerDate',
                    'TimeStop'  => 'TicketCreateTimeOlderDate'
                },
                'Element'  => 'CreateTime',
                'TimeStop' => '2016-09-09 23:59:59'
            },
            {
                'Block'            => 'Time',
                'Name'             => 'Last changed times',
                'TimePeriodFormat' => 'DateInputFormat',
                'Values'           => {
                    'TimeStart' => 'TicketLastChangeTimeNewerDate',
                    'TimeStop'  => 'TicketLastChangeTimeOlderDate'
                },
                'TimeStop' => '2016-09-09 23:59:59',
                'Element'  => 'LastChangeTime'
            },
            {
                'Block'            => 'Time',
                'Name'             => 'Change times',
                'TimePeriodFormat' => 'DateInputFormat',
                'Values'           => {
                    'TimeStart' => 'TicketChangeTimeNewerDate',
                    'TimeStop'  => 'TicketChangeTimeOlderDate'
                },
                'TimeStop' => '2016-09-09 23:59:59',
                'Element'  => 'ChangeTime'
            },
            {
                'Element'  => 'CloseTime2',
                'TimeStop' => '2016-09-09 23:59:59',
                'Values'   => {
                    'TimeStop'  => 'TicketCloseTimeOlderDate',
                    'TimeStart' => 'TicketCloseTimeNewerDate'
                },
                'TimePeriodFormat' => 'DateInputFormat',
                'Name'             => 'Close Time',
                'Block'            => 'Time'
            },
            {
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation',
                'Block'            => 'Time',
                'TimeStop'         => '2016-09-09 23:59:59',
                'Element'          => 'EscalationTime',
                'Values'           => {
                    'TimeStop'  => 'TicketEscalationTimeOlderDate',
                    'TimeStart' => 'TicketEscalationTimeNewerDate'
                }
            },
            {
                'Block'            => 'Time',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - First Response Time',
                'Values'           => {
                    'TimeStop'  => 'TicketEscalationResponseTimeOlderDate',
                    'TimeStart' => 'TicketEscalationResponseTimeNewerDate'
                },
                'TimeStop' => '2016-09-09 23:59:59',
                'Element'  => 'EscalationResponseTime'
            },
            {
                'Block'            => 'Time',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - Update Time',
                'Values'           => {
                    'TimeStop'  => 'TicketEscalationUpdateTimeOlderDate',
                    'TimeStart' => 'TicketEscalationUpdateTimeNewerDate'
                },
                'Element'  => 'EscalationUpdateTime',
                'TimeStop' => '2016-09-09 23:59:59'
            },
            {
                'Block'            => 'Time',
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'Escalation - Solution Time',
                'Values'           => {
                    'TimeStart' => 'TicketEscalationSolutionTimeNewerDate',
                    'TimeStop'  => 'TicketEscalationSolutionTimeOlderDate'
                },
                'Element'  => 'EscalationSolutionTime',
                'TimeStop' => '2016-09-09 23:59:59'
            },
            {
                'Block'  => 'MultiSelectField',
                'Values' => {
                    'customer-1@localhost' => 'customer-1@localhost',
                    'test648960397241'     => 'test648960397241'
                },
                'Name'    => 'CustomerID',
                'Element' => 'CustomerID'
            },
            {
                'Block'   => 'InputField',
                'Element' => 'DynamicField_ProcessManagementProcessID',
                'Name'    => 'Process'
            },
            {
                'Block'   => 'InputField',
                'Element' => 'DynamicField_ProcessManagementActivityID',
                'Name'    => 'Activity'
            },
            {
                'Element' => 'DynamicField_TestText',
                'Name'    => 'TestText',
                'Block'   => 'InputField'
            },
            {
                'Block'       => 'MultiSelectField',
                'Name'        => 'TestDD',
                'Translation' => 0,
                'Values'      => {
                    '3' => 'Drei',
                    '1' => 'Eins',
                    '2' => 'Zwei'
                },
                'IsDynamicField' => 1,
                'ShowAsTree'     => 0,
                'Element'        => 'DynamicField_TestDD'
            },
            {
                'Element' => 'DynamicField_TestDT',
                'Values'  => {
                    'TimeStop'  => 'DynamicField_TestDT_SmallerThanEquals',
                    'TimeStart' => 'DynamicField_TestDT_GreaterThanEquals'
                },
                'TimePeriodFormat' => 'DateInputFormatLong',
                'Name'             => 'TestDT',
                'Block'            => 'Time'
            }
        ],
        'SumCol'    => '1',
        'CreatedBy' => '2'
    },
    'FormatDefinition' => undef,
    'Data'             => [
        [
            'Queue',
            'open',
            'closed successful',
            'pending auto close+',
            'pending reminder',
            'new',
            'removed',
            'pending auto close-',
            'merged',
            'closed unsuccessful',
            'Sum'
        ],
        [
            'Junk',
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ],
        [
            'Misc',
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ],
        [
            'Postmaster',
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ],
        [
            'Raw',
            0,
            '102',
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            102
        ],
        [
            'Sum',
            0,
            102,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            102
        ],
    ],
);

# Working part
# (subs in unittests would have to be created above the executing calls
#  that's why subs for getting the demo data wouldn't make it more readable...)

for my $Key ( sort keys %DemoData ) {
    my $FilePath = '/tmp/';
    my $FileName = "$Key.xlsx";

    my $Output = $ExcelObject->Array2Excel(
        %{ $DemoData{$Key} },
    );

    my $FileLocation = $MainObject->FileWrite(
        Directory => $FilePath,
        Filename  => "$Key.xlsx",
        Content   => \$Output,
    );

    my $Success = 0;
    $Success = 1 if ( -e $FilePath . $FileName );

    $Self->True(
        $Success,
        'Created Excel Sheet successfully: ' . $FilePath . $FileName,
    );
}

# FormatDefinition
my $FormatDefinitionYAML = '---
Name: Worksheet
FreezePanes:
  - Column: 0
    Row: 1
1:
  Format:
    align: center
    bg_color: silver
    bold: 1
    border: 1
    valign: vcentre
A1:
    Format:
        bg_color: green
D:
  Format:
    align: center
    bold: 1
    color: red
    valign: vcentre
H:
  Format:
    align: center
    bold: 1
    bg_color: ccffff
    color: ED053B
    valign: vcentre
B3:
  Format:
    bold: 1
LASTROW:
  Format:
    bold: 1
    bottom: 1
LASTCOLUMN:
  Format:
    border: 1';

my $StatID = $StatsObject->StatsAdd(
    UserID => 1,
);

my $HashNew = $StatsObject->StatsGet(
    StatID => $StatID,
);
my $Hash = $StatsObject->StatsGet(
    StatID => '1',
);

$StatsObject->StatsUpdate(
    StatID => $StatID,
    Hash   => {
        %{$Hash},
        %{$HashNew},
    },
    UserID => 1,
);

my $Stat = $Kernel::OM->Get('Kernel::System::Stats')->StatsGet(
    StatID => $StatID,
    UserID => 1,
);

my $FormatDefinitionFileLocation = $ConfigObject->Get('Home')
    . '/var/stats/formatdefinition/excel/'
    . $Stat->{StatNumber} . '.yml';

my $FileLocation = $MainObject->FileWrite(
    Location => $FormatDefinitionFileLocation,
    Content  => \$FormatDefinitionYAML,
);

my $FormatDefinition = $ExcelObject->GetFormatDefinition(
    Stat => $Stat,
);

$Self->IsDeeply(
    $FormatDefinition,
    {
        'Name'        => 'Worksheet',
        'FreezePanes' => [
            {
                'Column' => '0',
                'Row'    => '1'
            }
        ],
        'LASTCOLUMN' => {
            'Format' => {
                'border' => '1'
            }
        },
        'LASTROW' => {
            'Format' => {
                'bold'   => '1',
                'bottom' => '1'
            }
        },
        '1' => {
            'Format' => {
                'align'    => 'center',
                'bg_color' => 'silver',
                'bold'     => '1',
                'border'   => '1',
                'valign'   => 'vcentre'
            }
        },
        'A1' => {
            'Format' => {
                'bg_color' => 'green',
            }
        },
        'B3' => {
            'Format' => {
                'bold' => '1'
            }
        },
        'D' => {
            'Format' => {
                'align'  => 'center',
                'bold'   => '1',
                'color'  => 'red',
                'valign' => 'vcentre'
            }
        },
        'H' => {
            'Format' => {
                'align'    => 'center',
                'bg_color' => 'ccffff',
                'bold'     => '1',
                'color'    => 'ED053B',
                'valign'   => 'vcentre'
            }
        },
    },
    'FormatDefinition',
);

my $Success = $MainObject->FileDelete(
    Location        => $FileLocation,
    DisableWarnings => 1,
);

# ColumnContentFormat
# String URL DateTime Number

my @Tests = (
    {
        Name => 'ColumnContentFormat - String',
        Data => {
            Value => 'Test',
        },
        Expected => {
            ColumnContentFormat => 'String',
        }
    },
    {
        Name => 'ColumnContentFormat - String',
        Data => {
            Value => 'Test 123',
        },
        Expected => {
            ColumnContentFormat => 'String',
        }
    },
    {
        Name => 'ColumnContentFormat - String',
        Data => {
            Value => '123 test',
        },
        Expected => {
            ColumnContentFormat => 'String',
        }
    },
    {
        Name => 'ColumnContentFormat - URL',
        Data => {
            Value => 'https://www.znuny.com/',
        },
        Expected => {
            ColumnContentFormat => 'URL',
        }
    },
    {
        Name => 'ColumnContentFormat - URL',
        Data => {
            Value => 'http://www.znuny.com/',
        },
        Expected => {
            ColumnContentFormat => 'URL',
        }
    },
    {
        Name => 'ColumnContentFormat - URL = String',
        Data => {
            Value => 'www.znuny.com',
        },
        Expected => {
            ColumnContentFormat => 'String',
        }
    },
    {
        Name => 'ColumnContentFormat - DateTime',
        Data => {
            Value => '2016-01-14 17:06:57',
        },
        Expected => {
            ColumnContentFormat => 'DateTime',
        }
    },
    {
        Name => 'ColumnContentFormat - DateTime',
        Data => {
            Value => '2016-01-14',
        },
        Expected => {
            ColumnContentFormat => 'DateTime',
        }
    },
    {
        Name => 'ColumnContentFormat - DateTime',
        Data => {
            Value => '2016-2016-2016',
        },
        Expected => {
            ColumnContentFormat => 'String',
        }
    },
    {
        Name => 'ColumnContentFormat - Number',
        Data => {
            Value => '2016',
        },
        Expected => {
            ColumnContentFormat => 'Number',
        }
    },
    {
        Name => 'ColumnContentFormat - Number',
        Data => {
            Value => '-2016',
        },
        Expected => {
            ColumnContentFormat => 'Number',
        }
    },
    {
        Name => 'ColumnContentFormat - Number',
        Data => {
            Value => ' -2016 ',
        },
        Expected => {
            ColumnContentFormat => 'Number',
        }
    },
);

for my $Test (@Tests) {

    my $ColumnContentFormat = $ExcelObject->GetColumnContentFormat(
        Value  => $Test->{Data}->{Value},
        Format => $Test->{Data}->{Format},
    );

    $Self->Is(
        $ColumnContentFormat,
        $Test->{Expected}->{ColumnContentFormat},
        $Test->{Name} . ' - ' . $Test->{Data}->{Value},
    );
}

# MergeFormatDefinitions
@Tests = (
    {
        Name => 'undef',
        Data => {
            Merge             => undef,    # $WorksheetFormatDefinition{MergeFormatDefinitions},
            FormatDefinitions => [
                undef,                     # $CellFormatDefinition{Format},
                undef,                     # $RowFormatDefinition{Format},
                undef,                     # $ColumnFormatDefinition{Format},
                undef,                     # $Merge{Format},
                undef,                     # $CellData{Format},
                undef,                     # $DefaultFormatDefinition{Format},
            ],
        },
        Expected => {},
    },
    {
        Name => 'CellFormatDefinition',
        Data => {
            Merge             => undef,    # $WorksheetFormatDefinition{MergeFormatDefinitions},
            FormatDefinitions => [

                # $CellFormatDefinition{Format},
                {
                    'color' => 'silver',
                    'right' => 1
                },
                undef,                     # $RowFormatDefinition{Format},
                undef,                     # $ColumnFormatDefinition{Format},
                undef,                     # $Merge{Format},
                undef,                     # $CellData{Format},
                undef,                     # $DefaultFormatDefinition{Format},
            ],
        },
        Expected => {
            'color' => 'silver',
            'right' => 1
        },
    },
    {
        Name => 'CellFormatDefinition + RowFormatDefinition',
        Data => {
            Merge             => undef,    # $WorksheetFormatDefinition{MergeFormatDefinitions},
            FormatDefinitions => [

                # $CellFormatDefinition{Format},
                {
                    'color' => 'silver',
                    'right' => 1,
                },

                # $RowFormatDefinition{Format},
                {
                    'color' => 'red',
                    'right' => 0,
                    'bold'  => 1,
                },
                undef,    # $ColumnFormatDefinition{Format},
                undef,    # $Merge{Format},
                undef,    # $CellData{Format},
                undef,    # $DefaultFormatDefinition{Format},
            ],
        },
        Expected => {
            'color' => 'silver',
            'right' => 1
        },
    },
    {
        Name => 'CellFormatDefinition + RowFormatDefinition',
        Data => {
            Merge             => 1,    # $WorksheetFormatDefinition{MergeFormatDefinitions},
            FormatDefinitions => [

                # $CellFormatDefinition{Format},
                {
                    'color'  => 'silver',
                    'right'  => 1,
                    'valign' => 'vcentre',
                },

                # $RowFormatDefinition{Format},
                {
                    'color' => 'red',
                    'right' => 0,
                    'bold'  => 1,
                },
                undef,    # $ColumnFormatDefinition{Format},
                undef,    # $Merge{Format},
                undef,    # $CellData{Format},
                undef,    # $DefaultFormatDefinition{Format},
            ],
        },
        Expected => {
            'color'  => 'silver',
            'right'  => 1,
            'bold'   => 1,
            'valign' => 'vcentre',
        },
    },
);
for my $Test (@Tests) {
    my %Format = $ExcelObject->MergeFormatDefinitions(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        \%Format,
        $Test->{Expected},
        'MergeFormatDefinitions - ' . $Test->{Name},
    );
}

# GetColumnIdentifierByNumber
@Tests = (
    {
        Name => '1:A',
        Data => {
            ColumnNumber => 1,
        },
        Expected => 'A',
    },
    {
        Name => '6:F',
        Data => {
            ColumnNumber => 6,
        },
        Expected => 'F',
    },
    {
        Name => '26:Z',
        Data => {
            ColumnNumber => 26,
        },
        Expected => 'Z',
    },
    {
        Name => '27:AA',
        Data => {
            ColumnNumber => 27,
        },
        Expected => 'AA',
    },
    {
        Name => '53:BA',
        Data => {
            ColumnNumber => 53,
        },
        Expected => 'BA',
    },
    {
        Name => '54:BB',
        Data => {
            ColumnNumber => 54,
        },
        Expected => 'BB',
    },
);

for my $Test (@Tests) {
    my $ColumnIdentifier = $ExcelObject->GetColumnIdentifierByNumber(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $ColumnIdentifier,
        $Test->{Expected},
        'GetColumnIdentifierByNumber - ' . $Test->{Name},
    );
}

# _ReplaceDataSeries
@Tests = (
    {
        Name => 'LastRow 123:undef',
        Data => {
            Type    => 'LastRow',
            LastRow => '123',
            Value   => undef,
        },
        Expected => undef,
    },
    {
        Name => 'LastRow 123:abc',
        Data => {
            Type    => 'LastRow',
            LastRow => '123',
            Value   => 'abc',
        },
        Expected => 'abc',
    },
    {
        Name => 'LastRow 123:abc',
        Data => {
            Type    => 'LastRow',
            LastRow => '123',
            Value   => 'LASTROW',
        },
        Expected => '123',
    },
    {
        Name => 'LastColumn 123:undef',
        Data => {
            Type       => 'LastColumn',
            LastColumn => '123',
            Value      => undef,
        },
        Expected => undef,
    },
    {
        Name => 'LastColumn 123:abc',
        Data => {
            Type       => 'LastColumn',
            LastColumn => '123',
            Value      => 'abc',
        },
        Expected => 'abc',
    },
    {
        Name => 'LastColumn 123:abc',
        Data => {
            Type       => 'LastColumn',
            LastColumn => '123',
            Value      => 'LASTCOLUMN',
        },
        Expected => '123',
    },
);

for my $Test (@Tests) {
    my $Value = $ExcelObject->_ReplaceDataSeries(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $Value,
        $Test->{Expected},
        '_ReplaceDataSeries - ' . $Test->{Name},
    );
}

1;
