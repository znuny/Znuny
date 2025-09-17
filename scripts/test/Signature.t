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

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');

# get signature object
my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');

# add signature
my $SignatureName = $HelperObject->GetRandomID();
my $SignatureText = "Your OTRS-Team

<OTRS_CURRENT_UserFirstname> <OTRS_CURRENT_UserLastname>

--
Super Support Company Inc. - Waterford Business Park
5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
Email: hot\@florida.com - Web: http://hot.florida.com/
--";

my $SignatureID = $SignatureObject->SignatureAdd(
    Name        => $SignatureName,
    Text        => $SignatureText,
    ContentType => 'text/plain; charset=iso-8859-1',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

$Self->True(
    $SignatureID,
    'SignatureAdd()',
);

my %Signature = $SignatureObject->SignatureGet( ID => $SignatureID );

$Self->Is(
    $Signature{Name} || '',
    $SignatureName,
    'SignatureGet() - Name',
);
$Self->True(
    $Signature{Text} eq $SignatureText,
    'SignatureGet() - Signature text',
);
$Self->Is(
    $Signature{ContentType} || '',
    'text/plain; charset=iso-8859-1',
    'SignatureGet() - Comment',
);
$Self->Is(
    $Signature{Comment} || '',
    'some comment',
    'SignatureGet() - Comment',
);
$Self->Is(
    $Signature{ValidID} || '',
    1,
    'SignatureGet() - ValidID',
);

my %SignatureList = $SignatureObject->SignatureList( Valid => 0 );
$Self->True(
    exists $SignatureList{$SignatureID} && $SignatureList{$SignatureID} eq $SignatureName,
    "SignatureList() contains the signature $SignatureName",
);

my $SignatureNameUpdate = $SignatureName . ' - Update';
my $SignatureTextUpdate = $SignatureText . ' - Update';
my $SignatureUpdate     = $SignatureObject->SignatureUpdate(
    ID          => $SignatureID,
    Name        => $SignatureNameUpdate,
    Text        => $SignatureTextUpdate,
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment 1',
    ValidID     => 2,
    UserID      => 1,
);

$Self->True(
    $SignatureUpdate,
    'SignatureUpdate()',
);

%Signature = $SignatureObject->SignatureGet( ID => $SignatureID );

$Self->Is(
    $Signature{Name} || '',
    $SignatureNameUpdate,
    'SignatureGet() - Name',
);
$Self->True(
    $Signature{Text} eq $SignatureTextUpdate,
    'SignatureGet() - Signature',
);
$Self->Is(
    $Signature{ContentType} || '',
    'text/plain; charset=utf-8',
    'SignatureGet() - Comment',
);
$Self->Is(
    $Signature{Comment} || '',
    'some comment 1',
    'SignatureGet() - Comment',
);
$Self->Is(
    $Signature{ValidID} || '',
    2,
    'SignatureGet() - ValidID',
);

%SignatureList = $SignatureObject->SignatureList( Valid => 1 );
$Self->False(
    exists $SignatureList{$SignatureID},
    "SignatureList() does not contain invalid signature $SignatureNameUpdate",
);

# SignatureCopy
my $NewSignatureID = $SignatureObject->SignatureCopy(
    ID     => $SignatureID,
    UserID => 1,
);

$Self->True(
    $NewSignatureID,
    'SignatureCopy() - test copy of signature'
);

my $CopiedSignatureName = $LayoutObject->{LanguageObject}->Translate( '%s (copy)', $SignatureNameUpdate );

my %CopiedSignature = $SignatureObject->SignatureGet(
    ID => $NewSignatureID,
);

$Self->True(
    keys %CopiedSignature,
    'SignatureCopy() - test copy of signature'
);

$Self->True(
    $CopiedSignature{Name} && $CopiedSignature{Name} eq $CopiedSignatureName,
    'SignatureCopy() - check copy name'
);

my $SignatureIDSecondCopy = $SignatureObject->SignatureCopy(
    ID     => $NewSignatureID,
    UserID => 1,
);

$Self->True(
    $SignatureIDSecondCopy,
    'SignatureCopy() - test copy of signature copy'
);

# get random id
my $RandomID = $HelperObject->GetRandomID();

# create default salutation
my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');
my $NewSalutationID  = $SalutationObject->SalutationAdd(
    Name        => 'New Salutation',
    Text        => "--\nSome Salutation Infos",
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
    SignatureID         => $SignatureID,
    SalutationID        => $NewSalutationID,
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
    Name        => $QueueName . '- copy 1',
    SignatureID => $SignatureID,
);

# create new queue
my $QueueID3 = $QueueObject->QueueAdd(
    %NewQueueParams,
    Name        => $QueueName . '- copy 2',
    SignatureID => $NewSignatureID,
);

$Self->True(
    $QueueID1 && $QueueID2 && $QueueID3,
    'QueueAdd() - test creation of new queues',
);

# SignatureExport
my @ExportTests = (
    {
        Name =>
            "SignatureExport() - test export of copied signature that should contain queue with id: $QueueID3 (Signature name: $CopiedSignature{Name})",
        Params => {
            ID => $NewSignatureID,
        },
        ExpectedData => [
            {
                Queues => {
                    $QueueID3 => "$QueueName- copy 2",
                },
                %CopiedSignature,
            }
        ],
        Import => {
            OverwriteCase => {
                ExpectedData => {
                    Added            => '',
                    Errors           => '',
                    Success          => 1,
                    Updated          => $CopiedSignatureName,
                    NotUpdated       => '',
                    AdditionalErrors => [],
                }
            }
        }
    },
    {
        Name =>
            "SignatureExport() - test export of original Signature that should contains queues with id: $QueueID1, $QueueID2 (Signature name: $Signature{Name})",
        Params => {
            ID => $SignatureID,
        },
        ExpectedData => [
            {
                Queues => {
                    $QueueID1 => $QueueName,
                    $QueueID2 => "$QueueName- copy 1",
                },
                %Signature,
            }
        ],
        Import => {
            OverwriteCase => {
                ExpectedData => {
                    Added            => '',
                    Errors           => '',
                    Success          => 1,
                    Updated          => $Signature{Name},
                    NotUpdated       => '',
                    AdditionalErrors => [],
                }
            }
        }
    },
);

# perform export & check it
for my $ExportTest (@ExportTests) {

    my $Data = $SignatureObject->SignatureExport(
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

# SignatureImport
# if export was succesfull, we define import tests based on this
my @ImportTests = grep { IsHashRefWithData( $_->{ImportParams} ) } @ExportTests;
for my $ImportTest (@ImportTests) {

    # test import result when trying to overwrite, but no overwriting is possible
    my $ImportResult = $SignatureObject->SignatureImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSignatures => 0,
        UserID                      => 1,
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
        'SignatureImport() - test response when trying to overwrite without overwrite existing signatures parameter'
    );

    # test import result when trying to overwrite and overwriting is possible
    $ImportResult = $SignatureObject->SignatureImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSignatures => 1,
        UserID                      => 1,
    );

    $Self->IsDeeply(
        $ImportResult,
        $ImportTest->{Import}->{OverwriteCase}->{ExpectedData},
        'SignatureImport() - test response when trying to overwrite with overwrite permission parameter'
    );
}

my @AfterImportTests = (
    {
        Name         => 'SignatureQueuesList() - test original signature linked data check after import',
        SignatureID  => $SignatureID,
        ExpectedData => $ExportTests[1]->{ExpectedData}->[0]->{Queues},
    },
    {
        Name         => 'SignatureQueuesList() - test copied signature linked data check after import',
        SignatureID  => $NewSignatureID,
        ExpectedData => $ExportTests[0]->{ExpectedData}->[0]->{Queues},
    },
);

for my $Test (@AfterImportTests) {
    my %SignatureQueuesAfterImport = $SignatureObject->SignatureQueuesList(
        ID => $Test->{SignatureID},
    );

    $Self->IsDeeply(
        \%SignatureQueuesAfterImport,
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
            AdditionalErrors => ['One or more signatures "Name" parameter is missing!'],
            Added            => '',
            Success          => 1,
            Updated          => '',
            NotUpdated       => '',
        },
        Name => 'SignatureImport() - test response when for missing Name parameter.'
    }
);

