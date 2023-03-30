# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use File::Path qw(mkpath rmtree);

my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject   = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Disable email addresses checking.
$HelperObject->ConfigSettingChange(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $HomeDir = $ConfigObject->Get('Home');

# Create directory for certificates and private keys.
my $CertPath    = $ConfigObject->Get('Home') . "/var/tmp/certs";
my $PrivatePath = $ConfigObject->Get('Home') . "/var/tmp/private";
mkpath( [$CertPath],    0, 0770 );    ## no critic
mkpath( [$PrivatePath], 0, 0770 );    ## no critic

# Set SMIME paths.
$ConfigObject->Set(
    Key   => 'SMIME::CertPath',
    Value => $CertPath,
);
$ConfigObject->Set(
    Key   => 'SMIME::PrivatePath',
    Value => $PrivatePath,
);

my $OpenSSLBin = $ConfigObject->Get('SMIME::Bin') || '/usr/bin/openssl';

# Get the openssl version string, e.g. OpenSSL 0.9.8e 23 Feb 2007.
my $OpenSSLVersionString = qx{$OpenSSLBin version};
my $OpenSSLMajorVersion;

# Get the openssl major version, e.g. 1 for version 1.0.0.
if ( $OpenSSLVersionString =~ m{ \A (?: (?: Open|Libre)SSL )? \s* ( \d )  }xmsi ) {
    $OpenSSLMajorVersion = $1;
}

$ConfigObject->Set(
    Key   => 'SMIME',
    Value => 1,
);
$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::DoNotSendEmail',
);

# Check if openssl is located there.
if ( !-e $OpenSSLBin ) {

    # Maybe it's a mac with macport.
    if ( -e '/opt/local/bin/openssl' ) {
        $ConfigObject->Set(
            Key   => 'SMIME::Bin',
            Value => '/opt/local/bin/openssl',
        );
    }
}

my $SMIMEObject = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

if ( !$SMIMEObject ) {
    print STDERR "NOTICE: No SMIME support!\n";

    if ( !-e $OpenSSLBin ) {
        $Self->False(
            1,
            "No such $OpenSSLBin!",
        );
    }
    elsif ( !-x $OpenSSLBin ) {
        $Self->False(
            1,
            "$OpenSSLBin not executable!",
        );
    }
    elsif ( !-e $CertPath ) {
        $Self->False(
            1,
            "No such $CertPath!",
        );
    }
    elsif ( !-d $CertPath ) {
        $Self->False(
            1,
            "No such $CertPath directory!",
        );
    }
    elsif ( !-w $CertPath ) {
        $Self->False(
            1,
            "$CertPath not writable!",
        );
    }
    elsif ( !-e $PrivatePath ) {
        $Self->False(
            1,
            "No such $PrivatePath!",
        );
    }
    elsif ( !-d $Self->{PrivatePath} ) {
        $Self->False(
            1,
            "No such $PrivatePath directory!",
        );
    }
    elsif ( !-w $PrivatePath ) {
        $Self->False(
            1,
            "$PrivatePath not writable!",
        );
    }
    return 1;
}

my $Check1Hash       = 'f62a2257';
my $Check2Hash       = '35c7d865';
my $ZnunyRootCAHash  = 'dfde6898';
my $ZnunySub1CAHash  = '5fcf9bdc';
my $ZnunySub2CAHash  = '37de711c';
my $OTRSUserCertHash = '097aa832';

