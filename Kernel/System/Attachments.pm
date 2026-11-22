# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny4OTRS::Deprecated::ArticleFunctions)

package Kernel::System::Attachments;

use strict;
use warnings;
use utf8;

use POSIX qw/ceil/;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AttachmentPreview',
    'Kernel::System::Encode',
    'Kernel::System::FileTemp',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

use Archive::Zip                  qw( :ERROR_CODES );
use Digest::MD5                   qw(md5_hex);
use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Attachments - ticket attachment lib

=head1 SYNOPSIS

Backend functions for listing, reusing and archiving ticket attachments.

=head1 PUBLIC INTERFACE

=head2 new()

    Don't use the constructor directly, use the ObjectManager instead:

    my $AttachmentsObject = $Kernel::OM->Get('Kernel::System::Attachments');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 IsArticleCountReached()

Check if ArticleCount is greater or equal Attachment::DeactivateWidgetArticleCount.

    my $IsArticleCountReached = $AttachmentsObject->IsArticleCountReached(
        TicketID => 123,
    );

Returns:

    my $IsReached = 1;

=cut

sub IsArticleCountReached {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my $Config = $ConfigObject->Get('Attachment');

    return 0 if $Config->{DeactivateWidgetArticleCount} eq 0;

    my $ArticleCount = $ArticleObject->ArticleCount(
        TicketID => $Param{TicketID},
    );

    return 1 if $ArticleCount >= $Config->{DeactivateWidgetArticleCount};
    return 0;
}

=head2 IsArticleAttachmentCountReached()

Check if ArticleAttchmentCount is greater or equal DeactivateWidgetAttachmentCount.

    my $IsArticleAttachmentCountReached = $AttachmentsObject->IsArticleAttachmentCountReached(
        TicketID => 123,
    );

Returns:

    my $IsReached = 1;

=cut

sub IsArticleAttachmentCountReached {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('Attachment');

    return 0 if $Config->{DeactivateWidgetAttachmentCount} eq 0;

    my $ArticleAttachmentCount = $Self->ArticleAttachmentCount(
        TicketID => $Param{TicketID},
    );

    return 1 if $ArticleAttachmentCount >= $Config->{DeactivateWidgetAttachmentCount};
    return 0;
}

=head2 ArticleAttachmentCount()

Returns the count of article attachment for given ticket-id.

    my $ArticleAttachmentCount = $AttachmentsObject->ArticleAttachmentCount(
        TicketID  => 123,
    );

Returns:

    my $ArticleAttachmentCount = 1;

=cut

sub ArticleAttachmentCount {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw(TicketID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        TicketID => $Param{TicketID},
    );

    my $ArticleAttachmentCount;

    for my $ArticleID ( sort @ArticleIDs ) {

        $ArticleAttachmentCount += $ArticleObject->ArticleAttachmentCount(
            TicketID  => $Param{TicketID},
            ArticleID => $ArticleID,
        );
    }

    return $ArticleAttachmentCount;
}

=head2 ArticleAttachmentGet()

This function will return a attachment of ticket article.

    my %Attachment = $AttachmentsObject->ArticleAttachmentGet(
        TicketID  => 123,
        ArticleID => 123,
        FileID    => 123,
        UserID    => 123,
    );

Returns:

    my %Attachment = (
        'Content'            => '...',
        'ContentAlternative' => '...',
        'ContentID'          => '...',
        'ContentType'        => '...',
        'Disposition'        => '...',
        'Filename'           => '...',
        'FilesizeRaw'        => '...',
    );

=cut

