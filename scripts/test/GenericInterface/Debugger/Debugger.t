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

# get web service object
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();

my $WebserviceID = $WebserviceObject->WebserviceAdd(
    Config => {
        Debugger => {
            DebugThreshold => 'debug',
            TestMode       => 1,
        },
        Provider => {
            Transport => {
                Type => '',
            },
        },
    },
    Name    => "$RandomID web service",
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $WebserviceID,
    "WebserviceAdd()",
);

# first test the debugger in general
# a few tests to instantiate incorrectly
my $DebuggerObject;
eval {
    $DebuggerObject = Kernel::GenericInterface::Debugger->new();
};
$Self->False(
    ref $DebuggerObject,
    'DebuggerObject instantiate with objects, no options',
);

eval {
    $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig => {
            DebugThreshold => 'debug',
            TestMode       => 1,
        },
    );
};
$Self->False(
    ref $DebuggerObject,
    'DebuggerObject instantiate without WebserviceID',
);

eval {
    $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        WebserviceID => $WebserviceID,
    );
};
$Self->False(
    ref $DebuggerObject,
    'DebuggerObject instantiate without DebuggerConfig',
);

eval {
    $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig => {
            TestMode => 1,
        },
        CommunicationType => 'Provider',
        WebserviceID      => $WebserviceID,
    );
};
$Self->True(
    ref $DebuggerObject,
    'DebuggerObject instantiate without DebugThreshold',
);

eval {
    $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig => {
            DebugThreshold => 'nonexistinglevel',
            TestMode       => 1,
        },
        CommunicationType => 'Provider',
        WebserviceID      => $WebserviceID,
    );
};
$Self->False(
    ref $DebuggerObject,
    'DebuggerObject instantiate with non existing DebugThreshold',
);

# correctly now
$DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'notice',
        TestMode       => 1,
    },
    WebserviceID      => $WebserviceID,
    CommunicationType => 'Provider',
);
$Self->Is(
    ref $DebuggerObject,
    'Kernel::GenericInterface::Debugger',
    'DebuggerObject instantiate correctly',
);

my $Result;

# log without Summary
eval {
    $Result = $DebuggerObject->DebugLog() || 0;
};
$Self->False(
    $Result,
    'DebuggerObject call without summary',
);

# log with incorrect debug level
eval {
    $Result = $DebuggerObject->DebugLog(
        Summary    => 'an entry with incorrect debug level',
        DebugLevel => 'notexistingdebuglevel',
    ) || 0;
};
$Self->False(
    $Result,
    'DebuggerObject call with invalid debug level',
);

# log correctly
$Result = $DebuggerObject->DebugLog(
    Summary    => 'a correct entry',
    DebugLevel => 'debug',
) || 0;
$Self->True(
    $Result,
    'DebuggerObject correct call',
);

# log with custom functions - debug level should be overwritten by function
$Result = $DebuggerObject->Error(
    Summary    => 'a correct entry',
    DebugLevel => 'notexistingbutshouldnotbeused',
) || 0;
$Self->True(
    $Result,
    'DebuggerObject call to custom function error, debug level should be overwritten',
);
$Result = $DebuggerObject->Debug(
    Summary    => 'a correct entry',
    DebugLevel => 'notexistingbutshouldnotbeused',
) || 0;
$Self->True(
    $Result,
    'DebuggerObject call to custom function debug',
);
$Result = $DebuggerObject->Info(
    Summary    => 'a correct entry',
    DebugLevel => 'notexistingbutshouldnotbeused',
) || 0;
$Self->True(
    $Result,
    'DebuggerObject call to custom function debug',
);
$Result = $DebuggerObject->Notice(
    Summary    => 'a correct entry',
    DebugLevel => 'notexistingbutshouldnotbeused',
) || 0;
$Self->True(
    $Result,
    'DebuggerObject call to custom function debug',
);

# delete config
my $Success = $WebserviceObject->WebserviceDelete(
    ID     => $WebserviceID,
    UserID => 1,
);

$Self->True(
    $Success,
    "WebserviceDelete()",
);

