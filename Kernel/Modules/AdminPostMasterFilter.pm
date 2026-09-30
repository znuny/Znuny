# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminPostMasterFilter;

use strict;
use warnings;

use Kernel::Language              qw(Translatable);
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

    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $Name           = $ParamObject->GetParam( Param => 'Name' );
    my $OldName        = $ParamObject->GetParam( Param => 'OldName' );
    my $StopAfterMatch = $ParamObject->GetParam( Param => 'StopAfterMatch' ) || 0;

    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $PostMasterFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');
    my $YAMLObject             = $Kernel::OM->Get('Kernel::System::YAML');

    # ------------------------------------------------------------ #
    # delete
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Delete = $PostMasterFilterObject->FilterDelete(
            Name => $Name,
        );

        if ( !$Delete ) {
            return $LayoutObject->ErrorScreen();
        }

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => $Delete,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        return $Self->_MaskUpdate( Data => {} );
    }

    # ------------------------------------------------------------ #
    # update
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {
        my %Data = $PostMasterFilterObject->FilterGet( Name => $Name );
        if ( !%Data ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( 'No such filter: %s', $Name ),
            );
        }
        return $Self->_MaskUpdate(
            Name => $Name,
            Data => \%Data,
        );
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'UpdateAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my @Match;
        my @Set;
        my @Not;

        my %GetParam;

        for my $Number ( 1 .. $ConfigObject->Get('PostmasterHeaderFieldCount') ) {
            $GetParam{"MatchHeader$Number"} = $ParamObject->GetParam( Param => "MatchHeader$Number" );
            $GetParam{"MatchValue$Number"}  = $ParamObject->GetParam( Param => "MatchValue$Number" );
            $GetParam{"MatchNot$Number"}    = $ParamObject->GetParam( Param => "MatchNot$Number" );
            $GetParam{"SetHeader$Number"}   = $ParamObject->GetParam( Param => "SetHeader$Number" );
            $GetParam{"SetValue$Number"}    = $ParamObject->GetParam( Param => "SetValue$Number" );

            if ( $GetParam{"MatchHeader$Number"} && length $GetParam{"MatchValue$Number"} ) {
                push @Match, {
                    Key   => $GetParam{"MatchHeader$Number"},
                    Value => $GetParam{"MatchValue$Number"},
                };
                push @Not, {
                    Key   => $GetParam{"MatchHeader$Number"},
                    Value => $GetParam{"MatchNot$Number"},
                };
            }

            if ( $GetParam{"SetHeader$Number"} && length $GetParam{"SetValue$Number"} ) {
                push @Set, {
                    Key   => $GetParam{"SetHeader$Number"},
                    Value => $GetParam{"SetValue$Number"},
                };
            }
        }

        # perform validation
        my %FilterInsertErrors = $PostMasterFilterObject->FilterInsertErrorsCheck(
            Match          => \@Match,
            Set            => \@Set,
            Name           => $Name,
            StopAfterMatch => $StopAfterMatch,
        );

        my %Errors = map { $_ => 'ServerError' } keys %FilterInsertErrors;

        # check if new name already exists if it's different than initial
        if ( !$Errors{NameInvalid} && $Name ne $OldName ) {
            my $AlreadyExists = $PostMasterFilterObject->NameExistsCheck(
                Name => $Name,
            );

            $Errors{NameInvalid} = 'ServerError' if $AlreadyExists;
        }

        if (%Errors) {
            return $Self->_MaskUpdate(
                Name => $Name,
                Data => {
                    %Errors,
                    OldName        => $OldName,
                    Name           => $Name,
                    Set            => \@Set,
                    Match          => \@Match,
                    StopAfterMatch => $StopAfterMatch,
                    Not            => \@Not,
                },
            );
        }
        $PostMasterFilterObject->FilterDelete( Name => $OldName );
        $PostMasterFilterObject->FilterAdd(
            Name           => $Name,
            Match          => \@Match,
            Set            => \@Set,
            StopAfterMatch => $StopAfterMatch,
            Not            => \@Not,
        );

        # if the user would like to continue editing the postmaster filter, just redirect to the update screen
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            my $URIEscapedName = $LayoutObject->LinkEncode($Name);    # See internal issues #478 and #684.
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Subaction=Update;Name=$URIEscapedName" );
        }
        else {

            # otherwise return to overview
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }

        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # Export
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FilterExport' ) {

        my $FilterName = $ParamObject->GetParam( Param => 'Name' ) || '';
        my $FilterData;
        if ($FilterName) {
            $FilterData = $PostMasterFilterObject->FilterExport(
                Name => $FilterName,
            );

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Error exporting postmaster filter with Name %s!', $FilterName ),
            ) if !IsArrayRefWithData($FilterData);
        }
        else {
            $FilterData = $PostMasterFilterObject->FilterExport(
                ExportAll => 1,
            );
        }

        my $Filename = $PostMasterFilterObject->FilterExportFilenameGet(
            Name   => $FilterName,
            Format => 'YAML',
        );

        my $FilterDataYAML = $YAMLObject->Dump( Data => $FilterData );

        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $FilterDataYAML,
            Type        => 'attachment',
            Filename    => $Filename,
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # Copy
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FilterCopy' ) {

        my $FilterName = $ParamObject->GetParam( Param => 'Name' ) || '';

        $LayoutObject->ChallengeTokenCheck();

        my $NewFilterName = $PostMasterFilterObject->FilterCopy(
            Name   => $FilterName,
            UserID => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen(
            Message => Translatable("Error creating the postmaster filter."),
        ) if !$NewFilterName;

        # return to overview
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # Import
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FilterImport' ) {

        $LayoutObject->ChallengeTokenCheck();

        my $FormID      = $ParamObject->GetParam( Param => 'FormID' ) || '';
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param  => 'FileUpload',
            Source => 'string',
        );

        my $OverwriteExistingFilters = $ParamObject->GetParam( Param => 'OverwriteExistingFilters' ) || '';

        my $FilterImport = $PostMasterFilterObject->FilterImport(
            Content                  => $UploadStuff{Content},
            OverwriteExistingFilters => $OverwriteExistingFilters,
            UserID                   => $Self->{UserID},
        );

        if ( !$FilterImport->{Success} ) {
            my $Message = $FilterImport->{Message}
                || Translatable(
                'Filters could not be imported due to an unknown error. Please check logs for more information.'
                );
            return $LayoutObject->ErrorScreen(
                Message => $Message,
            );
        }

        if ( $FilterImport->{Added} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following postmaster filters have been added successfully: %s.',
                    $FilterImport->{Added}
                ),
            };
        }
        if ( $FilterImport->{Updated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following postmaster filters have been updated successfully: %s.',
                    $FilterImport->{Updated}
                ),
            };
        }
        if ( $FilterImport->{NotUpdated} ) {
            push @{ $Param{NotifyData} }, {
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'The following postmaster filters were not updated: %s.',
                    $FilterImport->{NotUpdated}
                ),
            };
        }
        if ( $FilterImport->{Errors} ) {
            push @{ $Param{NotifyData} }, {
                Priority => 'Error',
                Info     => $LayoutObject->{LanguageObject}->Translate(
                    'Errors adding/updating the following postmaster filters: %s. Please check logs for more information.',
                    $FilterImport->{Errors}
                ),
            };
        }
        if ( IsArrayRefWithData( $FilterImport->{AdditionalErrors} ) ) {
            for my $Error ( @{ $FilterImport->{AdditionalErrors} } ) {
                push @{ $Param{NotifyData} }, {
                    Priority => 'Error',
                    Info     => $LayoutObject->{LanguageObject}->Translate($Error),
                };
            }
        }

        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # show filters status
        if ( $Param{NotifyData} ) {
            for my $Filter ( @{ $Param{NotifyData} } ) {
                $Output .= $LayoutObject->Notify(
                    %{$Filter},
                );
            }
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPostMasterFilter',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPostMasterFilter',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _MaskUpdate {
    my ( $Self, %Param ) = @_;

    my $PostMasterFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');
    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');

    my %Data    = %{ $Param{Data} };
    my $Counter = 0;
    if ( $Data{Match} ) {
        for my $Index ( 0 .. ( scalar @{ $Data{Match} } ) - 1 ) {
            if ( $Data{Match}->[$Index]->{Key} && length $Data{Match}->[$Index]->{Value} ) {
                $Counter++;
                $Data{"MatchValue$Counter"}  = $Data{Match}->[$Index]->{Value};
                $Data{"MatchHeader$Counter"} = $Data{Match}->[$Index]->{Key};
                $Data{"MatchNot$Counter"}    = $Data{Not}->[$Index]->{Value} ? ' checked="checked"' : '';
            }
        }
    }
    $Counter = 0;
    if ( $Data{Set} ) {
        for my $Item ( @{ $Data{Set} } ) {
            if ( $Item->{Key} && length $Item->{Value} ) {
                $Counter++;
                $Data{"SetValue$Counter"}  = $Item->{Value};
                $Data{"SetHeader$Counter"} = $Item->{Key};
            }
        }
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            Action => $Self->{Subaction},
            Name   => $Param{Name},
        },
    );
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    my %Headers = $PostMasterFilterObject->FilterHeadersGet();

    # build strings
    for my $Number ( 1 .. $ConfigObject->Get('PostmasterHeaderFieldCount') ) {
        $Data{"MatchHeader$Number"} = $LayoutObject->BuildSelection(
            Data => { %{ $Headers{Match} }, ( '' => '-' ) },

            Name        => "MatchHeader$Number",
            SelectedID  => $Data{"MatchHeader$Number"},
            Class       => 'Modernize ' . ( $Data{ 'MatchHeader' . $Number . 'Invalid' } || '' ),
            Translation => 0,
            HTMLQuote   => 1,
        );
        $Data{"SetHeader$Number"} = $LayoutObject->BuildSelection(
            Data        => { %{ $Headers{Set} }, ( '' => '-' ) },
            Name        => "SetHeader$Number",
            SelectedID  => $Data{"SetHeader$Number"},
            Class       => 'Modernize ' . ( $Data{ 'SetHeader' . $Number . 'Invalid' } || '' ),
            Translation => 0,
            HTMLQuote   => 1,
        );
    }
    $Data{"StopAfterMatch"} = $LayoutObject->BuildSelection(
        Data => {
            0 => 'No',
            1 => 'Yes'
        },
        Name        => 'StopAfterMatch',
        SelectedID  => $Data{StopAfterMatch} || 0,
        Class       => 'Modernize Validate_RequiredDropdown',
        Translation => 1,
        HTMLQuote   => 1,
    );

    my $OldName = $Data{Name};
    if ( $Param{Data}->{NameInvalid} ) {
        $OldName = $Data{OldName};
    }

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param, %Data,
            OldName => $OldName,
            Action  => $Self->{Subaction},
        },
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminPostMasterFilter',
        Data         => \%Param,
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $PostMasterFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, },
    );
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'ActionImportExport' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => { %Param, },
    );

    my %List = $PostMasterFilterObject->FilterList();

    if (%List) {
        for my $Key ( sort keys %List ) {
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    Name => $Key,
                },
            );
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}

1;
