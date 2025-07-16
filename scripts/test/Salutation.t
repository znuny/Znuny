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

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');
my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $YAMLObject       = $Kernel::OM->Get('Kernel::System::YAML');
my $QueueObject      = $Kernel::OM->Get('Kernel::System::Queue');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# add salutation
my $SalutationName = 'salutation' . $HelperObject->GetRandomID();
my $Salutation     = "Dear <OTRS_CUSTOMER_REALNAME>,

Thank you for your request. Your email address in our database
is \"<OTRS_CUSTOMER_DATA_UserEmail>\".
";

my $SalutationID = $SalutationObject->SalutationAdd(
    Name        => $SalutationName,
    Text        => $Salutation,
    ContentType => 'text/plain; charset=iso-8859-1',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

$Self->True(
    $SalutationID,
    'SalutationAdd()',
);

my %Salutation = $SalutationObject->SalutationGet( ID => $SalutationID );

$Self->Is(
    $Salutation{Name} || '',
    $SalutationName,
    'SalutationGet() - Name',
);
$Self->True(
    $Salutation{Text} eq $Salutation,
    'SalutationGet() - Salutation',
);
$Self->Is(
    $Salutation{ContentType} || '',
    'text/plain; charset=iso-8859-1',
    'SalutationGet() - Comment',
);
$Self->Is(
    $Salutation{Comment} || '',
    'some comment',
    'SalutationGet() - Comment',
);
$Self->Is(
    $Salutation{ValidID} || '',
    1,
    'SalutationGet() - ValidID',
);

my %SalutationList = $SalutationObject->SalutationList( Valid => 0 );
$Self->True(
    exists $SalutationList{$SalutationID} && $SalutationList{$SalutationID} eq $SalutationName,
    'SalutationList() contains the salutation ' . $SalutationName . ' with ID ' . $SalutationID,
);

%SalutationList = $SalutationObject->SalutationList( Valid => 1 );
$Self->True(
    exists $SalutationList{$SalutationID} && $SalutationList{$SalutationID} eq $SalutationName,
    'SalutationList() contains the salutation ' . $SalutationName . ' with ID ' . $SalutationID,
);

my $SalutationNameUpdate = $SalutationName . '1';
my $SalutationUpdate     = $SalutationObject->SalutationUpdate(
    ID          => $SalutationID,
    Name        => $SalutationNameUpdate,
    Text        => $Salutation . '1',
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment 1',
    ValidID     => 2,
    UserID      => 1,
);

$Self->True(
    $SalutationUpdate,
    'SalutationUpdate()',
);

%Salutation = $SalutationObject->SalutationGet( ID => $SalutationID );

$Self->Is(
    $Salutation{Name} || '',
    $SalutationNameUpdate,
    'SalutationGet() - Name',
);
$Self->True(
    $Salutation{Text} eq $Salutation . '1',
    'SalutationGet() - Salutation',
);
$Self->Is(
    $Salutation{ContentType} || '',
    'text/plain; charset=utf-8',
    'SalutationGet() - Comment',
);
$Self->Is(
    $Salutation{Comment} || '',
    'some comment 1',
    'SalutationGet() - Comment',
);
$Self->Is(
    $Salutation{ValidID} || '',
    2,
    'SalutationGet() - ValidID',
);

%SalutationList = $SalutationObject->SalutationList( Valid => 0 );
$Self->True(
    exists $SalutationList{$SalutationID} && $SalutationList{$SalutationID} eq $SalutationNameUpdate,
    'SalutationList() contains the salutation ' . $SalutationNameUpdate . ' with ID ' . $SalutationID,
);

%SalutationList = $SalutationObject->SalutationList( Valid => 1 );
$Self->False(
    exists $SalutationList{$SalutationID},
    'SalutationList() does not contain the salutation ' . $SalutationNameUpdate . ' with ID ' . $SalutationID,
);

# SalutationCopy
my $NewSalutationID = $SalutationObject->SalutationCopy(
    ID     => $SalutationID,
    UserID => 1,
);

$Self->True(
    $NewSalutationID,
    'SalutationCopy() - test copy of salutation'
);

my $CopiedSalutationName = $LayoutObject->{LanguageObject}->Translate( '%s (copy)', $SalutationNameUpdate );

my %CopiedSalutation = $SalutationObject->SalutationGet(
    ID => $NewSalutationID,
);

$Self->True(
    keys %CopiedSalutation,
    'SalutationCopy() - test copy of salutation'
);

$Self->True(
    $CopiedSalutation{Name} && $CopiedSalutation{Name} eq $CopiedSalutationName,
    'SalutationCopy() - check copy name'
);

my $SalutationIDSecondCopy = $SalutationObject->SalutationCopy(
    ID     => $NewSalutationID,
    UserID => 1,
);

$Self->True(
    $SalutationIDSecondCopy,
    'SalutationCopy() - test copy of salutation copy'
);

# get random id
my $RandomID = $HelperObject->GetRandomID();

my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
my $NewSignatureID  = $SignatureObject->SignatureAdd(
    Name        => 'New Signature',
    Text        => "--\nSome Signature Infos",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

# set queue name
my $QueueName      = 'Some::Queue' . $RandomID;
my %NewQueueParams = (
    Name                => $QueueName,
    ValidID             => 1,
    GroupID             => 1,
    FirstResponseTime   => 0,
    FirstResponseNotify => 0,
    UpdateTime          => 0,
    UpdateNotify        => 0,
    SolutionTime        => 0,
    SolutionNotify      => 0,
    SystemAddressID     => 1,
    SalutationID        => $SalutationID,
    SignatureID         => $NewSignatureID,
    Comment             => 'Some Comment',
    UserID              => 1,
);

# create new queue
my $QueueID1 = $QueueObject->QueueAdd(
    %NewQueueParams,
);

# create new queue
my $QueueID2 = $QueueObject->QueueAdd(
    %NewQueueParams,
    Name         => $QueueName . '- copy 1',
    SalutationID => $SalutationID,
);

# create new queue
my $QueueID3 = $QueueObject->QueueAdd(
    %NewQueueParams,
    Name         => $QueueName . '- copy 2',
    SalutationID => $NewSalutationID,
);

$Self->True(
    $QueueID1 && $QueueID2 && $QueueID3,
    'QueueAdd() - test creation of new queues',
);

# SalutationExport
my @ExportTests = (
    {
        Name =>
            "SalutationExport() - test export of copied salutation that should contain queue with id: $QueueID3 (Salutation name: $CopiedSalutation{Name})",
        Params => {
            ID => $NewSalutationID,
        },
        ExpectedData => [
            {
                Queues => {
                    $QueueID3 => "$QueueName- copy 2",
                },
                %CopiedSalutation,
            }
        ],
        Import => {
            OverwriteCase => {
                ExpectedData => {
                    Added            => '',
                    Errors           => '',
                    Success          => 1,
                    Updated          => $CopiedSalutationName,
                    NotUpdated       => '',
                    AdditionalErrors => [],
                }
            }
        }
    },
    {
        Name =>
            "SalutationExport() - test export of original Salutation that should contains queues with id: $QueueID1, $QueueID2 (Salutation name: $Salutation{Name})",
        Params => {
            ID => $SalutationID,
        },
        ExpectedData => [
            {
                Queues => {
                    $QueueID1 => $QueueName,
                    $QueueID2 => "$QueueName- copy 1",
                },
                %Salutation,
            }
        ],
        Import => {
            OverwriteCase => {
                ExpectedData => {
                    Added            => '',
                    Errors           => '',
                    Success          => 1,
                    Updated          => $Salutation{Name},
                    NotUpdated       => '',
                    AdditionalErrors => [],
                }
            }
        }
    },
);

# perform export & check it
for my $ExportTest (@ExportTests) {

    my $Data = $SalutationObject->SalutationExport(
        %{ $ExportTest->{Params} }
    );

    $Self->True(
        IsArrayRefWithData($Data),
        $ExportTest->{Name} . ' - 1',
    );

    my $ExportContentDump = $YAMLObject->Dump(
        Data => $Data,
    );

    my $IsDeeply = $Self->IsDeeply(
        $Data,
        $ExportTest->{ExpectedData},
        $ExportTest->{Name} . ' - 2',
    );

    $ExportTest->{ImportParams} = {
        Content => $ExportContentDump,
        Valid   => 0,
    } if $IsDeeply;
}

# SalutationImport
# if export was succesfull, we define import tests based on this
my @ImportTests = grep { IsHashRefWithData( $_->{ImportParams} ) } @ExportTests;
for my $ImportTest (@ImportTests) {

    # test import result when trying to overwrite, but no overwriting is possible
    my $ImportResult = $SalutationObject->SalutationImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSalutations => 0,
        UserID                       => 1,
    );

    my $ExpectedData = {
        Added            => '',
        Errors           => '',
        Success          => 1,
        Updated          => '',
        NotUpdated       => $ImportTest->{ExpectedData}->[0]->{Name},
        AdditionalErrors => [],
    };

    $Self->IsDeeply(
        $ImportResult,
        $ExpectedData,
        'SalutationImport() - test response when trying to overwrite without overwrite existing salutations parameter'
    );

    # test import result when trying to overwrite and overwriting is possible
    $ImportResult = $SalutationObject->SalutationImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSalutations => 1,
        UserID                       => 1,
    );

    $Self->IsDeeply(
        $ImportResult,
        $ImportTest->{Import}->{OverwriteCase}->{ExpectedData},
        'SalutationImport() - test response when trying to overwrite with overwrite permission parameter'
    );
}