sub ArticleAttachmentGet {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw(TicketID ArticleID FileID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $TicketID  = $Param{TicketID};
    my $ArticleID = $Param{ArticleID};
    my $UserID    = $Param{UserID};
    my $FileID    = $Param{FileID};

    my $ArticleBackendObject = $ArticleObject->BackendForArticle(
        TicketID  => $TicketID,
        ArticleID => $ArticleID,
    );

    return $ArticleBackendObject->ArticleAttachment(
        ArticleID => $ArticleID,
        FileID    => $FileID,
        UserID    => $UserID,
    );
}

=head2 ArticleAttachmentListGet()

    Assembles all downloadable attachments of a ticket in order of its articles.

    my $TicketAttachments = $AttachmentsObject->ArticleAttachmentListGet(
        TicketID => 140,
    );

    Returns array ref with all attachments of the given ticket, sorted by article.
    Duplicate filenames will be extended by a counter (starting with 2, the first keeps its original name).

    my $TicketAttachments = [
        {
            ArticleID   => 176,
            FileID      => 1,
            Filename    => 'test1.txt',
            Filesize    => 24,
            ContentType => 'text',
        },
        {
            ArticleID   => 178,
            FileID      => 2,
            Filename    => 'test2.txt'
            Filesize    => 453,
            ContentType => 'text',
        },
        {
            ArticleID   => 179,
            FileID      => 1,
            Filename    => 'test2-2.txt'
            Filesize    => 381,
            ContentType => 'text',
        },
        # ...
    };

=cut

sub ArticleAttachmentListGet {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('Attachment');

    NEEDED:
    for my $Needed (qw( TicketID )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @TicketAttachments;
    my %FilenameCounters;

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        TicketID => $Param{TicketID},
    );
    return \@TicketAttachments if !@ArticleIDs;

    my %ArticleCheck;
    ARTICLEID:
    for my $ArticleID ( sort @ArticleIDs ) {
        my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
            TicketID         => $Param{TicketID},
            ArticleID        => $ArticleID,
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );

        next ARTICLEID if !%AttachmentIndex;

        FILEID:
        for my $FileID ( sort keys %AttachmentIndex ) {
            my $ContentType = $AttachmentIndex{$FileID}->{ContentType} || '';
            $ContentType =~ s{;.*}{}g;
            $ContentType =~ s{\s+}{}g;

            my $Filename  = $AttachmentIndex{$FileID}->{Filename};
            my $Filesize  = $AttachmentIndex{$FileID}->{FilesizeRaw};
            my $IconClass = $Self->AttachmentIconClassGet(
                ContentType => $ContentType,
            );

            if ( $Config && !$Config->{ShowDuplicateFiles} ) {
                next FILEID if $ArticleCheck{ $Filename . $Filesize };
                $ArticleCheck{ $Filename . $Filesize } = 1;
            }

            # Keep filename unique across all attachments of the article.
            $Filename = $Self->_GenerateUniqueFilename(
                FilenameToCheck  => $Filename,
                FilenameCounters => \%FilenameCounters,
            );
            next FILEID if !$Filename;

            my %ArticleAttachment = (
                ArticleID   => $ArticleID,
                FileID      => $FileID,
                Filename    => $Filename,
                Filesize    => $Filesize,
                ContentType => $ContentType,
                IconClass   => $IconClass,
            );

            push @TicketAttachments, \%ArticleAttachment;
        }
    }

    # Sort ticket attachments by their filenames.
    @TicketAttachments = sort { $a->{Filename} cmp $b->{Filename} } @TicketAttachments;

    return \@TicketAttachments;
}

=head2 ArticleAndAttachmentListGet()

This function will return a list of all attachments of the articles of a ticket.

    my @Attachments = $AttachmentsObject->ArticleAndAttachmentListGet(
        TicketID => 123,
        UserID   => 1,
    );

Returns:

    my @Attachments = (
        {
            'InlineElement'          => 1,
            'IncomingTime'           => '1553173426',
            'ReplyTo'                => '',
            'FileID'                 => '{"ArticleID":"23","FileID":"1"}',
            'IsVisibleForCustomer'   => '0',
            'Bcc'                    => '',
            'ChangeTime'             => '2019-03-21 13:03:46',
            'MessageID'              => '<1553173426.689500.811959156@ubuntu>',
            'ContentType'            => 'image/jpeg; name="burger.jpg"',
            'To'                     => 'customer-1 customer-1 customer-1@localhost',
            'From'                   => 'OTRS System <otrs@localhost>',
            'Filename'               => 'burger.jpg',
            'ArticlePage'            => '1',
            'Body'                   => '...',
            'CreateBy'               => '2',
            'ContentCharset'         => 'utf-8',
            'Cc'                     => '',
            'Subject'                => '[Ticket#2019020754000017] asdf asdf',
            'ContentAlternative'     => '',
            'MimeType'               => 'text/plain',
            'Disposition'            => 'inline',
            'SenderTypeID'           => '1',
            'FilesizeRaw'            => '75849',
            'CommunicationChannelID' => '1',
            'InReplyTo'              => '',
            'SenderType'             => 'agent',
            'FileArticleTypeCSS'     => undef,
            'References'             => '',
            'FileTypeCSS'            => 'fa-file-image-o',
            'ArticleID'              => 23,
            'Charset'                => 'utf-8',
            'ContentID'              => '<inline635369.416134411.1553173389.5979040.7744862@ubuntu>',
            'TicketID'               => '22',
            'ArticleNumber'          => 5,
            'CreateTime'             => '2019-03-21 13:03:46',
            'ChangeBy'               => '2'
        },
        # ...
    );

