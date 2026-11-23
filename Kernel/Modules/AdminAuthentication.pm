# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminAuthentication;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AuthenticationConfig',
    'Kernel::System::Authentication::Plugin::SAML',
    'Kernel::System::Group',
    'Kernel::System::JSON',
    'Kernel::System::Main',
    'Kernel::System::Valid',
    'Kernel::System::VirtualFS',
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

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Self->{Subaction} eq 'Wizard' ) {
        return $Self->_Wizard(%Param);
    }
    elsif ( $Self->{Subaction} eq 'EditAgentAuth' ) {
        return $Self->_Edit( Context => 'Agent' );
    }
    elsif ( $Self->{Subaction} eq 'EditCustomerAuth' ) {
        return $Self->_Edit( Context => 'Customer' );
    }
    elsif ( $Self->{Subaction} eq 'SaveAgentAuth' ) {
        return $Self->_Save( Context => 'Agent' );
    }
    elsif ( $Self->{Subaction} eq 'SaveCustomerAuth' ) {
        return $Self->_Save( Context => 'Customer' );
    }
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        return $Self->_Delete(%Param);
    }
    elsif ( $Self->{Subaction} eq 'UploadCertificate' ) {
        return $Self->_UploadCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'GenerateCertificate' ) {
        return $Self->_GenerateCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'DeleteCertificate' ) {
        return $Self->_DeleteCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'VerifyMetadata' ) {
        return $Self->_VerifyMetadata(%Param);
    }
    elsif ( $Self->{Subaction} eq 'UseMetadataCertificate' ) {
        return $Self->_UseMetadataCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'ViewCertificate' ) {
        return $Self->_ViewCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'DownloadCertificate' ) {
        return $Self->_DownloadCertificate(%Param);
    }
    elsif ( $Self->{Subaction} eq 'CertificateInfo' ) {
        return $Self->_CertificateInfo(%Param);
    }
    elsif ( $Self->{Subaction} eq 'CertificatePoolList' ) {
        return $Self->_CertificatePoolList(%Param);
    }
    elsif ( $Self->{Subaction} eq 'DownloadMetadata' ) {
        return $Self->_DownloadMetadata(%Param);
    }
    elsif ( $Self->{Subaction} eq 'Deploy' ) {
        return $Self->_Deploy(%Param);
    }
    elsif ( $Self->{Subaction} eq 'InvalidateAndDeploy' ) {
        return $Self->_InvalidateAndDeploy(%Param);
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');
    my $MainObject                 = $Kernel::OM->Get('Kernel::System::Main');

    if ( !$MainObject->Require( 'Net::SAML2', Silent => 1 ) ) {
        $Output .= $LayoutObject->Notify(
            Priority => 'Error',
            Info     =>
                Translatable(
                'Perl module Net::SAML2 is not installed. SAML authentication cannot work until it is installed on the server.'
                ),
        );
    }

    if ( !$AuthenticationConfigObject->IsDeploySynced() ) {

        # Only ask for a deploy that can succeed.
        my $ConfigProblems = $Self->_ConfigProblems();
        my $HasErrors      = grep { $_->{State} eq 'Error' } values %{$ConfigProblems};

        if ($HasErrors) {
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Info     => Translatable(
                    'Authentication configuration is not in sync with the deployed configuration, but it can\'t be deployed: a valid configuration has a problem, see the status below. Fix it or set it to invalid, then deploy.'
                ),
            );
        }
        else {
            $Output .= $LayoutObject->Notify(
                Priority => 'Notice',
                Info     => Translatable(
                    'Authentication configuration is not in sync with the deployed configuration, please deploy.'
                ),
                Link => $LayoutObject->{Baselink}
                    . "Action=$Self->{Action};Subaction=Deploy;$LayoutObject->{ChallengeTokenParam}",
            );
        }
    }

    $Output .= $Self->_Overview(%Param);
    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                = $Kernel::OM->Get('Kernel::System::Valid');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    my %ValidIDs = $ValidObject->ValidList();

    my @AgentConfigs = $AuthenticationConfigObject->SortedList(
        Context => 'Agent',
        UserID  => $Self->{UserID},
    );
    my @CustomerConfigs = $AuthenticationConfigObject->SortedList(
        Context => 'Customer',
        UserID  => $Self->{UserID},
    );

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AdminAuthentication/Overview',
        Data         => {
            AgentConfigs    => \@AgentConfigs,
            CustomerConfigs => \@CustomerConfigs,
            ValidIDs        => \%ValidIDs,
            ConfigProblems  => $Self->_ConfigProblems(),
            DeployErrors    => $Param{DeployErrors} || [],
        },
    );

    return $Output;
}