# Extra tests for check values in DB
#debug|info|notice|error
my @Tests = (
    {
        Name              => 'Test 1',
        DebugThreshold    => 'debug',
        CommunicationType => 'Provider',
        SuccessDebug      => '1',
        SuccessInfo       => '1',
        SuccessNotice     => '1',
        SuccessError      => '1',
        Summary           => 'log Summary',
        Data              => 'specific information',
    },
    {
        Name              => 'Test 2',
        DebugThreshold    => 'info',
        CommunicationType => 'Provider',
        SuccessDebug      => '0',
        SuccessInfo       => '1',
        SuccessNotice     => '1',
        SuccessError      => '1',
        Summary           => 'log Summary',
        Data              => 'specific information',
    },
    {
        Name              => 'Test 3',
        DebugThreshold    => 'notice',
        CommunicationType => 'Provider',
        SuccessDebug      => '0',
        SuccessInfo       => '0',
        SuccessNotice     => '1',
        SuccessError      => '1',
        Summary           => 'log Summary',
        Data              => 'specific information',
    },
    {
        Name              => 'Test 4',
        DebugThreshold    => 'error',
        CommunicationType => 'Provider',
        SuccessDebug      => '0',
        SuccessInfo       => '0',
        SuccessNotice     => '0',
        SuccessError      => '1',
        Summary           => 'log Summary',
        Data              => 'specific information',
    },
);

#my @DebugLogIDs;
for my $Test (@Tests) {
    my $SuccessCounter = 0;

    $RandomID = $HelperObject->GetRandomID();

    my $WebserviceID = $WebserviceObject->WebserviceAdd(
        Config => {
            Debugger => {
                DebugThreshold => 'debug',
                TestMode       => 1,
            },
            Provider => {
                Transport => {
                    Type => '',
                },
            },
        },
        Name    => "$RandomID web service",
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $WebserviceID,
        "WebserviceAdd()",
    );

    # debugger object
    $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig => {
            DebugThreshold => $Test->{DebugThreshold},
            TestMode       => 0,
        },
        WebserviceID      => $WebserviceID,
        CommunicationType => $Test->{CommunicationType},
    );

    for my $DebugLevel (qw( Debug Info Notice Error )) {
        $Result = $DebuggerObject->$DebugLevel(
            Summary => $Test->{Summary} . $DebugLevel,
            Data    => $Test->{Data} . $DebugLevel,
        ) || 0;
        $SuccessCounter++ if $Test->{"Success$DebugLevel"};
    }

    # test LogGetWithData
    my $LogData = $Kernel::OM->Get('Kernel::System::GenericInterface::DebugLog')->LogGetWithData(
        CommunicationID => $DebuggerObject->{CommunicationID},
    );
    $Self->Is(
        ref $LogData,
        'HASH',
        "$Test->{Name} - LogGetWithData()",
    );
    $Self->Is(
        ref $LogData->{Data},
        'ARRAY',
        "$Test->{Name} - LogGetWithData() - Data",
    );

    $Self->Is(
        $LogData->{CommunicationID},
        $DebuggerObject->{CommunicationID},
        "$Test->{Name} - LogGet() - CommunicationID",
    );
    $Self->Is(
        $LogData->{WebserviceID},
        $WebserviceID,
        "$Test->{Name} - LogGet() - WebserviceID",
    );
    $Self->Is(
        $LogData->{CommunicationType},
        $Test->{CommunicationType},
        "$Test->{Name} - LogGet() - CommunicationType",
    );

    my $Counter = 0;
    for my $DebugLevel (qw( Debug Info Notice Error )) {
        my $AuxData       = $Test->{Data} . $DebugLevel;
        my $AuxSummary    = $Test->{Summary} . $DebugLevel;
        my $AuxDebugLevel = $DebugLevel;
        for my $DataFromDB ( @{ $LogData->{Data} } ) {
            if (
                $DataFromDB->{Data} eq $AuxData       &&
                $DataFromDB->{Summary} eq $AuxSummary &&
                $DataFromDB->{DebugLevel} eq lc $AuxDebugLevel
                )
            {
                $Counter++;
            }
        }
    }

    $Self->Is(
        scalar @{ $LogData->{Data} },
        $SuccessCounter,
        "$Test->{Name} - Expected entries compared with entries from DB.",
    );

    $Self->Is(
        scalar @{ $LogData->{Data} },
        $Counter,
        "$Test->{Name} - Compare entries from DB with expected data.",
    );

}

# cleanup is done by RestoreDatabase.

1;