=cut

sub ArticleAndAttachmentListGet {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(TicketID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $TicketID = $Param{TicketID};
    my $UserID   = $Param{UserID};

    my @Articles = $ArticleObject->ArticleList(
        TicketID => $TicketID,
    );

    my @Attachments;
    ARTICLEID:
    for my $Article (@Articles) {
        my $ArticleBackendObject = $ArticleObject->BackendForArticle(
            %{$Article},
        );

        my %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $TicketID,
            ArticleID => $Article->{ArticleID},
            UserID    => $UserID,
        );

        # read attachments
        my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID        => $Article->{ArticleID},
            UserID           => $UserID,
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
        );

        for my $FileID ( sort keys %Index ) {
            my %Attachment = (
                %Article,
                %{ $Index{$FileID} },
            );

            $Attachment{IsPreviewable}
                = $Kernel::OM->Get('Kernel::System::AttachmentPreview')->IsPreviewable(%Attachment);
            $Attachment{FileID}   = $FileID;
            $Attachment{DataJSON} = $JSONObject->Encode(
                Data => {
                    FileID    => $Attachment{FileID},
                    ArticleID => $Article{ArticleID},
                },
            );

            my $RowsPerPage = $ConfigObject->Get('Ticket::Frontend::MaxArticlesPerPage') || 1000;
            $Attachment{ArticlePage} = ceil( scalar @Articles / $RowsPerPage );

            # get icon class
            $Attachment{FileTypeCSS} = $Self->AttachmentIconClassGet(%Attachment);

            # get css for direction icon
            $Attachment{FileArticleTypeCSS} = $Self->AttachmentDirectionIconClassGet(%Article);

            # get inline element
            $Attachment{InlineElement} = $Attachment{Disposition} eq 'inline' ? 1 : 0;

            push @Attachments, \%Attachment;
        }
    }

    return @Attachments;
}

=head2 CreateTicketAttachmentZipArchive()

    Creates a Zip archive for the given article and file IDs of a ticket.
    Returns the content of the generated Zip archive.

    my $ZipArchiveContentRef = $AttachmentsObject->CreateTicketAttachmentZipArchive(
        TicketID    => 140,

        # The returned array from ArticleAttachmentListGet() can be used here.
        # Filename is optional and defaults to the filename stored with the attachment.
        Attachments => [
            {
                ArticleID => 176,
                FileID    => 1,
                Filename  => 'test1.txt',
            },
            {
                ArticleID => 178,
                FileID    => 2,
                Filename  => 'test2.txt'
            },
            {
                ArticleID => 179,
                FileID    => 1,
                Filename  => 'test2-2.txt'
            },
            # ...
        ],
        UserID => 1,
    );

    Returns string ref with content of created Zip archive.

=cut