my @AfterImportTests = (
    {
        Name         => 'SalutationQueuesList() - test original salutation linked data check after import',
        SalutationID => $SalutationID,
        ExpectedData => $ExportTests[1]->{ExpectedData}->[0]->{Queues},
    },
    {
        Name         => 'SalutationQueuesList() - test copied salutation linked data check after import',
        SalutationID => $NewSalutationID,
        ExpectedData => $ExportTests[0]->{ExpectedData}->[0]->{Queues},
    },
);

for my $Test (@AfterImportTests) {
    my %SalutationQueuesAfterImport = $SalutationObject->SalutationQueuesList(
        ID => $Test->{SalutationID},
    );

    $Self->IsDeeply(
        \%SalutationQueuesAfterImport,
        $Test->{ExpectedData},
        $Test->{Name},
    );
}

# test case where content parameters are missing
my $ImportMissingNameTest = <<"EOF";
---
- some-property: some-value
EOF
@ImportTests = (
    {
        ImportParams => {
            Content => $ImportMissingNameTest,
        },
        ExpectedData => {
            Errors           => '',
            AdditionalErrors => ['One or more salutations "Name" parameter is missing!'],
            Added            => '',
            Success          => 1,
            Updated          => '',
            NotUpdated       => '',
        },
        Name => 'SalutationImport() - test response for missing Name parameter.'
    }
);

