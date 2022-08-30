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

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation;

# get helper object
# skip SSL certificate verification
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => 1,
    CommunicationType => 'Provider',
);

# create a operation instance
my $OperationObject = Kernel::GenericInterface::Operation->new(
    DebuggerObject => $DebuggerObject,
    WebserviceID   => 1,
    Operation      => 'Test',
    OperationType  => 'Test::Test',
);
$Self->Is(
    ref $OperationObject,
    'Kernel::GenericInterface::Operation',
    'OperationObject was correctly instantiated',
);

my @OperationTests = (
    {
        Data => {
            one   => 'one',
            two   => 'two',
            three => 'three',
            four  => 'four',
            five  => 'five',
        },
        ResultData => {
            one   => 'one',
            two   => 'two',
            three => 'three',
            four  => 'four',
            five  => 'five',
        },
        ResultSuccess => 1,
    },
    {
        Data          => [],
        ResultData    => undef,
        ResultSuccess => 0,
    },
    {
        Data          => undef,
        ResultData    => undef,
        ResultSuccess => 1,
    },
    {
        Data          => {},
        ResultData    => {},
        ResultSuccess => 1,
    },
    {
        Data => {
            TestError => 123,
            ErrorData => {
                Value1 => 1,
                Value2 => 2,
                Value3 => 3,
            },
        },
        ResultData => {
            ErrorData => {
                Value1 => 1,
                Value2 => 2,
                Value3 => 3,
            },
        },
        ResultErrorMessage => 'Error message for error code: 123',
        ResultSuccess      => 0,
    },
);

my $Counter;
for my $Test (@OperationTests) {
    $Counter++;
    my $OperationResult = $OperationObject->Run(
        Data => $Test->{Data},
    );

    # check if function return correct status
    $Self->Is(
        $OperationResult->{Success},
        $Test->{ResultSuccess},
        'Test data set ' . $Counter . ' Test: Success.',
    );

    # check if function return correct data
    $Self->IsDeeply(
        $OperationResult->{Data},
        $Test->{ResultData},
        'Test data set ' . $Counter . ' Test: Data Structure.',
    );

    if ( !$OperationResult->{Success} && $Test->{ResultErrorMessage} ) {
        $Self->Is(
            $OperationResult->{ErrorMessage},
            $Test->{ResultErrorMessage},
            'Test data set ' . $Counter . ' Test: Error Message.',
        );
    }
}

1;