sub CreateTicketAttachmentZipArchive {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject     = $Kernel::OM->Get('Kernel::System::Main');
    my $ArticleObject  = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $FileTempObject = $Kernel::OM->Get('Kernel::System::FileTemp');
    my $EncodeObject   = $Kernel::OM->Get('Kernel::System::Encode');

    NEEDED:
    for my $Needed (qw( TicketID Attachments UserID )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !IsArrayRefWithData( $Param{Attachments} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Attachments' must be an array ref with data!",
        );
        return;
    }

    # Ensure unique filenames.
    # Don't rely on Attachments parameter being generated by ArticleAttachmentListGet().
    # I could have been assembled manually.
    my %FilenameCounters;

    my %FileContentByFilename;

    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {
        my %ArticleAttachment = $ArticleObject->ArticleAttachment(
            TicketID  => $Param{TicketID},
            ArticleID => $Attachment->{ArticleID},
            FileID    => $Attachment->{FileID},
            UserID    => $Param{UserID},
        );
        if ( !%ArticleAttachment ) {
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                    "Attachment for ticket ID $Param{TicketID}, article ID $Attachment->{ArticleID} and file ID $Attachment->{FileID} could not be found.",
            );
            next ATTACHMENT;
        }

        # Ensure unique filename. Callers that only know article and file ID may omit it.
        # Filename is sanitized so path segments cannot slip into the ZIP member name
        # (including Unicode slash lookalikes used to bypass a plain basename strip).
        my $Filename = $Self->_SanitizeZipMemberName(
            $Attachment->{Filename} // $ArticleAttachment{Filename},
        );
        $Filename = $Self->_GenerateUniqueFilename(
            FilenameToCheck  => $Filename,
            FilenameCounters => \%FilenameCounters,
        );
        next ATTACHMENT if !$Filename;

        # Encode filename to be UTF-8 to avoid problems with Zip archive.
        $EncodeObject->EncodeOutput( \$Filename );

        $FileContentByFilename{$Filename} = \$ArticleAttachment{Content};
    }

    return if !%FileContentByFilename;

    my $ZipArchive = Archive::Zip->new();
    for my $Filename ( sort keys %FileContentByFilename ) {
        my $FileContent = ${ $FileContentByFilename{$Filename} };
        $ZipArchive->addString( $FileContent, $Filename );
    }

    my ( $ZipArchiveFH, $ZipArchiveFilename ) = $FileTempObject->TempFile();
    if ( $ZipArchive->writeToFileHandle($ZipArchiveFH) != AZ_OK ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error writing zip archive to temporary file $ZipArchiveFilename.",
        );
        return;
    }
    close $ZipArchiveFH;

    my $ZipArchiveContentRef = $MainObject->FileRead(
        Location => $ZipArchiveFilename,
    );
    if ( !$ZipArchiveContentRef ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error reading zip archive from temporary file $ZipArchiveFilename.",
        );
        return;
    }

    return $ZipArchiveContentRef;
}

=head2 AddAttachmentsToArticle()

    Adds attachments to an existing article (that might already have attachments).
    Ensures that there are no duplicate filenames within the article.

    my $AttachmentsAdded = $AttachmentsObject->AddAttachmentsToArticle(
        TicketID  => 140,
        ArticleID => 192,

        # Key is article ID, values is array of file IDs of the article.
        ArticleFileIDsToAdd => {
            176 => [ 1, 3, ],
            178 => [ 2, ],
            179 => [ 1, 5, 7, ],
        },

        UserID => 1,
    );

=cut

