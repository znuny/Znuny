# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminSignature;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

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

    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
    my $YAMLObject      = $Kernel::OM->Get('Kernel::System::YAML');

    my $Notification = $ParamObject->GetParam( Param => 'Notification' ) || '';

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID   = $ParamObject->GetParam( Param => 'ID' ) || '';
        my %Data = $SignatureObject->SignatureGet(
            ID => $ID,
        );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Signature updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Text Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }
        $GetParam{'Text'} = $ParamObject->GetParam(
            Param => 'Text',
            Raw   => 1
        ) || '';

        # get content type
        my $ContentType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $ContentType = 'text/html';
        }

        # check needed data
        for my $Needed (qw(Name ValidID Text)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            # update signature
            my $Update = $SignatureObject->SignatureUpdate(
                %GetParam,
                ContentType => $ContentType,
                UserID      => $Self->{UserID},
            );
            if ($Update) {

                # if the user would like to continue editing the signature, just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$ID;Notification=Update"
                    );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Update" );
                }
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Change',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam = ();
        $GetParam{Name} = $ParamObject->GetParam( Param => 'Name' );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }
        $GetParam{'Text'} = $ParamObject->GetParam(
            Param => 'Text',
            Raw   => 1
        ) || '';

        # get content type
        my $ContentType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $ContentType = 'text/html';
        }

        # check needed data
        for my $Needed (qw(Name ValidID Text)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add signature
            my $NewSignature = $SignatureObject->SignatureAdd(
                %GetParam,
                ContentType => $ContentType,
                UserID      => $Self->{UserID},
            );

            if ($NewSignature) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Signature added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminSignature',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Add',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # Delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my %GetParam;
        for my $Parameter (qw(ID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        my $Delete = $SignatureObject->SignatureDelete(
            ID     => $GetParam{ID},
            UserID => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen() if !$Delete;
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # SignatureExport
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SignatureExport' ) {

        my $SignatureID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $SignatureData;
        my $SignatureName;
        if ($SignatureID) {
            $SignatureData = $SignatureObject->SignatureExport(
                ID => $SignatureID,
            );

            return $LayoutObject->ErrorScreen(
                Message =>
                    $LayoutObject->{LanguageObject}->Translate( 'Error exporting signature with ID %s!', $SignatureID ),
            ) if !IsArrayRefWithData($SignatureData);

            $SignatureName = $SignatureData->[0]->{Name};
        }
        else {
            $SignatureData = $SignatureObject->SignatureExport(
                ExportAll => 1,
            );
        }

        my $Filename = $SignatureObject->SignatureExportFilenameGet(
            Name   => $SignatureName,
            Format => 'YAML',
        );

        # convert signature data hash to string
        my $SignatureDataYAML = $YAMLObject->Dump( Data => $SignatureData );

        # send the result to the browser
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $SignatureDataYAML,
            Type        => 'attachment',
            Filename    => $Filename,
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # SignatureCopy
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SignatureCopy' ) {

        my $SignatureID = $ParamObject->GetParam( Param => 'ID' ) || '';

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $NewResponseID = $SignatureObject->SignatureCopy(
            ID     => $SignatureID,
            UserID => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen(
            Message => Translatable("Error creating the signature."),
        ) if !$NewResponseID;

        # return to overview
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # SignatureImport
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SignatureImport' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $FormID      = $ParamObject->GetParam( Param => 'FormID' ) || '';
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param  => 'FileUpload',
            Source => 'string',
        );

        my $OverwriteExistingSignatures = $ParamObject->GetParam( Param => 'OverwriteExistingSignatures' ) || '';

        my $SignatureImport = $SignatureObject->SignatureImport(
            Content                     => $UploadStuff{Content},
            OverwriteExistingSignatures => $OverwriteExistingSignatures,
            UserID                      => $Self->{UserID},
            ValidID                     => 0,
        );

        if ( !$SignatureImport->{Success} ) {
            my $Message = $SignatureImport->{Message}
                || Translatable(
                'Signatures could not be imported due to an unknown error. Please check logs for more information.'
                );
            return $LayoutObject->ErrorScreen(
                Message => $Message,
            );
        }

        if ( $SignatureImport->{Added} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following signatures have been added successfully: %s.',
                    $SignatureImport->{Added}
                ),
            };
        }
        if ( $SignatureImport->{Updated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following signatures have been updated successfully: %s.',
                    $SignatureImport->{Updated}
                ),
            };
        }
        if ( $SignatureImport->{NotUpdated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following signatures were not updated: %s.',
                    $SignatureImport->{NotUpdated}
                ),
            };
        }
        if ( $SignatureImport->{Errors} ) {
            push @{ $Param{NotifyData} }, {
                Priority => 'Error',
                Info     => $LayoutObject->{LanguageObject}->Translate(
                    'Errors adding/updating the following signatures: %s. Please check logs for more information.',
                    $SignatureImport->{Errors}
                ),
            };
        }
        if ( IsArrayRefWithData( $SignatureImport->{AdditionalErrors} ) ) {
            for my $Error ( @{ $SignatureImport->{AdditionalErrors} } ) {
                push @{ $Param{NotifyData} }, {
                    Priority => 'Error',
                    Info     => $LayoutObject->{LanguageObject}->Translate($Error),
                };
            }
        }

        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # show Signatures if any
        if ( $Param{NotifyData} ) {
            for my $Signature ( @{ $Param{NotifyData} } ) {
                $Output .= $LayoutObject->Notify(
                    %{$Signature},
                );
            }
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Signature updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSignature',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );

        # reformat from plain to html
        if ( $Param{ContentType} && $Param{ContentType} =~ /text\/plain/i ) {
            $Param{Text} = $HTMLUtilsObject->ToHTML(
                String => $Param{Text},
            );
        }
    }
    else {

        # reformat from html to plain
        if ( $Param{ContentType} && $Param{ContentType} =~ /text\/html/i ) {
            $Param{Text} = $HTMLUtilsObject->ToAscii(
                String => $Param{Text},
            );
        }
    }

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'ActionList',
    );

    $LayoutObject->Block(
        Name => 'ActionOverview',
    );

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );
    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # shows header
    if ( $Param{Action} eq 'Change' ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'ActionList',
    );

    $LayoutObject->Block(
        Name => 'ActionAdd',
    );

    $LayoutObject->Block(
        Name => 'ActionImportExport',
    );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'Filter'
    );

    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
    my %List            = $SignatureObject->SignatureList(
        Valid => 0,
    );

    # if there are any results, they are shown
    if (%List) {

        # get valid list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
        for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {

            my %Data = $SignatureObject->SignatureGet( ID => $ListKey );
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    Valid => $ValidList{ $Data{ValidID} },
                    %Data,
                },
            );
        }
    }

    # otherwise a no data message is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }
    return 1;
}

1;
