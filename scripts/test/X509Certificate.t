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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $X509CertificateObject = $Kernel::OM->Get('Kernel::System::X509Certificate');

return 1 if !$X509CertificateObject->IsSupported();

my $Home = $ConfigObject->Get('Home');

my $X509Certificate = $X509CertificateObject->Parse(
    FilePath => "$Home/scripts/test/sample/X509Certificate/RSACert.pem",
);

$Self->True(
    scalar IsHashRefWithData($X509Certificate),
    'Parse() must return a hash ref with data.',
);

my $ExpectedX509Object = $X509Certificate->{CryptOpenSSLX509Object};
$Self->Is(
    ref $ExpectedX509Object,
    'Crypt::OpenSSL::X509',
    'Parse(): Returned X.509 object must be of expected type.',
);

my %ExpectedCertificate = (
    Serial    => '0DFA',
    IsExpired => 1,
    Issuer =>
        'C=JP, ST=Tokyo, L=Chuo-ku, O=Frank4DD, OU=WebCert Support, CN=Frank4DD Web CA, emailAddress=support@frank4dd.com',
    Email                  => '',
    Version                => '00',
    NotAfter               => 'Aug 21 05:26:54 2017 GMT',
    NotBefore              => 'Aug 22 05:26:54 2012 GMT',
    Subject                => 'C=JP, ST=Tokyo, O=Frank4DD, CN=www.example.com',
    CryptOpenSSLX509Object => $ExpectedX509Object,
);

$Self->IsDeeply(
    $X509Certificate,
    \%ExpectedCertificate,
    'Parse() must return expected certificate data.',
);

$X509Certificate = $X509CertificateObject->Parse(
    FilePath => "$Home/scripts/test/sample/X509Certificate/NONEXISTING.pem",
);

$Self->False(
    scalar $X509Certificate,
    'Parse() must return nothing if certiticate file could not be read.',
);

1;