sub AddAttachmentsToArticle {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw( TicketID ArticleID ArticleFileIDsToAdd UserID )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !IsHashRefWithData( $Param{ArticleFileIDsToAdd} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Parameter "ArticleFileIDsToAdd" must be a hash ref with data.',
        );
        return;
    }

    # Fetch attachment filenames of the article to which the other attachments will be added.
    # This is needed to ensure unique filenames within the article.
    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $Param{TicketID},
        ArticleID        => $Param{ArticleID},
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
        ExcludeInline    => 1,
    );

    my %FilenameCounters;

    FILEID:
    for my $FileID ( sort keys %AttachmentIndex ) {
        my $Filename = $AttachmentIndex{$FileID}->{Filename};
        $FilenameCounters{$Filename}++;
    }

    # Add attachments to existing article.
    ARTICLEID:
    for my $ArticleID ( sort keys %{ $Param{ArticleFileIDsToAdd} } ) {
        my $TicketID = $ArticleObject->TicketIDLookup(
            ArticleID => $ArticleID,
        );
        if ( !$TicketID ) {
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                    "Ticket ID for article ID $ArticleID could not be found.",
            );

            next ARTICLEID;
        }

        my $ArticleBackendObject = $ArticleObject->BackendForArticle(
            TicketID  => $TicketID,
            ArticleID => $ArticleID,
        );
        next ARTICLEID if !$ArticleBackendObject;
        next ARTICLEID if !$ArticleBackendObject->can('ArticleWriteAttachment');

        FILEID:
        for my $FileID ( @{ $Param{ArticleFileIDsToAdd}->{$ArticleID} } ) {
            my %ArticleAttachment = $ArticleObject->ArticleAttachment(
                TicketID  => $Param{TicketID},
                ArticleID => $ArticleID,
                FileID    => $FileID,
                UserID    => $Param{UserID},
            );
            if ( !%ArticleAttachment ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                        "Attachment for ticket ID $TicketID, article ID $ArticleID and file ID $FileID could not be found.",
                );
                next FILEID;
            }

            # Keep filename unique across all attachments of the article.
            my $Filename = $Self->_GenerateUniqueFilename(
                FilenameToCheck  => $ArticleAttachment{Filename},
                FilenameCounters => \%FilenameCounters,
            );
            next FILEID if !$Filename;

            my $ArticleAttachmentAdded = $ArticleBackendObject->ArticleWriteAttachment(
                Content     => $ArticleAttachment{Content},
                ContentType => $ArticleAttachment{ContentType},
                Filename    => $Filename,
                Disposition => 'attachment',
                ArticleID   => $Param{ArticleID},
                UserID      => $Param{UserID},
            );
            if ( !$ArticleAttachmentAdded ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                        "Error adding attachment with filename '$Filename' to ticket ID $TicketID, article ID $ArticleID.",
                );
                next FILEID;
            }
        }
    }

    $ArticleObject->_ArticleCacheClear(
        TicketID => $Param{TicketID},
    );

    return 1;
}

=head2 AttachmentIconClassGet()

This function will return the icon class for the attachment.

    my $IconClass = $AttachmentsObject->AttachmentIconClassGet(
        ContentType => 'application/pdf',
    );

Returns:

    my $IconClass = 'fa-file-word-o';

=cut

sub AttachmentIconClassGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ContentType)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $ContentType = $Param{ContentType};

    my %Classes = (
        'fa-file-image-o' => qr{ ^image/ }xmsi,
        'fa-file-pdf-o'   => qr{ application/pdf }xmsi,
        'fa-file-word-o'  => qr{
            application/vnd.openxmlformats-officedocument.wordprocessingml.document
            | application/vnd.oasis.opendocument.text
            | application/msword
            | application/rtf
            | text/rtf
            | application/vnd.openxmlformats-officedocument.wordprocessingml.template
        }xmsi,
        'fa-file-excel-o' => qr{
            application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
            | application/msexcel
            | application/vnd.ms-excel
            | application/vnd.openxmlformats-officedocument.spreadsheetml.template
        }xmsi,
        'fa-file-powerpoint-o' => qr{
            application/vnd.ms-powerpoint
            | application/mspowerpoint
            | application/vnd.openxmlformats-officedocument.presentationml.presentation
            | application/vnd.openxmlformats-officedocument.presentationml.template
            | application/vnd.openxmlformats-officedocument.presentationml.slideshow
        }xmsi,
        'fa-file-audio-o'   => qr{ ^audio/ }xmsi,
        'fa-file-video-o'   => qr{ ^video/ }xmsi,
        'fa-file-archive-o' => qr{
            application/x-zip-compressed
            | application/gzip
            | application/zip
            | application/x-rar-compressed
            | application/x-gtar
        }xmsi,
    );

    # set CSS icon class name for different file types
    my $Result = 'fa-file-o';
    TYPE:
    for my $Class ( sort keys %Classes ) {
        my $Regex = $Classes{$Class};

        next TYPE if $ContentType !~ $Regex;

        $Result = $Class;

        last TYPE;
    }

    return $Result;
}

=head2 AttachmentDirectionIconClassGet()

This function will return the icon class for the direction.

    my $IconClass = $AttachmentsObject->AttachmentDirectionIconClassGet(
        IsVisibleForCustomer => 1,
        SenderType           => 'customer',
    );

Returns:

    my $IconClass = 'fa-long-arrow-left';

=cut

sub AttachmentDirectionIconClassGet {
    my ( $Self, %Param ) = @_;

    return                      if !$Param{IsVisibleForCustomer};
    return 'fa-long-arrow-left' if $Param{SenderType} eq 'customer';
    return 'fa-long-arrow-right';
}