my @Certificates = (
    {
        CertificateName       => 'Check1',
        CertificateHash       => $Check1Hash,
        CertificateFileName   => 'SMIMECertificate-1.asc',
        PrivateKeyFileName    => 'SMIMEPrivateKey-1.asc',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-1.asc',
    },
    {
        CertificateName       => 'Check2',
        CertificateHash       => $Check2Hash,
        CertificateFileName   => 'SMIMECertificate-2.asc',
        PrivateKeyFileName    => 'SMIMEPrivateKey-2.asc',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-2.asc',
    },
    {
        CertificateName       => 'OTRSUserCert',
        CertificateHash       => $OTRSUserCertHash,
        CertificateFileName   => 'SMIMECertificate-smimeuser1.crt',
        PrivateKeyFileName    => 'SMIMEPrivateKey-smimeuser1.pem',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-smimeuser1.crt',
    },
    {
        CertificateName       => 'ZnunySub1CA',
        CertificateHash       => $ZnunySub1CAHash,
        CertificateFileName   => 'SMIMECACertificate-Znuny-Sub1.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-Znuny-Sub1.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-Znuny-Sub1.crt',
    },
    {
        CertificateName       => 'ZnunySub2CA',
        CertificateHash       => $ZnunySub2CAHash,
        CertificateFileName   => 'SMIMECACertificate-Znuny-Sub2.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-Znuny-Sub2.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-Znuny-Sub2.crt',
    },
    {
        CertificateName       => 'ZnunyRootCA',
        CertificateHash       => $ZnunyRootCAHash,
        CertificateFileName   => 'SMIMECACertificate-Znuny-Root.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-Znuny-Root.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-Znuny-Root.crt',
    },
);

# Add chain certificates.
for my $Certificate (@Certificates) {

    # Add certificate.
    my $CertString = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{CertificateFileName},
    );
    my %Result = $SMIMEObject->CertificateAdd( Certificate => ${$CertString} );
    $Certificate->{IndexedFilename} = $Result{Filename};

    $Self->True(
        $Result{Successful} || '',
        "#$Certificate->{CertificateName} CertificateAdd() - $Result{Message}",
    );

    # Add private key.
    my $KeyString = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{PrivateKeyFileName},
    );
    my $Secret = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{PrivateSecretFileName},
    );
    %Result = $SMIMEObject->PrivateAdd(
        Private => ${$KeyString},
        Secret  => ${$Secret},
    );
    $Self->True(
        $Result{Successful} || '',
        "#$Certificate->{CertificateName} PrivateAdd()",
    );
}

my $CryptObject = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

my @PrivateCerts = $CryptObject->PrivateSearch(
    Search     => $Certificates[0]->{IndexedFilename},
    SearchType => 'filename',
);
my %Cert1Attributes = %{ $PrivateCerts[0] };

my @PublicCerts = $CryptObject->CertificateSearch(
    Search     => $Certificates[1]->{IndexedFilename},
    SearchType => 'filename',
);
my %Cert2Attributes = %{ $PublicCerts[0] };

my @Data = $CryptObject->SignerCertRelationGet(
    CertFingerprint => $Cert1Attributes{Fingerprint},
);

$Self->False(
    @Data ? 1 : 0,
    'Certificate 1 has no relations',
);

@Data = $CryptObject->SignerCertRelationGet(
    CertFingerprint => $Cert2Attributes{Fingerprint},
);

$Self->False(
    @Data ? 1 : 0,
    'Certificate 2 has no relations',
);

$CryptObject->SignerCertRelationAdd(
    CertificateID => $Cert1Attributes{CertificateID},
    CAID          => $Cert2Attributes{CertificateID},
    UserID        => 1,
);

@Data = $CryptObject->SignerCertRelationGet(
    CertFingerprint => $Cert1Attributes{Fingerprint},
);
$Self->True(
    @Data ? 1 : 0,
    'Certificate 1 has relations',
);

my $Success = $CryptObject->CertificateRemove(
    Filename => $Certificates[1]->{IndexedFilename},
);

$Self->True(
    @Data ? 1 : 0,
    'Certificate 2 got removed',
);

@Data = $CryptObject->SignerCertRelationGet(
    CertFingerprint => $Cert1Attributes{Fingerprint},
);
$Self->False(
    @Data ? 1 : 0,
    'Certificate 1 has no relations',
);

# Delete needed test directories.
for my $Directory ( $CertPath, $PrivatePath ) {
    my $Success = rmtree( [$Directory] );
    $Self->True(
        $Success,
        "Directory deleted - '$Directory'",
    );
}

# Cleanup is done by RestoreDatabase.

1;
