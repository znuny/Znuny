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
my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
my $AutoResponseObject  = $Kernel::OM->Get('Kernel::System::AutoResponse');
my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
my $MailQueueObject     = $Kernel::OM->Get('Kernel::System::MailQueue');
my $ArticleObject       = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $YAMLObject          = $Kernel::OM->Get('Kernel::System::YAML');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# get random id
my $RandomID = $HelperObject->GetRandomID();

# set queue name
my $QueueName = 'Some::Queue' . $RandomID;

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

# create default signature
my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
my $NewSignatureID  = $SignatureObject->SignatureAdd(
    Name        => 'New Signature',
    Text        => "--\nSome Signature Infos",
    ContentType => 'text/plain; charset=utf-8',
    Comment     => 'some comment',
    ValidID     => 1,
    UserID      => 1,
);

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
    SignatureID         => $NewSignatureID,
    SalutationID        => $NewSalutationID,
    Comment             => 'Some Comment',
    UserID              => 1,
);

# create new queue
my $QueueID = $QueueObject->QueueAdd(
    %NewQueueParams
);

# create new additional queue
my $AdditionalQueueID = $QueueObject->QueueAdd(
    %NewQueueParams,
    Name => $QueueName . ' - copy',
);

$Self->True(
    $QueueID,
    "QueueAdd() - $QueueName, $QueueID",
);

# use Test email backend
$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::Test',
);
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => '0',
);

my $CustomerUserID = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => 'John',
    UserLastname   => 'Doe',
    UserCustomerID => "Customer#$RandomID",
    UserLogin      => "CustomerLogin#$RandomID",
    UserEmail      => "customer$RandomID\@example.com",
    UserPassword   => 'some_pass',
    ValidID        => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserID,
    "Customer created."
);

# add system address
my $SystemAddressNameRand = 'SystemAddress' . $HelperObject->GetRandomID();
my $SystemAddressEmail    = $SystemAddressNameRand . '@example.com';
my $SystemAddressRealname = "$SystemAddressNameRand, $SystemAddressNameRand";
my $SystemAddressID       = $SystemAddressObject->SystemAddressAdd(
    Name     => $SystemAddressEmail,
    Realname => $SystemAddressRealname,
    ValidID  => 1,
    QueueID  => $QueueID,
    Comment  => 'Some Comment',
    UserID   => 1,
);
$Self->True(
    $SystemAddressID,
    'SystemAddressAdd()',
);

my %AutoResponseType = $AutoResponseObject->AutoResponseTypeList(
    Valid => 1,
);

