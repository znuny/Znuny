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

# provide no objects
my $DebugLogObject;

# with just objects
$DebugLogObject = $Kernel::OM->Get('Kernel::System::GenericInterface::DebugLog');
$Self->Is(
    ref $DebugLogObject,
    'Kernel::System::GenericInterface::DebugLog',
    'DebugLog::new() constructor failure, just objects.',
);

my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
my $SystemTime = $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch();

my @Tests = (

    {
        Name   => 'Without WebserviceID',
        Config => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Provider',       # 'Provider' or 'Requester'
            RemoteIP          => '192.168.0.1',    # optional
            DebugLevel        => 'info',
            Summary           => 'log Summary',
        },
        ArrayData => {
            {
                Data => 'specific information',
            },
        },
        SuccessAdd => 0,
    },
    {
        Name   => 'Without CommunicationID',
        Config => {
            WebserviceID      => $WebserviceID,
            CommunicationType => 'Provider',       # 'Provider' or 'Requester'
            RemoteIP          => '192.168.0.1',    # optional
            DebugLevel        => 'info',
            Summary           => 'log Summary',
        },
        ArrayData => {
            {
                Data => 'specific information',
            },
        },
        SuccessAdd => 0,
    },
    {
        Name   => 'Without CommunicationType',
        Config => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            WebserviceID => $WebserviceID,
            RemoteIP     => '192.168.0.1',
            DebugLevel   => 'info',
            Summary      => 'log Summary',
        },
        ArrayData => {
            {
                Data => 'specific information',
            },
        },
        SuccessAdd => 0,
    },
    {
        Name   => 'Without RemoteIP',
        Config => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            WebserviceID      => $WebserviceID,
            CommunicationType => 'Provider',
            DebugLevel        => 'info',
            Summary           => 'log Summary',
        },
        ArrayData => {
            {
                Data => 'specific information',
            },
        },
        SuccessAdd => 1,
    },
    {
        Name       => 'With empty data',
        SuccessAdd => '1',
        Config     => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Provider',
            RemoteIP          => '192.168.0.1',
            WebserviceID      => $WebserviceID,
            DebugLevel        => 'info',
            Summary           => 'log Summary',
        },
        ArrayData => {
            Data => '',
        },
    },
    {
        Name       => 'Complete params',
        SuccessAdd => '1',
        Config     => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Provider',
            RemoteIP          => '192.168.0.1',
            WebserviceID      => $WebserviceID,
            DebugLevel        => 'debug',
            Summary           => 'log Summary for DebugLevel - debug',
        },
        ArrayData => {
            Data1 => 'something to write here',
            Data2 => 'a nice data structure',
            Data3 => 'specific information',
        },
    },
    {
        Name       => 'Complete params',
        SuccessAdd => '1',
        Config     => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Provider',
            RemoteIP          => '',
            WebserviceID      => $WebserviceID,
            DebugLevel        => 'info',
            Summary           => 'log Summary for DebugLevel - info',
        },
        ArrayData => {
            Value1 => 'this should be a string',
            Value2 => 'later I will check this string',
        },
    },
    {
        Name       => 'Complete params',
        SuccessAdd => '1',
        Config     => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Requester',
            RemoteIP          => '192.168.0.1',
            WebserviceID      => $WebserviceID,
            DebugLevel        => 'notice',
            Summary           => 'log Summary for DebugLevel - notice',
        },
        ArrayData => {
            Data1 => 'nothing special here',
            Data3 => 'now is a requester',
        },
    },
    {
        Name       => 'Complete params',
        SuccessAdd => '1',
        Config     => {
            CommunicationID => $MainObject->MD5sum(
                String => $SystemTime . $HelperObject->GetRandomID(),
            ),
            CommunicationType => 'Requester',
            RemoteIP          => '',
            WebserviceID      => $WebserviceID,
            DebugLevel        => 'error',
            Summary           => 'log Summary for DebugLevel - error',
        },
        ArrayData => {
            Entrie1 => 'something to write here',
            Entrie2 => '',
            Entrie3 => 'a new entry',
            Entrie4 => 'more words for test',
            Entrie5 => 'maybe in another time',
            Entrie6 => 'sunny day',
            Entrie7 => 'last comment',
        },
    },
);

