# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminSendmailConfig;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');

    my %GetParam;
    my @Params = (
        qw(
            ID
            SendmailModule CMD Host Port Timeout SkipSSLVerification IsFallbackConfig
            AuthenticationType AuthUser AuthPassword OAuth2TokenConfigID
            Comments ValidID
        )
    );
    for my $Parameter (@Params) {
        $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
    }

    my @EmailAddresses = $ParamObject->GetArray(
        Param => 'EmailAddresses',
    );
    $GetParam{EmailAddresses} = \@EmailAddresses;

    if ( $Self->{Subaction} eq 'Add' ) {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_OutputSendmailModuleConfigHint();

        $Self->_Edit(
            Subaction => 'Add',
        );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSendmailConfig',
            Data         => {
                Subaction => 'Add',
            },
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        my $Errors = $Self->CheckFormData(%GetParam) // {};

        if ( !IsHashRefWithData($Errors) ) {
            my $SendmailConfigID = $SendmailConfigObject->Add(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($SendmailConfigID) {
                return $LayoutObject->Redirect(
                    OP => "Action=$Self->{Action}",
                );
            }
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_OutputSendmailModuleConfigHint();

        $Self->_Edit(
            Subaction => 'Add',
            %GetParam,
            %{$Errors},
        );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSendmailConfig',
            Data         => {
                Subaction => 'Add',
            },
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'Update' ) {
        my $SendmailConfig = $SendmailConfigObject->Get( ID => $GetParam{ID} );
        if ( !IsHashRefWithData($SendmailConfig) ) {
            return $LayoutObject->ErrorScreen(
                Message => "Sendmail config with ID $GetParam{ID} not found.",
            );
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_OutputSendmailModuleConfigHint();

        $Self->_Edit(
            Subaction => 'Update',
            %{$SendmailConfig},
        );

        my $ShowUpdateNotification = $ParamObject->GetParam( Param => 'Notification' ) // '';
        if ( $ShowUpdateNotification eq 'Update' ) {
            $Output .= $LayoutObject->Notify( Info => Translatable('Outbound email profile updated!') );
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSendmailConfig',
            Data         => {
                Subaction => 'Update',
            },
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'UpdateAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        my $Errors = $Self->CheckFormData(%GetParam) // {};

        if ( !IsHashRefWithData($Errors) ) {
            my $SendmailConfigUpdated = $SendmailConfigObject->Update(
                %GetParam,
                UserID => $Self->{UserID},
            );
            if ($SendmailConfigUpdated) {
                my $ContinueAfterSave = $ParamObject->GetParam( Param => 'ContinueAfterSave' );
                if ($ContinueAfterSave) {
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Update;ID=$GetParam{ID};Notification=Update"
                    );
                }
                else {
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Notification=Update",
                    );
                }
            }
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_OutputSendmailModuleConfigHint();

        $Self->_Edit(
            Subaction => 'Update',
            %GetParam,
            %{$Errors},
        );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSendmailConfig',
            Data         => {
                Subaction => 'Update',
            },
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $LayoutObject->ChallengeTokenCheck();

        my $SendmailConfigDeleted = $SendmailConfigObject->Delete(
            ID => $GetParam{ID},
        );
        if ( !$SendmailConfigDeleted ) {
            return $LayoutObject->ErrorScreen(
                Message => "Error deleting sendmail config with ID $GetParam{ID}.",
            );
        }
        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action}",
        );
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $Self->_OutputSendmailModuleConfigHint();

    $Self->_Overview();

    my $ShowUpdateNotification = $ParamObject->GetParam( Param => 'Notification' ) // '';
    if ( $ShowUpdateNotification eq 'Update' ) {
        $Output .= $LayoutObject->Notify( Info => Translatable('Outbound email profile updated!') );
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminSendmailConfig',

        #             Data         => \%Param,
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');

    $Self->_OutputSendmailModuleConfigHint();
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    my $SendmailConfigs = $SendmailConfigObject->GetAll();
    if ( IsArrayRefWithData($SendmailConfigs) ) {
        my %ValidList = $ValidObject->ValidList();
        my @ValidIDs  = $ValidObject->ValidIDsGet();
        my %ValidIDs  = map { $_ => 1 } @ValidIDs;

        my $AuthenticationTypes = $SendmailConfigObject->GetAuthenticationTypes() // {};

        for my $SendmailConfig ( @{$SendmailConfigs} ) {
            my $EmailAddressesString = '';
            if ( IsArrayRefWithData( $SendmailConfig->{EmailAddresses} ) ) {
                $EmailAddressesString = join ', ', @{ $SendmailConfig->{EmailAddresses} };
            }

            $LayoutObject->Block(
                Name => 'OverviewRow',
                Data => {
                    %{$SendmailConfig},
                    EmailAddressesString => $EmailAddressesString,
                    ShownValid           => $ValidList{ $SendmailConfig->{ValidID} },
                    IsValid              => $ValidIDs{ $SendmailConfig->{ValidID} } ? 1 : 0,
                    AuthenticationTypes  => $AuthenticationTypes,
                },
            );
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'OverviewNoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');
    my $SendmailConfigObject    = $Kernel::OM->Get('Kernel::System::SendmailConfig');

    my $SendmailConfigs = $SendmailConfigObject->GetAll() // [];
    my ($FallbackSendmailConfig) = grep { $_->{IsFallbackConfig} } @{$SendmailConfigs};

    my $SendmailModules = $SendmailConfigObject->GetAvailableSendmailModules() // {};

    $LayoutObject->AddJSData(
        Key   => 'SendmailModules',
        Value => $SendmailModules
    );

    $Param{SendmailModuleSelection} = $LayoutObject->BuildSelection(
        Data       => [ sort keys %{$SendmailModules} ],
        Name       => 'SendmailModule',
        SelectedID => $Param{SendmailModule},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'TypeAddInvalid'} || '' ),
    );

    my $AuthenticationTypes = $SendmailConfigObject->GetAuthenticationTypes();
    $Param{AuthenticationTypeSelection} = $LayoutObject->BuildSelection(
        Data         => $AuthenticationTypes,
        Name         => 'AuthenticationType',
        SelectedID   => $Param{AuthenticationType},
        Class        => 'Modernize ' . ( $Param{Errors}->{'AuthenticationTypeInvalid'} // '' ),
        Translation  => 1,
        PossibleNone => 1,
    );

    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;
    $Param{ValidIDSelection} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    my @ValidOAuth2TokenConfigs = $OAuth2TokenConfigObject->DataListGet(
        ValidID => $ValidListReverse{valid},
        UserID  => $Self->{UserID},
    );

    my %ValidOAuth2TokenConfigs = map {
        $_->{ $OAuth2TokenConfigObject->{Identifier} } => $_->{Name}
    } @ValidOAuth2TokenConfigs;

    $Param{OAuth2TokenConfigSelection} = $LayoutObject->BuildSelection(
        Data         => \%ValidOAuth2TokenConfigs,
        Name         => 'OAuth2TokenConfigID',
        SelectedID   => $Param{OAuth2TokenConfigID} // '',
        Class        => 'Modernize ' . ( $Param{Errors}->{'OAuth2TokenConfigIDInvalid'} || '' ),
        PossibleNone => 1,    # to be able to set it to empty if a configured token config has gone invalid.
    );

    my $UnusedSenderEmailAddresses = $SendmailConfigObject->GetSenderEmailAddresses(
        OnlyUnused              => 1,
        KeepForSendmailConfigID => $Param{ID},
    );
    $Param{EmailAddressesSelection} = $LayoutObject->BuildSelection(
        Data       => $UnusedSenderEmailAddresses,
        Name       => 'EmailAddresses',
        SelectedID => $Param{EmailAddresses},
        Multiple   => 1,
        Class      => 'Modernize ' . ( $Param{Errors}->{'EmailAddressesInvalid'} || '' ),
    );

    $Self->_OutputSendmailModuleConfigHint();

    $LayoutObject->Block(
        Name => 'ActionList',
    );

    $LayoutObject->Block(
        Name => 'ActionOverview',
    );

    $LayoutObject->Block(
        Name => 'Edit',
        Data => {
            %Param,
            %{ $Param{Errors} },
            FallbackSendmailConfig => $FallbackSendmailConfig,
        },
    );

    return 1;
}

sub _OutputSendmailModuleConfigHint {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Show information if config option SendmailModule is no set to MultiSendmail.
    my $SendmailModule = $ConfigObject->Get('SendmailModule') // '';
    return '' if $SendmailModule eq 'Kernel::System::Email::MultiSendmail';

    my $Output = $LayoutObject->Notify(
        Priority => 'Warning',
        Info     => Translatable(
            "Configuration option 'SendmailModule' has to be set to 'Kernel::System::Email::MultiSendmail' to be able to use the outbound email profiles managed here."
        ),
        Link => $LayoutObject->{Baselink} . 'Action=AdminSystemConfiguration;Subaction=View;Setting=SendmailModule',
    );

    return $Output;
}

sub CheckFormData {
    my ( $Self, %Param ) = @_;

    my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');

    my $SendmailModules = $SendmailConfigObject->GetAvailableSendmailModules();

    my %Errors;

    NEEDED:
    for my $Needed (qw(SendmailModule ValidID)) {
        next NEEDED if IsStringWithData( $Param{$Needed} );

        $Errors{ $Needed . 'Invalid' } = 'ServerError';
    }

    my $SendmailModuleConfigOptions = $SendmailModules->{ $Param{SendmailModule} } // {};

    OPTION:
    for my $Option ( sort keys %{$SendmailModuleConfigOptions} ) {
        my $IsRequired = $SendmailModuleConfigOptions->{$Option}->{Required};
        next OPTION if !$IsRequired;
        next OPTION if IsStringWithData( $Param{$Option} );

        $Errors{ $Option . 'Invalid' } = 'ServerError';
    }

    if (
        $SendmailModuleConfigOptions->{Port}
        && IsStringWithData( $Param{Port} )
        && (
            $Param{Port} !~ m{\A[1-9]\d?\d?\d?\d?\z}
            || $Param{Port} > 65535
        )
        )
    {
        $Errors{'PortInvalid'} = 'ServerError';
    }

    if (
        $SendmailModuleConfigOptions->{Timeout}
        && IsStringWithData( $Param{Timeout} )
        && $Param{Timeout} !~ m{\A[1-9]\d?\d?\z}
        )
    {
        $Errors{'TimeoutInvalid'} = 'ServerError';
    }

    # Check credential fields for selected authentication type.
    if (
        $SendmailModuleConfigOptions->{AuthenticationType}
        && IsStringWithData( $Param{AuthenticationType} )
        )
    {
        my $AuthenticationType = $Param{AuthenticationType};
        my $AuthConfigOptions
            = $SendmailModuleConfigOptions->{AuthenticationType}->{PossibleValues}->{$AuthenticationType} // {};

        AUTHOPTION:
        for my $AuthOption ( sort keys %{$AuthConfigOptions} ) {
            my $IsRequired = $AuthConfigOptions->{$AuthOption}->{Required};
            next AUTHOPTION if !$IsRequired;
            next AUTHOPTION if IsStringWithData( $Param{$AuthOption} );

            $Errors{ $AuthOption . 'Invalid' } = 'ServerError';
        }
    }

    if (
        !$Param{IsFallbackConfig}
        && !IsArrayRefWithData( $Param{EmailAddresses} )
        )
    {
        $Errors{'EmailAddressesInvalid'} = 'ServerError';
    }

    return \%Errors;
}

1;