# Runs the checks of Deploy() for every valid config, without fetching any IdP metadata.
# Returns a hash ref ID => { State => 'Error' or 'Warning', Message => '...' } for every config
# with a problem. 'Warning': deploying still works, but has to fetch the IdP metadata.
sub _ConfigProblems {
    my ( $Self, %Param ) = @_;

    return $Self->{ConfigProblems} if $Self->{ConfigProblems};

    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');
    my $SAMLPluginObject           = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    my %ValidIDs = map { $_ => 1 } $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    my %Problems;

    for my $Context (qw(Agent Customer)) {
        my @Rows = $AuthenticationConfigObject->SortedList(
            Context => $Context,
            UserID  => $Self->{UserID},
        );

        ROW:
        for my $Row (@Rows) {
            next ROW if !$ValidIDs{ $Row->{ValidID} };
            next ROW if ( $Row->{Type} // '' ) ne 'SAML';

            my %Prepared = $SAMLPluginObject->PrepareCertificates(
                Row     => $Row,
                Offline => 1,
            );
            next ROW if $Prepared{Success};

            $Problems{ $Row->{ID} } = {
                State   => $Prepared{NeedsMetadata} ? 'Warning' : 'Error',
                Message => $Prepared{Message},
            };
        }
    }

    $Self->{ConfigProblems} = \%Problems;

    return \%Problems;
}

sub _Wizard {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    my %SlotSelection;
    my %AssertionConsumerURL;

    CONTEXT:
    for my $Context (qw(Agent Customer)) {
        my $SlotStatus = $AuthenticationConfigObject->SlotStatusList(
            Context => $Context,
            UserID  => $Self->{UserID},
        );

        $SlotSelection{$Context} = $Self->_BuildSlotSelection(
            SlotStatus => $SlotStatus,
            Name       => "WizardSlot$Context",
        );

        $AssertionConsumerURL{$Context} = $Self->_ComputeAssertionConsumerURL( Context => $Context );
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminAuthentication/Wizard',
        Data         => {
            $Self->_BuildSyncFormData(),
            AgentSlotSelection                  => $SlotSelection{Agent},
            CustomerSlotSelection               => $SlotSelection{Customer},
            AgentRequestAssertionConsumerURL    => $AssertionConsumerURL{Agent},
            CustomerRequestAssertionConsumerURL => $AssertionConsumerURL{Customer},
            Issuer                              => $Self->_ComputeDefaultIssuer(),
            FQDN                                => $ConfigObject->Get('FQDN'),
        },
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $Context = $Param{Context};

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    my $ID = $ParamObject->GetParam( Param => 'ID' );

    my %Config;
    if ($ID) {
        %Config = $AuthenticationConfigObject->DataGet(
            ID     => $ID,
            UserID => $Self->{UserID},
        );
        if ( !%Config ) {
            return $LayoutObject->ErrorScreen(
                Message => "Authentication config with ID $ID could not be found.",
            );
        }
    }

    my $SlotStatus = $AuthenticationConfigObject->SlotStatusList(
        Context => $Context,
        UserID  => $Self->{UserID},
    );

    my %FormData = $Self->_ConfigToFormData(
        Context => $Context,
        ID      => $ID,
        Config  => \%Config,
    );

    return $Self->_RenderEditForm(
        Context    => $Context,
        SlotStatus => $SlotStatus,
        FormData   => \%FormData,
    );
}

sub _Save {
    my ( $Self, %Param ) = @_;

    my $Context = $Param{Context};

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');
    my $VirtualFSObject            = $Kernel::OM->Get('Kernel::System::VirtualFS');

    $LayoutObject->ChallengeTokenCheck();

    my %GetParam;
    for my $Key (
        qw(
        ID Name Slot ValidID
        RequestLoginButtonText Issuer RequestNameIDFormat RequestSignSigAlg UserLoginAttribute
        ResponseEncryptionEnabled
        MetaDataSourceType RequestMetaDataURL RequestMetaDataXML
        SSLOptionsEnabled SSLCAFile SSLCAPath SSLVerifyHostname
        RequestSignKeyVFSFilename RequestSignKeyCertVFSFilename IdPCACertVFSFilename
        SyncEnabled
        UserSyncGroupsDefinitionAttribute UserSyncRolesDefinitionAttribute
        ContinueAfterSave
        )
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    my %Errors;

    REQUIRED:
    for my $Required (qw(Name RequestLoginButtonText Issuer ValidID)) {
        next REQUIRED if defined $GetParam{$Required} && length $GetParam{$Required};
        $Errors{"${Required}Invalid"} = 'ServerError';
    }

    # The name is written into a comment line of the generated Perl config file.
    if ( length( $GetParam{Name} // '' ) && $GetParam{Name} =~ m{[\x00-\x1F\x7F]} ) {
        $Errors{NameInvalid} = 'ServerError';
    }

    if ( !defined $GetParam{Slot} ) {
        $Errors{SlotInvalid} = 'ServerError';
    }

    # Optional login attribute(s), comma separated. Written into the generated Perl config file.
    my @UserLoginAttributes = grep {length} map { s{\A\s+|\s+\z}{}gr } split /,/, $GetParam{UserLoginAttribute} // '';
    if ( grep {m{[\x00-\x1F\x7F]}} @UserLoginAttributes ) {
        $Errors{UserLoginAttributeInvalid} = 'ServerError';
    }

    if ( !$GetParam{MetaDataSourceType} || $GetParam{MetaDataSourceType} !~ m{\A(?:URL|XML)\z} ) {
        $Errors{MetaDataSourceTypeInvalid} = 'ServerError';
    }
    elsif ( $GetParam{MetaDataSourceType} eq 'URL' ) {
        $Errors{RequestMetaDataURLInvalid} = 'ServerError' if !length( $GetParam{RequestMetaDataURL} // '' );
    }
    else {
        $Errors{RequestMetaDataXMLInvalid} = 'ServerError' if !length( $GetParam{RequestMetaDataXML} // '' );
    }

    # The certificate fields are hidden inputs filled by the certificate widget. Only blobs of
    # the matching role from our own VirtualFS namespace are accepted, since saving or deleting
    # a config deletes blobs it no longer references.
    my %RoleByVFSKey = (
        RequestSignKeyVFSFilename     => 'RequestSignKey',
        RequestSignKeyCertVFSFilename => 'RequestSignKeyCert',
        IdPCACertVFSFilename          => 'IdPCACert',
    );

    VFSKEY:
    for my $VFSKey ( sort keys %RoleByVFSKey ) {
        my $Filename = $GetParam{$VFSKey};
        next VFSKEY if !$Filename;

        my $Role = $RoleByVFSKey{$VFSKey};
        if ( $Filename =~ m{\AVirtualFS::AuthenticationConfig::SAML::\Q$Role\E::[0-9a-f]{32}\z} ) {
            my @Existing = $VirtualFSObject->Find( Filename => $Filename );
            next VFSKEY if @Existing;
        }

        $Errors{"${VFSKey}Invalid"} = 'ServerError';
        $GetParam{$VFSKey} = '';
    }

    # Uniqueness of Name.
    if ( defined $GetParam{Name} && length $GetParam{Name} ) {
        my %Existing = $AuthenticationConfigObject->DataGet(
            Name   => $GetParam{Name},
            UserID => $Self->{UserID},
        );
        if ( %Existing && ( !$GetParam{ID} || $Existing{ID} != $GetParam{ID} ) ) {
            $Errors{NameInvalid} = 'ServerError';
        }
    }

    # Slot re-validation (guards against a race with another admin, and against
    # colliding with a slot already used by one of our own other rows).
    my $SlotStatus = $AuthenticationConfigObject->SlotStatusList(
        Context => $Context,
        UserID  => $Self->{UserID},
    );

    if ( defined $GetParam{Slot} ) {
        my $Status       = $SlotStatus->{ $GetParam{Slot} };
        my $IsCurrentRow = $GetParam{ID}
            && $Status->{State} eq 'Ours'
            && $Status->{AuthenticationConfigID} == $GetParam{ID};

        if ( !$IsCurrentRow && $Status->{State} ne 'Free' ) {
            $Errors{SlotInvalid} = 'ServerError';
        }
    }

    if ( $Context eq 'Agent' && $GetParam{SyncEnabled} && defined $GetParam{Slot} ) {
        my $Status        = $SlotStatus->{ $GetParam{Slot} };
        my $SyncIsCurrent = $GetParam{ID}
            && $Status->{State} eq 'Ours'
            && $Status->{AuthenticationConfigID} == $GetParam{ID};

        if ( $Status->{SyncLocked} && !$SyncIsCurrent ) {
            $Errors{SyncEnabledInvalid} = 'ServerError';
        }
    }

    # Shows the submitted form again with the given errors.
    my $RenderFormWithErrors = sub {
        my %FormErrors = @_;

        my %FormData = (
            %GetParam,
            %FormErrors,
            RequestAssertionConsumerURL => $Self->_ComputeAssertionConsumerURL( Context => $Context ),
        );

        if ( $Context eq 'Agent' ) {
            %FormData = (
                %FormData,
                $Self->_CollectSyncFormData( ParamObject => $ParamObject ),
            );
        }

        return $Self->_RenderEditForm(
            Context    => $Context,
            SlotStatus => $SlotStatus,
            FormData   => \%FormData,
        );
    };

    return $RenderFormWithErrors->(%Errors) if %Errors;

    # Assemble AuthConfig.
    # RequestAssertionConsumerURL is never taken from user input - it is always derived from the
    # system's own HttpType/FQDN/ScriptAlias, since it must point back at this very system.
    my %AuthConfig = (
        RequestLoginButtonText      => $GetParam{RequestLoginButtonText},
        RequestAssertionConsumerURL => $Self->_ComputeAssertionConsumerURL( Context => $Context ),
        Issuer                      => $GetParam{Issuer},
        MetaDataSourceType          => $GetParam{MetaDataSourceType},
    );

    # Both are plain <select>s with a fixed option list - a mismatch only happens via a
    # tampered request, so falling back to unset (framework/Net::SAML2 default) is enough,
    # no need for a hard validation error here.
    my %ValidNameIDFormats = map { $_ => 1 } (
        'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified',
        'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
        'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
    );
    if ( $GetParam{RequestNameIDFormat} && $ValidNameIDFormats{ $GetParam{RequestNameIDFormat} } ) {
        $AuthConfig{RequestNameIDFormat} = $GetParam{RequestNameIDFormat};
    }

    # Login taken from these attributes instead of the NameID, see Kernel::System::Auth::SAML::Response::GetLogin().
    if (@UserLoginAttributes) {
        $AuthConfig{UserLoginAttribute} = \@UserLoginAttributes;
    }

    my %ValidSigAlgs = map { $_ => 1 } qw(sha256 sha384 sha512 sha1);
    if ( $GetParam{RequestSignSigAlg} && $ValidSigAlgs{ $GetParam{RequestSignSigAlg} } ) {
        $AuthConfig{RequestSignSigAlg} = $GetParam{RequestSignSigAlg};
    }

    # Always stored explicitly (unlike the two fields above) so that DeployConfigLines can
    # tell "never saved with this checkbox" (missing key, defaults to enabled) apart from
    # "explicitly turned off" (0) for rows saved before this field existed.
    $AuthConfig{ResponseEncryptionEnabled} = $GetParam{ResponseEncryptionEnabled} ? 1 : 0;

    if ( $GetParam{MetaDataSourceType} eq 'URL' ) {
        $AuthConfig{RequestMetaDataURL} = $GetParam{RequestMetaDataURL};
    }
    else {
        $AuthConfig{RequestMetaDataXML} = $GetParam{RequestMetaDataXML};
    }

    # SSL options only apply to fetching the metadata from a URL.
    if ( $GetParam{MetaDataSourceType} eq 'URL' && $GetParam{SSLOptionsEnabled} ) {
        $AuthConfig{RequestMetaDataURLSSLOptions} = {
            SSL_ca_file     => $GetParam{SSLCAFile} || undef,
            SSL_ca_path     => $GetParam{SSLCAPath} || undef,
            verify_hostname => $GetParam{SSLVerifyHostname} ? 1 : 0,
        };
    }

    $AuthConfig{RequestSignKeyVFSFilename}     = $GetParam{RequestSignKeyVFSFilename}     || undef;
    $AuthConfig{RequestSignKeyCertVFSFilename} = $GetParam{RequestSignKeyCertVFSFilename} || undef;
    $AuthConfig{IdPCACertVFSFilename}          = $GetParam{IdPCACertVFSFilename}          || undef;

    my %ValidIDs      = map { $_ => 1 } $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my $IsValidConfig = $ValidIDs{ $GetParam{ValidID} } ? 1 : 0;

    # Deploying must not depend on fetching the IdP metadata, so the IdP CA certificate is
    # stored now. If none was uploaded, it is taken from the metadata, like the "Use
    # certificate from metadata" button does. The admin can check it in the form afterwards.
    my %CertificateErrors;
    if ( !$AuthConfig{IdPCACertVFSFilename} ) {
        my %Stored = $Self->_StoreIdPCertificateFromMetadata(
            AuthConfig => \%AuthConfig,
        );
        if ( $Stored{Success} ) {
            $AuthConfig{IdPCACertVFSFilename} = $Stored{Filename};
            $GetParam{IdPCACertVFSFilename}   = $Stored{Filename};
        }
        elsif ($IsValidConfig) {
            $CertificateErrors{IdPCACert} = Translatable(
                'No IdP CA certificate was uploaded and none could be taken from the IdP metadata.'
            );
        }
    }

    # The same checks Deploy() runs, so that a valid config can always be deployed.
    if ( $IsValidConfig && !%CertificateErrors ) {
        my %Prepared = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML')->PrepareCertificates(
            Row => {
                Name       => $GetParam{Name},
                Context    => $Context,
                Slot       => $GetParam{Slot},
                AuthConfig => \%AuthConfig,
            },
            Offline => 1,
        );
        if ( !$Prepared{Success} ) {
            $CertificateErrors{ $Prepared{Role} || 'IdPCACert' } = $Prepared{Message};
        }
    }

    if (%CertificateErrors) {
        my %FormErrors;
        for my $Role ( sort keys %CertificateErrors ) {
            $FormErrors{"${Role}VFSFilenameInvalid"}      = 'ServerError';
            $FormErrors{"${Role}VFSFilenameErrorMessage"} = $CertificateErrors{$Role};
        }

        return $RenderFormWithErrors->(%FormErrors);
    }

    my $SyncEnabled = ( $Context eq 'Agent' && $GetParam{SyncEnabled} ) ? 1 : 0;

    my %SyncConfig;
    if ($SyncEnabled) {
        %SyncConfig = $Self->_BuildSyncConfig(
            ParamObject => $ParamObject,
            GetParam    => \%GetParam,
        );
    }

    # If sync was left disabled in the setup wizard but IdP metadata verification discovered
    # attribute names there, keep them so they aren't lost - the admin will see them pre-filled
    # (SAML attribute side only) once they enable sync on the full edit screen later.
    # They can't go into UserSyncMap itself: it maps Znuny attribute => SAML attribute, and the
    # Znuny side isn't known yet. Only for a brand-new config; see below for later saves.
    if ( $Context eq 'Agent' && !$GetParam{ID} && !$SyncConfig{UserSyncMap} ) {
        my $DiscoveredAttributesJSON = $ParamObject->GetParam( Param => 'WizardDiscoveredAttributes' );

        if ($DiscoveredAttributesJSON) {
            my $DiscoveredAttributes = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                Data => $DiscoveredAttributesJSON,
            );

            if ( ref $DiscoveredAttributes eq 'ARRAY' && @{$DiscoveredAttributes} ) {
                $SyncConfig{WizardDiscoveredAttributes} = [ grep { length $_ } @{$DiscoveredAttributes} ];
            }
        }
    }

    my $UserID = $Self->{UserID};
    my $ID     = $GetParam{ID};

    if ($ID) {

        # Certificates/keys are written to VirtualFS immediately when uploaded/generated/removed
        # (see _UploadCertificate/_GenerateCertificate/_DeleteCertificate), so by the time we get
        # here the hidden VFSFilename fields already reflect the admin's latest choice. Any
        # VirtualFS blob that was referenced by the *previous* saved state but is no longer
        # referenced now (replaced or removed) would otherwise be orphaned - clean it up here.
        my %OldConfig = $AuthenticationConfigObject->DataGet(
            ID     => $ID,
            UserID => $UserID
        );
        my $OldAuthConfig = $OldConfig{AuthConfig} || {};

        ROLE:
        for my $VFSKey (qw(RequestSignKeyVFSFilename RequestSignKeyCertVFSFilename IdPCACertVFSFilename)) {
            my $OldFilename = $OldAuthConfig->{$VFSKey};

            next ROLE if !$OldFilename;
            next ROLE if $OldFilename !~ m{\AVirtualFS::AuthenticationConfig::};
            next ROLE if $OldFilename eq ( $AuthConfig{$VFSKey} // '' );

            # Certificates/keys are stored content-addressed and may be shared by more than
            # one config (e.g. the same IdP CA cert used for both an agent and a customer
            # config). Only delete the VirtualFS blob if no other config still references it.
            next ROLE if $AuthenticationConfigObject->VFSFilenameInUse(
                Filename  => $OldFilename,
                ExcludeID => $ID,
                UserID    => $UserID,
            );

            $VirtualFSObject->Delete(
                Filename        => $OldFilename,
                DisableWarnings => 1,
            );
        }

        # Keep the attribute names discovered by the wizard until the admin has actually
        # set up a sync map, so saving the edit screen with sync still disabled doesn't drop them.
        my $OldSyncConfig = $OldConfig{SyncConfig} || {};
        if (
            $Context eq 'Agent'
            && !$SyncConfig{UserSyncMap}
            && ref $OldSyncConfig->{WizardDiscoveredAttributes} eq 'ARRAY'
            )
        {
            $SyncConfig{WizardDiscoveredAttributes} = $OldSyncConfig->{WizardDiscoveredAttributes};
        }

        my $Updated = $AuthenticationConfigObject->DataUpdate(
            ID          => $ID,
            Name        => $GetParam{Name},
            Type        => 'SAML',
            Context     => $Context,
            Slot        => $GetParam{Slot},
            AuthConfig  => \%AuthConfig,
            SyncEnabled => $SyncEnabled,
            SyncConfig  => %SyncConfig ? \%SyncConfig : undef,
            ValidID     => $GetParam{ValidID},
            UserID      => $UserID,
        );
        if ( !$Updated ) {
            return $LayoutObject->ErrorScreen(
                Message => "Error updating authentication config with ID $ID.",
            );
        }
    }
    else {
        $ID = $AuthenticationConfigObject->DataAdd(
            Name        => $GetParam{Name},
            Type        => 'SAML',
            Context     => $Context,
            Slot        => $GetParam{Slot},
            AuthConfig  => \%AuthConfig,
            SyncEnabled => $SyncEnabled,
            SyncConfig  => %SyncConfig ? \%SyncConfig : undef,
            ValidID     => $GetParam{ValidID},
            CreateBy    => $UserID,
            ChangeBy    => $UserID,
            UserID      => $UserID,
        );
        if ( !$ID ) {
            return $LayoutObject->ErrorScreen(
                Message => 'Error adding authentication config.',
            );
        }
    }

    if ( $GetParam{ContinueAfterSave} ) {
        my $EditSubaction = $Context eq 'Agent' ? 'EditAgentAuth' : 'EditCustomerAuth';
        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action};Subaction=$EditSubaction;ID=$ID",
        );
    }

    return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
}

sub _Delete {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ValidObject                = $Kernel::OM->Get('Kernel::System::Valid');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    $LayoutObject->ChallengeTokenCheck();

    my $ID = $ParamObject->GetParam( Param => 'ID' );

    if ( !$ID ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    my %Config = $AuthenticationConfigObject->DataGet(
        ID     => $ID,
        UserID => $Self->{UserID},
    );
    if ( !%Config ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    # Only invalid configurations may be deleted - a valid (in-use) one must be set to
    # invalid first, so nobody accidentally deletes a config that is actively deployed/relied on.
    my %ValidIDs  = $ValidObject->ValidList();
    my $ValidName = $ValidIDs{ $Config{ValidID} } || '';

    if ( $ValidName eq 'valid' ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message =>
                Translatable(
                'Only invalid authentication configurations can be deleted. Please set the configuration to invalid first.'
                ),
        );
    }

    my $Deleted = $AuthenticationConfigObject->DataDelete(
        ID     => $ID,
        UserID => $Self->{UserID},
    );

    return $Self->_JSONResponse( Success => $Deleted ? 1 : 0 );
}

sub _UploadCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    $LayoutObject->ChallengeTokenCheck();

    my $Role = $ParamObject->GetParam( Param => 'Role' );
    if ( !$Role || $Role !~ m{\A(?:RequestSignKey|RequestSignKeyCert|IdPCACert)\z} ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Invalid or missing Role.'),
        );
    }

    # Either a file upload or PEM text pasted into the certificate widget.
    my %Upload;
    my $PastedContent = $ParamObject->GetParam( Param => 'PastedContent' ) // '';
    if ( $PastedContent =~ m{\S} ) {
        $PastedContent =~ s{\r\n?}{\n}g;
        $PastedContent =~ s{\A\s+|\s+\z}{}g;

        %Upload = (
            Content  => $PastedContent . "\n",
            Filename => "pasted-$Role.pem",
        );
    }
    else {
        %Upload = $ParamObject->GetUploadAll( Param => 'FileUpload' );
    }

    if ( !%Upload || !length( $Upload{Content} // '' ) ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('No file was uploaded.'),
        );
    }

    # Net::SAML2 reads certificates and keys as PEM files, so accept nothing else.
    my %Validation = $SAMLPluginObject->ValidateContent(
        Role    => $Role,
        Content => $Upload{Content},
    );
    if ( !$Validation{Success} ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => $Validation{Message},
        );
    }

    my $Filename = $Self->_WriteCertificateBlob(
        Role    => $Role,
        Content => $Validation{PEM},
        Name    => $Upload{Filename},
    );
    if ( !$Filename ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Error storing the uploaded file.'),
        );
    }

    return $Self->_JSONResponse(
        Success      => 1,
        Filename     => $Filename,
        OrigFilename => $Upload{Filename},
    );
}