my @DebugLogIDs;
KEY:
for my $Test (@Tests) {

    my $ErrorFlag = 1;
    for my $DataTest ( sort keys %{ $Test->{ArrayData} } ) {
        my $DebugLogResult = $DebugLogObject->LogAdd(
            %{ $Test->{Config} },
            Data => $Test->{ArrayData}->{$DataTest},
        );
        if ( !$Test->{SuccessAdd} ) {
            $Self->False(
                $DebugLogResult,
                "$Test->{Name} - LogAdd()",
            );
        }
        else {
            $Self->True(
                $DebugLogResult,
                "$Test->{Name} - LogAdd()",
            );
        }
        next KEY if !$DebugLogResult;
        $ErrorFlag = 0;
    }
    next KEY if $ErrorFlag;

    my $DebugLogIDsCommunicationID = $Test->{Config}->{CommunicationID};

    # remember id to delete it later
    push @DebugLogIDs, $DebugLogIDsCommunicationID;

    # get record
    my $LogData = '';
    $LogData = $DebugLogObject->LogGet(
        CommunicationID => $DebugLogIDsCommunicationID,
    );

    $Self->Is(
        ref $LogData,
        'HASH',
        "$Test->{Name} - LogGetWithData()",
    );

    $Self->IsNot(
        ref $LogData->{Data},
        'ARRAY',
        "$Test->{Name} - LogGetWithData() - Data",
    );

    # verify LogID
    $Self->True(
        $LogData->{LogID},
        "$Test->{Name} - LogGet() - LogID",
    );
    $Self->Is(
        $LogData->{CommunicationID},
        $DebugLogIDsCommunicationID,
        "$Test->{Name} - LogGet() - CommunicationID",
    );

    $Self->Is(
        $LogData->{WebserviceID},
        $WebserviceID,
        "$Test->{Name} - LogGet() - WebserviceID",
    );
    $Self->Is(
        $LogData->{CommunicationType},
        $Test->{Config}->{CommunicationType},
        "$Test->{Name} - LogGet() - CommunicationType",
    );

    my $DebugLogID = $LogData->{LogID};

    # test LogGetWithData
    $LogData = $DebugLogObject->LogGetWithData(
        CommunicationID => $DebugLogIDsCommunicationID,
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

    # verify LogID
    $Self->Is(
        $LogData->{LogID},
        $DebugLogID,
        "$Test->{Name} - LogGet() - LogID",
    );
    $Self->Is(
        $LogData->{CommunicationID},
        $DebugLogIDsCommunicationID,
        "$Test->{Name} - LogGet() - CommunicationID",
    );
    $Self->Is(
        $LogData->{WebserviceID},
        $WebserviceID,
        "$Test->{Name} - LogGet() - WebserviceID",
    );
    $Self->Is(
        $LogData->{CommunicationType},
        $Test->{Config}->{CommunicationType},
        "$Test->{Name} - LogGet() - CommunicationType",
    );

    my $Counter = 0;
    for my $DataTest ( sort keys %{ $Test->{ArrayData} } ) {
        my $AuxData       = $Test->{ArrayData}->{$DataTest};
        my $AuxSummary    = $Test->{Config}->{Summary};
        my $AuxDebugLevel = $Test->{Config}->{DebugLevel};
        for my $DataFromDB ( @{ $LogData->{Data} } ) {
            if (
                $DataFromDB->{Data} eq $AuxData       &&
                $DataFromDB->{Summary} eq $AuxSummary &&
                $DataFromDB->{DebugLevel} eq $AuxDebugLevel
                )
            {

                $Counter++;
            }
        }
    }

    $Self->Is(
        scalar @{ $LogData->{Data} },
        $Counter,
        "$Test->{Name} - LogGet() - Compare Results",
    );

    # LogSearch
    $LogData = $DebugLogObject->LogSearch(
        CommunicationID => $DebugLogIDsCommunicationID,
        WithData        => 0,                             # optional
    );
    $Self->Is(
        ref $LogData,
        'ARRAY',
        "$Test->{Name} - LogSearch() - WithOutData",
    );

    for my $DataFromSearch ( @{$LogData} ) {

        # verify LogID
        $Self->Is(
            $DataFromSearch->{LogID},
            $DebugLogID,
            "$Test->{Name} - LogSearch() - LogID",
        );
        $Self->Is(
            $DataFromSearch->{CommunicationID},
            $DebugLogIDsCommunicationID,
            "$Test->{Name} - LogSearch() - CommunicationID",
        );
        $Self->Is(
            $DataFromSearch->{WebserviceID},
            $WebserviceID,
            "$Test->{Name} - LogSearch() - WebserviceID",
        );
        $Self->Is(
            $DataFromSearch->{CommunicationType},
            $Test->{Config}->{CommunicationType},
            "$Test->{Name} - LogSearch() - CommunicationType",
        );

    }

    # with data
    $LogData = $DebugLogObject->LogSearch(
        CommunicationID => $DebugLogIDsCommunicationID,
        WithData        => 1,                             # optional
    );
    $Self->Is(
        ref $LogData,
        'ARRAY',
        "$Test->{Name} - LogSearch() - WithData",
    );

    for my $DataFromSearch ( @{$LogData} ) {

        # verify LogID
        $Self->Is(
            $DataFromSearch->{LogID},
            $DebugLogID,
            "$Test->{Name} - LogSearch() - LogID",
        );
        $Self->Is(
            $DataFromSearch->{CommunicationID},
            $DebugLogIDsCommunicationID,
            "$Test->{Name} - LogSearch() - CommunicationID",
        );
        $Self->Is(
            $DataFromSearch->{WebserviceID},
            $WebserviceID,
            "$Test->{Name} - LogSearch() - WebserviceID",
        );
        $Self->Is(
            $DataFromSearch->{CommunicationType},
            $Test->{Config}->{CommunicationType},
            "$Test->{Name} - LogSearch() - CommunicationType",
        );

        $Counter = 0;
        for my $DataTest ( sort keys %{ $Test->{ArrayData} } ) {
            my $AuxData       = $Test->{ArrayData}->{$DataTest};
            my $AuxSummary    = $Test->{Config}->{Summary};
            my $AuxDebugLevel = $Test->{Config}->{DebugLevel};
            for my $DataFromDB ( @{ $DataFromSearch->{Data} } ) {
                if (
                    $DataFromDB->{Data} eq $AuxData       &&
                    $DataFromDB->{Summary} eq $AuxSummary &&
                    $DataFromDB->{DebugLevel} eq $AuxDebugLevel
                    )
                {

                    $Counter++;
                }
            }
        }

        $Self->Is(
            scalar @{ $DataFromSearch->{Data} },
            $Counter,
            "$Test->{Name} - LogSearch() - Compare Results",
        );
    }

}

# check if search contains exactly communication ids
my %DebugLogIDCheck = map { $_ => 1 } @DebugLogIDs;
my $AllEntries      = $DebugLogObject->LogSearch(
    WebserviceID => $WebserviceID,
);
for my $Entry ( @{$AllEntries} ) {
    $Self->True(
        $DebugLogIDCheck{ $Entry->{CommunicationID} },
        "LogSearch() for web service found CommunicationID $Entry->{CommunicationID}",
    );
    delete $DebugLogIDCheck{ $Entry->{CommunicationID} };
}
for my $CommunicationID ( sort keys %DebugLogIDCheck ) {
    $Self->False(
        $CommunicationID,
        "LogSearch() for web service found CommunicationID $CommunicationID",
    );
}

# check LogSearch() limit
my $OneEntry = $DebugLogObject->LogSearch(
    WebserviceID => $WebserviceID,
    Limit        => 1,
);
$Self->Is(
    scalar @{$OneEntry},
    1,
    "LogSearch() limit returns expected number of results",
);

# end tests

# delete config
for my $DebugLogID (@DebugLogIDs) {
    my $LogData = $DebugLogObject->LogSearch(
        CommunicationID => $DebugLogID,
        WithData        => 0,             # optional
    );

    my $Success = $DebugLogObject->LogDelete(
        CommunicationID => $DebugLogID,
    );
    $Self->True(
        $Success,
        "LogDelete() deleted Log $DebugLogID",
    );

    $Success = $DebugLogObject->LogDelete(
        CommunicationID => $DebugLogID,
    );
    $Self->False(
        $Success,
        "LogDelete() deleted Log confirmation $DebugLogID",
    );
}

# cleanup is done by RestoreDatabase.

1;