for my $ImportTest (@ImportTests) {

    my $ImportResult = $SalutationObject->SalutationImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSalutations => 1,
        UserID                       => 1,
    );

    $Self->IsDeeply(
        $ImportResult,
        $ImportTest->{ExpectedData},
        $ImportTest->{Name},
    );
}

# SalutationQueueLinkBySalutation

# context:
# copied salutation is now linked with $QueueID3
# original salutation is now linked with $QueueID1, $QueueID2
my @SalutationQueueChangeTests = (
    {
        Name   => 'test a link change of queues for salutation where queues does not exists in the db',
        Params => {
            ID       => $SalutationID,
            QueueIDs => [ -1, -2, -3 ],
        },
        ExpectedData => {
            SalutationQueueLinkBySalutation => undef,
            SalutationQueuesList =>
                $AfterImportTests[0]->{ExpectedData},

        },
    },
    {
        Name =>
            'test a link change of queues for salutation where some queue does not exists & some queues does exists in the db',
        Params => {
            ID       => $SalutationID,
            QueueIDs => [ -1, $QueueID1, $QueueID2 ],
        },
        ExpectedData => {
            SalutationQueueLinkBySalutation => 1,
            SalutationQueuesList            => {
                $QueueID1 => $NewQueueParams{Name},
                $QueueID2 => $QueueName . '- copy 1',
            },
        },
    },
    {
        Name =>
            'test a link change of queues for salutation where three queues are assigned, but two of them are already linked',
        Params => {
            ID       => $SalutationID,
            QueueIDs => [$QueueID3],    # salutation at this point should contain $QueueID1, $QueueID2 but not $QueueID3
        },
        ExpectedData => {
            SalutationQueueLinkBySalutation => 1,
            SalutationQueuesList            => {
                $QueueID1 => $NewQueueParams{Name},
                $QueueID2 => $QueueName . '- copy 1',
                $QueueID3 => $QueueName . '- copy 2',
            },
        },
    }
);

