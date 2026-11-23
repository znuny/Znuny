# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::Authentication::Plugin::SAML;

use strict;
use warnings;

use utf8;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthenticationConfig',
    'Kernel::System::Crypt::Secret',
    'Kernel::System::FileTemp',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::VirtualFS',
    'Kernel::System::X509Certificate',
);

=head1 NAME

Kernel::System::Authentication::Plugin::SAML - SAML 2.0 authentication plugin for AdminAuthentication

=head1 SYNOPSIS

Implements everything specific to SAML 2.0 authentication configs (for
Kernel::System::Auth::SAML, Kernel::System::Auth::Sync::SAML and
Kernel::System::CustomerAuth::SAML) on behalf of the generic
Kernel::System::AuthenticationConfig, which resolves to this class for any
config row with C<Type =E<gt> 'SAML'> (see
C<AuthenticationConfig::Plugin###SAML> in SysConfig).

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $PluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 VFSFilenameKeys()

Returns the list of AuthConfig keys that hold VirtualFS filenames for this
plugin, so the generic AuthenticationConfig can clean them up on delete/
replace without needing to know anything SAML-specific.

=cut

sub VFSFilenameKeys {
    my ( $Self, %Param ) = @_;

    return qw(RequestSignKeyVFSFilename RequestSignKeyCertVFSFilename IdPCACertVFSFilename);
}

=head2 GenerateCertificate()

Generates a self-signed certificate/private key pair (for use as
RequestSignKey) by shelling out to openssl, the same way
Kernel::System::Crypt::SMIME does. Does not persist anything - the
caller is responsible for storing the returned content (e.g. in
VirtualFS).

    my %Certificate = $PluginObject->GenerateCertificate(
        CommonName   => 'saml.example.com',
        KeySize      => 2048,               # 2048 or 4096
        ValidityDays => 365,
    );

Returns:

    my %Certificate = (
        Cert => "-----BEGIN CERTIFICATE-----...",
        Key  => "-----BEGIN PRIVATE KEY-----...",
    );

=cut

sub GenerateCertificate {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject     = $Kernel::OM->Get('Kernel::System::Main');
    my $FileTempObject = $Kernel::OM->Get('Kernel::System::FileTemp');

    NEEDED:
    for my $Needed (qw(CommonName KeySize ValidityDays)) {
        next NEEDED if defined $Param{$Needed} && length $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    if ( $Param{KeySize} !~ m{\A(?:2048|4096)\z} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Invalid KeySize '$Param{KeySize}', must be 2048 or 4096!",
        );
        return;
    }

    if ( $Param{ValidityDays} !~ m{\A\d+\z} || $Param{ValidityDays} < 1 ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Invalid ValidityDays '$Param{ValidityDays}'!",
        );
        return;
    }

    # Sanitize CommonName for safe use in an openssl -subj argument.
    my $CommonName = $Param{CommonName};
    $CommonName =~ s{[^a-zA-Z0-9_.:\-\* ]}{}g;

    if ( !length $CommonName ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'CommonName does not contain any valid characters!',
        );
        return;
    }

    my $Cmd = $Self->_OpenSSLCommand();

    my ( $FHKey, $KeyFile ) = $FileTempObject->TempFile();
    close $FHKey;
    my ( $FHCert, $CertFile ) = $FileTempObject->TempFile();
    close $FHCert;

    my $Options = "req -x509 -newkey rsa:$Param{KeySize} -keyout $KeyFile -out $CertFile"
        . " -days $Param{ValidityDays} -nodes -subj \"/CN=$CommonName\"";

    my $LogMessage = qx{$Cmd $Options 2>&1};

    my $KeyContentRef  = $MainObject->FileRead( Location => $KeyFile );
    my $CertContentRef = $MainObject->FileRead( Location => $CertFile );

    if ( !$KeyContentRef || !$CertContentRef || !${$KeyContentRef} || !${$CertContentRef} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not generate certificate: $LogMessage",
        );
        return;
    }

    return (
        Cert => ${$CertContentRef},
        Key  => ${$KeyContentRef},
    );
}

=head2 ValidateContent()

Checks that uploaded or pasted content really is a certificate (certificate
roles) or an unencrypted private key (RequestSignKey role). Only the PEM
blocks are kept, any other text around them is dropped. Each block is
written to a temporary file and checked with openssl before the caller
stores anything.

    my %Result = $PluginObject->ValidateContent(
        Role    => 'IdPCACert',    # or RequestSignKey, RequestSignKeyCert
        Content => "-----BEGIN CERTIFICATE-----...",
    );

Returns:

    my %Result = (
        Success => 1,
        PEM     => "-----BEGIN CERTIFICATE-----...\n",
    );

    # or, on failure:
    my %Result = (
        Success => 0,
        Message => 'This is not a certificate in PEM format (-----BEGIN CERTIFICATE-----).',
    );

