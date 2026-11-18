# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketZoom::Attachments;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;
use Kernel::System::VariableCheck qw( IsArrayRefWithData );

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $AttachmentPreviewObject = $Kernel::OM->Get('Kernel::System::AttachmentPreview');
    my $AttachmentsObject       = $Kernel::OM->Get('Kernel::System::Attachments');

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get('Attachment') // {};

    my %Ticket = %{ $Param{Ticket} };

    return if $AttachmentsObject->IsArticleCountReached(
        TicketID => $Ticket{TicketID},
    );

    return if $AttachmentsObject->IsArticleAttachmentCountReached(
        TicketID => $Ticket{TicketID},
    );

    my $TicketAttachments = $AttachmentsObject->ArticleAttachmentListGet(
        TicketID => $Ticket{TicketID},
        UserID   => $Self->{UserID},
    );
    return if !IsArrayRefWithData($TicketAttachments);

    my $ShowAttachmentsCount = $Config->{ $LayoutObject->{Action} }->{ShowAttachmentsCount}
        // $Config->{ShowAttachmentsCount};

    # Add previewability to every attachment
    $_->{IsPreviewable} = $AttachmentPreviewObject->IsPreviewable(%$_) for @{$TicketAttachments};

    $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
        Key  => __PACKAGE__ . '::Run',
        Code => 'Core.Agent.Attachments.InitTicketAttachmentZipArchiveDownload();',
    );

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketZoom/Attachments',
        Data         => {
            TicketID             => $Ticket{TicketID},
            Attachments          => $TicketAttachments,
            EnablePreview        => $Config->{EnablePreview},
            ShowAttachmentsCount => $ShowAttachmentsCount,
        },
    );

    return {
        Output => $Output,
        defined $Param{Config}{Rank} ? ( Rank => $Param{Config}{Rank} ) : (),
    };
}

1;
