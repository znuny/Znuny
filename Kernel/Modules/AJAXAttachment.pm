# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AJAXAttachment;

use strict;
use warnings;
use utf8;

use MIME::Base64;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $JSONObject        = $Kernel::OM->Get('Kernel::System::JSON');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

    my %GetParam;
    NEEDED:
    for my $Needed (qw(FormID FileID)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed ) || '';
    }

    # Challenge token check for write action
    $LayoutObject->ChallengeTokenCheck();

    if ( $Self->{Subaction} eq 'Upload' ) {

        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'Files',
        );

        $UploadCacheObject->FormIDAddFile(
            FormID      => $GetParam{FormID},
            Disposition => 'attachment',
            %UploadStuff,
        );

        # Get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $GetParam{FormID},
        );

        my @AttachmentData;

        my $PreviewContentTypes = $ConfigObject->Get('Attachment')->{PreviewContentTypes} || {};

        ATTACHMENT:
        for my $Attachment (@Attachments) {

            # Hide inline attachments from the display. Please see bug#13498 for more information.
            next ATTACHMENT if $Attachment->{Disposition} && $Attachment->{Disposition} eq 'inline';

            # Add human readable data size.
            $Attachment->{HumanReadableDataSize} = $LayoutObject->HumanReadableDataSize(
                Size => $Attachment->{Filesize},
            );

            # Add preview flag if content type is in the preview content types list.
            # This is used to determine if the attachment can be previewed in the UI.
            if ( $Attachment->{ContentType} && $PreviewContentTypes->{ $Attachment->{ContentType} } ) {
                $Attachment->{Preview} = 1;
            }

            push @AttachmentData, $Attachment;
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSONObject->Encode(
                Data => \@AttachmentData,
            ),
            Type    => 'inline',
            NoCache => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'Download' ) {

        my %Attachment;
        NEEDED:
        for my $Needed (qw(FileID FormID)) {
            next NEEDED if defined $GetParam{$Needed};

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( '%s is missing. The file could not be downloaded properly.', $Needed ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        my @Attachments = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $GetParam{FormID},
        );

        ATTACHMENT:
        for my $Attachment (@Attachments) {

            next ATTACHMENT if $Attachment->{FileID} ne $GetParam{FileID};
            %Attachment = %{$Attachment};
            last ATTACHMENT;
        }

        return $LayoutObject->Attachment(
            %Attachment,
            ContentType => 'attachment',
            Sandbox     => 1,
        );

    }
    elsif ( $Self->{Subaction} eq 'Preview' ) {

        my %Attachment;
        NEEDED:
        for my $Needed (qw(FileID FormID)) {
            next NEEDED if defined $GetParam{$Needed};

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( '%s is missing. The file could not be previewed properly.', $Needed ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        my @Attachments = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $GetParam{FormID},
        );

        ATTACHMENT:
        for my $Attachment (@Attachments) {

            next ATTACHMENT if $Attachment->{FileID} ne $GetParam{FileID};
            %Attachment = %{$Attachment};

            if ( $Attachment->{ContentType} ) {
                $Attachment{ContentBase64} = encode_base64( $Attachment->{Content} );
                $Attachment{SourceData}    = "data:$Attachment->{ContentType};base64,";
                $Attachment{Template}      = "Iframe";
            }

            last ATTACHMENT;
        }

        my $Content = $JSONObject->Encode(
            Data => {
                Message    => 'Success',
                Attachment => \%Attachment,
            }
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $Content,
            Sandbox     => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        NEEDED:
        for my $Needed (qw(FileID FormID)) {
            next NEEDED if defined $GetParam{$Needed};

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( '%s is missing. The file could not be deleted properly.', $Needed ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        my $DeleteAttachment = $UploadCacheObject->FormIDRemoveFile(
            FormID => $GetParam{FormID},
            FileID => $GetParam{FileID},
        );

        my $Return = {
            Message => 'Error',
            Data    => [],
        };
        if ($DeleteAttachment) {

            my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                FormID => $GetParam{FormID},
            );

            my @AttachmentData;

            ATTACHMENT:
            for my $Attachment (@Attachments) {

                # Hide inline attachments from the display. Please see bug#13498 for more information.
                next ATTACHMENT if $Attachment->{Disposition} eq 'inline';

                push @AttachmentData, $Attachment;
            }

            $Return = {
                Message => 'Success',
                Data    => \@AttachmentData,
            };
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSONObject->Encode(
                Data => $Return,
            ),
            Type    => 'inline',
            NoCache => 1,
        );
    }
}

1;