=cut

sub ValidateContent {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $FileTempObject = $Kernel::OM->Get('Kernel::System::FileTemp');

    my $Role    = $Param{Role}    // '';
    my $Content = $Param{Content} // '';
    my $IsKey   = $Role eq 'RequestSignKey' ? 1 : 0;

    $Content =~ s{\r\n?}{\n}g;

    # Net::SAML2 can't use a passphrase, so encrypted keys are not accepted. A certificate
    # role may hold a chain, so all certificate blocks are kept.
    my @Blocks;
    if ($IsKey) {
        my ($Block) = $Content =~ m{(-----BEGIN\ ((?:RSA\ |EC\ )?PRIVATE\ KEY)-----.+?-----END\ \2-----)}xms;
        push @Blocks, $Block if $Block;
    }
    else {
        @Blocks = $Content =~ m{(-----BEGIN\ CERTIFICATE-----.+?-----END\ CERTIFICATE-----)}xmsg;
    }

    if ( !@Blocks ) {
        return (
            Success => 0,
            Message => $IsKey
            ? Translatable('This is not an unencrypted private key in PEM format (-----BEGIN PRIVATE KEY-----).')
            : Translatable('This is not a certificate in PEM format (-----BEGIN CERTIFICATE-----).'),
        );
    }

    my $Cmd = $Self->_OpenSSLCommand();

    # An empty passphrase makes openssl fail on a legacy encrypted key instead of prompting for one.
    my $Options = $IsKey ? 'pkey -noout -passin pass:' : 'x509 -noout';

    BLOCK:
    for my $Block (@Blocks) {
        my ( $FH, $Filename ) = $FileTempObject->TempFile();
        print $FH "$Block\n";
        close $FH;

        my $Output = qx{$Cmd $Options -in $Filename 2>&1};
        next BLOCK if !$?;

        $LogObject->Log(
            Priority => 'notice',
            Message  => "openssl rejected the uploaded content for role '$Role': $Output",
        );

        return (
            Success => 0,
            Message => $IsKey
            ? Translatable('The private key could not be read. Only unencrypted private keys are supported.')
            : Translatable('The certificate could not be read.'),
        );
    }

    return (
        Success => 1,
        PEM     => join( "\n", @Blocks ) . "\n",
    );
}

=head2 PrepareCertificates()

Reads the certificate/key stored in VirtualFS for a single config row and
decrypts the private key. Doesn't write anything, so Deploy() can check
every config row before it changes any file, and the admin interface can
run the same checks when a config is saved. Kernel::System::Auth::SAML
can't verify assertions without an IdP CA certificate, so a row without
one fails.

The admin interface stores the IdP CA certificate when a config is saved
(taken from the IdP metadata if none was uploaded). Only for configs saved
before that, the certificate is still taken from the IdP metadata here,
which may fetch it over the network. With Offline => 1 that is skipped and
such a row fails with NeedsMetadata => 1.

    my %Result = $PluginObject->PrepareCertificates(
        Row     => $Row,
        Offline => 1,    # optional, never fetch the IdP metadata
    );

Returns:

    my %Result = (
        Success      => 1,
        Certificates => {
            SignKey   => \$Content,    # not set if no signing key is configured
            IdPCACert => \$Content,
        },
    );

    # or, on failure:
    my %Result = (
        Success       => 0,
        Role          => 'IdPCACert',    # or RequestSignKey, the certificate that failed
        Message       => 'Could not read the IdP CA certificate.',
        NeedsMetadata => 1,              # only with Offline, if the certificate would be taken from the metadata
    );

=cut

