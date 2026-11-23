# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject     = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $VirtualFSObject  = $Kernel::OM->Get('Kernel::System::VirtualFS');
my $SAMLPluginObject = $Kernel::OM->Get('Kernel::System::Authentication::Plugin::SAML');

my $RandomID = $HelperObject->GetRandomID();

my %Certificate = $SAMLPluginObject->GenerateCertificate(
    CommonName   => 'unittest.example.org',
    KeySize      => 2048,
    ValidityDays => 1,
);
$Self->True(
    ( $Certificate{Cert} && $Certificate{Key} ) ? 1 : 0,
    'GenerateCertificate() must return a certificate and a key.',
);

#
# GenerateSPMetadata()
#

my $CertFilename = "VirtualFS::AuthenticationConfig::SAML::RequestSignKeyCert::UnitTest$RandomID";
$VirtualFSObject->Write(
    Filename => $CertFilename,
    Content  => \$Certificate{Cert},
    Mode     => 'binary',
);

my @MetadataTests = (
    {
        Name       => 'encryption enabled by default',
        AuthConfig => {
            RequestSignKeyVFSFilename     => 'UnitTestKey',
            RequestSignKeyCertVFSFilename => $CertFilename,
        },
        ExpectedUses => [ 'signing', 'encryption' ],
    },
    {
        Name       => 'encryption disabled',
        AuthConfig => {
            RequestSignKeyVFSFilename     => 'UnitTestKey',
            RequestSignKeyCertVFSFilename => $CertFilename,
            ResponseEncryptionEnabled     => 0,
        },
        ExpectedUses => ['signing'],
    },
    {
        Name       => 'no signing key to decrypt with',
        AuthConfig => {
            RequestSignKeyCertVFSFilename => $CertFilename,
        },
        ExpectedUses => ['signing'],
    },
);

for my $Test (@MetadataTests) {
    my $XML = $SAMLPluginObject->GenerateSPMetadata(
        Row => {
            Name       => 'UnitTest',
            Context    => 'Agent',
            Slot       => '1',
            AuthConfig => {
                Issuer => 'https://unittest.example.org',
                %{ $Test->{AuthConfig} },
            },
        },
    );

    my @Uses = $XML =~ m{<md:KeyDescriptor\ use="([^"]+)">}xmsg;

    $Self->IsDeeply(
        \@Uses,
        $Test->{ExpectedUses},
        "GenerateSPMetadata() - $Test->{Name}.",
    );
}

#
# ValidateContent()
#

my ($KeyBody) = $Certificate{Key} =~ m{-----BEGIN\ PRIVATE\ KEY-----\n(.+?)-----END}xms;
my $LegacyEncryptedKey = "-----BEGIN RSA PRIVATE KEY-----\n"
    . "Proc-Type: 4,ENCRYPTED\n"
    . "DEK-Info: AES-128-CBC,00112233445566778899AABBCCDDEEFF\n\n"
    . $KeyBody
    . "-----END RSA PRIVATE KEY-----\n";

my @ValidateTests = (
    {
        Name           => 'certificate',
        Role           => 'IdPCACert',
        Content        => $Certificate{Cert},
        ExpectedBlocks => 1,
    },
    {
        Name           => 'certificate chain',
        Role           => 'IdPCACert',
        Content        => $Certificate{Cert} . $Certificate{Cert},
        ExpectedBlocks => 2,
    },
    {
        Name           => 'certificate with text around it',
        Role           => 'RequestSignKeyCert',
        Content        => "<script>alert(1)</script>\r\n$Certificate{Cert}\r\ntrailing text",
        ExpectedBlocks => 1,
    },
    {
        Name    => 'fake certificate block',
        Role    => 'IdPCACert',
        Content => "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----\n",
    },
    {
        Name    => 'private key as certificate',
        Role    => 'IdPCACert',
        Content => $Certificate{Key},
    },
    {
        Name           => 'private key',
        Role           => 'RequestSignKey',
        Content        => $Certificate{Key},
        ExpectedBlocks => 1,
    },
    {
        Name    => 'certificate as private key',
        Role    => 'RequestSignKey',
        Content => $Certificate{Cert},
    },
    {
        Name    => 'fake private key block',
        Role    => 'RequestSignKey',
        Content => "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----\n",
    },
    {
        Name    => 'encrypted private key',
        Role    => 'RequestSignKey',
        Content => "-----BEGIN ENCRYPTED PRIVATE KEY-----\n$KeyBody-----END ENCRYPTED PRIVATE KEY-----\n",
    },
    {
        Name    => 'legacy encrypted private key',
        Role    => 'RequestSignKey',
        Content => $LegacyEncryptedKey,
    },
);

