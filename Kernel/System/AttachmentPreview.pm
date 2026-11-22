# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::AttachmentPreview;

use strict;
use warnings;
use utf8;
use List::Util qw( any );

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Kernel::System::AttachmentPreview - shared attachment preview type checks

=head1 DESCRIPTION

Decides whether a file may be shown in the attachment preview overlay,
based on C<Attachment###PreviewContentTypes>.

=head1 PUBLIC INTERFACE

=head2 new()

    Don't use the constructor directly, use the ObjectManager instead:

    my $AttachmentPreviewObject = $Kernel::OM->Get('Kernel::System::AttachmentPreview');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 IsPreviewable()

Returns true if the given file can be shown in the preview overlay.

    my $Ok = $AttachmentPreviewObject->IsPreviewable(
        ContentType => 'application/pdf',
        Filename    => 'document.pdf',    # optional
    );

=cut

sub IsPreviewable {
    my ( $Self, %Param ) = @_;

    my $Filename    = $Param{Filename} // '';
    my $ContentType = $Self->_NormalizedContentType( $Param{ContentType} );
    $ContentType = 'image/jpeg' if $ContentType eq 'image/jpg';    # Non-standard alias used by some clients.

    my $AttachmentConfig    = $Kernel::OM->Get('Kernel::Config')->Get('Attachment') || {};
    my $PreviewContentTypes = $AttachmentConfig->{PreviewContentTypes}              || {};

    return 1 if $ContentType                 && $PreviewContentTypes->{$ContentType};
    return 1 if $Filename =~ m{ \.pdf \z }xi && $PreviewContentTypes->{'application/pdf'};
    return 0;
}

=head2 IsPDF()

Returns true if the given file looks like a PDF.

    my $IsPDF = $AttachmentPreviewObject->IsPDF(
        ContentType => 'application/pdf',
        Filename    => 'document.pdf',    # optional
    );

=cut

sub IsPDF {
    my ( $Self, %Param ) = @_;

    my $ContentType = $Self->_NormalizedContentType( $Param{ContentType} );
    my $Filename    = $Param{Filename} // '';

    return 1 if $ContentType eq 'application/pdf';
    return 1 if $Filename =~ m{ \.pdf \z }xi;
    return 0;
}

=head2 GetPDFSettings()

Returns the PDF preview settings for a ticket.

    my $Settings = $AttachmentPreviewObject->GetPDFSettings(
        Ticket   => \%Ticket,    # optional if TicketID is given
        TicketID => 123,         # optional if Ticket is given
        UserID   => 1,           # optional, default 1
    );

Returns:

    {
        Active           => 1,
        ShowFirstPreview => 1,
        Width            => '100%',
        Height           => '500px',
    }

=cut

sub GetPDFSettings {
    my ( $Self, %Param ) = @_;

    my %Ticket   = %{ $Param{Ticket} || {} };
    my $TicketID = $Param{TicketID} || $Ticket{TicketID};

    if ( !$Param{Ticket} && $TicketID && $Self->{_SettingsCache}->{$TicketID} ) {
        return $Self->{_SettingsCache}->{$TicketID};
    }

    if ( !%Ticket && $TicketID ) {
        %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
        );
    }

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get('ArticleZoomPDFPreview') || {};

    my %Settings = (
        Active           => 0,
        ShowFirstPreview => 0,
        Width            => $Config->{Width}  || '100%',
        Height           => $Config->{Height} || '500px',
    );

    # Check whether the current ticket matches the list of attributes and values in the sysconfig
    my $CheckPrefs = sub {
        my ($Attrs) = @_;

        # If $Attrs is unset or %$Attrs empty, always enable
        return 1 if !( defined $Attrs && %$Attrs );

        for my $TicketAttribute ( sort keys %$Attrs ) {

            # If $TicketAttribute is required but not in %$Ticket, fail
            return if !defined $Ticket{$TicketAttribute};

            # Succeed if Ticket attribute matches any from the list, otherwise go on checking
            return 1 if any { $Ticket{$TicketAttribute} eq $_ } @{ $Attrs->{$TicketAttribute} };
        }
    };

    $Settings{Active}           = $CheckPrefs->( $Config->{TicketAttributes}->{ActivatePreview} );
    $Settings{ShowFirstPreview} = $CheckPrefs->( $Config->{TicketAttributes}->{ShowFirstPreview} );

    if ( $Ticket{TicketID} ) {
        $Self->{_SettingsCache}->{ $Ticket{TicketID} } = \%Settings;
    }

    return \%Settings;
}

sub _NormalizedContentType {
    my ( $Self, $ContentType ) = @_;

    return '' if !defined $ContentType;

    $ContentType =~ s{;.*}{}g;
    $ContentType =~ s{\s+}{}g;

    return lc $ContentType;
}

1;