sub PrepareCertificates {
    my ( $Self, %Param ) = @_;

    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');
    my $SecretObject    = $Kernel::OM->Get('Kernel::System::Crypt::Secret');

    my $Row        = $Param{Row}        || {};
    my $AuthConfig = $Row->{AuthConfig} || {};

    my %FilenameKeyByRole = (
        SignKey   => 'RequestSignKeyVFSFilename',
        IdPCACert => 'IdPCACertVFSFilename',
    );
    my %ReadErrorMessage = (
        SignKey   => Translatable('Could not read the SP signing key.'),
        IdPCACert => Translatable('Could not read the IdP CA certificate.'),
    );

    # Role names as used by the admin interface (certificate widgets, VFSFilename fields).
    my %AdminRole = (
        SignKey   => 'RequestSignKey',
        IdPCACert => 'IdPCACert',
    );

    my %Certificates;

    ROLE:
    for my $Role ( sort keys %FilenameKeyByRole ) {
        my $VFSFilename = $AuthConfig->{ $FilenameKeyByRole{$Role} };

        if ( !$VFSFilename ) {
            next ROLE if $Role ne 'IdPCACert';

            # Configs saved before the admin interface stored the certificate on save.
            if ( $Param{Offline} ) {
                return (
                    Success       => 0,
                    Role          => $AdminRole{$Role},
                    NeedsMetadata => 1,
                    Message       => Translatable(
                        'No IdP CA certificate is stored. It is taken from the IdP metadata on every deploy. Save the configuration to store it.'
                    ),
                );
            }

            # The IdP metadata usually embeds it.
            my $DerivedCert = $Self->DeriveIdPCertificateFromMetadata(
                AuthConfig => $AuthConfig,
            );
            if ( !$DerivedCert ) {
                return (
                    Success => 0,
                    Role    => $AdminRole{$Role},
                    Message => Translatable(
                        'No IdP CA certificate was uploaded and none could be taken from the IdP metadata.'
                    ),
                );
            }

            $Certificates{$Role} = \$DerivedCert;
            next ROLE;
        }

        my %File = $VirtualFSObject->Read(
            Filename => $VFSFilename,
            Mode     => 'binary',
        );
        if ( !%File ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not read '$VFSFilename' from VirtualFS.",
            );
            return (
                Success => 0,
                Role    => $AdminRole{$Role},
                Message => $ReadErrorMessage{$Role},
            );
        }

        $Certificates{$Role} = $File{Content};

        next ROLE if $Role ne 'SignKey';

        # The private key may be stored AES encrypted (see Kernel::System::Crypt::Secret),
        # Decrypt() returns unencrypted content unchanged.
        my $PlainKey = $SecretObject->Decrypt(
            Value => ${ $File{Content} },
        );
        if ( !defined $PlainKey ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not decrypt '$VFSFilename' from VirtualFS.",
            );
            return (
                Success => 0,
                Role    => $AdminRole{$Role},
                Message =>
                    Translatable('Could not decrypt the SP signing key. Please check the configured encryption key.'),
            );
        }

        $Certificates{$Role} = \$PlainKey;
    }

    return (
        Success      => 1,
        Certificates => \%Certificates,
    );
}

=head2 MaterializeCertificates()

Writes the certificate/key returned by PrepareCertificates() for a single
config row to a stable file below the Home directory's var/saml/ folder,
since Net::SAML2 (used by Kernel::System::Auth::SAML) only accepts
filesystem paths for RequestSignKey/IdPCACert, not in-memory content.
Removes the file of a role that has no certificate/key anymore.

    my $Success = $PluginObject->MaterializeCertificates(
        Row          => $Row,
        Certificates => $Result{Certificates},    # from PrepareCertificates()
    );

=cut

sub MaterializeCertificates {
    my ( $Self, %Param ) = @_;

    my $Row = $Param{Row};
    return if !$Row;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Certificates = $Param{Certificates} || {};

    my $Home    = $ConfigObject->Get('Home');
    my $CertDir = "$Home/var/saml";

    # Deploy can run as the web server user (admin UI) or as the Znuny user (console/daemon),
    # and both need to read and rewrite these files later. Same scheme as
    # bin/znuny.SetPermissions.pl: SETGID directory, so new files get the web server group,
    # and files readable/writable by owner and group only. Unlike SetPermissions' 02775,
    # others can't list the directory, since it holds a private key.
    if ( !-d $CertDir ) {
        if ( !mkdir $CertDir ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not create directory '$CertDir': $!",
            );
            return;
        }
    }

    # Also on every later deploy, to fix directories created before this was set. Has no
    # effect if another user owns the directory, which is fine then.
    chmod 02770, $CertDir;    ## no critic (ProhibitLeadingZeros)

    ROLE:
    for my $Role (qw(SignKey IdPCACert)) {
        my $Content = $Certificates->{$Role};
        my $Path    = $Self->_CertificatePath(
            Context => $Row->{Context},
            Slot    => $Row->{Slot},
            Role    => $Role,
        );

        if ( !$Content ) {

            # Nothing to materialize for this role - remove any stale file left over
            # from a previous deploy (e.g. the certificate was since removed).
            unlink $Path if -e $Path;
            next ROLE;
        }

        my $FileLocation = $MainObject->FileWrite(
            Location   => $Path,
            Content    => $Content,
            Mode       => 'binary',
            Type       => 'Local',
            Permission => '660',
        );
        if ( !$FileLocation ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not write certificate file '$Path'.",
            );
            return;
        }
    }

    return 1;
}

=head2 DeployConfigLines()

Builds the Kernel/Config/Files/ZZZZnunyGeneratedAuthentication.pm lines for
a single SAML config row: the AuthModule/Customer::AuthModule slot
assignment, all of its AuthConfig options, materialized certificate paths,
and (agent context only) its sync module assignment and SyncConfig options.

    my $Lines = $PluginObject->DeployConfigLines(
        Row => $Row,
    );