for my $ImportTest (@ImportTests) {

    my $ImportResult = $SignatureObject->SignatureImport(
        %{ $ImportTest->{ImportParams} },
        OverwriteExistingSignatures => 1,
        UserID                      => 1,
    );

    $Self->IsDeeply(
        $ImportResult,
        $ImportTest->{ExpectedData},
        $ImportTest->{Name},
    );
}

# SignatureQueueLinkBySignature

# context:
# copied signature is now linked with $QueueID3
# original signature is now linked with $QueueID1, $QueueID2
my @SignatureQueueChangeTests = (
    {
        Name   => 'test a link change of queues for signature where queues does not exists in the db',
        Params => {
            ID       => $SignatureID,
            QueueIDs => [ -1, -2, -3 ],
        },
        ExpectedData => {
            SignatureQueueLinkBySignature => undef,
            SignatureQueuesList =>
                $AfterImportTests[0]->{ExpectedData},

        },
    },
    {
        Name =>
            'test a link change of queues for signature where some queue does not exists & some queues does exists in the db',
        Params => {
            ID       => $SignatureID,
            QueueIDs => [ -1, $QueueID1, $QueueID2 ],
        },
        ExpectedData => {
            SignatureQueueLinkBySignature => 1,
            SignatureQueuesList           => {
                $QueueID1 => $NewQueueParams{Name},
                $QueueID2 => $QueueName . '- copy 1',
            },
        },
    },
    {
        Name =>
            'test a link change of queues for signature where three queues are assigned, but two of them are already linked',
        Params => {
            ID       => $SignatureID,
            QueueIDs => [$QueueID3],    # signature at this point should contain $QueueID1, $QueueID2 but not $QueueID3
        },
        ExpectedData => {
            SignatureQueueLinkBySignature => 1,
            SignatureQueuesList           => {
                $QueueID1 => $NewQueueParams{Name},
                $QueueID2 => $QueueName . '- copy 1',
                $QueueID3 => $QueueName . '- copy 2',
            },
        },
    }
);

