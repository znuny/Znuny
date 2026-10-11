# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::PostMaster;

# The Content-Type header of the attachment contains the encoded non-ASCII file name
# and is longer than 450 characters (see https://github.com/znuny/Znuny/issues/856).
# Such an attachment was not stored on PostgreSQL and got lost in the upload cache
# (e.g. when forwarding the article).

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $ContentRef = $MainObject->FileRead(
    Location => $ConfigObject->Get('Home') . '/scripts/test/sample/PostMaster/LongContentTypeAttachment.box',
    Mode     => 'binmode',
    Result   => 'ARRAY',
);

my $ExpectedFilename    = 'Графік_планового_технічного_обслуговування_серверного_обладнання_на_четвертий_квартал.pdf';
my $ExpectedContent     = 'Znuny unit test attachment';
my $ExpectedContentType = 'application/pdf; name="'
    . join(
    ' ',
    '=?UTF-8?Q?=D0=93=D1=80=D0=B0=D1=84=D1=96=D0=BA_=D0=BF=D0=BB=D0=B0=D0=BD?=',
    '=?UTF-8?Q?=D0=BE=D0=B2=D0=BE=D0=B3=D0=BE_=D1=82=D0=B5=D1=85=D0=BD=D1=96?=',
    '=?UTF-8?Q?=D1=87=D0=BD=D0=BE=D0=B3=D0=BE_=D0=BE=D0=B1=D1=81=D0=BB=D1=83?=',
    '=?UTF-8?Q?=D0=B3=D0=BE=D0=B2=D1=83=D0=B2=D0=B0=D0=BD=D0=BD=D1=8F_=D1=81?=',
    '=?UTF-8?Q?=D0=B5=D1=80=D0=B2=D0=B5=D1=80=D0=BD=D0=BE=D0=B3=D0=BE_=D0=BE?=',
    '=?UTF-8?Q?=D0=B1=D0=BB=D0=B0=D0=B4=D0=BD=D0=B0=D0=BD=D0=BD=D1=8F_=D0=BD?=',
    '=?UTF-8?Q?=D0=B0_=D1=87=D0=B5=D1=82=D0=B2=D0=B5=D1=80=D1=82=D0=B8=D0=B9?=',
    '=?UTF-8?Q?_=D0=BA=D0=B2=D0=B0=D1=80=D1=82=D0=B0=D0=BB=2Epdf?=',
    ) . '"';

$Self->True(
    length $ExpectedContentType > 450,
    'Content-Type header of the sample attachment is longer than 450 characters',
);

STORAGEBACKEND:
for my $StorageBackend (qw(DB FS)) {

    # Make sure that the article backend gets recreated with the configured storage module.
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::Ticket::Article::Backend::Email'],
    );

    $ConfigObject->Set(
        Key   => 'Ticket::Article::Backend::MIMEBase::ArticleStorage',
        Value => 'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorage' . $StorageBackend,
    );

    my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

    $Self->Is(
        $ArticleBackendObject->{ArticleStorageModule},
        'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorage' . $StorageBackend,
        "$StorageBackend - Article backend loaded the correct storage module",
    );

    my $TicketID;
    {
        my $CommunicationLogObject = $Kernel::OM->Create(
            'Kernel::System::CommunicationLog',
            ObjectParams => {
                Transport => 'Email',
                Direction => 'Incoming',
            },
        );
        $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

        my $PostMasterObject = Kernel::System::PostMaster->new(
            CommunicationLogObject => $CommunicationLogObject,
            Email                  => [ @{$ContentRef} ],
        );

        my @Return = $PostMasterObject->Run();

        $TicketID = $Return[1];

        $CommunicationLogObject->ObjectLogStop(
            ObjectLogType => 'Message',
            Status        => 'Successful',
        );
        $CommunicationLogObject->CommunicationStop(
            Status => 'Successful',
        );
    }

    $Self->True(
        $TicketID,
        "$StorageBackend - Ticket created",
    );

    my ($Article) = $ArticleObject->ArticleList( TicketID => $TicketID );

    my %AttachmentIndex = $ArticleBackendObject->ArticleAttachmentIndex(
        ArticleID        => $Article->{ArticleID},
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
    );
    my @FileIDs = sort keys %AttachmentIndex;

    $Self->Is(
        scalar @FileIDs,
        1,
        "$StorageBackend - Attachment with long Content-Type header has been stored",
    );

    next STORAGEBACKEND if !@FileIDs;

    my %Attachment = $ArticleBackendObject->ArticleAttachment(
        ArticleID => $Article->{ArticleID},
        FileID    => $FileIDs[0],
    );

    $Self->Is(
        $Attachment{Filename},
        $ExpectedFilename,
        "$StorageBackend - Attachment filename",
    );
    $Self->Is(
        $Attachment{ContentType},
        $ExpectedContentType,
        "$StorageBackend - Attachment content type",
    );
    $Self->Is(
        $Attachment{Content},
        $ExpectedContent,
        "$StorageBackend - Attachment content",
    );

    # The attachment is added to the upload cache e.g. when forwarding the article.
    for my $UploadCacheModule (qw(DB FS)) {

        $Kernel::OM->ObjectsDiscard(
            Objects => ['Kernel::System::Web::UploadCache'],
        );

        $ConfigObject->Set(
            Key   => 'WebUploadCacheModule',
            Value => "Kernel::System::Web::UploadCache::$UploadCacheModule",
        );

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
        my $FormID            = $UploadCacheObject->FormIDCreate();

        my $Success = $UploadCacheObject->FormIDAddFile(
            FormID => $FormID,
            %Attachment,
            Disposition => 'attachment',
        );

        $Self->True(
            $Success,
            "$StorageBackend - UploadCache $UploadCacheModule - FormIDAddFile()",
        );

        my @Files = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $FormID,
        );

        $Self->Is(
            scalar @Files,
            1,
            "$StorageBackend - UploadCache $UploadCacheModule - FormIDGetAllFilesData() file count",
        );
        $Self->Is(
            $Files[0]->{ContentType},
            $ExpectedContentType,
            "$StorageBackend - UploadCache $UploadCacheModule - FormIDGetAllFilesData() content type",
        );
        $Self->Is(
            $Files[0]->{Content},
            $ExpectedContent,
            "$StorageBackend - UploadCache $UploadCacheModule - FormIDGetAllFilesData() content",
        );

        $UploadCacheObject->FormIDRemove( FormID => $FormID );
    }
}

# cleanup is done by RestoreDatabase.

1;