=cut

sub DeployConfigLines {
    my ( $Self, %Param ) = @_;

    my $Row = $Param{Row};
    return '' if !$Row;

    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    my $Context = $Row->{Context};
    my $Slot    = $Row->{Slot};

    my ( $SlotKey, $Prefix, $ModuleClass );
    if ( $Context eq 'Agent' ) {
        $SlotKey     = 'AuthModule';
        $Prefix      = 'AuthModule::SAML::';
        $ModuleClass = 'Kernel::System::Auth::SAML';
    }
    else {
        $SlotKey     = 'Customer::AuthModule';
        $Prefix      = 'Customer::AuthModule::SAML::';
        $ModuleClass = 'Kernel::System::CustomerAuth::SAML';
    }

    my %SkipAuthConfigKeys = (
        MetaDataSourceType            => 1,
        RequestSignKeyVFSFilename     => 1,
        RequestSignKeyCertVFSFilename => 1,
        IdPCACertVFSFilename          => 1,
        ResponseEncryptionEnabled     => 1,
    );

    # A line break in the name would end the comment and turn the rest into Perl code.
    my $Name = $Row->{Name} // '';
    $Name =~ s{[\x00-\x1F\x7F]+}{ }g;

    my $Output = "# SAML config '$Name' ($Context, slot '$Slot')\n";
    $Output .= $AuthenticationConfigObject->DumpAssignment(
        Accessor => "\$Self->{'$SlotKey$Slot'}",
        Value    => $ModuleClass,
    );

    $Output .= $AuthenticationConfigObject->EmitConfigLines(
        Config   => $Row->{AuthConfig} || {},
        Prefix   => $Prefix,
        Slot     => $Slot,
        SkipKeys => \%SkipAuthConfigKeys,
    );

    ROLE:
    for my $Role (qw(SignKey IdPCACert)) {
        my $ConfigKey = $Role eq 'SignKey' ? 'RequestSignKey' : 'IdPCACert';
        my $Path      = $Self->_CertificatePath(
            Context => $Context,
            Slot    => $Slot,
            Role    => $Role,
        );

        # MaterializeCertificates() (called before this, per row, by the generic Deploy())
        # writes the file of every role that has a certificate (uploaded, or for IdPCACert
        # taken from the metadata) and removes it otherwise.
        next ROLE if !-e $Path;

        $Output .= $AuthenticationConfigObject->DumpAssignment(
            Accessor => "\$Self->{'$Prefix$ConfigKey$Slot'}",
            Value    => $Path,
        );
    }

    # SP metadata publishes the signing cert for encryption too (see GenerateSPMetadata()), so
    # an IdP encrypting to it needs the private key materialized for RequestSignKey above.
    # Missing ResponseEncryptionEnabled (never saved with that checkbox) defaults to enabled,
    # preserving the always-on behavior this had before the checkbox existed.
    my $AuthConfig        = $Row->{AuthConfig} || {};
    my $EncryptionEnabled = defined $AuthConfig->{ResponseEncryptionEnabled}
        ? $AuthConfig->{ResponseEncryptionEnabled}
        : 1;
    my $SignKeyPath = $Self->_CertificatePath(
        Context => $Context,
        Slot    => $Slot,
        Role    => 'SignKey',
    );
    if ( $EncryptionEnabled && -e $SignKeyPath ) {
        $Output .= $AuthenticationConfigObject->DumpAssignment(
            Accessor => "\$Self->{'${Prefix}ResponseEncryptKey$Slot'}",
            Value    => $SignKeyPath,
        );
    }

    if ( $Context eq 'Agent' && $Row->{SyncEnabled} && $Row->{SyncConfig} ) {
        $Output .= $AuthenticationConfigObject->DumpAssignment(
            Accessor => "\$Self->{'AuthSyncModule$Slot'}",
            Value    => 'Kernel::System::Auth::Sync::SAML',
        );

        $Output .= $AuthenticationConfigObject->EmitConfigLines(
            Config   => $Row->{SyncConfig} || {},
            Prefix   => 'AuthSyncModule::SAML::',
            Slot     => $Slot,
            SkipKeys => {

                # Admin UI only (setup wizard), not a sync module option.
                WizardDiscoveredAttributes => 1,
            },
        );
    }

    $Output .= "\n";

    return $Output;
}

=head2 VerifyMetadata()