for my $Test (@SalutationQueueChangeTests) {
    my $Success = $SalutationObject->SalutationQueueLinkBySalutation(
        %{ $Test->{Params} },
        UserID => 1,
    );

    $Self->True(
        $Success eq $Test->{ExpectedData}->{SalutationQueueLinkBySalutation},
        'SalutationQueueLinkBySalutation() - ' . $Test->{Name},
    );

    my %SalutationQueues = $SalutationObject->SalutationQueuesList(
        ID => $Test->{Params}->{ID},
    );

    $Self->IsDeeply(
        \%SalutationQueues,
        $Test->{ExpectedData}->{SalutationQueuesList},
        'SalutationQueuesList() - ' . $Test->{Name},
    );
}

# $NewSalutationID was at first linked to $QueueID3, but in the tests above $QueueID3 was linked to $SalutationID
# check if $NewSalutationID still contains linked $QueueID3 data - it shouldn't
my %NewSalutationQueuesAfterLinking = $SalutationObject->SalutationQueuesList(
    ID => $NewSalutationID,
);

$Self->True(
    keys %NewSalutationQueuesAfterLinking == 0,
    "SalutationQueuesList() - test if $NewSalutationID copied salutation contains linked data that was re-linked to original salutation.",
);

# SalutationDelete
my @DeleteTests = (
    {
        Name   => "SalutationDelete() - delete Salutation with id: $SalutationID.",
        Params => {
            ID => $SalutationID,
        },
        ExpectedData => undef,
    },
    {
        Name   => "SalutationDelete() - delete Salutation with id: $NewSalutationID.",
        Params => {
            ID => $NewSalutationID,
        },
        ExpectedData => 1,
    }
);

for my $Test (@DeleteTests) {
    my $SalutationID = $Test->{Params}->{ID};

    my $DeleteSuccess = $SalutationObject->SalutationDelete(
        %{ $Test->{Params} },
        UserID => 1,
    );

    $Self->True(
        $DeleteSuccess eq $Test->{ExpectedData},
        $Test->{Name},
    );
}

my @LinkedQueues = ( $QueueID1, $QueueID2, $QueueID3 );

# reset queues that was linked to $SalutationID
for my $QueueID (@LinkedQueues) {
    my %Queue = $QueueObject->QueueGet(
        ID => $QueueID,
    );

    # reset salutation to some queue that was created at the beginning of the test module
    # this queue wasn't used at all
    my $Success = $QueueObject->QueueUpdate(
        %Queue,
        SalutationID => $SalutationIDSecondCopy,
        UserID       => 1,
    );

    $Self->True(
        $Success,
        "QueueUpdate() - update queue to salutation that wasn't used in linking before (reset queue)",
    );
}

# try to delete salutation now, after linked data should be cleared
my $DeleteSuccess = $SalutationObject->SalutationDelete(
    ID     => $SalutationID,
    UserID => 1,
);

$Self->True(
    $DeleteSuccess,
    "SalutationDelete() - delete salutation: $SalutationID after it's queues links were deleted",
);

my %Data = $SalutationObject->SalutationGet(
    ID => $SalutationID,
);

$Self->False(
    $Data{ID},
    "SalutationGet() - delete salutation: $SalutationID after it's queues links were deleted",
);

# cleanup is done by RestoreDatabase

1;