for my $Test (@SignatureQueueChangeTests) {
    my $Success = $SignatureObject->SignatureQueueLinkBySignature(
        %{ $Test->{Params} },
        UserID => 1,
    );

    $Self->True(
        $Success eq $Test->{ExpectedData}->{SignatureQueueLinkBySignature},
        'SignatureQueueLinkBySignature() - ' . $Test->{Name},
    );

    my %SignatureQueues = $SignatureObject->SignatureQueuesList(
        ID => $Test->{Params}->{ID},
    );

    $Self->IsDeeply(
        \%SignatureQueues,
        $Test->{ExpectedData}->{SignatureQueuesList},
        'SignatureQueuesList() - ' . $Test->{Name},
    );
}

# $NewSignatureID was at first linked to $QueueID3, but in the tests above $QueueID3 was linked to $SignatureID
# check if $NewSignatureID still contains linked $QueueID3 data - it shouldn't
my %NewSignatureQueuesAfterLinking = $SignatureObject->SignatureQueuesList(
    ID => $NewSignatureID,
);

$Self->True(
    keys %NewSignatureQueuesAfterLinking == 0,
    "SignatureQueuesList() - test if $NewSignatureID copied signature contains linked data that was re-linked to original signature.",
);

# SignatureDelete
my @DeleteTests = (
    {
        Name   => "SignatureDelete() - delete Signature with id: $SignatureID.",
        Params => {
            ID => $SignatureID,
        },
        ExpectedData => undef,
    },
    {
        Name   => "SignatureDelete() - delete Signature with id: $NewSignatureID.",
        Params => {
            ID => $NewSignatureID,
        },
        ExpectedData => 1,
    }
);

for my $Test (@DeleteTests) {
    my $SignatureID = $Test->{Params}->{ID};

    my $DeleteSuccess = $SignatureObject->SignatureDelete(
        %{ $Test->{Params} },
        UserID => 1,
    );

    $Self->True(
        $DeleteSuccess eq $Test->{ExpectedData},
        $Test->{Name},
    );
}

my @LinkedQueues = ( $QueueID1, $QueueID2, $QueueID3 );

# reset queues that was linked to $SignatureID
for my $QueueID (@LinkedQueues) {
    my %Queue = $QueueObject->QueueGet(
        ID => $QueueID,
    );

    # reset signature to some queue that was created at the beginning of the test module
    # this queue wasn't used at all
    my $Success = $QueueObject->QueueUpdate(
        %Queue,
        SignatureID => $SignatureIDSecondCopy,
        UserID      => 1,
    );

    $Self->True(
        $Success,
        "QueueUpdate() - update queue to signature that wasn't used in linking before (reset queue)",
    );
}

# try to delete signature now, after linked data should be cleared
my $DeleteSuccess = $SignatureObject->SignatureDelete(
    ID     => $SignatureID,
    UserID => 1,
);

$Self->True(
    $DeleteSuccess,
    "SignatureDelete() - delete signature: $SignatureID after it's queues links were deleted",
);

my %Data = $SignatureObject->SignatureGet(
    ID => $SignatureID,
);

$Self->False(
    $Data{ID},
    "SignatureGet() - delete signature: $SignatureID after it's queues links were deleted",
);

# cleanup is done by RestoreDatabase

1;