Parses IdP metadata (URL or XML) via Net::SAML2::IdP - the same class
Kernel::System::Auth::SAML::Request uses at login time - and reports back
whether it's parseable, plus a few useful details for the admin to sanity
check before saving (entity ID, SSO URL, whether it carries a signing
certificate).

    my %Result = $PluginObject->VerifyMetadata(
        SourceType => 'URL',                 # or 'XML'
        URL        => 'https://idp.example.com/metadata',
        XML        => '...',                 # only used if SourceType is 'XML'
        SSLOptions => { ... },                # optional, only used for SourceType 'URL'
    );

Returns:

    my %Result = (
        Success        => 1,
        EntityID       => 'https://idp.example.com/realms/master',
        SSOUrl         => 'https://idp.example.com/realms/master/protocol/saml',
        HasSigningCert => 1,
        Attributes     => [ { Name => '...', FriendlyName => '...' } ],
    );

    # or, on failure:
    my %Result = (
        Success => 0,
        Message => 'Could not parse the metadata. Please check the URL/XML and try again.',
    );

=cut

sub VerifyMetadata {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    if ( !$MainObject->Require( 'Net::SAML2::IdP', Silent => 1 ) ) {
        return (
            Success => 0,
            Message => Translatable('Net::SAML2 is not installed on the server, metadata cannot be verified.'),
        );
    }

    if ( ( $Param{SourceType} // '' ) eq 'URL' && !$Param{URL} ) {
        return (
            Success => 0,
            Message => Translatable('Metadata URL is empty.'),
        );
    }
    if ( ( $Param{SourceType} // '' ) eq 'XML' && !$Param{XML} ) {
        return (
            Success => 0,
            Message => Translatable('Metadata XML is empty.'),
        );
    }

    my $IdP = $Self->_BuildIdPFromMetadata(%Param);

    if ( !$IdP ) {
        return (
            Success => 0,
            Message => Translatable('Could not parse the metadata. Please check the URL/XML and try again.'),
        );
    }

    my $Certs          = $IdP->cert('signing');
    my $HasSigningCert = ( $Certs && ref $Certs eq 'ARRAY' && @{$Certs} ) ? 1 : 0;

    my $SSOUrl = $IdP->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect')
        || $IdP->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST');

    return (
        Success        => 1,
        EntityID       => $IdP->entityid(),
        SSOUrl         => $SSOUrl,
        HasSigningCert => $HasSigningCert,
        Attributes     => $Self->_ExtractAttributesFromMetadata(%Param),
    );
}

=head2 GenerateSPMetadata()

Generates SAML 2.0 SP metadata XML for a single saved config row, for the
admin to hand to their Identity Provider (as an alternative/complement to
manually registering the entity ID, ACS URL and certificate).

    my $XML = $PluginObject->GenerateSPMetadata(
        Row => $Row,
    );

=cut

sub GenerateSPMetadata {
    my ( $Self, %Param ) = @_;

    my $Row = $Param{Row};
    return if !$Row;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $AuthConfig   = $Row->{AuthConfig} || {};

    my $ScriptName = $Row->{Context} eq 'Agent' ? 'index.pl' : 'customer.pl';
    my $BaseURL    = ( $ConfigObject->Get('HttpType') // '' ) . '://'
        . ( $ConfigObject->Get('FQDN')        // '' ) . '/'
        . ( $ConfigObject->Get('ScriptAlias') // '' )
        . $ScriptName;
    my $ACSURL = "$BaseURL?Action=Login;IsSAMLLogin=1;Count=" . ( $Row->{Slot} // '' ) . ';';
    my $SLOURL = "$BaseURL?Action=SAMLSLO;Count=" .             ( $Row->{Slot} // '' ) . ';';

    my $KeyDescriptorXML = '';
    if ( $AuthConfig->{RequestSignKeyCertVFSFilename} ) {
        my $CertBase64 = $Self->_CertificateToBase64(
            Filename => $AuthConfig->{RequestSignKeyCertVFSFilename},
        );

        if ($CertBase64) {

            # The signing key also decrypts encrypted assertions (see DeployConfigLines()).
            my $EncryptionEnabled = defined $AuthConfig->{ResponseEncryptionEnabled}
                ? $AuthConfig->{ResponseEncryptionEnabled}
                : 1;

            my @Uses = ('signing');
            if ( $EncryptionEnabled && $AuthConfig->{RequestSignKeyVFSFilename} ) {
                push @Uses, 'encryption';
            }

            for my $Use (@Uses) {
                $KeyDescriptorXML .= qq{    <md:KeyDescriptor use="$Use">\n}
                    . qq{        <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">\n}
                    . qq{            <ds:X509Data>\n}
                    . qq{                <ds:X509Certificate>$CertBase64</ds:X509Certificate>\n}
                    . qq{            </ds:X509Data>\n}
                    . qq{        </ds:KeyInfo>\n}
                    . qq{    </md:KeyDescriptor>\n};
            }
        }
    }

    my $AuthnRequestsSigned = $AuthConfig->{RequestSignKeyVFSFilename} ? 'true' : 'false';
    my $EntityID            = $Self->_XMLEscape( $AuthConfig->{Issuer} );
    my $ACSURLEscaped       = $Self->_XMLEscape($ACSURL);
    my $SLOURLEscaped       = $Self->_XMLEscape($SLOURL);
    my $NameIDFormat        = $Self->_XMLEscape(
        $AuthConfig->{RequestNameIDFormat} || 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
    );

    my $XML = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
        . qq{<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="$EntityID">\n}
        . qq{    <md:SPSSODescriptor AuthnRequestsSigned="$AuthnRequestsSigned" WantAssertionsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">\n}
        . $KeyDescriptorXML
        . qq{        <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="$SLOURLEscaped" />\n}
        . qq{        <md:NameIDFormat>$NameIDFormat</md:NameIDFormat>\n}
        . qq{        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ACSURLEscaped" index="0" isDefault="true" />\n}
        . qq{    </md:SPSSODescriptor>\n}
        . qq{</md:EntityDescriptor>\n};

    return $XML;
}

=head2 CertificateInfo()

Parses a stored certificate (RequestSignKeyCert or IdPCACert role) and
returns its details for display behind an "info" action. Not meaningful for
the bare RequestSignKey role - a private key by itself has no X.509 fields
(Subject/Issuer/validity are certificate attributes) - callers should not
offer this action for that role.

    my %Info = $PluginObject->CertificateInfo(
        Filename => 'VirtualFS::AuthenticationConfig::SAML::IdPCACert::<hash>',
    );

Returns:

    my %Info = (
        Success     => 1,
        Subject     => '...',
        Issuer      => '...',
        NotBefore   => '...',
        NotAfter    => '...',
        IsExpired   => 0,
        Serial      => '...',
        Email       => '...',
        Fingerprint => '...',   # SHA-256, as returned by Crypt::OpenSSL::X509
    );

    # or, on failure:
    my %Info = (
        Success => 0,
        Message => '...',
    );

=cut

sub CertificateInfo {
    my ( $Self, %Param ) = @_;

    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my %File = $VirtualFSObject->Read(
        Filename => $Param{Filename},
        Mode     => 'binary',
    );
    if ( !%File ) {
        return (
            Success => 0,
            Message => Translatable('Could not read the certificate from VirtualFS.'),
        );
    }

    return $Self->_ParseCertificate( PEM => ${ $File{Content} } );
}

=head2 CertificatePoolList()

Lists every distinct stored certificate/key for a given role, across all
authentication configs (not just the one currently being edited), so the
admin can reuse one instead of always uploading/generating fresh.

    my $Pool = $PluginObject->CertificatePoolList(
        Role   => 'IdPCACert',   # or RequestSignKey, RequestSignKeyCert
        UserID => 1,
    );

Returns an arrayref of hashrefs (cert-role entries carry the parsed fields,
the bare RequestSignKey role only carries Filename/OrigFilename/UsedBy):

    [
        {
            Filename     => 'VirtualFS::AuthenticationConfig::SAML::IdPCACert::<hash>',
            OrigFilename => 'idp-ca.pem',
            Subject      => '...',
            Issuer       => '...',
            NotAfter     => '...',
            IsExpired    => 0,
            Fingerprint  => '...',
            UsedBy       => [ { ID, Name, Context, Slot }, ... ],
        },
        ...
    ]

=cut

sub CertificatePoolList {
    my ( $Self, %Param ) = @_;

    my $Role = $Param{Role};
    return [] if !$Role;

    my $VirtualFSObject            = $Kernel::OM->Get('Kernel::System::VirtualFS');
    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

    my $IsCertRole = ( $Role eq 'RequestSignKeyCert' || $Role eq 'IdPCACert' ) ? 1 : 0;

    my @Filenames = $VirtualFSObject->Find(
        Filename => "VirtualFS::AuthenticationConfig::SAML::${Role}::*",
    );

    my @Pool;

    FILENAME:
    for my $Filename (@Filenames) {
        my %File = $VirtualFSObject->Read(
            Filename => $Filename,
            Mode     => 'binary',
        );
        next FILENAME if !%File;

        my $UsedBy = $AuthenticationConfigObject->VFSFilenameUsedBy(
            Filename  => $Filename,
            ExcludeID => $Param{ExcludeID} || 0,
            UserID    => $Param{UserID},
        );

        my %Entry = (
            Filename     => $Filename,
            OrigFilename => $File{Preferences}->{OrigFilename},
            UsedBy       => $UsedBy,
        );

        if ($IsCertRole) {
            my %Info = $Self->_ParseCertificate( PEM => ${ $File{Content} } );
            if ( $Info{Success} ) {
                $Entry{Subject}     = $Info{Subject};
                $Entry{Issuer}      = $Info{Issuer};
                $Entry{NotAfter}    = $Info{NotAfter};
                $Entry{IsExpired}   = $Info{IsExpired};
                $Entry{Fingerprint} = $Info{Fingerprint};
            }
        }

        push @Pool, \%Entry;
    }

    if ($IsCertRole) {

        # Furthest-expiring first - a reasonable default ordering without a stored
        # creation timestamp to sort by.
        @Pool = sort { ( $b->{NotAfter} || '' ) cmp( $a->{NotAfter} || '' ) } @Pool;
    }

    return \@Pool;
}

=head2 DeriveIdPCertificateFromMetadata()

Extracts the Identity Provider's signing certificate straight out of its
metadata (URL or XML), the same way MaterializeCertificates() derives a
fallback IdPCACert when nothing was explicitly uploaded/generated for that
role. Public (and takes a plain hash instead of a saved AuthConfig) so the
admin controller can also offer it as an explicit "use certificate from
metadata" action, independently of any saved config row.

    my $Cert = $PluginObject->DeriveIdPCertificateFromMetadata(
        AuthConfig => {
            MetaDataSourceType           => 'URL',   # or 'XML'
            RequestMetaDataURL           => 'https://idp.example.com/metadata',
            RequestMetaDataXML           => '...',   # only used if SourceType is 'XML'
            RequestMetaDataURLSSLOptions => { ... },  # optional
        },
    );

Returns the PEM certificate text, or undef (after logging) if none could be
found/parsed.

=cut

sub DeriveIdPCertificateFromMetadata {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $AuthConfig = $Param{AuthConfig} || {};

    my $IdP = $Self->_BuildIdPFromMetadata(
        SourceType => $AuthConfig->{MetaDataSourceType} || ( $AuthConfig->{RequestMetaDataURL} ? 'URL' : 'XML' ),
        URL        => $AuthConfig->{RequestMetaDataURL},
        XML        => $AuthConfig->{RequestMetaDataXML},
        SSLOptions => $AuthConfig->{RequestMetaDataURLSSLOptions},
    );

    if ( !$IdP ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not parse IdP metadata to derive its certificate: " . ( $@ || 'unknown error' ),
        );
        return;
    }

    my $Certs = $IdP->cert('signing');
    return if !$Certs || ref $Certs ne 'ARRAY' || !@{$Certs};

    return $Certs->[0];
}

=begin Internal:

=cut

sub _ParseCertificate {
    my ( $Self, %Param ) = @_;

    my $X509CertificateObject = $Kernel::OM->Get('Kernel::System::X509Certificate');

    if ( !$X509CertificateObject->IsSupported() ) {
        return (
            Success => 0,
            Message => Translatable(
                'Perl module Crypt::OpenSSL::X509 is not installed, certificate details cannot be parsed.'
            ),
        );
    }

    my $Parsed = $X509CertificateObject->Parse(
        String => $Param{PEM},
    );
    if ( !$Parsed ) {
        return (
            Success => 0,
            Message => Translatable('Could not parse the certificate.'),
        );
    }

    my $Fingerprint = eval { $Parsed->{CryptOpenSSLX509Object}->fingerprint_sha256() };

    return (
        Success     => 1,
        Subject     => $Parsed->{Subject},
        Issuer      => $Parsed->{Issuer},
        NotBefore   => $Parsed->{NotBefore},
        NotAfter    => $Parsed->{NotAfter},
        IsExpired   => $Parsed->{IsExpired},
        Serial      => $Parsed->{Serial},
        Email       => $Parsed->{Email},
        Fingerprint => $Fingerprint,
    );
}

sub _ExtractAttributesFromMetadata {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    return [] if !$MainObject->Require( 'XML::LibXML',               Silent => 1 );
    return [] if !$MainObject->Require( 'XML::LibXML::XPathContext', Silent => 1 );

    my $XML;
    if ( ( $Param{SourceType} // '' ) eq 'XML' ) {
        $XML = $Param{XML};
    }
    else {
        return [] if !$Param{URL};
        return [] if !$MainObject->Require( 'LWP::UserAgent', Silent => 1 );

        my $UserAgent = LWP::UserAgent->new();
        if ( ref $Param{SSLOptions} eq 'HASH' && %{ $Param{SSLOptions} } ) {
            $UserAgent->ssl_opts( %{ $Param{SSLOptions} } );
        }

        my $Response = eval { $UserAgent->get( $Param{URL} ) };
        return [] if !$Response || !$Response->is_success();

        $XML = $Response->decoded_content();
    }

    return [] if !$XML;

    # The metadata comes from an admin-entered URL or pasted XML, so don't resolve external
    # entities or DTDs (XXE), which would let it read local files or reach internal hosts.
    my $Dom = eval {
        XML::LibXML->load_xml(
            string          => $XML,
            no_network      => 1,
            expand_entities => 0,
            load_ext_dtd    => 0,
        );
    };
    return [] if !$Dom;

    my $XPath = XML::LibXML::XPathContext->new($Dom);
    $XPath->registerNs( 'saml', 'urn:oasis:names:tc:SAML:2.0:assertion' );
    $XPath->registerNs( 'auth', 'http://docs.oasis-open.org/wsfed/authorization/200706' );

    my %Seen;
    my @Attributes;

    # Standard SAML metadata extension point for listing attributes (EntityAttributes,
    # AttributeAuthorityDescriptor, or an example AttributeStatement some IdPs embed for
    # documentation).
    ATTRIBUTE:
    for my $Node ( $XPath->findnodes('//saml:Attribute') ) {
        my $Name = $Node->getAttribute('Name');
        next ATTRIBUTE if !defined $Name || !length $Name;
        next ATTRIBUTE if $Seen{$Name}++;

        push @Attributes, {
            Name         => $Name,
            FriendlyName => $Node->getAttribute('FriendlyName'),
        };
    }

    # Microsoft Entra ID / ADFS federation metadata doesn't use saml:Attribute at all - it
    # declares claims via WS-Federation's ClaimType elements instead, e.g.:
    # <auth:ClaimType Uri="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
    #     <auth:DisplayName>E-Mail Address</auth:DisplayName>
    # </auth:ClaimType>
    CLAIMTYPE:
    for my $Node ( $XPath->findnodes('//auth:ClaimType') ) {
        my $Name = $Node->getAttribute('Uri');
        next CLAIMTYPE if !defined $Name || !length $Name;
        next CLAIMTYPE if $Seen{$Name}++;

        my ($DisplayNameNode) = $XPath->findnodes( 'auth:DisplayName', $Node );

        push @Attributes, {
            Name         => $Name,
            FriendlyName => $DisplayNameNode ? $DisplayNameNode->textContent() : undef,
        };
    }

    return \@Attributes;
}

sub _BuildIdPFromMetadata {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
    return if !$MainObject->Require( 'Net::SAML2::IdP', Silent => 1 );

    my %IdPParams;

    if ( ( $Param{SourceType} // '' ) eq 'URL' ) {
        return if !$Param{URL};

        $IdPParams{url} = $Param{URL};
        if ( ref $Param{SSLOptions} eq 'HASH' && %{ $Param{SSLOptions} } ) {
            $IdPParams{ssl_opts} = $Param{SSLOptions};
        }

        return eval { Net::SAML2::IdP->new_from_url(%IdPParams) };
    }

    return if !$Param{XML};

    $IdPParams{xml} = $Param{XML};

    return eval { Net::SAML2::IdP->new_from_xml(%IdPParams) };
}

sub _OpenSSLCommand {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Bin      = $ConfigObject->Get('SMIME::Bin') || '/usr/bin/openssl';
    my $RandFile = $ConfigObject->Get('TempDir') . '/.rnd_' . $<;

    my $Cmd;
    if ( $^O =~ m{mswin}i ) {
        $Cmd = qq{"$Bin"};
    }
    else {
        $Cmd = "LC_MESSAGES=POSIX $Bin";
    }

    return 'HOME=' . $ConfigObject->Get('Home') . " RANDFILE=$RandFile $Cmd";
}

sub _CertificatePath {
    my ( $Self, %Param ) = @_;

    my $Home    = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my $Slot    = length $Param{Slot}       ? $Param{Slot} : 'default';
    my $Role    = $Param{Role} eq 'SignKey' ? 'signkey'    : 'idpcacert';
    my $Context = lc $Param{Context};

    return "$Home/var/saml/$Context-$Slot-$Role.pem";
}

sub _CertificateToBase64 {
    my ( $Self, %Param ) = @_;

    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my %File = $VirtualFSObject->Read(
        Filename => $Param{Filename},
        Mode     => 'binary',
    );
    return if !%File;

    my $Content = ${ $File{Content} };
    $Content =~ s{-----BEGIN\s+CERTIFICATE-----}{}g;
    $Content =~ s{-----END\s+CERTIFICATE-----}{}g;
    $Content =~ s{\s+}{}g;

    return $Content;
}

sub _XMLEscape {
    my ( $Self, $String ) = @_;

    return '' if !defined $String;

    $String =~ s{&}{&amp;}g;
    $String =~ s{<}{&lt;}g;
    $String =~ s{>}{&gt;}g;
    $String =~ s{"}{&quot;}g;

    return $String;
}

=end Internal:

=cut

1;