sub _GenerateCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    $LayoutObject->ChallengeTokenCheck();

    my $Role = $ParamObject->GetParam( Param => 'Role' ) || 'RequestSignKey';
    if ( $Role ne 'RequestSignKey' ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Only the SP signing key can be generated.'),
        );
    }

    my $CommonName   = $ParamObject->GetParam( Param => 'CommonName' )   || $ConfigObject->Get('FQDN') || 'localhost';
    my $KeySize      = $ParamObject->GetParam( Param => 'KeySize' )      || 2048;
    my $ValidityDays = $ParamObject->GetParam( Param => 'ValidityDays' ) || 365;

    my %Certificate = $SAMLPluginObject->GenerateCertificate(
        CommonName   => $CommonName,
        KeySize      => $KeySize,
        ValidityDays => $ValidityDays,
    );

    if ( !%Certificate ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Error generating certificate. Please check the system log.'),
        );
    }

    my $KeyOrigFilename = 'generated-' . lc($Role) . '.key';

    my $KeyFilename = $Self->_WriteCertificateBlob(
        Role    => $Role,
        Content => $Certificate{Key},
        Name    => $KeyOrigFilename,
    );
    if ( !$KeyFilename ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Error storing the generated key in VirtualFS.'),
        );
    }

    # The certificate half of the pair isn't read back by Znuny's own SAML code (only the
    # private key is, as RequestSignKey), but it still has to be handed to the Identity
    # Provider admin to register this system as a trusted SP, so it must not be silently
    # discarded. Store it under its own role so it stays discoverable independently of the key.
    my $CertOrigFilename = 'generated-' . lc($Role) . '.pem';

    my $CertFilename = $Self->_WriteCertificateBlob(
        Role    => "${Role}Cert",
        Content => $Certificate{Cert},
        Name    => $CertOrigFilename,
    );
    if ( !$CertFilename ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Error storing the generated certificate in VirtualFS.'),
        );
    }

    return $Self->_JSONResponse(
        Success          => 1,
        Filename         => $KeyFilename,
        OrigFilename     => $KeyOrigFilename,
        CertFilename     => $CertFilename,
        CertOrigFilename => $CertOrigFilename,
    );
}

