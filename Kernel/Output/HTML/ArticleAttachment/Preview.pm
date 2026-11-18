# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ArticleAttachment::Preview;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AttachmentPreview',
    'Kernel::System::Log',
);

sub Run {
    my ( $Self, %Param ) = @_;

    NEEDED:
    for my $Needed (qw(File Article)) {
        next NEEDED if defined $Param{$Needed};
        $Kernel::OM->Get('Kernel::System::Log')->Error("Parameter '$Needed' is needed!");
        return;
    }

    my $AttachmentPreviewObject = $Kernel::OM->Get('Kernel::System::AttachmentPreview');
    my $IsPDF                   = $AttachmentPreviewObject->IsPDF( %{ $Param{File} // {} } );

    # TODO do we still need this whole attachment type distinction logic?
    if ($IsPDF) {

        # PDF preview depends on a whole bunch of Ticket attributes
        my $Settings = $AttachmentPreviewObject->GetPDFSettings(
            TicketID => $Param{TicketID} || $Param{Article}->{TicketID},
            UserID   => $Self->{UserID}  || 1,
        );
        return if !$Settings->{Active};
    }
    else {
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get('Attachment') // {};
        return if !$Config->{EnablePreview};
        return if !$AttachmentPreviewObject->IsPreviewable( %{ $Param{File} // {} } );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketID     = $Param{Article}->{TicketID} || $Param{TicketID};
    my $ArticleID    = $Param{Article}->{ArticleID};
    my $FileID       = $Param{File}->{FileID};

    my $AttachmentURL = $LayoutObject->{Baselink}
        . "Action=AgentTicketAttachment;TicketID=$TicketID;ArticleID=$ArticleID;FileID=$FileID";

    return (
        %{ $Param{File} },
        Action       => 'Preview',
        Link         => "$AttachmentURL;Preview=1",
        DownloadLink => $AttachmentURL,
        Target       => '',
        Class        => $IsPDF ? 'ArticleAttachmentPreview' : 'AttachmentPreview',
    );
}

1;
