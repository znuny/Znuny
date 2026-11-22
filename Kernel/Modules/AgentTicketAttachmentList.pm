# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketAttachmentList;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Attachments',
    'Kernel::System::JSON',
    'Kernel::System::Ticket',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
    my $AttachmentsObject = $Kernel::OM->Get('Kernel::System::Attachments');

    return $LayoutObject->NoPermission( WithHeader => 'yes' ) if !$TicketObject->TicketPermission(
        Type     => 'ro',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    # get ACL restrictions
    my %PossibleActions = ( 1 => $Self->{Action} );

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );
    my %AclAction = $TicketObject->TicketAclActionData();

    # check if ACL restrictions exist
    if ( $ACL || %AclAction ) {
        my %AclActionLookup = reverse %AclAction;

        # show error screen if ACL prohibits this action
        if ( !$AclActionLookup{ $Self->{Action} } ) {
            return $LayoutObject->NoPermission( WithHeader => 'yes' );
        }
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    my $Subaction = $Self->{Subaction} // '';
    return $Self->_DownloadAsZIP( Ticket => \%Ticket ) if $Subaction eq 'DownloadAsZIP';
    return $Self->_DownloadZipArchive()                if $Subaction eq 'DownloadZipArchive';

    my @Attachments = $AttachmentsObject->ArticleAndAttachmentListGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    my $Output = $LayoutObject->Header(
        Value     => $Ticket{Number},
        Type      => 'Small',
        BodyClass => 'Popup',
    );

    $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
        Key  => 'AgentTicketAttachmentList',
        Code => 'Core.Agent.Attachments.InitAgentTicketAttachmentList();',
    );

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get('Attachment') // {};

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentTicketAttachmentList',
        Data         => {
            %Param,
            %Ticket,
            Attachments   => \@Attachments,
            EnablePreview => $Config->{EnablePreview},
        },
    );

    $Output .= $LayoutObject->Footer(
        Type => 'Small',
    );

    return $Output;
}

# Zips the attachments selected in the attachment list popup. That list also offers inline
# attachments and duplicates, so the selection is used as given instead of being matched
# against ArticleAttachmentListGet().
sub _DownloadAsZIP {
    my ( $Self, %Param ) = @_;

    my $JSONObject        = $Kernel::OM->Get('Kernel::System::JSON');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $AttachmentsObject = $Kernel::OM->Get('Kernel::System::Attachments');

    my @AttachmentsChecked = $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray( Param => 'Attachments' );

    my %ValidArticleIDMap = map { $_->{ArticleID} => 1 }
        $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleList( TicketID => $Self->{TicketID} );
    my @SelectedTicketAttachments;

    ATTACHMENT:
    for my $AttachmentJSON (@AttachmentsChecked) {

        my $Attachment = $JSONObject->Decode(
            Data => $AttachmentJSON,
        );
        next ATTACHMENT if !IsHashRefWithData($Attachment);

        if ( !$ValidArticleIDMap{ $Attachment->{ArticleID} } ) {
            $LayoutObject->FatalError(
                Message => 'Invalid ArticleID!',
            );
        }

        push @SelectedTicketAttachments, {
            ArticleID => $Attachment->{ArticleID},
            FileID    => $Attachment->{FileID},
        };
    }

    my $ZipArchiveContentRef = $AttachmentsObject->CreateTicketAttachmentZipArchive(
        TicketID    => $Self->{TicketID},
        Attachments => \@SelectedTicketAttachments,
        UserID      => $Self->{UserID},
    );
    if ( !$ZipArchiveContentRef ) {
        $LayoutObject->FatalError(
            Message => 'Error creating Zip archive.',
        );
    }

    return $LayoutObject->Attachment(
        Filename    => 'Ticket-Attachments-' . $Param{Ticket}->{TicketNumber} . '.zip',
        ContentType => 'application/zip',
        Content     => $$ZipArchiveContentRef,
        NoCache     => 1,
    );
}

# Zips the attachments selected in the ticket zoom sidebar widget. That widget lists the
# deduplicated, non-inline attachments of ArticleAttachmentListGet(), so the selection is
# validated against that list.
sub _DownloadZipArchive {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AttachmentsObject = $Kernel::OM->Get('Kernel::System::Attachments');

    my @ArticleFileIDStrings = $ParamObject->GetArray( Param => 'ArticleFileIDString' );
    if ( !@ArticleFileIDStrings ) {
        $LayoutObject->FatalError(
            Message => 'Parameter ArticleFileIDString is missing.',
        );
    }

    my $TicketAttachments = $AttachmentsObject->ArticleAttachmentListGet(
        TicketID => $Self->{TicketID},
    );

    if ( !IsArrayRefWithData($TicketAttachments) ) {
        $LayoutObject->FatalError(
            Message => "Ticket with ID $Self->{TicketID} does not contain any article with attachments.",
        );
    }

    my %AttachmentByArticleFileID = map { ( "$_->{ArticleID},$_->{FileID}" => $_ ) } @{$TicketAttachments};

    my @SelectedTicketAttachments;
    for my $ArticleFileIDString (@ArticleFileIDStrings) {
        my $Attachment = $AttachmentByArticleFileID{$ArticleFileIDString};

        if ( !$Attachment ) {
            $LayoutObject->FatalError(
                Message =>
                    "ArticleFileIDString parameter contains invalid article and/or file ID for ticket with ID $Self->{TicketID}: $ArticleFileIDString.",
            );
        }

        push @SelectedTicketAttachments, $Attachment;
    }

    my $ZipArchiveContentRef = $AttachmentsObject->CreateTicketAttachmentZipArchive(
        TicketID    => $Self->{TicketID},
        Attachments => \@SelectedTicketAttachments,
        UserID      => $Self->{UserID},
    );
    if ( !$ZipArchiveContentRef ) {
        $LayoutObject->FatalError(
            Message => 'Error creating Zip archive.',
        );
    }

    return $LayoutObject->Attachment(
        Filename    => "TicketAttachments$Self->{TicketID}.zip",
        ContentType => 'application/zip',
        Content     => $$ZipArchiveContentRef,
        NoCache     => 1,
    );
}

1;