for my $TypeID ( sort keys %AutoResponseType ) {

    my $AutoResponseNameRand = 'SystemAddress' . $HelperObject->GetRandomID();

    my %Tests = (
        Created => {
            Name        => $AutoResponseNameRand,
            Subject     => 'Some Subject - updated',
            Response    => 'Some Response - updated',
            Comment     => 'Some Comment - updated',
            AddressID   => $SystemAddressID,
            TypeID      => $TypeID,
            ContentType => 'text/plain',
            ValidID     => 1,
        },
        Updated => {
            Name        => $AutoResponseNameRand . ' - updated',
            Subject     => 'Some Subject - updated',
            Response    => 'Some Response - updated',
            Comment     => 'Some Comment - updated',
            AddressID   => $SystemAddressID,
            TypeID      => $TypeID,
            ContentType => 'text/html',
            ValidID     => 2,
        },
        ExpectedData => {
            AutoResponseID => '',
            Address        => $SystemAddressEmail,
            Realname       => $SystemAddressRealname,
        },
    );

    # add auto response
    my $AutoResponseID = $AutoResponseObject->AutoResponseAdd(
        UserID => 1,
        %{ $Tests{Created} },
    );

    # this will be used later to test function AutoResponseGetByTypeQueueID()
    $Tests{ExpectedData}{AutoResponseID} = $AutoResponseID;

    $Self->True(
        $AutoResponseID,
        "AutoResponseAdd() - AutoResponseType: $AutoResponseType{$TypeID}",
    );

    my %AutoResponse = $AutoResponseObject->AutoResponseGet( ID => $AutoResponseID );

    for my $Item ( sort keys %{ $Tests{Created} } ) {
        $Self->Is(
            $AutoResponse{$Item} || '',
            $Tests{Created}{$Item},
            "AutoResponseGet() - $Item",
        );
    }

    my %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 0 );
    my $List             = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() - test Auto Response is in the list.',
    );

    %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 1 );
    $List             = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() - test Auto Response is in the list.',
    );

    # get a list of the queues that do not have auto response
    my %AutoResponseWithoutQueue = $AutoResponseObject->AutoResponseWithoutQueue();

    $Self->True(
        exists $AutoResponseWithoutQueue{$QueueID} && $AutoResponseWithoutQueue{$QueueID} eq $QueueName,
        'AutoResponseWithoutQueue() contains queue ' . $QueueName . ' with ID ' . $QueueID,
    );

    my %AutoResponseListByType = $AutoResponseObject->AutoResponseList(
        TypeID => $TypeID,
        Valid  => 1,
    );
    $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() by AutoResponseTypeID (AutoResponseTypeID) - test Auto Response is in the list.',
    );

    my $AutoResponseQueue = $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [$AutoResponseID],
        UserID          => 1,
    );
    $Self->True(
        $AutoResponseQueue,
        'AutoResponseQueue()',
    );

    # check again after assigning auto response to queue
    %AutoResponseWithoutQueue = $AutoResponseObject->AutoResponseWithoutQueue();
    $Self->False(
        exists $AutoResponseWithoutQueue{$QueueID} && $AutoResponseWithoutQueue{$QueueID} eq $QueueName,
        'AutoResponseWithoutQueue() does not contain queue ' . $QueueName . ' with ID ' . $QueueID,
    );

    my %AutoResponseData = $AutoResponseObject->AutoResponseGetByTypeQueueID(
        QueueID => $QueueID,
        Type    => $AutoResponseType{$TypeID},
    );

    for my $Item (qw/AutoResponseID Address Realname/) {
        $Self->Is(
            $AutoResponseData{$Item} || '',
            $Tests{ExpectedData}{$Item},
            "AutoResponseGetByTypeQueueID() - $Item",
        );
    }

    if ( $TypeID == 1 ) {

        # auto-reply

        my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => 'Email',
        );

        # create a new ticket
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Some Ticket Title',
            QueueID      => $QueueID,
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => "Customer#$RandomID",
            CustomerUser => "CustomerLogin#$RandomID",
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->IsNot(
            $TicketID,
            undef,
            'TicketCreate() - TicketID should not be undef',
        );

        my $ArticleID1 = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            From                 => 'Some Agent <otrs@example.com>',
            To                   => 'Suplier<suplier@example.com>',
            Subject              => 'Email for suplier',
            Body                 => 'the message text',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'OwnerUpdate',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
        );
        $Self->True(
            $ArticleID1,
            "First article created."
        );

        my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
        my $CleanUpSuccess  = $TestEmailObject->CleanUp();
        $Self->True(
            $CleanUpSuccess,
            'Cleanup Email backend',
        );

        my $ArticleID2 = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 0,
            SenderType           => 'customer',
            From                 => 'Suplier<suplier@example.com>',
            To                   => 'Some Agent <otrs@example.com>',
            Subject              => 'some short description',
            Body                 => 'the message text',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'OwnerUpdate',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
            AutoResponseType     => 'auto reply',
            OrigHeader           => {
                From    => 'Some Agent <otrs@example.com>',
                Subject => 'some short description',
            },
        );

        $Self->True(
            $ArticleID2,
            "Second article created."
        );

        # Auto response create a new article, so we need to get the article id generated
        #   - supposedly it should be the last created article for the ticket.
        my @Articles = $ArticleObject->ArticleList(
            TicketID => $TicketID,
            OnlyLast => 1,
        );

        # Get the mail queue element.
        my $MailQueueElement = $MailQueueObject->Get( ArticleID => $Articles[0]->{ArticleID} );

        # Make sure that auto-response is not sent to the customer (in CC) - See bug#12293
        $Self->IsDeeply(
            $MailQueueElement->{Recipient},
            [
                'otrs@example.com'
            ],
            'Check AutoResponse recipients.'
        );

        # Check From header line if it was quoted correctly, please see bug#13130 for more information.
        $Self->True(
            ( $MailQueueElement->{Message}->{Header} =~ m{^From:\s+"$Tests{ExpectedData}->{Realname}"}sm ) // 0,
            'Check From header line quoting'
        );
    }

    # AutoResponseQueuesList
    my %AutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
        ID => $AutoResponseID,
    );

    my $Queue = $QueueObject->QueueLookup( QueueID => $QueueID );

    $Self->True(
        $Queue eq $AutoResponseQueues{$QueueID},
        'AutoResponseQueuesList() - test if queue name/id exists and is valid'
    );

    # AutoResponseCopy
    my $NewAutoResponseID = $AutoResponseObject->AutoResponseCopy(
        ID     => $AutoResponseID,
        UserID => 1,
    );

    $Self->True(
        $NewAutoResponseID,
        'AutoResponseCopy() - test copy of auto response'
    );

    my $CopiedAutoResponseName = $LayoutObject->{LanguageObject}->Translate( '%s (copy)', $Tests{Created}->{Name} );

    # AutoResponseExport
    my @ExportTests = (
        {
            Name =>
                "AutoResponseExport() - test export of copied auto response (Auto response name: $CopiedAutoResponseName)",
            Params => {
                ID => $NewAutoResponseID,
            },
            ExpectedData => [
                {
                    ID => $NewAutoResponseID,
                    %{ $Tests{Created} },
                    Name    => $CopiedAutoResponseName,
                    Queues  => {},
                    Type    => $AutoResponseType{ $Tests{Created}->{TypeID} },
                    Address => $SystemAddressEmail,
                }
            ],
            Import => {
                OverwriteCase => {
                    ExpectedData => {
                        Added            => '',
                        Errors           => '',
                        Success          => 1,
                        Updated          => $CopiedAutoResponseName,
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                }
            }
        },
        {
            Name   => "AutoResponseExport() - test export of original autoresponse (Auto response name: $Tests{Name})",
            Params => {
                ID => $AutoResponseID,
            },
            ExpectedData => [
                {
                    ID => $AutoResponseID,
                    %{ $Tests{Created} },
                    Queues => {
                        $QueueID => $Queue,
                    },
                    Type    => $AutoResponseType{ $Tests{Created}->{TypeID} },
                    Address => $SystemAddressEmail,
                }
            ],
            Import => {
                OverwriteCase => {
                    ExpectedData => {
                        Added            => '',
                        Errors           => '',
                        Success          => 1,
                        Updated          => $Tests{Created}->{Name},
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                }
            }
        },
    );

    # perform export & check it
    for my $ExportTest (@ExportTests) {

        my $Data = $AutoResponseObject->AutoResponseExport(
            %{ $ExportTest->{Params} }
        );

        $Self->True(
            IsArrayRefWithData($Data),
            $ExportTest->{Name} . ' - 1',
        );

        my $ExportContentDump = $YAMLObject->Dump(
            Data => $Data,
        );

        for my $Row ( @{$Data} ) {
            delete $Row->{CreateBy};
            delete $Row->{CreateTime};
            delete $Row->{ChangeTime};
            delete $Row->{ChangeBy};
        }

        my $IsDeeply = $Self->IsDeeply(
            $Data,
            $ExportTest->{ExpectedData},
            $ExportTest->{Name} . ' - 2',
        );

        $ExportTest->{ImportParams} = {
            Content => $ExportContentDump,
        } if $IsDeeply;
    }

    # AutoResponseImport
    # if export was succesfull, we define import tests based on this
    my @ImportTests = grep { IsHashRefWithData( $_->{ImportParams} ) } @ExportTests;
    for my $ImportTest (@ImportTests) {

        # test import result when trying to overwrite, but no overwriting is possible
        my $ImportResult = $AutoResponseObject->AutoResponseImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingAutoResponses => 0,
            UserID                         => 1,
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
            'AutoResponseImport() - test response when trying to overwrite without overwrite existing auto responses parameter'
        );

        # test import result when trying to overwrite and overwriting is possible
        $ImportResult = $AutoResponseObject->AutoResponseImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingAutoResponses => 1,
            UserID                         => 1,
        );

        $Self->IsDeeply(
            $ImportResult,
            $ImportTest->{Import}->{OverwriteCase}->{ExpectedData},
            'AutoResponseImport() - test response when trying to overwrite with overwrite permission parameter'
        );
    }

    my @AfterImportTests = (
        {
            Name           => 'AutoResponseQueuesList() - test original auto response linked data check after import',
            AutoResponseID => $AutoResponseID,
            ExpectedData   => {
                $QueueID => $Queue,
            },
        },
        {
            Name           => 'AutoResponseQueuesList() - test copied auto response linked data check after import',
            AutoResponseID => $NewAutoResponseID,
            ExpectedData   => {},
        },
    );

    for my $Test (@AfterImportTests) {
        my %AutoResponseQueuesAfterImport = $AutoResponseObject->AutoResponseQueuesList(
            ID => $Test->{AutoResponseID},
        );

        $Self->IsDeeply(
            \%AutoResponseQueuesAfterImport,
            $Test->{ExpectedData},
            $Test->{Name},
        );
    }

    # test case where content parameters is missing
    my $ImportMissingNameTest = <<"EOF";