sub _VerifyMetadata {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    $LayoutObject->ChallengeTokenCheck();

    my $SourceType = $ParamObject->GetParam( Param => 'MetaDataSourceType' ) || 'URL';
    my $URL        = $ParamObject->GetParam( Param => 'RequestMetaDataURL' );
    my $XML        = $ParamObject->GetParam( Param => 'RequestMetaDataXML' );

    my %SSLOptions;
    if ( $ParamObject->GetParam( Param => 'SSLOptionsEnabled' ) ) {
        my $SSLCAFile         = $ParamObject->GetParam( Param => 'SSLCAFile' );
        my $SSLCAPath         = $ParamObject->GetParam( Param => 'SSLCAPath' );
        my $SSLVerifyHostname = $ParamObject->GetParam( Param => 'SSLVerifyHostname' );
        %SSLOptions = (
            SSL_ca_file     => $SSLCAFile || undef,
            SSL_ca_path     => $SSLCAPath || undef,
            verify_hostname => $SSLVerifyHostname ? 1 : 0,
        );
    }

    my %Result = $SAMLPluginObject->VerifyMetadata(
        SourceType => $SourceType,
        URL        => $URL,
        XML        => $XML,
        SSLOptions => \%SSLOptions,
    );

    return $Self->_JSONResponse(%Result);
}

sub _UseMetadataCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    $LayoutObject->ChallengeTokenCheck();

    my $SourceType = $ParamObject->GetParam( Param => 'MetaDataSourceType' ) || 'URL';
    my $URL        = $ParamObject->GetParam( Param => 'RequestMetaDataURL' );
    my $XML        = $ParamObject->GetParam( Param => 'RequestMetaDataXML' );

    my %SSLOptions;
    if ( $ParamObject->GetParam( Param => 'SSLOptionsEnabled' ) ) {
        my $SSLCAFile         = $ParamObject->GetParam( Param => 'SSLCAFile' );
        my $SSLCAPath         = $ParamObject->GetParam( Param => 'SSLCAPath' );
        my $SSLVerifyHostname = $ParamObject->GetParam( Param => 'SSLVerifyHostname' );
        %SSLOptions = (
            SSL_ca_file     => $SSLCAFile || undef,
            SSL_ca_path     => $SSLCAPath || undef,
            verify_hostname => $SSLVerifyHostname ? 1 : 0,
        );
    }

    my %Result = $Self->_StoreIdPCertificateFromMetadata(
        AuthConfig => {
            MetaDataSourceType           => $SourceType,
            RequestMetaDataURL           => $URL,
            RequestMetaDataXML           => $XML,
            RequestMetaDataURLSSLOptions => \%SSLOptions,
        },
    );

    return $Self->_JSONResponse(%Result);
}

# Takes the signing certificate from the IdP metadata of the given AuthConfig, checks it and
# stores it in VirtualFS as IdP CA certificate. Used by the "Use certificate from metadata"
# button and by _Save() if no IdP CA certificate was uploaded. Returns
# ( Success => 1, Filename => '...' ) or ( Success => 0, Message => '...' ).
sub _StoreIdPCertificateFromMetadata {
    my ( $Self, %Param ) = @_;

    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    my $Cert = $SAMLPluginObject->DeriveIdPCertificateFromMetadata(
        AuthConfig => $Param{AuthConfig},
    );
    if ( !$Cert ) {
        return (
            Success => 0,
            Message =>
                Translatable('Could not find a certificate in the metadata. Please check the URL/XML and try again.'),
        );
    }

    my %Validation = $SAMLPluginObject->ValidateContent(
        Role    => 'IdPCACert',
        Content => $Cert,
    );
    if ( !$Validation{Success} ) {
        return (
            Success => 0,
            Message => $Validation{Message},
        );
    }

    my $Filename = $Self->_WriteCertificateBlob(
        Role    => 'IdPCACert',
        Content => $Validation{PEM},
        Name    => 'from-metadata.pem',
    );
    if ( !$Filename ) {
        return (
            Success => 0,
            Message => Translatable('Error storing the certificate.'),
        );
    }

    return (
        Success  => 1,
        Filename => $Filename,
    );
}

