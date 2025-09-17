# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminSalutation;

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

    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');
    my $YAMLObject       = $Kernel::OM->Get('Kernel::System::YAML');

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID   = $ParamObject->GetParam( Param => 'ID' ) || '';
        my %Data = $SalutationObject->SalutationGet(
            ID => $ID,
        );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSalutation',
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

        my $Note = '';
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

            # update salutation
            my $Update = $SalutationObject->SalutationUpdate(
                %GetParam,
                ContentType => $ContentType,
                UserID      => $Self->{UserID},
            );
            if ($Update) {

                # if the user would like to continue editing the salutation, just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Subaction=Change;ID=$ID" );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
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
            TemplateFile => 'AdminSalutation',
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
            TemplateFile => 'AdminSalutation',
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

        my $Note = '';
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

            # add salutation
            my $AddressID = $SalutationObject->SalutationAdd(
                %GetParam,
                ContentType => $ContentType,
                UserID      => $Self->{UserID},
            );

            if ($AddressID) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Salutation added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminSalutation',
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
            TemplateFile => 'AdminSalutation',
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

        my $Delete = $SalutationObject->SalutationDelete(
            ID     => $GetParam{ID},
            UserID => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen() if !$Delete;
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # SalutationExport
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SalutationExport' ) {

        my $SalutationID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $SalutationData;
        my $SalutationName;
        if ($SalutationID) {
            $SalutationData = $SalutationObject->SalutationExport(
                ID => $SalutationID,
            );

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Error exporting salutation with ID %s!', $SalutationID ),
            ) if !IsArrayRefWithData($SalutationData);

            $SalutationName = $SalutationData->[0]->{Name};
        }
        else {
            $SalutationData = $SalutationObject->SalutationExport(
                ExportAll => 1,
            );
        }

        my $Filename = $SalutationObject->SalutationExportFilenameGet(
            Name   => $SalutationName,
            Format => 'YAML',
        );

        # convert the Salutation data hash to string
        my $SalutationDataYAML = $YAMLObject->Dump( Data => $SalutationData );

        # send the result to the browser
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $SalutationDataYAML,
            Type        => 'attachment',
            Filename    => $Filename,
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # SalutationCopy
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SalutationCopy' ) {

        my $SalutationID = $ParamObject->GetParam( Param => 'ID' ) || '';

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $NewResponseID = $SalutationObject->SalutationCopy(
            ID     => $SalutationID,
            UserID => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen(
            Message => Translatable("Error creating the salutation."),
        ) if !$NewResponseID;

        # return to overview
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # SalutationImport
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SalutationImport' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $FormID      = $ParamObject->GetParam( Param => 'FormID' ) || '';
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param  => 'FileUpload',
            Source => 'string',
        );

        my $OverwriteExistingSalutations = $ParamObject->GetParam( Param => 'OverwriteExistingSalutations' ) || '';

        my $SalutationImport = $SalutationObject->SalutationImport(
            Content                      => $UploadStuff{Content},
            OverwriteExistingSalutations => $OverwriteExistingSalutations,
            UserID                       => $Self->{UserID},
        );

        if ( !$SalutationImport->{Success} ) {
            my $Message = $SalutationImport->{Message}
                || Translatable(
                'Salutations could not be imported due to an unknown error. Please check logs for more information.'
                );
            return $LayoutObject->ErrorScreen(
                Message => $Message,
            );
        }

        if ( $SalutationImport->{Added} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following salutations have been added successfully: %s.',
                    $SalutationImport->{Added}
                ),
            };
        }
        if ( $SalutationImport->{Updated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following salutations have been updated successfully: %s.',
                    $SalutationImport->{Updated}
                ),
            };
        }
        if ( $SalutationImport->{NotUpdated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following salutations were not updated: %s.',
                    $SalutationImport->{NotUpdated}
                ),
            };
        }
        if ( $SalutationImport->{Errors} ) {
            push @{ $Param{NotifyData} }, {
                Priority => 'Error',
                Info     => $LayoutObject->{LanguageObject}->Translate(
                    'Errors adding/updating the following salutations: %s. Please check logs for more information.',
                    $SalutationImport->{Errors}
                ),
            };
        }
        if ( IsArrayRefWithData( $SalutationImport->{AdditionalErrors} ) ) {
            for my $Error ( @{ $SalutationImport->{AdditionalErrors} } ) {
                push @{ $Param{NotifyData} }, {
                    Priority => 'Error',
                    Info     => $LayoutObject->{LanguageObject}->Translate($Error),
                };
            }
        }

        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # show Salutations if any
        if ( $Param{NotifyData} ) {
            for my $Salutation ( @{ $Param{NotifyData} } ) {
                $Output .= $LayoutObject->Notify(
                    %{$Salutation},
                );
            }
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSalutation',
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
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSalutation',
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
        Name => 'Filter',
    );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');

    my %List = $SalutationObject->SalutationList(
        Valid => 0,
    );

    # if there are any results, they are shown
    if (%List) {

        # get valid list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
        for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {

            my %Data = $SalutationObject->SalutationGet( ID => $ListKey );
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