---
- Address: some-address-1
EOF
    my $ImportMissingSystemAddressTest = <<"EOF";
---
- Name: some-name-1
EOF

    @ImportTests = (
        {
            ImportParams => {
                Content => $ImportMissingSystemAddressTest,
            },
            ExpectedData => {
                Errors           => 'some-name-1',
                AdditionalErrors => ['One or more auto responses "Address" parameter is missing!'],
                Added            => '',
                Success          => 1,
                Updated          => '',
                NotUpdated       => '',
            },
            Name => 'AutoResponseImport() - test response when for missing Address parameter.',
        },
        {
            ImportParams => {
                Content => $ImportMissingNameTest,
            },
            ExpectedData => {
                Errors           => '',
                AdditionalErrors => ['One or more auto responses "Name" parameter is missing!'],
                Added            => '',
                Success          => 1,
                Updated          => '',
                NotUpdated       => '',
            },
            Name => 'AutoResponseImport() - test response for missing Name parameter.'
        }
    );

    for my $ImportTest (@ImportTests) {

        my $ImportResult = $AutoResponseObject->AutoResponseImport(
            %{ $ImportTest->{ImportParams} },
            OverwriteExistingAutoResponses => 1,
            UserID                         => 1,
        );

        $Self->IsDeeply(
            $ImportResult,
            $ImportTest->{ExpectedData},
            $ImportTest->{Name},
        );
    }

    $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [$AutoResponseID],
        UserID          => 1,
    );

    my %Queue = $QueueObject->QueueGet(
        ID => $QueueID,
    );

    my %AdditionalQueue = $QueueObject->QueueGet(
        ID => $AdditionalQueueID,
    );

    my %OriginalAutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
        ID => $AutoResponseID,
    );

    my %CopiedAutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
        ID => $NewAutoResponseID,
    );

    $Self->IsDeeply(
        \%CopiedAutoResponseQueues,
        {},
        'AutoResponseQueuesList() - test copied auto response empty linked queues before next import',
    );

    $Self->True(
        $OriginalAutoResponseQueues{$QueueID},
        'AutoResponseQueuesList() - test original auto response linked queue before next import',
    );

    my @AdditionalImportTests = (
        {
            Name    => 'Overwrite linked queues data by copied auto response',
            Content => {
                %{ @{ $YAMLObject->Load( Data => $ExportTests[0]->{ImportParams}->{Content} ) }[0] },

                # copied auto response does not have any links as it should be,
                # but test a case where copied auto response (so auto response with the same type
                # as original auto response) contains same link to the same queue id as
                # original auto response
                # in this case link should be overwritten by the copy
                (
                    Queues => {
                        $QueueID => $Queue{Name},    # this is the queue that original auto response is linked to
                        $AdditionalQueueID =>
                            $AdditionalQueue{Name}    # additionally test some new queue id that was recently created
                    }
                )
            },
            SubTest => {
                ImportResult => {
                    Name =>
                        'AutoResponseImport() - test import of auto response copy that should overwrite linked data of the original auto response',
                    ExpectedData => {
                        Added            => '',
                        Errors           => '',
                        Success          => 1,
                        Updated          => $CopiedAutoResponseName,
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                },
                OriginalAutoResponseQueues => {
                    Name =>
                        'AutoResponseQueuesList() - test original auto response empty linked queues after importing copied auto response',
                    ExpectedData => {},
                },
                CopiedAutoResponseQueues => {
                    Name         => 'AutoResponseQueuesList() - test copy auto response linked queue',
                    ExpectedData => {
                        $QueueID           => $Queue{Name},
                        $AdditionalQueueID => $AdditionalQueue{Name}
                    },
                }
            }
        },
        {
            Name    => 'Import copied auto response with linked queue that does not exists',
            Content => {
                %{ @{ $YAMLObject->Load( Data => $ExportTests[0]->{ImportParams}->{Content} ) }[0] },

                # copied auto response does not have any links as it should be,
                # but test a case where copied auto response (so auto response with the same type
                # as original auto response) contains same link to the same queue id as
                # original auto response
                # in this case link should be overwritten by the copy
                (
                    Queues => {
                        1 => $Queue{Name} . '-this-queue-name-should-not-exists-in-the-system',
                        2 => $AdditionalQueue{Name}    # this queue name exists in the system
                    },
                )
            },
            SubTest => {
                ImportResult => {
                    Name =>
                        'AutoResponseImport() - test import of auto response copy that should include only linked queues data that exists in the system',
                    ExpectedData => {
                        Added            => '',
                        Errors           => $CopiedAutoResponseName,
                        Success          => 1,
                        Updated          => '',
                        NotUpdated       => '',
                        AdditionalErrors => [],
                    }
                },
                OriginalAutoResponseQueues => {
                    Name =>
                        'AutoResponseQueuesList() - test original auto response empty linked queues after importing copied auto response',
                    ExpectedData => {},
                },
                CopiedAutoResponseQueues => {
                    Name         => 'AutoResponseQueuesList() - test copy auto response linked queue',
                    ExpectedData => {
                        $QueueID           => $Queue{Name},
                        $AdditionalQueueID => $AdditionalQueue{Name}
                    },
                }
            }
        }
    );

    for my $AdditionalImportTest (@AdditionalImportTests) {
        my $OverwriteLinkedDataContentYAML = $YAMLObject->Dump(
            Data => [ $AdditionalImportTest->{Content} ],
        );

        # test import result when trying to overwrite and overwriting is possible
        my $ImportCopyResult = $AutoResponseObject->AutoResponseImport(
            Content                        => $OverwriteLinkedDataContentYAML,
            UserID                         => 1,
            OverwriteExistingAutoResponses => 1,
        );

        $Self->IsDeeply(
            $ImportCopyResult,
            $AdditionalImportTest->{SubTest}->{ImportResult}->{ExpectedData},
            $AdditionalImportTest->{SubTest}->{ImportResult}->{Name},
        );

        %OriginalAutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
            ID => $AutoResponseID,
        );

        %CopiedAutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
            ID => $NewAutoResponseID,
        );

        # check if original auto response does not contains the linked data
        $Self->IsDeeply(
            \%OriginalAutoResponseQueues,
            $AdditionalImportTest->{SubTest}->{OriginalAutoResponseQueues}->{ExpectedData},
            $AdditionalImportTest->{SubTest}->{OriginalAutoResponseQueues}->{Name},
        );

        # check if copied auto response contains the linked data
        $Self->IsDeeply(
            \%CopiedAutoResponseQueues,
            $AdditionalImportTest->{SubTest}->{CopiedAutoResponseQueues}->{ExpectedData},
            $AdditionalImportTest->{SubTest}->{CopiedAutoResponseQueues}->{Name},
        );
    }

    $AutoResponseQueue = $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [],
        UserID          => 1,
    );

    my $AutoResponseUpdate = $AutoResponseObject->AutoResponseUpdate(
        ID     => $AutoResponseID,
        UserID => 1,
        %{ $Tests{Updated} },
    );

    $Self->True(
        $AutoResponseUpdate,
        'AutoResponseUpdate()',
    );

    %AutoResponse = $AutoResponseObject->AutoResponseGet( ID => $AutoResponseID );

    for my $Item ( sort keys %{ $Tests{Created} } ) {
        $Self->Is(
            $AutoResponse{$Item} || '',
            $Tests{Updated}{$Item},
            "AutoResponseGet() - $Item",
        );
    }

    %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 1 );
    $List             = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->False(
        $List,
        'AutoResponseList() - test Auto Response is not in the list of valid Auto Responses.',
    );

    %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 0 );

    $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() - test Auto Response is in the list of all Auto Responses.',
    );

    # AutoResponseDelete
    my @AutoresponseIDsToDelete = ( $AutoResponseID, $NewAutoResponseID );
    for my $ID (@AutoresponseIDsToDelete) {
        my $DeleteSuccess = $AutoResponseObject->AutoResponseDelete(
            ID     => $ID,
            UserID => 1,
        );

        $Self->True(
            $DeleteSuccess,
            "AutoResponseDelete() - delete auto response with id: $ID.",
        );

        my %Data = $AutoResponseObject->AutoResponseGet(
            ID => $ID,
        );

        # no worries, "Use of uninitialized value" in logs are expected
        $Self->False(
            $Data{ID},
            "AutoResponseGet() - after deletion of auto response with id: $ID - additional check.",
        );
    }
}

# cleanup is done by RestoreDatabase

1;