sub _DeleteCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');
    my $VirtualFSObject            = $Kernel::OM->Get('Kernel::System::VirtualFS');

    $LayoutObject->ChallengeTokenCheck();

    my $Filename = $ParamObject->GetParam( Param => 'Filename' );

    # Only ever allow deleting blobs inside our own VirtualFS namespace, never an arbitrary
    # VirtualFS filename that might belong to another feature (attachments, packages, ...).
    if ( !$Filename || $Filename !~ m{\AVirtualFS::AuthenticationConfig::} ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    # Only clears the blob from the form (handled client-side already). A blob that any saved
    # config still references, including the one being edited, is kept: the edit may still be
    # cancelled. _Save() deletes it once the saved config no longer references it.
    my $InUse = $AuthenticationConfigObject->VFSFilenameInUse(
        Filename => $Filename,
        UserID   => $Self->{UserID},
    );

    if ( !$InUse ) {
        $VirtualFSObject->Delete(
            Filename        => $Filename,
            DisableWarnings => 1,
        );
    }

    return $Self->_JSONResponse( Success => 1 );
}

sub _ViewCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    $LayoutObject->ChallengeTokenCheck();

    my $Filename = $ParamObject->GetParam( Param => 'Filename' );

    # Allow-list, not a deny-list: only ever allow reading back roles that are public
    # certificates. RequestSignKey (the private key itself) must never be readable through
    # this action.
    if ( !$Filename || $Filename !~ m{\AVirtualFS::AuthenticationConfig::SAML::(?:RequestSignKeyCert|IdPCACert)::} ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    my %File = $VirtualFSObject->Read(
        Filename => $Filename,
        Mode     => 'binary',
    );
    if ( !%File ) {
        return $Self->_JSONResponse(
            Success => 0,
            Message => Translatable('Could not read the certificate from VirtualFS.'),
        );
    }

    return $Self->_JSONResponse(
        Success => 1,
        Content => ${ $File{Content} },
    );
}

sub _DownloadCertificate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    $LayoutObject->ChallengeTokenCheck();

    my $Filename = $ParamObject->GetParam( Param => 'Filename' );

    # Same allow-list as _ViewCertificate - only ever allow downloading roles that are public
    # certificates. RequestSignKey (the private key itself) must never be downloadable.
    if ( !$Filename || $Filename !~ m{\AVirtualFS::AuthenticationConfig::SAML::(?:RequestSignKeyCert|IdPCACert)::} ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Invalid or missing certificate.',
        );
    }

    my %File = $VirtualFSObject->Read(
        Filename => $Filename,
        Mode     => 'binary',
    );
    if ( !%File ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Could not read the certificate from VirtualFS.'),
        );
    }

    my $DownloadFilename = $File{Preferences}->{OrigFilename} || 'certificate.pem';
    $DownloadFilename =~ s{[^A-Za-z0-9_.-]}{_}g;

    return $LayoutObject->Attachment(
        ContentType => 'application/x-pem-file',
        Content     => ${ $File{Content} },
        Filename    => $DownloadFilename,
        Type        => 'attachment',
    );
}

sub _CertificateInfo {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    $LayoutObject->ChallengeTokenCheck();

    my $Filename = $ParamObject->GetParam( Param => 'Filename' );

    # Same allow-list as _ViewCertificate - only ever allow reading back roles that are
    # public certificates. RequestSignKey (the private key itself) must never be readable
    # through this action, and has no X.509 fields to parse anyway.
    if ( !$Filename || $Filename !~ m{\AVirtualFS::AuthenticationConfig::SAML::(?:RequestSignKeyCert|IdPCACert)::} ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    my %Info = $SAMLPluginObject->CertificateInfo(
        Filename => $Filename,
    );

    return $Self->_JSONResponse(%Info);
}

sub _CertificatePoolList {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    $LayoutObject->ChallengeTokenCheck();

    my $Role = $ParamObject->GetParam( Param => 'Role' );
    if ( !$Role || $Role !~ m{\A(?:RequestSignKey|RequestSignKeyCert|IdPCACert)\z} ) {
        return $Self->_JSONResponse( Success => 0 );
    }

    my $ExcludeID = $ParamObject->GetParam( Param => 'ID' );

    my $Pool = $SAMLPluginObject->CertificatePoolList(
        Role      => $Role,
        ExcludeID => $ExcludeID || 0,
        UserID    => $Self->{UserID},
    );

    return $Self->_JSONResponse(
        Success => 1,
        Pool    => $Pool,
    );
}

sub _WriteCertificateBlob {
    my ( $Self, %Param ) = @_;

    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    # Content-addressed filename (identifier is a hash/fingerprint of the content, not a
    # random UUID) so that uploading/generating the exact same certificate or key always maps
    # to the same VirtualFS entry. This gives natural deduplication now, and will make it
    # straightforward for an upcoming certificate management feature to list every stored
    # certificate/key once, independently of which authentication config(s) reference it. The
    # "SAML" segment namespaces this plugin's blobs from any future authentication type's.
    my $Hash     = $MainObject->MD5sum( String => \$Param{Content} );
    my $Filename = "VirtualFS::AuthenticationConfig::SAML::$Param{Role}::$Hash";

    my @Existing = $VirtualFSObject->Find( Filename => $Filename );
    return $Filename if @Existing;

    my $Content = $Param{Content};

    # The private key is stored AES encrypted if an encryption key is configured (see
    # Kernel::System::Crypt::Secret), otherwise unencrypted. The hash above is always taken
    # from the plain content, since encrypting the same key twice gives different results.
    if ( $Param{Role} eq 'RequestSignKey' ) {
        my $SecretObject = $Kernel::OM->Get('Kernel::System::Crypt::Secret');

        if ( $SecretObject->IsAvailable() ) {
            $Content = $SecretObject->Encrypt( Value => $Content );
            return if !defined $Content;
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => 'No encryption key configured, storing SAML private key unencrypted. '
                    . 'Set the ZNUNY_CONFIG_SECRET_KEY environment variable or '
                    . '$Self->{ConfigSecretKeyFile} in Kernel/Config.pm to store it encrypted.',
            );
        }
    }

    my $Success = $VirtualFSObject->Write(
        Filename    => $Filename,
        Content     => \$Content,
        Mode        => 'binary',
        Preferences => {
            OrigFilename => $Param{Name},
        },
    );

    return $Success ? $Filename : undef;
}

sub _Deploy {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    $LayoutObject->ChallengeTokenCheck();

    my @Errors;
    my $Location = $AuthenticationConfigObject->Deploy(
        UserID => $Self->{UserID},
        Errors => \@Errors,
    );

    if ($Location) {
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    my $LanguageObject = $LayoutObject->{LanguageObject};

    # The failed configs are listed in the overview, each with the option to set it to invalid
    # and deploy the others.
    my @Lines = (
        $LanguageObject->Translate(
            'The authentication configuration was not deployed. The previously deployed configuration is still active.'
        ),
    );
    if ( !@Errors ) {
        push @Lines, $LanguageObject->Translate('Please check the system log for details.');
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Notify(
        Priority => 'Error',
        Info     => join( "\n", @Lines ),
    );
    $Output .= $Self->_Overview(
        %Param,
        DeployErrors => \@Errors,
    );
    $Output .= $LayoutObject->Footer();

    return $Output;
}

# Sets a config that can't be deployed to invalid and deploys the others. Offered on the deploy
# error page, so the admin decides explicitly that the login of this config stops working.
sub _InvalidateAndDeploy {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    $LayoutObject->ChallengeTokenCheck();

    my $ID = $ParamObject->GetParam( Param => 'ID' );

    my %Config;
    if ($ID) {
        %Config = $AuthenticationConfigObject->DataGet(
            ID     => $ID,
            UserID => $Self->{UserID},
        );
    }
    if ( !%Config ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Authentication configuration not found.'),
        );
    }

    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    my $Updated = $AuthenticationConfigObject->DataUpdate(
        ID          => $Config{ID},
        Name        => $Config{Name},
        Type        => $Config{Type},
        Context     => $Config{Context},
        Slot        => $Config{Slot},
        AuthConfig  => $Config{AuthConfig},
        SyncEnabled => $Config{SyncEnabled},
        SyncConfig  => $Config{SyncConfig},
        ValidID     => $InvalidID,
        UserID      => $Self->{UserID},
    );
    if ( !$Updated ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Could not set the authentication configuration to invalid.'),
        );
    }

    return $Self->_Deploy(%Param);
}