=head2 _SanitizeZipMemberName()

    Returns a ZIP member name that cannot express a relative or absolute path.
    Control characters, native separators, Unicode slash lookalikes and Windows
    drive/ADS colons are neutralized; only the final path segment is kept.
    Empty names and C<.>/C<..> fall back to C<attachment>.

    my $SafeName = $AttachmentsObject->_SanitizeZipMemberName('../foo.txt');
    # 'foo.txt'

=cut

sub _SanitizeZipMemberName {
    my ( $Self, $Filename ) = @_;

    return 'attachment' if !defined $Filename;

    # Normalize every known path separator to ASCII '/' before taking the basename,
    # including Unicode lookalikes used to bypass a plain '/' strip.
    $Filename =~ s{[\\/\x{FF0F}\x{2215}\x{2044}]}{/}g;

    # ASCII controls (including NUL) must not reach the ZIP.
    $Filename =~ s{[\x{00}-\x{1f}]}{ }g;

    # Windows drive letters and alternate data streams.
    $Filename =~ s{:}{ }g;

    # Keep only the final path segment.
    $Filename =~ s{.*/}{}g;

    $Filename =~ s{\A\s+|\s+\z}{}g;
    $Filename =~ s{\s+}{ }g;

    return 'attachment' if $Filename =~ m{^ (?: \s* | \.\.? ) $ }x;

    return $Filename;
}

=head2 _AddFilenameCounter()

    Adds counter to a given filename (to prevent duplicate filenames).

    my $FilenameWithCounter = $AttachmentsObject->_AddFilenameCounter(
        Filename        => 'test.txt',
        FilenameCounter => 3,
    );

    my $FilenameWithCounter = 'test-3.txt';

=cut

sub _AddFilenameCounter {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw( Filename FilenameCounter )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Filename        = $Param{Filename};
    my $FilenameCounter = $Param{FilenameCounter};

    # Start search for dot at second character of filename
    # because the first character could be the dot of a hidden file as in '.hidden.txt'.
    my $FilenameDotPosition  = index( $Filename, '.', 1 );
    my $FilenameHasExtension = $FilenameDotPosition != -1 ? 1 : 0;
    if ($FilenameHasExtension) {

        # Add file counter after base filename (before first extension).
        $Filename =~ s{\A(.+?)(\.)}{$1_$FilenameCounter$2};

        return $Filename;
    }

    # Add file counter to end of filename.
    $Filename .= "_$FilenameCounter";

    return $Filename;
}

=head2 _GenerateUniqueFilename()

    If necessary, adds counter to a given filename to prevent duplicate filenames.

    my $UniqueFilename = $AttachmentsObject->_GenerateUniqueFilename(
        FilenameToCheck => 'test.txt',

        # Increases counter for generated file names on hash ref.
        FilenameCounters => {
            # would be turned into test_2.txt if FilenameToCheck is test.txt
            'test.txt'      => 1,

            # would be turned into my_file_2_3.jpg if FilenameToCheck is my_file_2.jpg
            # because counter is 2 and therefore there was already a my_file_2_2.jpg generated before.
            'my_file_2.jpg' => 2,
        },
    );

    my $UniqueFilename = 'test_2.txt';

=cut

sub _GenerateUniqueFilename {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw( FilenameToCheck FilenameCounters )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( ref $Param{FilenameCounters} ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'FilenameCounters' must be a hash ref.",
        );
        return;
    }

    my $Filename         = $Param{FilenameToCheck};
    my $FilenameCounters = $Param{FilenameCounters};

    $FilenameCounters->{$Filename}++;

    while ( $FilenameCounters->{$Filename} > 1 ) {
        $Filename = $Self->_AddFilenameCounter(
            Filename        => $Filename,
            FilenameCounter => $FilenameCounters->{$Filename},
        );

        # Also add newly created filename to counters to avoid e. g. the case
        # where test1.txt turns into test1_2.txt but an original file with name test1_2.txt
        # was also present.
        $FilenameCounters->{$Filename}++;

        # Loop protection
        if ( $FilenameCounters->{$Filename} > 1000 ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Generating unique filename for '$Filename' cancelled after 1000 tries.",
            );
            return;
        }
    }

    return $Filename;
}

1;
