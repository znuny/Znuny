# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::ObjectDependencies)

package Kernel::System::UnitTest::TicketToUnitTest::HistoryType::AddNote;

use strict;
use warnings;
use utf8;

use MIME::Base64 qw();

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ArticleID TicketID HistoryType)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %Article = $ArticleObject->ArticleGet(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID},
        UserID    => 1,
    );

    $Article{Body}     //= '';
    $Article{Charset}  //= '';
    $Article{MimeType} //= 'text/plain';

    my %HTMLBodyIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID     => $Param{TicketID},
        ArticleID    => $Param{ArticleID},
        OnlyHTMLBody => 1,
    );

    my @HTMLBodyFileIDs = sort { $a <=> $b } keys %HTMLBodyIndex;
    my $HTMLBodyFileID  = $HTMLBodyFileIDs[0];

    if ( defined $HTMLBodyFileID ) {
        my %HTMLBody = $ArticleObject->ArticleAttachment(
            TicketID  => $Param{TicketID},
            ArticleID => $Param{ArticleID},
            FileID    => $HTMLBodyFileID,
        );

        if ( defined $HTMLBody{Content} && length $HTMLBody{Content} ) {
            $Article{Body}     = $HTMLBody{Content};
            $Article{MimeType} = 'text/html';

            if ( $HTMLBody{ContentType} && $HTMLBody{ContentType} =~ /charset\s*=\s*["']?([^"';\s]+)/i ) {
                $Article{Charset} = $1;
            }
        }
    }

    if ( !$Article{Charset} ) {
        $Article{Charset} = 'utf-8';
    }

    my $ChannelName = $Article{CommunicationChannel} || 'Internal';

    my $BodyTerminator = 'BODY';
    if ( $Article{Body} =~ m/^BODY$/m ) {
        $BodyTerminator = 'ZNUNY_TICKET_TO_UNITTEST_BODY';
    }

    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $Param{TicketID},
        ArticleID        => $Param{ArticleID},
        ExcludePlainText => 1,
        ExcludeHTMLBody  => 1,
    );

    my $AttachmentOutput  = '';
    my @AttachmentFileIDs = sort { $a <=> $b } keys %AttachmentIndex;

    if (@AttachmentFileIDs) {
        $AttachmentOutput .= "require MIME::Base64;\n\@Attachments = ();\n\n";
    }

    my $AttachmentCounter = 0;
    FILE_ID:
    for my $FileID (@AttachmentFileIDs) {
        my %Attachment = $ArticleObject->ArticleAttachment(
            TicketID  => $Param{TicketID},
            ArticleID => $Param{ArticleID},
            FileID    => $FileID,
        );

        next FILE_ID if !%Attachment;

        $AttachmentCounter++;

        my $Terminator         = "ZNUNY_ATTACHMENT_$AttachmentCounter";
        my $EncodedContent     = MIME::Base64::encode_base64( $Attachment{Content} // '' );
        my $ContentType        = $Self->_QuotePerlString( $Attachment{ContentType} );
        my $Filename           = $Self->_QuotePerlString( $Attachment{Filename} );
        my $ContentID          = $Self->_QuotePerlString( $Attachment{ContentID} );
        my $ContentAlternative = $Self->_QuotePerlString( $Attachment{ContentAlternative} );
        my $Disposition        = $Self->_QuotePerlString( $Attachment{Disposition} || 'attachment' );

        $AttachmentOutput .= <<"ATTACHMENT";
\$TempValue = <<'$Terminator';
$EncodedContent
$Terminator
chomp \$TempValue;

push \@Attachments, {
    Content            => MIME::Base64::decode_base64(\$TempValue),
    ContentType        => '$ContentType',
    Filename           => '$Filename',
    ContentID          => '$ContentID',
    ContentAlternative => '$ContentAlternative',
    Disposition        => '$Disposition',
};

ATTACHMENT
    }

    my $QuotedSubject     = $Self->_QuotePerlString( $Article{Subject} );
    my $QuotedFrom        = $Self->_QuotePerlString( $Article{From} );
    my $QuotedTo          = $Self->_QuotePerlString( $Article{To} );
    my $QuotedCharset     = $Self->_QuotePerlString( $Article{Charset} );
    my $QuotedMimeType    = $Self->_QuotePerlString( $Article{MimeType} );
    my $QuotedChannelName = $Self->_QuotePerlString($ChannelName);
    my $QuotedHistoryType = $Self->_QuotePerlString( $Param{HistoryType} );
    my $QuotedSenderType  = $Self->_QuotePerlString( $Article{SenderType} );
    my $QuotedVisible     = $Self->_QuotePerlString( $Article{IsVisibleForCustomer} );

    my $AttachmentParam = '';
    if ($AttachmentCounter) {
        $AttachmentParam = "    Attachment            => \\\@Attachments,\n";
    }

    my $Output = $AttachmentOutput;
    $Output .= <<"OUTPUT";
\$TempValue = <<'$BodyTerminator';
$Article{Body}
$BodyTerminator

\$ArticleID = \$HelperObject->ArticleCreate(
    TicketID             => \$TicketID,
    ChannelName          => '$QuotedChannelName',
    Subject              => '$QuotedSubject',
    Body                 => \$TempValue,
    IsVisibleForCustomer => '$QuotedVisible',
    SenderType           => '$QuotedSenderType',
    From                 => '$QuotedFrom',
    To                   => '$QuotedTo',
    Charset              => '$QuotedCharset',
    MimeType             => '$QuotedMimeType',
    HistoryType          => '$QuotedHistoryType',
    HistoryComment       => 'UnitTest',
    UserID               => \$UserID,
$AttachmentParam);

# trigger transaction events
\$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);
\$TicketObject = \$Kernel::OM->Get('Kernel::System::Ticket');

OUTPUT

    return $Output;
}

sub _QuotePerlString {
    my ( $Self, $Value ) = @_;

    $Value //= '';
    $Value =~ s{\\}{\\\\}g;
    $Value =~ s{'}{\\'}g;

    return $Value;
}

1;
