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

use Kernel::System::Auth::SAML::Request;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $SSLOptions = {
    SSL_ca_file     => '/etc/ssl/certs/ca.pem',
    verify_hostname => 1,
};

my @Tests = (
    {
        Name   => 'Proxy, NoProxy and SSL options',
        Config => {
            'WebUserAgent::Proxy'                  => 'http://proxy.example.com:8001/',
            'WebUserAgent::NoProxy'                => 'localhost; 127.0.0.1',
            'WebUserAgent::DisableSSLVerification' => 0,
        },
        SAMLConfig => {
            RequestMetaDataURL           => 'https://idp.example.com/metadata',
            RequestMetaDataURLSSLOptions => $SSLOptions,
        },
        Proxy => {
            http  => 'http://proxy.example.com:8001/',
            https => 'http://proxy.example.com:8001/',
            ftp   => 'http://proxy.example.com:8001/',
        },
        NoProxy    => [ 'localhost', '127.0.0.1' ],
        SSLOptions => {
            SSL_ca_file     => '/etc/ssl/certs/ca.pem',
            verify_hostname => 1,
        },
    },
    {
        Name   => 'No proxy configured',
        Config => {
            'WebUserAgent::Proxy'                  => '',
            'WebUserAgent::NoProxy'                => '',
            'WebUserAgent::DisableSSLVerification' => 0,
        },
        SAMLConfig => {
            RequestMetaDataURL => 'https://idp.example.com/metadata',
        },
        Proxy => {
            http  => undef,
            https => undef,
            ftp   => undef,
        },
        NoProxy    => [],
        SSLOptions => {},
    },
    {
        Name   => 'Disable SSL verification overrides SAML SSL options',
        Config => {
            'WebUserAgent::Proxy'                  => 'http://proxy.example.com:8001/',
            'WebUserAgent::NoProxy'                => 'idp.example.com',
            'WebUserAgent::DisableSSLVerification' => 1,
        },
        SAMLConfig => {
            RequestMetaDataURL           => 'https://idp.example.com/metadata',
            RequestMetaDataURLSSLOptions => $SSLOptions,
        },
        Proxy => {
            http  => 'http://proxy.example.com:8001/',
            https => 'http://proxy.example.com:8001/',
            ftp   => 'http://proxy.example.com:8001/',
        },
        NoProxy    => ['idp.example.com'],
        SSLOptions => {
            SSL_ca_file     => '/etc/ssl/certs/ca.pem',
            verify_hostname => 0,
        },
    },
);

TEST:
for my $Test (@Tests) {
    CONFIGKEY:
    for my $ConfigKey ( sort keys %{ $Test->{Config} } ) {
        $ConfigObject->Set(
            Key   => $ConfigKey,
            Value => $Test->{Config}->{$ConfigKey},
        );
    }

    my %OriginalSSLOptions;
    if ( $Test->{SAMLConfig}->{RequestMetaDataURLSSLOptions} ) {
        %OriginalSSLOptions = %{ $Test->{SAMLConfig}->{RequestMetaDataURLSSLOptions} };
    }

    my $RequestObject = Kernel::System::Auth::SAML::Request->new(
        Count  => 1,
        Config => $Test->{SAMLConfig},
    );
    my $UserAgent = $RequestObject->_GetMetadataUserAgent();

    SCHEME:
    for my $Scheme (qw(http https ftp)) {
        $Self->Is(
            $UserAgent->proxy($Scheme),
            $Test->{Proxy}->{$Scheme},
            "$Test->{Name}: $Scheme proxy",
        );
    }

    $Self->IsDeeply(
        $UserAgent->{no_proxy},
        $Test->{NoProxy},
        "$Test->{Name}: no_proxy hosts",
    );

    SSLKEY:
    for my $SSLKey ( sort keys %{ $Test->{SSLOptions} } ) {
        $Self->Is(
            $UserAgent->ssl_opts($SSLKey),
            $Test->{SSLOptions}->{$SSLKey},
            "$Test->{Name}: ssl_opts $SSLKey",
        );
    }

    $Self->Is(
        $UserAgent->timeout(),
        180,
        "$Test->{Name}: default LWP timeout",
    );
    $Self->True(
        $UserAgent->agent() =~ m{\Alibwww-perl/},
        "$Test->{Name}: default LWP user agent",
    );

    if (%OriginalSSLOptions) {
        $Self->IsDeeply(
            $Test->{SAMLConfig}->{RequestMetaDataURLSSLOptions},
            \%OriginalSSLOptions,
            "$Test->{Name}: SAML SSL options are unchanged",
        );
    }
}

1;