sub _DownloadMetadata {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');
    my $SAMLPluginObject           = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

    my $ID = $ParamObject->GetParam( Param => 'ID' );

    my %Row = $AuthenticationConfigObject->DataGet(
        ID     => $ID,
        UserID => $Self->{UserID},
    );
    if ( !%Row ) {
        return $LayoutObject->ErrorScreen(
            Message => "Authentication config with ID $ID could not be found.",
        );
    }

    my $XML = $SAMLPluginObject->GenerateSPMetadata(
        Row => \%Row,
    );
    if ( !$XML ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Error generating SP metadata.',
        );
    }

    my $Filename = 'saml-sp-metadata-' . $Row{Name} . '.xml';
    $Filename =~ s{[^A-Za-z0-9_.-]}{_}g;

    return $LayoutObject->Attachment(
        ContentType => 'application/samlmetadata+xml',
        Content     => $XML,
        Filename    => $Filename,
        Type        => 'attachment',
    );
}

sub _RenderEditForm {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $PermissionTypes = $ConfigObject->Get('System::Permission') || [ 'rw', 'ro' ];

    my %ValidIDs         = $ValidObject->ValidList();
    my $ValidIDSelection = $LayoutObject->BuildSelection(
        Data       => \%ValidIDs,
        Name       => 'ValidID',
        SelectedID => $Param{FormData}->{ValidID},
        Class      => 'Modernize Validate_Required',
    );

    my $SlotSelection = $Self->_BuildSlotSelection(
        SlotStatus   => $Param{SlotStatus},
        CurrentID    => $Param{FormData}->{ID},
        SelectedSlot => $Param{FormData}->{Slot},
    );

    my %ExtraData;

    if ( $Param{Context} eq 'Agent' ) {
        %ExtraData = $Self->_BuildSyncFormData( FormData => $Param{FormData} );
    }

    my $TemplateFile
        = $Param{Context} eq 'Agent' ? 'AdminAuthentication/EditAgentAuth' : 'AdminAuthentication/EditCustomerAuth';

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    $Output .= $LayoutObject->Output(
        TemplateFile => $TemplateFile,
        Data         => {
            %{ $Param{FormData} },
            %ExtraData,
            ValidIDSelection => $ValidIDSelection,
            SlotSelection    => $SlotSelection,
            Context          => $Param{Context},
            PermissionTypes  => $PermissionTypes,
            FQDN             => $ConfigObject->Get('FQDN'),
        },
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _BuildSyncFormData {
    my ( $Self, %Param ) = @_;

    # Template data for AdminAuthentication/SyncSettings.tt (group/role selections, row
    # templates, HasRoles). Used by the agent edit screen and the setup wizard.
    # FormData is optional and holds the rows/selections of an existing config.

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    $Param{FormData} ||= {};

    my $PermissionTypes = $ConfigObject->Get('System::Permission') || [ 'rw', 'ro' ];

    my %SyncFormData;

    my %GroupList    = $GroupObject->GroupList( Valid => 1 );
    my %RoleList     = $GroupObject->RoleList( Valid => 1 );
    my %GroupNameMap = map { $_ => $_ } values %GroupList;
    my %RoleNameMap  = map { $_ => $_ } values %RoleList;

    my $HasRoles = %RoleNameMap ? 1 : 0;
    $SyncFormData{HasRoles} = $HasRoles;

    $SyncFormData{InitialGroupsSelection} = $LayoutObject->BuildSelection(
        Data       => \%GroupNameMap,
        Name       => 'UserSyncInitialGroups',
        SelectedID => $Param{FormData}->{UserSyncInitialGroups} || [],
        Multiple   => 1,
        Size       => 6,
        Class      => 'Modernize',
    );

    $SyncFormData{UserSyncGroupsDefinitionGroupTemplate} = $Self->_BuildNameSelectionRows(
        Rows    => $Param{FormData}->{UserSyncGroupsDefinitionRows} || [],
        Field   => 'Group',
        Prefix  => 'UserSyncGroupsDefinition',
        NameMap => \%GroupNameMap,
    );
    $SyncFormData{UserSyncGroupsDefinitionPermTemplate} = $Self->_BuildPermSelectionRows(
        Rows            => $Param{FormData}->{UserSyncGroupsDefinitionRows} || [],
        Prefix          => 'UserSyncGroupsDefinition',
        PermissionTypes => $PermissionTypes,
    );
    $SyncFormData{UserSyncAttributeGroupsDefinitionGroupTemplate} = $Self->_BuildNameSelectionRows(
        Rows    => $Param{FormData}->{UserSyncAttributeGroupsDefinitionRows} || [],
        Field   => 'Group',
        Prefix  => 'UserSyncAttributeGroupsDefinition',
        NameMap => \%GroupNameMap,
    );
    $SyncFormData{UserSyncAttributeGroupsDefinitionPermTemplate} = $Self->_BuildPermSelectionRows(
        Rows            => $Param{FormData}->{UserSyncAttributeGroupsDefinitionRows} || [],
        Prefix          => 'UserSyncAttributeGroupsDefinition',
        PermissionTypes => $PermissionTypes,
    );
    $SyncFormData{UserSyncRolesDefinitionRoleTemplate} = $Self->_BuildNameSelectionRows(
        Rows     => $Param{FormData}->{UserSyncRolesDefinitionRows} || [],
        Field    => 'Role',
        Prefix   => 'UserSyncRolesDefinition',
        NameMap  => \%RoleNameMap,
        Disabled => !$HasRoles,
        Multiple => 1,
    );
    $SyncFormData{UserSyncAttributeRolesDefinitionRoleTemplate} = $Self->_BuildNameSelectionRows(
        Rows     => $Param{FormData}->{UserSyncAttributeRolesDefinitionRows} || [],
        Field    => 'Role',
        Prefix   => 'UserSyncAttributeRolesDefinition',
        NameMap  => \%RoleNameMap,
        Disabled => !$HasRoles,
        Multiple => 1,
    );

    return %SyncFormData;
}

sub _BuildNameSelectionRows {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Index = 0;
    for my $Row ( @{ $Param{Rows} } ) {
        $Index++;

        $Row->{"$Param{Field}SelectHTML"} = $LayoutObject->BuildSelection(
            Data         => $Param{NameMap},
            Name         => "$Param{Prefix}$Param{Field}_$Index",
            SelectedID   => $Row->{ $Param{Field} },
            PossibleNone => $Param{Multiple} ? 0 : 1,
            Multiple     => $Param{Multiple},
            Disabled     => $Param{Disabled},
            Class        => 'Modernize',
        );
    }

    # Plain (non-modernized, unindexed) select used as the clone source for the hidden row template -
    # JS activates it as a Modernize field only after cloning, to avoid corrupting the template itself.
    return $LayoutObject->BuildSelection(
        Data         => $Param{NameMap},
        Name         => "$Param{Prefix}$Param{Field}",
        PossibleNone => $Param{Multiple} ? 0 : 1,
        Multiple     => $Param{Multiple},
        Disabled     => $Param{Disabled},
    );
}

sub _BuildPermSelectionRows {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %PermMap = map { $_ => $_ } @{ $Param{PermissionTypes} || [] };

    my $Index = 0;
    for my $Row ( @{ $Param{Rows} } ) {
        $Index++;

        $Row->{PermSelectHTML} = $LayoutObject->BuildSelection(
            Data       => \%PermMap,
            Name       => "$Param{Prefix}Perm_$Index",
            SelectedID => $Row->{Perm} || [],
            Multiple   => 1,
            Class      => 'Modernize',
        );
    }

    # Plain (non-modernized, unindexed) select used as the clone source for the hidden row template -
    # JS activates it as a Modernize field only after cloning, to avoid corrupting the template itself.
    return $LayoutObject->BuildSelection(
        Data     => \%PermMap,
        Name     => "$Param{Prefix}Perm",
        Multiple => 1,
    );
}

sub _BuildSlotSelection {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %SlotData;
    SLOT:
    for my $Slot ( '', 1 .. 10 ) {
        my $Status        = $Param{SlotStatus}->{$Slot};
        my $IsCurrentSlot = defined $Param{CurrentID}
            && $Status->{State} eq 'Ours'
            && $Status->{AuthenticationConfigID} == $Param{CurrentID};

        next SLOT if $Status->{State} ne 'Free' && !$IsCurrentSlot;

        my $Label = length $Slot ? "Slot $Slot" : 'Default';
        if ( $Status->{AuthenticationConfigName} ) {
            $Label .= " ($Status->{AuthenticationConfigName})";
        }

        $SlotData{$Slot} = $Label;
    }

    return $LayoutObject->BuildSelection(
        Data       => \%SlotData,
        Name       => $Param{Name} || 'Slot',
        SelectedID => $Param{SelectedSlot},
        Class      => 'Modernize Validate_Required',
    );
}

sub _ComputeAssertionConsumerURL {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ScriptName = $Param{Context} eq 'Agent' ? 'index.pl' : 'customer.pl';

    return ( $ConfigObject->Get('HttpType')   // '' ) . '://'
        . ( $ConfigObject->Get('FQDN')        // '' ) . '/'
        . ( $ConfigObject->Get('ScriptAlias') // '' )
        . "$ScriptName?Action=Login";
}

sub _ComputeDefaultIssuer {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    return ( $ConfigObject->Get('HttpType') // '' ) . '://' . ( $ConfigObject->Get('FQDN') // '' );
}

sub _ConfigToFormData {
    my ( $Self, %Param ) = @_;

    my $Config     = $Param{Config}        || {};
    my $AuthConfig = $Config->{AuthConfig} || {};
    my $SyncConfig = $Config->{SyncConfig} || {};

    my %FormData = (
        ID                          => $Param{ID},
        Name                        => $Config->{Name},
        Slot                        => $Config->{Slot},
        ValidID                     => $Config->{ValidID} || 1,
        RequestLoginButtonText      => $AuthConfig->{RequestLoginButtonText},
        RequestAssertionConsumerURL => $Self->_ComputeAssertionConsumerURL( Context => $Param{Context} ),
        Issuer                      => $AuthConfig->{Issuer} || $Self->_ComputeDefaultIssuer(),
        RequestNameIDFormat         => $AuthConfig->{RequestNameIDFormat},
        RequestSignSigAlg           => $AuthConfig->{RequestSignSigAlg},
        UserLoginAttribute          => ref $AuthConfig->{UserLoginAttribute} eq 'ARRAY'
        ? join( ', ', @{ $AuthConfig->{UserLoginAttribute} } )
        : $AuthConfig->{UserLoginAttribute},

        # Missing key (never saved with this checkbox) defaults to enabled, preserving the
        # always-on behavior this had before the checkbox existed.
        ResponseEncryptionEnabled => defined $AuthConfig->{ResponseEncryptionEnabled}
        ? $AuthConfig->{ResponseEncryptionEnabled}
        : 1,

        MetaDataSourceType            => $AuthConfig->{MetaDataSourceType},
        RequestMetaDataURL            => $AuthConfig->{RequestMetaDataURL},
        RequestMetaDataXML            => $AuthConfig->{RequestMetaDataXML},
        SSLOptionsEnabled             => $AuthConfig->{RequestMetaDataURLSSLOptions} ? 1 : 0,
        SSLCAFile                     => $AuthConfig->{RequestMetaDataURLSSLOptions}->{SSL_ca_file},
        SSLCAPath                     => $AuthConfig->{RequestMetaDataURLSSLOptions}->{SSL_ca_path},
        SSLVerifyHostname             => $AuthConfig->{RequestMetaDataURLSSLOptions}->{verify_hostname},
        RequestSignKeyVFSFilename     => $AuthConfig->{RequestSignKeyVFSFilename},
        RequestSignKeyCertVFSFilename => $AuthConfig->{RequestSignKeyCertVFSFilename},
        IdPCACertVFSFilename          => $AuthConfig->{IdPCACertVFSFilename},
    );

    if ( $Param{Context} eq 'Agent' ) {
        $FormData{SyncEnabled}           = $Config->{SyncEnabled} ? 1 : 0;
        $FormData{UserSyncMapRows}       = $Self->_FlattenHash( $SyncConfig->{UserSyncMap} || {}, [qw(Key Value)] );
        $FormData{UserSyncInitialGroups} = $SyncConfig->{UserSyncInitialGroups} || [];

        # Attribute names discovered by the setup wizard: pre-fill them as SAML attribute
        # only rows, the admin picks the matching Znuny attribute for each one.
        if ( !$SyncConfig->{UserSyncMap} && ref $SyncConfig->{WizardDiscoveredAttributes} eq 'ARRAY' ) {
            push @{ $FormData{UserSyncMapRows} }, map { { Key => '', Value => $_ } }
                @{ $SyncConfig->{WizardDiscoveredAttributes} };
        }
        $FormData{UserSyncGroupsDefinitionAttribute} = $SyncConfig->{'UserSyncGroupsDefinition::Attribute'};
        $FormData{UserSyncGroupsDefinitionRows}
            = $Self->_FlattenGroupsDefinition( $SyncConfig->{UserSyncGroupsDefinition} || {} );
        $FormData{UserSyncAttributeGroupsDefinitionRows}
            = $Self->_FlattenAttributeGroupsDefinition( $SyncConfig->{UserSyncAttributeGroupsDefinition} || {} );
        $FormData{UserSyncRolesDefinitionAttribute} = $SyncConfig->{'UserSyncRolesDefinition::Attribute'};
        $FormData{UserSyncRolesDefinitionRows}
            = $Self->_FlattenRolesDefinition( $SyncConfig->{UserSyncRolesDefinition} || {} );
        $FormData{UserSyncAttributeRolesDefinitionRows}
            = $Self->_FlattenAttributeRolesDefinition( $SyncConfig->{UserSyncAttributeRolesDefinition} || {} );
    }

    return %FormData;
}

sub _CollectSyncFormData {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Param{ParamObject};

    my $UserSyncGroupsDefinitionAttribute = $ParamObject->GetParam( Param => 'UserSyncGroupsDefinitionAttribute' );
    my $UserSyncRolesDefinitionAttribute  = $ParamObject->GetParam( Param => 'UserSyncRolesDefinitionAttribute' );

    my %SyncConfig = $Self->_BuildSyncConfig(
        ParamObject => $ParamObject,
        GetParam    => {
            UserSyncGroupsDefinitionAttribute => $UserSyncGroupsDefinitionAttribute,
            UserSyncRolesDefinitionAttribute  => $UserSyncRolesDefinitionAttribute,
        },
    );

    return (
        UserSyncMapRows                   => $Self->_FlattenHash( $SyncConfig{UserSyncMap} || {}, [qw(Key Value)] ),
        UserSyncInitialGroups             => $SyncConfig{UserSyncInitialGroups} || [],
        UserSyncGroupsDefinitionAttribute => $SyncConfig{'UserSyncGroupsDefinition::Attribute'},
        UserSyncGroupsDefinitionRows => $Self->_FlattenGroupsDefinition( $SyncConfig{UserSyncGroupsDefinition} || {} ),
        UserSyncAttributeGroupsDefinitionRows =>
            $Self->_FlattenAttributeGroupsDefinition( $SyncConfig{UserSyncAttributeGroupsDefinition} || {} ),
        UserSyncRolesDefinitionAttribute => $SyncConfig{'UserSyncRolesDefinition::Attribute'},
        UserSyncRolesDefinitionRows => $Self->_FlattenRolesDefinition( $SyncConfig{UserSyncRolesDefinition} || {} ),
        UserSyncAttributeRolesDefinitionRows =>
            $Self->_FlattenAttributeRolesDefinition( $SyncConfig{UserSyncAttributeRolesDefinition} || {} ),
    );
}

sub _BuildSyncConfig {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Param{ParamObject};
    my $GetParam    = $Param{GetParam};

    my %SyncConfig;

    my $MapRows = $Self->_CollectIndexedRows(
        ParamObject => $ParamObject,
        Prefix      => 'UserSyncMap',
        Fields      => [qw(Key Value)],
    );
    my %UserSyncMap;
    MAPROW:
    for my $Row ( @{$MapRows} ) {
        next MAPROW if !length( $Row->{Key} // '' );
        $UserSyncMap{ $Row->{Key} } = $Row->{Value};
    }
    $SyncConfig{UserSyncMap} = \%UserSyncMap if %UserSyncMap;

    my @InitialGroups = grep { length $_ } $ParamObject->GetArray( Param => 'UserSyncInitialGroups' );
    $SyncConfig{UserSyncInitialGroups} = \@InitialGroups if @InitialGroups;

    if ( length( $GetParam->{UserSyncGroupsDefinitionAttribute} // '' ) ) {
        $SyncConfig{'UserSyncGroupsDefinition::Attribute'} = $GetParam->{UserSyncGroupsDefinitionAttribute};
    }
    my $GroupsDefinitionRows = $Self->_CollectIndexedRows(
        ParamObject => $ParamObject,
        Prefix      => 'UserSyncGroupsDefinition',
        Fields      => [qw(SAMLValue Group)],
        MultiFields => [qw(Perm)],
    );
    my %GroupsDefinition;
    GROUPROW:
    for my $Row ( @{$GroupsDefinitionRows} ) {
        next GROUPROW if !length( $Row->{SAMLValue} // '' ) || !length( $Row->{Group} // '' );
        my %Perms = map { $_ => 1 } @{ $Row->{Perm} || [] };
        $GroupsDefinition{ $Row->{SAMLValue} }{ $Row->{Group} } = \%Perms;
    }
    $SyncConfig{UserSyncGroupsDefinition} = \%GroupsDefinition if %GroupsDefinition;

    my $AttrGroupsRows = $Self->_CollectIndexedRows(
        ParamObject => $ParamObject,
        Prefix      => 'UserSyncAttributeGroupsDefinition',
        Fields      => [qw(Attribute SAMLValue Group)],
        MultiFields => [qw(Perm)],
    );
    my %AttrGroupsDefinition;
    ATTRGROUPROW:
    for my $Row ( @{$AttrGroupsRows} ) {
        next ATTRGROUPROW
            if !length( $Row->{Attribute} // '' )
            || !length( $Row->{SAMLValue} // '' )
            || !length( $Row->{Group}     // '' );
        my %Perms = map { $_ => 1 } @{ $Row->{Perm} || [] };
        $AttrGroupsDefinition{ $Row->{Attribute} }{ $Row->{SAMLValue} }{ $Row->{Group} } = \%Perms;
    }
    $SyncConfig{UserSyncAttributeGroupsDefinition} = \%AttrGroupsDefinition if %AttrGroupsDefinition;

    if ( length( $GetParam->{UserSyncRolesDefinitionAttribute} // '' ) ) {
        $SyncConfig{'UserSyncRolesDefinition::Attribute'} = $GetParam->{UserSyncRolesDefinitionAttribute};
    }
    my $RolesDefinitionRows = $Self->_CollectIndexedRows(
        ParamObject => $ParamObject,
        Prefix      => 'UserSyncRolesDefinition',
        Fields      => [qw(SAMLValue Active)],
        MultiFields => [qw(Role)],
    );
    my %RolesDefinition;
    ROLEROW:
    for my $Row ( @{$RolesDefinitionRows} ) {
        next ROLEROW if !length( $Row->{SAMLValue} // '' );

        ROLE:
        for my $Role ( @{ $Row->{Role} } ) {
            next ROLE if !length $Role;
            $RolesDefinition{ $Row->{SAMLValue} }->{$Role} = $Row->{Active} ? 1 : 0;
        }
    }
    $SyncConfig{UserSyncRolesDefinition} = \%RolesDefinition if %RolesDefinition;

    my $AttrRolesRows = $Self->_CollectIndexedRows(
        ParamObject => $ParamObject,
        Prefix      => 'UserSyncAttributeRolesDefinition',
        Fields      => [qw(Attribute SAMLValue Active)],
        MultiFields => [qw(Role)],
    );
    my %AttrRolesDefinition;
    ATTRROLEROW:
    for my $Row ( @{$AttrRolesRows} ) {
        next ATTRROLEROW
            if !length( $Row->{Attribute} // '' )
            || !length( $Row->{SAMLValue} // '' );

        ROLE:
        for my $Role ( @{ $Row->{Role} } ) {
            next ROLE if !length $Role;
            $AttrRolesDefinition{ $Row->{Attribute} }->{ $Row->{SAMLValue} }->{$Role} = $Row->{Active} ? 1 : 0;
        }
    }
    $SyncConfig{UserSyncAttributeRolesDefinition} = \%AttrRolesDefinition if %AttrRolesDefinition;

    return %SyncConfig;
}

sub _CollectIndexedRows {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Param{ParamObject};
    my $Prefix      = $Param{Prefix};
    my $FirstField  = ( $Param{Fields} && $Param{Fields}->[0] ) || ( $Param{MultiFields} && $Param{MultiFields}->[0] );

    my @Names = $ParamObject->GetParamNames();

    my %Indexes;
    for my $Name (@Names) {
        if ( $Name =~ m{\A\Q$Prefix$FirstField\E_(\d+)\z} ) {
            $Indexes{$1} = 1;
        }
    }

    my @Rows;
    for my $Index ( sort { $a <=> $b } keys %Indexes ) {
        my %Row;

        for my $Field ( @{ $Param{Fields} || [] } ) {
            $Row{$Field} = $ParamObject->GetParam( Param => "$Prefix${Field}_$Index" );
        }

        for my $Field ( @{ $Param{MultiFields} || [] } ) {
            my @Values = $ParamObject->GetArray( Param => "$Prefix${Field}_$Index" );
            $Row{$Field} = \@Values;
        }

        push @Rows, \%Row;
    }

    return \@Rows;
}

sub _FlattenHash {
    my ( $Self, $Hash, $FieldNames ) = @_;

    my @Rows;
    for my $Key ( sort keys %{$Hash} ) {
        push @Rows, {
            $FieldNames->[0] => $Key,
            $FieldNames->[1] => $Hash->{$Key},
        };
    }

    return \@Rows;
}

sub _FlattenGroupsDefinition {
    my ( $Self, $Definition ) = @_;

    my @Rows;
    for my $SAMLValue ( sort keys %{$Definition} ) {
        for my $Group ( sort keys %{ $Definition->{$SAMLValue} } ) {
            my $PermHash = $Definition->{$SAMLValue}->{$Group} || {};
            push @Rows, {
                SAMLValue => $SAMLValue,
                Group     => $Group,
                Perm      => [ sort keys %{$PermHash} ],
                PermHash  => $PermHash,
            };
        }
    }

    return \@Rows;
}

sub _FlattenAttributeGroupsDefinition {
    my ( $Self, $Definition ) = @_;

    my @Rows;
    for my $Attribute ( sort keys %{$Definition} ) {
        for my $SAMLValue ( sort keys %{ $Definition->{$Attribute} } ) {
            for my $Group ( sort keys %{ $Definition->{$Attribute}->{$SAMLValue} } ) {
                my $PermHash = $Definition->{$Attribute}->{$SAMLValue}->{$Group} || {};
                push @Rows, {
                    Attribute => $Attribute,
                    SAMLValue => $SAMLValue,
                    Group     => $Group,
                    Perm      => [ sort keys %{$PermHash} ],
                    PermHash  => $PermHash,
                };
            }
        }
    }

    return \@Rows;
}

sub _FlattenRolesDefinition {
    my ( $Self, $Definition ) = @_;

    my @Rows;
    for my $SAMLValue ( sort keys %{$Definition} ) {
        push @Rows, $Self->_RoleRowsByActive(
            Roles => $Definition->{$SAMLValue},
            Row   => { SAMLValue => $SAMLValue },
        );
    }

    return \@Rows;
}

sub _FlattenAttributeRolesDefinition {
    my ( $Self, $Definition ) = @_;

    my @Rows;
    for my $Attribute ( sort keys %{$Definition} ) {
        for my $SAMLValue ( sort keys %{ $Definition->{$Attribute} } ) {
            push @Rows, $Self->_RoleRowsByActive(
                Roles => $Definition->{$Attribute}->{$SAMLValue},
                Row   => {
                    Attribute => $Attribute,
                    SAMLValue => $SAMLValue,
                },
            );
        }
    }

    return \@Rows;
}

# One form row per SAML value and Active state, holding all of its roles: the role field
# is a multiselect, and the Active checkbox applies to all roles of the row.
sub _RoleRowsByActive {
    my ( $Self, %Param ) = @_;

    my %RolesByActive;
    for my $Role ( sort keys %{ $Param{Roles} || {} } ) {
        my $Active = $Param{Roles}->{$Role} ? 1 : 0;
        push @{ $RolesByActive{$Active} }, $Role;
    }

    my @Rows;
    for my $Active ( reverse sort keys %RolesByActive ) {
        push @Rows, {
            %{ $Param{Row} },
            Role   => $RolesByActive{$Active},
            Active => $Active,
        };
    }

    return @Rows;
}

sub _JSONResponse {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( defined $Param{Message} && length $Param{Message} ) {
        $Param{Message} = $LayoutObject->{LanguageObject}->Translate( $Param{Message} );
    }

    my $JSON = $LayoutObject->JSONEncode( Data => \%Param );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON // '',
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