TEST:
for my $Test (@ValidateTests) {
    my %Result = $SAMLPluginObject->ValidateContent(
        Role    => $Test->{Role},
        Content => $Test->{Content},
    );

    if ( !$Test->{ExpectedBlocks} ) {
        $Self->False(
            $Result{Success},
            "ValidateContent() - $Test->{Name} must be rejected.",
        );
        next TEST;
    }

    my $Blocks = () = ( $Result{PEM} // '' ) =~ m{-----BEGIN\ }xmsg;

    $Self->True(
        $Result{Success},
        "ValidateContent() - $Test->{Name} must be accepted.",
    );
    $Self->Is(
        $Blocks,
        $Test->{ExpectedBlocks},
        "ValidateContent() - $Test->{Name} must keep the PEM blocks.",
    );
    $Self->False(
        ( $Result{PEM} // '' ) =~ m{script|trailing}xms ? 1 : 0,
        "ValidateContent() - $Test->{Name} must drop the text around the PEM blocks.",
    );
}

#
# CertificatePoolList()
#

my $IdPCACertFilename      = "VirtualFS::AuthenticationConfig::SAML::IdPCACert::UnitTest$RandomID";
my $RequestSignKeyFilename = "VirtualFS::AuthenticationConfig::SAML::RequestSignKey::UnitTest$RandomID";

$VirtualFSObject->Write(
    Filename => $IdPCACertFilename,
    Content  => \$Certificate{Cert},
    Mode     => 'binary',
);
$VirtualFSObject->Write(
    Filename => $RequestSignKeyFilename,
    Content  => \$Certificate{Key},
    Mode     => 'binary',
);

my %PoolFilenames;
for my $Role (qw(IdPCACert RequestSignKey RequestSignKeyCert)) {
    my $Pool = $SAMLPluginObject->CertificatePoolList(
        Role   => $Role,
        UserID => 1,
    );
    $PoolFilenames{$Role} = { map { $_->{Filename} => 1 } @{$Pool} };
}

$Self->True(
    $PoolFilenames{IdPCACert}->{$IdPCACertFilename} ? 1 : 0,
    'CertificatePoolList() must list the IdP CA certificate for its role.',
);
$Self->False(
    $PoolFilenames{IdPCACert}->{$RequestSignKeyFilename} ? 1 : 0,
    'CertificatePoolList() must not list the private key as IdP CA certificate.',
);
$Self->False(
    $PoolFilenames{IdPCACert}->{$CertFilename} ? 1 : 0,
    'CertificatePoolList() must not list the SP certificate as IdP CA certificate.',
);
$Self->True(
    $PoolFilenames{RequestSignKey}->{$RequestSignKeyFilename} ? 1 : 0,
    'CertificatePoolList() must list the private key for its role.',
);
$Self->False(
    $PoolFilenames{RequestSignKey}->{$IdPCACertFilename} ? 1 : 0,
    'CertificatePoolList() must not list a certificate as private key.',
);
$Self->True(
    $PoolFilenames{RequestSignKeyCert}->{$CertFilename} ? 1 : 0,
    'CertificatePoolList() must list the SP certificate for its role.',
);

#
# PrepareCertificates()
#

my %Row = (
    Name    => 'UnitTest',
    Context => 'Agent',
    Slot    => '1',
);

my %Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            IdPCACertVFSFilename => $IdPCACertFilename,
        },
    },
);
$Self->True(
    $Prepared{Success},
    'PrepareCertificates() with an uploaded IdP CA certificate must be successful.',
);
$Self->Is(
    ${ $Prepared{Certificates}->{IdPCACert} || \'' },
    $Certificate{Cert},
    'PrepareCertificates() must return the uploaded IdP CA certificate.',
);

%Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            IdPCACertVFSFilename => "VirtualFS::AuthenticationConfig::SAML::IdPCACert::Missing$RandomID",
        },
    },
);
$Self->False(
    $Prepared{Success},
    'PrepareCertificates() with a missing IdP CA certificate must fail.',
);
$Self->Is(
    $Prepared{Role},
    'IdPCACert',
    'PrepareCertificates() must report the IdP CA certificate as the failed role.',
);

%Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            MetaDataSourceType => 'XML',
            RequestMetaDataXML => '<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"/>',
        },
    },
);
$Self->False(
    $Prepared{Success},
    'PrepareCertificates() without any IdP CA certificate must fail.',
);
$Self->False(
    $Prepared{NeedsMetadata},
    'PrepareCertificates() without Offline must try the metadata, not report NeedsMetadata.',
);

# Offline, the IdP metadata is never used, even if it would contain a certificate.
%Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            MetaDataSourceType => 'URL',
            RequestMetaDataURL => 'https://unittest.invalid/metadata',
        },
    },
    Offline => 1,
);
$Self->False(
    $Prepared{Success},
    'PrepareCertificates() offline without a stored IdP CA certificate must fail.',
);
$Self->True(
    $Prepared{NeedsMetadata},
    'PrepareCertificates() offline without a stored IdP CA certificate must report NeedsMetadata.',
);
$Self->Is(
    $Prepared{Role},
    'IdPCACert',
    'PrepareCertificates() offline must report the IdP CA certificate as the failed role.',
);

%Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            IdPCACertVFSFilename => $IdPCACertFilename,
        },
    },
    Offline => 1,
);
$Self->True(
    $Prepared{Success},
    'PrepareCertificates() offline with a stored IdP CA certificate must be successful.',
);

%Prepared = $SAMLPluginObject->PrepareCertificates(
    Row => {
        %Row,
        AuthConfig => {
            IdPCACertVFSFilename      => $IdPCACertFilename,
            RequestSignKeyVFSFilename => "VirtualFS::AuthenticationConfig::SAML::RequestSignKey::Missing$RandomID",
        },
    },
    Offline => 1,
);
$Self->False(
    $Prepared{Success},
    'PrepareCertificates() with a missing signing key must fail.',
);
$Self->Is(
    $Prepared{Role},
    'RequestSignKey',
    'PrepareCertificates() must report the signing key as the failed role.',
);

#
# DeployConfigLines()
#

my $ConfigLines = $SAMLPluginObject->DeployConfigLines(
    Row => {
        %Row,
        Name       => "UnitTest\nsystem('id');\r# end",
        AuthConfig => {},
    },
);
$Self->False(
    $ConfigLines =~ m{^system}xms ? 1 : 0,
    'DeployConfigLines() must keep a line break in the name inside the comment.',
);

1;
