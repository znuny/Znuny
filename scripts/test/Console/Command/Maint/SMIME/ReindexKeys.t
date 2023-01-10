# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use File::Path qw(mkpath rmtree);

use vars (qw($Self));

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::SMIME::ReindexKeys');
my ( $Result, $ExitCode );
{
    local *STDOUT;
    open STDOUT, '>:utf8', \$Result;    ## no critic
    $ExitCode = $CommandObject->Execute('wrongvalue');
}
$Self->Is(
    $ExitCode,
    1,
    "Exit code with wrong value arguments",
);

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# create directory for certificates and private keys
my $CertPath    = $ConfigObject->Get('Home') . "/var/tmp/certs";
my $PrivatePath = $ConfigObject->Get('Home') . "/var/tmp/private";

mkpath( [$CertPath],    0, 0770 );    ## no critic
mkpath( [$PrivatePath], 0, 0770 );    ## no critic

# set SMIME paths
$ConfigObject->Set(
    Key   => 'SMIME::CertPath',
    Value => $CertPath,
);

$ConfigObject->Set(
    Key   => 'SMIME::PrivatePath',
    Value => $PrivatePath,
);

my $OpenSSLBin = $ConfigObject->Get('SMIME::Bin');

# set config
$ConfigObject->Set(
    Key   => 'SMIME',
    Value => 1,
);

# check if openssl is located there
if ( !-e $OpenSSLBin ) {

    # maybe it's a mac with macport
    if ( -e '/opt/local/bin/openssl' ) {
        $ConfigObject->Set(
            Key   => 'SMIME::Bin',
            Value => '/opt/local/bin/openssl',
        );
    }
}

# create crypt object
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
    elsif ( !-r $CertPath ) {
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

my $SmimeTestCert = '-----BEGIN CERTIFICATE-----
MIICqzCCAhQCCQDrve7Rkt7z1TANBgkqhkiG9w0BAQUFADCBmTELMAkGA1UEBhMC
TVgxEDAOBgNVBAgTB0phbGlzY28xFDASBgNVBAcTC0d1YWRhbGFqYXJhMQ0wCwYD
VQQKEwRPVFJTMSEwHwYDVQQLExhSZXNlYXJjaCBhbmQgRGV2ZWxvcG1lbnQxETAP
BgNVBAMTCG90cnMub3JnMR0wGwYJKoZIhvcNAQkBFg5zbWltZUB0ZXN0LmNvbTAe
Fw0xMTA0MDgxNDIzMjJaFw0xMjA0MDcxNDIzMjJaMIGZMQswCQYDVQQGEwJNWDEQ
MA4GA1UECBMHSmFsaXNjbzEUMBIGA1UEBxMLR3VhZGFsYWphcmExDTALBgNVBAoT
BE9UUlMxITAfBgNVBAsTGFJlc2VhcmNoIGFuZCBEZXZlbG9wbWVudDERMA8GA1UE
AxMIb3Rycy5vcmcxHTAbBgkqhkiG9w0BCQEWDnNtaW1lQHRlc3QuY29tMIGfMA0G
CSqGSIb3DQEBAQUAA4GNADCBiQKBgQDg9EoXpS/1kwc3JEB0zuJcyOKMZSWaQ/Ob
7/D2AMgcirq7RMOLW7KkX6vIfgDZtRIyyufzXhrRPAoKjofNVNbM8HNOPueRVE2i
Bq1IVxjaBnfvd2He7g4y6KHcPryuDtXanCtWIHmTMZFo4AYh0XlyaH2kyVaCHSz2
pjZnUJTlgQIDAQABMA0GCSqGSIb3DQEBBQUAA4GBALtZQpsB1UA3WtfHl7qoVM3d
X/umav+OgOsBHZKH4UV1CgLmgDz9i8kVy2yEKL/QgCE/aPjSOf46TSKQX4pQy/2w
sc8WqMKf2rOWj65HEarZnVMzTIErm14HJzJljkQg0gdR8ph4gFIscIfO9csLd8ud
BLrMsW3mKPx9cPinBGIH
-----END CERTIFICATE-----
';

# create the private secret key file otherwise test will always fail
my $FileLocation = $MainObject->FileWrite(
    Location => "$CertPath/wrongpublic.0",
    Content  => \$SmimeTestCert,
);

$CommandObject->Execute('public');

my @PublicCerts = $MainObject->DirectoryRead(
    Directory => $CertPath,
    Filter    => "*"
);

$Self->Is(
    $PublicCerts[0],
    "$CertPath/9d993e95.0",
    , "Rehash Pubic Certificate."
);

my @CertificateList = $SMIMEObject->CertificateList();
my $TestCert        = grep { $_ eq '9d993e95.0' } @CertificateList;

$Self->Is(
    $TestCert,
    1,
    "Certificate reindexed successfully."
);

my %Result = $SMIMEObject->CertificateRemove(
    Hash        => '9d993e95',
    Fingerprint => '45:BB:21:E6:AD:9B:0A:95:52:D6:0E:C1:95:94:D6:A4:AA:1E:A8:07',
);

File::Path::rmtree($CertPath);
File::Path::rmtree($PrivatePath);

1;
